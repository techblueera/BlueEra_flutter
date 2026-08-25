import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart';
import 'package:BlueEra/features/me/product/model/order_checkout_payload.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// What the customer chose at checkout.
class CheckoutChoice {
  /// `self-pickup` or `rider`.
  final String deliveryType;

  /// `cash` or `upi`.
  final String paymentMethod;

  /// Populated only for a rider order.
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

/// The checkout sheet (guide §4.2):
///
/// ```
/// How do you want it?   ( ) Pick up from the shop   (•) Deliver to my address
/// Deliver to: 12 MG Road, 560001                                        [>]
/// Delivery: ₹44 · 15–30 min
/// ⚠ Delivery costs more than your order. Picking it up is cheaper.
/// How will you pay?     (•) Cash    ( ) UPI
/// Items ₹500 · Delivery ₹44 · Total ₹544                    [ Place order ]
/// ```
///
/// Two rules it exists to hold:
///
///  * **The quote is fetched before the customer commits, not after.** The fee
///    they see is the fee the order records.
///  * **A high fee warns; it never blocks.** A customer who wants their ₹10
///    item delivered is allowed to pay ₹84 for it — they just must not be
///    surprised by it. `feasible:false` is the only thing that disables
///    delivery, and even then self-pickup is auto-selected rather than the
///    checkout being dead-ended.
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
    builder: (_) => _OrderCheckoutSheet(
      itemsTotal: itemsTotal,
      shopLat: shopLat,
      shopLng: shopLng,
      shopName: shopName,
      allowDelivery: allowDelivery,
      allowUpi: allowUpi,
    ),
  );
}

class _OrderCheckoutSheet extends StatefulWidget {
  final num itemsTotal;
  final double? shopLat;
  final double? shopLng;
  final String? shopName;
  final bool allowDelivery;
  final bool allowUpi;

  const _OrderCheckoutSheet({
    required this.itemsTotal,
    this.shopLat,
    this.shopLng,
    this.shopName,
    required this.allowDelivery,
    required this.allowUpi,
  });

  @override
  State<_OrderCheckoutSheet> createState() => _OrderCheckoutSheetState();
}

class _OrderCheckoutSheetState extends State<_OrderCheckoutSheet> {
  String _deliveryType = OrderDeliveryType.selfPickup;
  String _paymentMethod = OrderPaymentMethod.cash;

  SavedAddress? _address;
  DeliveryQuote? _quote;
  bool _loadingQuote = false;
  Timer? _debounce;

  /// True when the shop has no coordinates — delivery cannot even be quoted.
  bool get _canQuote =>
      widget.allowDelivery &&
      (widget.shopLat ?? 0) != 0 &&
      (widget.shopLng ?? 0) != 0;

  bool get _deliveryUsable =>
      _canQuote && (_quote == null || _quote!.feasible);

  num get _deliveryFee =>
      (_deliveryType == OrderDeliveryType.rider && _quote?.feasible == true)
          ? (_quote?.deliveryFee ?? 0)
          : 0;

  num get _total => widget.itemsTotal + _deliveryFee;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final picked = await showRideDropLocationSheet(context);
    if (picked == null || !mounted) return;
    setState(() => _address = picked);
    _scheduleQuote();
  }

  /// ~400 ms debounce on address change, per the guide.
  void _scheduleQuote() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchQuote);
  }

  Future<void> _fetchQuote() async {
    final addr = _address;
    if (!_canQuote || addr?.lat == null || addr?.lng == null) return;

    setState(() => _loadingQuote = true);
    final quote = await OrderLifecycleController.instance.fetchDeliveryQuote(
      shopLat: widget.shopLat!,
      shopLng: widget.shopLng!,
      dropLat: addr!.lat!,
      dropLng: addr.lng!,
      orderValue: widget.itemsTotal,
    );
    if (!mounted) return;
    setState(() {
      _quote = quote;
      _loadingQuote = false;
      // `feasible:false` is a 200, not an error. Disable delivery and put the
      // customer back on self-pickup rather than dead-ending the checkout.
      if (quote != null && !quote.feasible) {
        _deliveryType = OrderDeliveryType.selfPickup;
      }
    });
  }

  void _submit() {
    final isDelivery = _deliveryType == OrderDeliveryType.rider;
    final addr = _address;
    OrderDeliveryDetails? delivery;
    if (isDelivery && addr != null) {
      delivery = OrderDeliveryDetails(
        addressLine: addr.address.isNotEmpty ? addr.address : addr.fullAddress,
        landmark: addr.landmark,
        latitude: addr.lat,
        longitude: addr.lng,
        instructions: addr.houseNo.isNotEmpty ? 'House ${addr.houseNo}' : null,
        distanceKm: _quote?.distanceKm,
        feeEstimate: _quote?.deliveryFee,
        etaMinutes: _quote?.etaMinutes,
      );
    }
    Navigator.of(context).pop(CheckoutChoice(
      deliveryType: _deliveryType,
      paymentMethod: _paymentMethod,
      delivery: delivery,
      quote: isDelivery ? _quote : null,
    ));
  }

  bool get _canPlace {
    if (_deliveryType != OrderDeliveryType.rider) return true;
    return _address != null && _quote?.feasible == true && !_loadingQuote;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _sectionTitle('How do you want it?'),
              _radio(
                label: 'Pick up from the shop',
                value: OrderDeliveryType.selfPickup,
                group: _deliveryType,
                onChanged: (v) => setState(() => _deliveryType = v),
              ),
              _radio(
                label: 'Deliver to my address',
                value: OrderDeliveryType.rider,
                group: _deliveryType,
                enabled: _deliveryUsable,
                subtitle: !_canQuote
                    ? 'This shop has not set a location yet.'
                    : (_quote?.feasible == false ? _quote?.message : null),
                onChanged: (v) {
                  setState(() => _deliveryType = v);
                  if (_address == null) {
                    _pickAddress();
                  } else {
                    _scheduleQuote();
                  }
                },
              ),

              if (_deliveryType == OrderDeliveryType.rider) ...[
                const SizedBox(height: 8),
                _addressRow(),
                const SizedBox(height: 8),
                _quoteRow(),
              ],

              const SizedBox(height: 18),
              _sectionTitle('How will you pay?'),
              Row(
                children: [
                  Expanded(
                    child: _radio(
                      label: 'Cash',
                      value: OrderPaymentMethod.cash,
                      group: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v),
                    ),
                  ),
                  Expanded(
                    child: _radio(
                      label: 'UPI',
                      value: OrderPaymentMethod.upi,
                      group: _paymentMethod,
                      enabled: widget.allowUpi,
                      onChanged: (v) => setState(() => _paymentMethod = v),
                    ),
                  ),
                ],
              ),
              if (_paymentMethod == OrderPaymentMethod.upi)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: CustomText(
                    // Money is only requested after acceptance — if the shop
                    // turns out to be closed, nobody has to be refunded.
                    'You\'ll pay after the shop accepts your order.',
                    fontSize: SizeConfig.size12,
                    color: AppColors.secondaryTextColor,
                  ),
                ),

              const SizedBox(height: 18),
              const Divider(height: 1, color: AppColors.greyE5),
              const SizedBox(height: 12),
              _totalRow('Items', widget.itemsTotal),
              if (_deliveryType == OrderDeliveryType.rider)
                _totalRow('Delivery', _deliveryFee),
              const SizedBox(height: 6),
              _totalRow('Total', _total, emphasise: true),

              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _canPlace ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor:
                        AppColors.primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: CustomText(
                    'Place order',
                    fontSize: SizeConfig.size15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: CustomText(
          text,
          fontSize: SizeConfig.size15,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
      );

  Widget _radio({
    required String label,
    required String value,
    required String group,
    required ValueChanged<String> onChanged,
    bool enabled = true,
    String? subtitle,
  }) {
    final selected = group == value;
    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: !enabled
                  ? AppColors.greyE5
                  : (selected ? AppColors.primaryColor : AppColors.grayText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    label,
                    fontSize: SizeConfig.size14,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? AppColors.mainTextColor
                        : AppColors.grayText,
                  ),
                  if ((subtitle ?? '').isNotEmpty)
                    CustomText(
                      subtitle!,
                      fontSize: SizeConfig.size11,
                      color: AppColors.grayText,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressRow() {
    final addr = _address;
    return InkWell(
      onTap: _pickAddress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 20, color: AppColors.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                addr == null
                    ? 'Choose a delivery address'
                    : 'Deliver to: ${addr.fullAddress}',
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grayText),
          ],
        ),
      ),
    );
  }

  Widget _quoteRow() {
    if (_loadingQuote) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 8),
          CustomText(
            'Checking delivery…',
            fontSize: SizeConfig.size12,
            color: AppColors.secondaryTextColor,
          ),
        ],
      );
    }

    final q = _quote;
    if (q == null) {
      return CustomText(
        _address == null
            ? 'Pick an address to see the delivery charge.'
            : 'Delivery charge unavailable right now.',
        fontSize: SizeConfig.size12,
        color: AppColors.secondaryTextColor,
      );
    }

    if (!q.feasible) {
      return _amberNote(
        q.message ?? 'Delivery is not available to this address.',
        icon: Icons.block,
        showPickupShortcut: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Delivery: ₹${_money(q.deliveryFee ?? 0)}'
          '${q.etaLabel.isEmpty ? '' : ' · ${q.etaLabel}'}',
          fontSize: SizeConfig.size13,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        // Warn, never block.
        if (q.shouldWarnAboutFee) ...[
          const SizedBox(height: 6),
          _amberNote(
            q.suggestion ??
                'Delivery costs a lot compared to this order — collecting it '
                    'from the shop may be cheaper.',
            showPickupShortcut: true,
          ),
        ],
      ],
    );
  }

  Widget _amberNote(String text,
      {IconData icon = Icons.warning_amber_rounded,
      bool showPickupShortcut = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9A100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 15, color: const Color(0xFFA96A00)),
              const SizedBox(width: 6),
              Expanded(
                child: CustomText(
                  text,
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFA96A00),
                  maxLines: 4,
                ),
              ),
            ],
          ),
          if (showPickupShortcut)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(
                    () => _deliveryType = OrderDeliveryType.selfPickup),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: CustomText(
                  'Pick it up instead',
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, num value, {bool emphasise = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            label,
            fontSize: emphasise ? SizeConfig.size15 : SizeConfig.size13,
            fontWeight: emphasise ? FontWeight.w700 : FontWeight.w500,
            color: emphasise
                ? AppColors.mainTextColor
                : AppColors.secondaryTextColor,
          ),
          CustomText(
            '₹${_money(value)}',
            fontSize: emphasise ? SizeConfig.size18 : SizeConfig.size13,
            fontWeight: emphasise ? FontWeight.w800 : FontWeight.w600,
            color: emphasise ? AppColors.primaryColor : AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }

  static String _money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
