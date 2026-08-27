import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_broadcast_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_controllar.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart';
import 'package:flutter/material.dart';

/// The **self-pickup** escape hatch: *"Can't come? Get it delivered"*
/// (guide §5.5).
///
/// This is the only remaining `FIND_RIDER` case. A doorstep order never gets
/// here — it was quoted at checkout and dispatches by itself at `ready`. What
/// this sheet must **not** do is what the old button did: leave the chat for a
/// full-screen rider-booking flow and re-ask for an address.
///
/// Address → quote → confirm → dispatch, all in one sheet, and the card's live
/// search block takes over from there.
Future<void> showFindRiderSheet(
  BuildContext context, {
  required OrderCardContext ctx,
}) async {
  final businessId = ctx.businessId ?? '';
  if (businessId.isEmpty) {
    commonSnackBar(message: 'This shop cannot arrange delivery right now.');
    return;
  }

  // 1. Where to. The only time an address is asked for after checkout.
  final SavedAddress? drop = await showRideDropLocationSheet(context);
  if (drop == null || !context.mounted) return;
  if (drop.lat == null || drop.lng == null) {
    commonSnackBar(
      message: 'That address has no map location. '
          'Please pick it again from the suggestions.',
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: OrderElevation.sheet,
    builder: (_) => _FindRiderSheet(ctx: ctx, drop: drop),
  );
}

class _FindRiderSheet extends StatefulWidget {
  final OrderCardContext ctx;
  final SavedAddress drop;

  const _FindRiderSheet({required this.ctx, required this.drop});

  @override
  State<_FindRiderSheet> createState() => _FindRiderSheetState();
}

class _FindRiderSheetState extends State<_FindRiderSheet> {
  bool _loading = true;
  bool _dispatching = false;
  DeliveryQuote? _quote;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quote0();
  }

  /// Quote **before** the customer commits, exactly as checkout does.
  Future<void> _quote0() async {
    try {
      final orderNow = getOrPut(() => OrderNowController());
      await orderNow.viewBusinessForLocation(
          widget.ctx.businessId!, 'BUSINESS');
      final shopLat = double.tryParse(orderNow.lat.value) ?? 0.0;
      final shopLng = double.tryParse(orderNow.long.value) ?? 0.0;
      if (shopLat == 0.0 && shopLng == 0.0) {
        setState(() {
          _loading = false;
          _error = "We couldn't find the shop's location.";
        });
        return;
      }
      final q = await OrderLifecycleController.instance.fetchDeliveryQuote(
        shopLat: shopLat,
        shopLng: shopLng,
        dropLat: widget.drop.lat!,
        dropLng: widget.drop.lng!,
        orderValue: widget.ctx.orderTotal,
      );
      if (!mounted) return;
      setState(() {
        _quote = q;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "We couldn't get a delivery price just now.";
      });
    }
  }

  Future<void> _dispatch() async {
    final q = _quote;
    setState(() => _dispatching = true);
    final ok = await OrderBroadcastController.instance.dispatch(
      orderId: widget.ctx.orderId,
      service: widget.ctx.service,
      businessId: widget.ctx.businessId!,
      selfpickupType: widget.ctx.selfpickupType ?? 'product_selfpickup',
      orderFor: widget.ctx.orderFor,
      orderValue: widget.ctx.orderTotal,
      // The address the customer just picked, with the numbers they were just
      // shown. Nothing is re-asked and nothing is recomputed behind them.
      dropOverride: OrderDeliveryInfo(
        addressLine: widget.drop.fullAddress,
        landmark: widget.drop.landmark.isEmpty ? null : widget.drop.landmark,
        latitude: widget.drop.lat,
        longitude: widget.drop.lng,
        distanceKm: q?.distanceKm,
        feeEstimate: q?.deliveryFee,
        etaMinutes: q?.etaMinutes,
      ),
    );
    if (!mounted) return;
    setState(() => _dispatching = false);
    Navigator.of(context).pop();
    if (!ok) {
      commonSnackBar(
        message: "We couldn't start the delivery search. "
            'Your order is still packed and waiting at the shop.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote;
    final infeasible = q != null && !q.feasible;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          OrderSpace.l, OrderSpace.m, OrderSpace.l, OrderSpace.l),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(OrderRadius.card)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Get it delivered',
                      style: OrderType.title
                          .copyWith(color: AppColors.mainTextColor)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            Text(widget.drop.fullAddress,
                style: OrderType.label.copyWith(color: AppColors.grayText)),
            const SizedBox(height: OrderSpace.m),
            if (_loading)
              const OrderCardSkeleton(lines: 2)
            else if (_error != null)
              _note(OrderTone.warning, _error!)
            else if (infeasible)
              _note(
                OrderTone.warning,
                q.message ??
                    'Delivery is only available near the shop'
                        '${q.maxDistanceKm != null ? ' (within ${q.maxDistanceKm} km)' : ''}.',
              )
            else if (q != null) ...[
              Text(
                [
                  '₹${OrderMoneyRow.money(q.deliveryFee ?? 0)}',
                  if (q.etaLabel.isNotEmpty) q.etaLabel,
                  if (q.distanceKm != null) '${q.distanceKm} km',
                ].join(' · '),
                style: OrderType.mono(size: 18)
                    .copyWith(color: AppColors.mainTextColor),
              ),
              if (q.shouldWarnAboutFee) ...[
                const SizedBox(height: OrderSpace.s),
                // Warns, never blocks.
                _note(
                    OrderTone.warning,
                    q.suggestion ??
                        'Delivery costs a lot compared to this order. '
                            'Collecting it is cheaper.'),
              ],
            ],
            const SizedBox(height: OrderSpace.l),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed:
                    (_loading || _dispatching || infeasible) ? null : _dispatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  disabledBackgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OrderRadius.inner)),
                ),
                child: _dispatching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Find a delivery partner',
                        style: OrderType.body.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _note(OrderTone tone, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(OrderSpace.s),
        decoration: BoxDecoration(
          color: tone.surface,
          borderRadius: BorderRadius.circular(OrderRadius.inner),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tone.icon, size: 15, color: tone.color),
            const SizedBox(width: OrderSpace.s),
            Expanded(
              child: Text(text,
                  style: OrderType.label.copyWith(color: tone.color)),
            ),
          ],
        ),
      );
}
