import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/saved_address_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart';
import 'package:BlueEra/features/me/product/model/order_checkout_payload.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart'
    show userNameGlobal, userMobileGlobal;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// What the customer chose at checkout.
class CheckoutChoice {
  /// `self-pickup` or `rider`.
  final String deliveryType;

  /// `cash` or `upi`.
  final String paymentMethod;

  /// Populated only for a rider order — and only ever with a real coordinate.
  final OrderDeliveryDetails? delivery;

  /// The quote the customer was actually shown. Recorded on the order so a
  /// later dispute has the quoted numbers rather than a recomputed guess.
  final DeliveryQuote? quote;

  const CheckoutChoice({
    required this.deliveryType,
    required this.paymentMethod,
    this.delivery,
    this.quote,
  });

  bool get isDelivery => deliveryType == OrderDeliveryType.rider;
}

/// **Checkout is where delivery is decided** (guide §5).
///
/// This sheet is what removed the manual "find a rider" button from the order
/// card. The customer chooses pickup or delivery *before the order exists*,
/// because distance, feasibility, fee, ETA and rider matching all depend on the
/// address — and the backend **refuses** a doorstep order without coordinates.
///
/// Five steps, one visible at a time, each a **gate**:
///
/// ```
/// ①───②───③───④───⑤
/// Method  Address  Quote  Payment  Review
/// ```
///
/// The gate that matters is ②: `Continue` stays disabled until latitude **and**
/// longitude both exist. Text alone is not an address here — neither the order
/// gate nor the rider search can use it.
Future<CheckoutChoice?> showOrderCheckoutSheet(
  BuildContext context, {
  required num itemsTotal,
  double? shopLat,
  double? shopLng,
  String? shopName,
  bool allowDelivery = true,
  bool allowUpi = true,
}) {
  return showModalBottomSheet<CheckoutChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: OrderElevation.sheet,
    builder: (_) => _CheckoutStepper(
      itemsTotal: itemsTotal,
      shopLat: shopLat,
      shopLng: shopLng,
      shopName: shopName,
      allowDelivery: allowDelivery,
      allowUpi: allowUpi,
    ),
  );
}

enum _Step { method, address, quote, payment, review }

class _CheckoutStepper extends StatefulWidget {
  final num itemsTotal;
  final double? shopLat;
  final double? shopLng;
  final String? shopName;
  final bool allowDelivery;
  final bool allowUpi;

  const _CheckoutStepper({
    required this.itemsTotal,
    this.shopLat,
    this.shopLng,
    this.shopName,
    required this.allowDelivery,
    required this.allowUpi,
  });

  @override
  State<_CheckoutStepper> createState() => _CheckoutStepperState();
}

class _CheckoutStepperState extends State<_CheckoutStepper> {
  _Step _step = _Step.method;

  String _deliveryType = OrderDeliveryType.selfPickup;
  String _paymentMethod = OrderPaymentMethod.cash;

  SavedAddress? _address;
  final TextEditingController _receiverName = TextEditingController();
  final TextEditingController _receiverPhone = TextEditingController();
  final TextEditingController _riderNote = TextEditingController();

  DeliveryQuote? _quote;
  bool _quoteLoading = false;
  Timer? _debounce;

  bool get _isDelivery => _deliveryType == OrderDeliveryType.rider;

  /// Delivery needs the shop's own point to quote against. Without it the
  /// sheet degrades honestly rather than showing a broken quote.
  bool get _shopLocated =>
      widget.shopLat != null &&
      widget.shopLng != null &&
      !(widget.shopLat == 0 && widget.shopLng == 0);

  bool get _deliveryOffered => widget.allowDelivery && _shopLocated;

  @override
  void initState() {
    super.initState();
    // A vertical whose service cannot take a doorstep order — or a shop with
    // no location — has nothing to choose between. Skip straight to payment
    // rather than showing a two-card question with one card greyed out.
    if (!_deliveryOffered) _step = _Step.payment;
    _receiverName.text = userNameGlobal;
    _receiverPhone.text = userMobileGlobal;
    // Warm the saved-address list so step ② can decide between "pick one" and
    // "open the picker immediately" without a flash of the wrong state.
    if (!Get.isRegistered<SavedAddressController>()) {
      Get.put(SavedAddressController());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _receiverName.dispose();
    _receiverPhone.dispose();
    _riderNote.dispose();
    super.dispose();
  }

  // ── Flow ─────────────────────────────────────────────────────────────

  List<_Step> get _steps {
    if (!_deliveryOffered) {
      // Nothing to decide about delivery: two steps, and the rail says two.
      return const [_Step.payment, _Step.review];
    }
    if (_isDelivery) {
      return const [
        _Step.method,
        _Step.address,
        _Step.quote,
        _Step.payment,
        _Step.review
      ];
    }
    // Pickup skips address and quote entirely — there is nothing to ask.
    return const [_Step.method, _Step.payment, _Step.review];
  }

  int get _index => _steps.indexOf(_step);

  bool get _canContinue {
    switch (_step) {
      case _Step.method:
        return true;
      case _Step.address:
        // ⚠ THE GATE. A typed address with no coordinate does not pass.
        return _address?.lat != null &&
            _address?.lng != null &&
            _receiverPhone.text.trim().length >= 10;
      case _Step.quote:
        // An infeasible address cannot go forward as a delivery; the step
        // itself offers the switch back to pickup.
        return !_quoteLoading && (_quote?.feasible ?? true);
      case _Step.payment:
        return true;
      case _Step.review:
        return true;
    }
  }

  void _next() {
    if (_step == _Step.review) {
      _finish();
      return;
    }
    final at = _index;
    if (at < 0 || at + 1 >= _steps.length) return;
    setState(() => _step = _steps[at + 1]);
    if (_step == _Step.quote) _fetchQuote();
  }

  void _back() {
    final at = _index;
    if (at <= 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step = _steps[at - 1]);
  }

  void _chooseMethod(String type) {
    setState(() {
      _deliveryType = type;
      if (type == OrderDeliveryType.selfPickup) {
        // Going back to pickup clears nothing — coming forward again must
        // restore the address the customer already chose.
        _quote = null;
      }
    });
  }

  void _finish() {
    final a = _address;
    Navigator.of(context).pop(CheckoutChoice(
      deliveryType: _deliveryType,
      paymentMethod: _paymentMethod,
      delivery: _isDelivery && a != null
          ? OrderDeliveryDetails(
              addressLine: a.fullAddress,
              landmark: a.landmark.isEmpty ? null : a.landmark,
              latitude: a.lat,
              longitude: a.lng,
              contactName: _receiverName.text.trim(),
              contactNo: _receiverPhone.text.trim(),
              instructions: _riderNote.text.trim().isEmpty
                  ? null
                  : _riderNote.text.trim(),
              distanceKm: _quote?.distanceKm,
              feeEstimate: _quote?.deliveryFee,
              etaMinutes: _quote?.etaMinutes,
            )
          : null,
      quote: _isDelivery ? _quote : null,
    ));
  }

  // ── Quote ────────────────────────────────────────────────────────────

  /// Fired the moment a coordinate exists, debounced 400 ms, refired on any
  /// change of the pin (guide §5.3).
  void _fetchQuote() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchQuoteNow);
  }

  Future<void> _fetchQuoteNow() async {
    final a = _address;
    if (!_shopLocated || a?.lat == null || a?.lng == null) return;
    setState(() => _quoteLoading = true);
    final q = await OrderLifecycleController.instance.fetchDeliveryQuote(
      shopLat: widget.shopLat!,
      shopLng: widget.shopLng!,
      dropLat: a!.lat!,
      dropLng: a.lng!,
      orderValue: widget.itemsTotal,
    );
    if (!mounted) return;
    setState(() {
      _quote = q;
      _quoteLoading = false;
    });
  }

  Future<void> _pickAddress() async {
    final picked = await showRideDropLocationSheet(context);
    if (picked == null || !mounted) return;
    setState(() => _address = picked);
    _fetchQuote();
  }

  num get _deliveryFee => _isDelivery ? (_quote?.deliveryFee ?? 0) : 0;

  num get _total => widget.itemsTotal + _deliveryFee;

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(OrderRadius.card)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    OrderSpace.l, OrderSpace.s, OrderSpace.l, OrderSpace.l),
                child: AnimatedSize(
                  duration: OrderMotion.zoneExpand,
                  curve: OrderMotion.curve,
                  alignment: Alignment.topCenter,
                  child: _body(),
                ),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          OrderSpace.l, OrderSpace.m, OrderSpace.s, 0),
      child: Row(
        children: [
          // The progress rail: one dot per step, filled up to where we are.
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Container(
                  width: 14,
                  height: 1.5,
                  color: AppColors.greyE5,
                );
              }
              final at = i ~/ 2;
              final done = at <= _index;
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.primaryColor : AppColors.greyE5,
                ),
              );
            }),
          ),
          const Spacer(),
          Text('Checkout',
              style: OrderType.label.copyWith(color: AppColors.grayText)),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.method:
        return _methodStep();
      case _Step.address:
        return _addressStep();
      case _Step.quote:
        return _quoteStep();
      case _Step.payment:
        return _paymentStep();
      case _Step.review:
        return _reviewStep();
    }
  }

  // ① Method — two large cards, not radio buttons, each showing the
  //    consequence of the choice so the decision is informed before it is made.
  Widget _methodStep() {
    return Column(
      key: const ValueKey('method'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How should you get it?',
            style: OrderType.title.copyWith(color: AppColors.mainTextColor)),
        const SizedBox(height: OrderSpace.m),
        Row(
          children: [
            Expanded(
              child: _choiceCard(
                icon: Icons.storefront,
                title: 'Pick it up',
                subtitle: 'Free · ready in ~20 min',
                selected: !_isDelivery,
                onTap: () => _chooseMethod(OrderDeliveryType.selfPickup),
              ),
            ),
            const SizedBox(width: OrderSpace.m),
            Expanded(
              child: _choiceCard(
                icon: Icons.delivery_dining,
                title: 'Deliver to me',
                subtitle: _deliveryOffered ? 'from ₹40' : 'not available here',
                selected: _isDelivery,
                enabled: _deliveryOffered,
                onTap: () => _chooseMethod(OrderDeliveryType.rider),
              ),
            ),
          ],
        ),
        if (!_shopLocated && widget.allowDelivery) ...[
          const SizedBox(height: OrderSpace.m),
          _note(
            tone: OrderTone.muted,
            text: 'This shop has not set a location yet, so delivery '
                "can't be quoted. You can still collect your order.",
          ),
        ],
      ],
    );
  }

  Widget _choiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(OrderRadius.inner),
        child: Container(
          padding: const EdgeInsets.all(OrderSpace.m),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(OrderRadius.inner),
            border: Border.all(
              color: selected ? AppColors.primaryColor : AppColors.greyE5,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 22,
                  color:
                      selected ? AppColors.primaryColor : AppColors.grayText),
              const SizedBox(height: OrderSpace.s),
              Text(title,
                  style: OrderType.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: OrderType.label.copyWith(color: AppColors.grayText)),
            ],
          ),
        ),
      ),
    );
  }

  // ② Address — the gate.
  Widget _addressStep() {
    final a = _address;
    final controller = Get.find<SavedAddressController>();

    return Column(
      key: const ValueKey('address'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where should we deliver?',
            style: OrderType.title.copyWith(color: AppColors.mainTextColor)),
        const SizedBox(height: OrderSpace.m),
        Obx(() {
          final saved = controller.addresses;
          if (a == null && saved.isEmpty) {
            // No saved address → open the picker immediately. Never an empty
            // state with an "Add address" button; that is one dead tap.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _address == null && _step == _Step.address) {
                _pickAddress();
              }
            });
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in saved)
                _addressRow(
                  label: s.label,
                  text: s.fullAddress,
                  selected: a?.id == s.id,
                  hasPoint: s.lat != null && s.lng != null,
                  onTap: () {
                    setState(() => _address = s);
                    _fetchQuote();
                  },
                ),
              if (a != null && saved.every((s) => s.id != a.id))
                _addressRow(
                  label: a.label.isEmpty ? 'Selected' : a.label,
                  text: a.fullAddress,
                  selected: true,
                  hasPoint: a.lat != null && a.lng != null,
                  onTap: () {},
                ),
            ],
          );
        }),
        TextButton.icon(
          onPressed: _pickAddress,
          icon: const Icon(Icons.add_location_alt_outlined, size: 18),
          label: Text('Use another address',
              style: OrderType.label.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (a != null && (a.lat == null || a.lng == null))
          _note(
            tone: OrderTone.warning,
            text: 'This address has no map location. Pick it again from the '
                'suggestions so the rider can find it.',
          ),
        const SizedBox(height: OrderSpace.m),
        Text('Receiver',
            style: OrderType.label.copyWith(
                color: AppColors.grayText, fontWeight: FontWeight.w700)),
        const SizedBox(height: OrderSpace.s),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _receiverName,
                decoration: _field('Name'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: OrderSpace.s),
            Expanded(
              child: TextField(
                controller: _receiverPhone,
                keyboardType: TextInputType.phone,
                decoration: _field('Phone'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: OrderSpace.s),
        TextField(
          controller: _riderNote,
          decoration: _field('Note to the rider (optional)'),
        ),
      ],
    );
  }

  Widget _addressRow({
    required String label,
    required String text,
    required bool selected,
    required bool hasPoint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OrderSpace.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? AppColors.primaryColor : AppColors.grayText,
            ),
            const SizedBox(width: OrderSpace.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: OrderType.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor)),
                  Text(text,
                      style:
                          OrderType.label.copyWith(color: AppColors.grayText)),
                ],
              ),
            ),
            if (!hasPoint)
              const Icon(Icons.location_off_outlined,
                  size: 16, color: Color(0xFFA96A00)),
          ],
        ),
      ),
    );
  }

  // ③ Quote — automatic, skeletoned while in flight.
  Widget _quoteStep() {
    final q = _quote;

    return Column(
      key: const ValueKey('quote'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery',
            style: OrderType.title.copyWith(color: AppColors.mainTextColor)),
        const SizedBox(height: OrderSpace.m),
        if (_quoteLoading)
          // Skeleton, never ₹0 corrected a moment later.
          const OrderCardSkeleton(lines: 2)
        else if (q == null)
          _note(
            tone: OrderTone.muted,
            text: "We couldn't get a delivery price just now. "
                'You can retry, or collect the order from the shop.',
          )
        else if (!q.feasible) ...[
          _note(
            tone: OrderTone.warning,
            text: q.message ??
                'Delivery is only available near the shop'
                    '${q.maxDistanceKm != null ? ' (within ${q.maxDistanceKm} km)' : ''}.',
          ),
          const SizedBox(height: OrderSpace.s),
          _pickupInsteadButton(),
        ] else ...[
          Text(
            [
              '₹${OrderMoneyRow.money(q.deliveryFee ?? 0)}',
              if (q.etaLabel.isNotEmpty) q.etaLabel,
              if (q.distanceKm != null) '${q.distanceKm} km',
            ].join(' · '),
            style: OrderType.mono(size: 18)
                .copyWith(color: AppColors.mainTextColor),
          ),
          if (q.breakdownRows.isNotEmpty)
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: OrderSpace.s),
                title: Text('How is this calculated?',
                    style: OrderType.label
                        .copyWith(color: AppColors.primaryColor)),
                children: [
                  for (final row in q.breakdownRows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(row.key,
                              style: OrderType.label
                                  .copyWith(color: AppColors.grayText)),
                          Text(row.value,
                              style: OrderType.label.copyWith(
                                  color: AppColors.mainTextColor,
                                  fontFeatures: OrderType.tabular)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (q.shouldWarnAboutFee) ...[
            const SizedBox(height: OrderSpace.s),
            _note(
              tone: OrderTone.warning,
              text: q.suggestion ??
                  'Delivery costs a lot compared to this order. '
                      'Picking it up is cheaper.',
            ),
            const SizedBox(height: OrderSpace.s),
            // Warns, never blocks: a customer may pay ₹84 to have a ₹10 item
            // delivered — they must only not be surprised.
            _pickupInsteadButton(),
          ],
        ],
      ],
    );
  }

  Widget _pickupInsteadButton() {
    return OutlinedButton(
      onPressed: () {
        _chooseMethod(OrderDeliveryType.selfPickup);
        setState(() => _step = _Step.payment);
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primaryColor),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OrderRadius.inner)),
      ),
      child: Text('Pick it up instead',
          style: OrderType.label.copyWith(
              color: AppColors.primaryColor, fontWeight: FontWeight.w700)),
    );
  }

  // ④ Payment
  Widget _paymentStep() {
    return Column(
      key: const ValueKey('payment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How will you pay?',
            style: OrderType.title.copyWith(color: AppColors.mainTextColor)),
        const SizedBox(height: OrderSpace.m),
        Row(
          children: [
            Expanded(
              child: _choiceCard(
                icon: Icons.payments_outlined,
                title: 'Cash',
                subtitle: 'Pay at the counter',
                selected: _paymentMethod == OrderPaymentMethod.cash,
                onTap: () =>
                    setState(() => _paymentMethod = OrderPaymentMethod.cash),
              ),
            ),
            const SizedBox(width: OrderSpace.m),
            Expanded(
              child: _choiceCard(
                icon: Icons.qr_code_2,
                title: 'UPI',
                subtitle: 'After the shop accepts',
                selected: _paymentMethod == OrderPaymentMethod.upi,
                enabled: widget.allowUpi,
                onTap: () =>
                    setState(() => _paymentMethod = OrderPaymentMethod.upi),
              ),
            ),
          ],
        ),
        if (_paymentMethod == OrderPaymentMethod.upi) ...[
          const SizedBox(height: OrderSpace.m),
          _note(
            tone: OrderTone.neutral,
            // Money is only requested after a shop commits. If the shop turns
            // out to be closed, nobody has to be refunded.
            text: "You'll be asked to pay once the shop accepts the order — "
                'not before.',
          ),
        ],
      ],
    );
  }

  // ⑤ Review
  Widget _reviewStep() {
    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review',
            style: OrderType.title.copyWith(color: AppColors.mainTextColor)),
        const SizedBox(height: OrderSpace.s),
        _summaryRow(
          Icons.storefront,
          _isDelivery ? 'Delivered to you' : 'Collect from the shop',
          _isDelivery ? (_address?.fullAddress ?? '') : (widget.shopName ?? ''),
        ),
        _summaryRow(
          _paymentMethod == OrderPaymentMethod.upi
              ? Icons.qr_code_2
              : Icons.payments_outlined,
          _paymentMethod == OrderPaymentMethod.upi ? 'UPI' : 'Cash',
          _paymentMethod == OrderPaymentMethod.upi
              ? 'Requested after the shop accepts'
              : 'Pay when you collect',
        ),
        const SizedBox(height: OrderSpace.s),
        const OrderZoneDivider(),
        OrderMoneyRow(label: 'Items', amount: widget.itemsTotal),
        if (_isDelivery) OrderMoneyRow(label: 'Delivery', amount: _deliveryFee),
        OrderMoneyRow(label: 'Total', amount: _total, emphasise: true),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OrderSpace.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.grayText),
          const SizedBox(width: OrderSpace.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: OrderType.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor)),
                if (detail.isNotEmpty)
                  Text(detail,
                      style:
                          OrderType.label.copyWith(color: AppColors.grayText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final isLast = _step == _Step.review;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            OrderSpace.l, OrderSpace.s, OrderSpace.l, OrderSpace.m),
        child: Row(
          children: [
            if (_index > 0)
              TextButton(
                onPressed: _back,
                child: Text('Back',
                    style: OrderType.label.copyWith(
                        color: AppColors.grayText,
                        fontWeight: FontWeight.w700)),
              ),
            const Spacer(),
            if (isLast)
              Text('₹${OrderMoneyRow.money(_total)}',
                  style: OrderType.mono(size: 18)
                      .copyWith(color: AppColors.mainTextColor)),
            const SizedBox(width: OrderSpace.m),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _canContinue ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  disabledBackgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: OrderSpace.xl),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(OrderRadius.inner)),
                ),
                child: Text(isLast ? 'Place order' : 'Continue',
                    style: OrderType.body.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _note({required OrderTone tone, required String text}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: OrderSpace.s),
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
            child:
                Text(text, style: OrderType.label.copyWith(color: tone.color)),
          ),
        ],
      ),
    );
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: OrderType.label.copyWith(color: AppColors.grayText),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: OrderSpace.m, vertical: OrderSpace.m),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OrderRadius.inner),
          borderSide: const BorderSide(color: AppColors.greyE5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OrderRadius.inner),
          borderSide: const BorderSide(color: AppColors.greyE5),
        ),
      );
}
