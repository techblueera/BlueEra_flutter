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
/// Four steps, one visible at a time, each a **gate**:
///
/// ```
/// ①────────②───────③────────④
/// Address  Method  Payment  Review
/// ```
///
/// **Address comes first, and it did not used to.** The old order asked
/// "pick it up or have it delivered?" on step ① — before any address existed
/// — so the delivery card could only advertise a hardcoded `from ₹40`, and
/// §17.2's rule that self-pickup becomes the *default* when the fee exceeds
/// the basket was unreachable: the customer had already chosen. Now the quote
/// fires the moment a coordinate lands and is rendered **on the delivery card
/// itself**, so the price and the choice are the same screen. Someone who
/// never wanted delivery skips ① in one tap.
///
/// The gate that matters is ①: `Continue` stays disabled until latitude **and**
/// longitude both exist. Text alone is not an address here — neither the order
/// gate nor the rider search can use it.
///
/// The step order is [kOrderCheckoutSteps], named so the sequence itself can be
/// pinned by a test rather than living only inside a private getter.
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

/// The checkout steps, in the order guide §17.3 puts them.
///
/// **`address` comes before `method` on purpose, and this used to be wrong.**
/// The sheet asked "pick it up or have it delivered?" first, which meant the
/// delivery card could only advertise a made-up "from ₹40" — the real fee
/// cannot be known until there is a drop point to quote against. Two rules in
/// §17.2 are unreachable in that order: the fee has to be visible *at the
/// moment of choosing*, and when it exceeds the basket self-pickup has to be
/// the **default** selection, which is meaningless once the customer has
/// already chosen.
///
/// There is no separate `quote` step any more. The quote fires the moment a
/// coordinate exists and lands **on the delivery card itself**, so the choice
/// and the price are one screen rather than two.
enum _Step { address, method, payment, review }

/// The full checkout sequence, in the order guide §17.3 puts it:
/// address → quote → choose fulfilment → choose payment → place.
///
/// The quote is not a step of its own — it fires on the address and renders on
/// the delivery card — so §17.3's five lines are four screens. What matters,
/// and what this constant exists to pin, is that **`address` precedes
/// `method`**: the fee cannot be shown at the moment of choosing otherwise.
const List<_Step> kOrderCheckoutSteps = [
  _Step.address,
  _Step.method,
  _Step.payment,
  _Step.review,
];

/// A shop with no location, or a vertical whose service cannot take a doorstep
/// order, has nothing to choose between and nothing to price. Asking for a
/// delivery address there would be a dead step.
const List<_Step> kOrderCheckoutStepsNoDelivery = [
  _Step.payment,
  _Step.review,
];

/// Whether the checkout asks where to deliver **before** it asks how the order
/// should be fulfilled. Both must be true for §17.2 to be renderable at all.
bool get orderCheckoutAsksAddressFirst =>
    kOrderCheckoutSteps.indexOf(_Step.address) <
    kOrderCheckoutSteps.indexOf(_Step.method);

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
  _Step _step = _Step.address;

  /// Whether the customer has actually touched the fulfilment choice.
  ///
  /// Until they have, §17.2 is allowed to pre-select self-pickup for them when
  /// the quote comes back saying delivery costs more than the basket. After
  /// they have, it never moves under them again — a warning that silently
  /// changes a choice you just made is worse than no warning.
  bool _methodChosen = false;

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

  /// One shape, whichever fulfilment wins.
  ///
  /// The old flow branched here — pickup got three steps, delivery five — so
  /// the progress rail changed length under the customer the instant they
  /// tapped a card. Address first means the rail is honest from the first
  /// frame, and a customer who wants to collect can skip the address in one
  /// tap (see [_skipAddressForPickup]) rather than being marched through it.
  List<_Step> get _steps {
    if (!_deliveryOffered) {
      // Nothing to decide about delivery: two steps, and the rail says two.
      return kOrderCheckoutStepsNoDelivery;
    }
    return kOrderCheckoutSteps;
  }

  int get _index => _steps.indexOf(_step);

  bool get _canContinue {
    switch (_step) {
      case _Step.address:
        // ⚠ THE GATE. A typed address with no coordinate does not pass — a
        // rider order with no drop point is one nobody can fulfil (§17.3).
        return _address?.lat != null &&
            _address?.lng != null &&
            _receiverPhone.text.trim().length >= 10;
      case _Step.method:
        // Pickup is always allowed. Delivery waits for a quote, and an
        // infeasible address cannot go forward as one — the card itself
        // offers the switch back (§17.2 "out of range").
        if (!_isDelivery) return true;
        return !_quoteLoading && (_quote?.feasible ?? false);
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
  }

  /// "I'll collect it myself", from the address step.
  ///
  /// Address-first is right for pricing and wrong for a customer who was never
  /// going to want delivery, so they get one tap past it. It sets the choice
  /// explicitly, which also means §17.2 will not later move it back.
  void _skipAddressForPickup() {
    setState(() {
      _deliveryType = OrderDeliveryType.selfPickup;
      _methodChosen = true;
      _quote = null;
      _step = _Step.payment;
    });
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
      // From here on the choice is theirs and §17.2 must not move it.
      _methodChosen = true;
      if (type == OrderDeliveryType.selfPickup) {
        // Going back to pickup clears the fee, not the address — coming
        // forward again must restore the address they already chose.
        _quote = null;
      } else {
        // Re-quote if the address was picked while pickup was selected.
        if (_quote == null) _fetchQuote();
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
      // §17.2, "fee exceeds basket": *"make self-pickup the default
      // selection. Never let this be a silent surprise."* Only ever before the
      // customer has chosen for themselves — after that the choice is theirs
      // and the warning stays a warning. The suggestion is still rendered
      // verbatim beside the cards either way, so the default is never silent.
      if (!_methodChosen && (q?.feeExceedsOrderValue ?? false)) {
        _deliveryType = OrderDeliveryType.selfPickup;
      }
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
      case _Step.address:
        return _addressStep();
      case _Step.method:
        return _methodStep();
      case _Step.payment:
        return _paymentStep();
      case _Step.review:
        return _reviewStep();
    }
  }

  // ② Method — two large cards, not radio buttons, each showing the
  //    consequence of the choice so the decision is informed before it is made.
  //
  //    Everything §17.2 asks for lands HERE, because this is the moment of
  //    choosing: the real quoted fee, the ETA range, the economics suggestion
  //    verbatim, the out-of-range message, and the breakdown disclosure.
  Widget _methodStep() {
    final q = _quote;
    final outOfRange = q != null && !q.feasible;

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
                subtitle: 'Free · from the shop',
                selected: !_isDelivery,
                onTap: () => _chooseMethod(OrderDeliveryType.selfPickup),
              ),
            ),
            const SizedBox(width: OrderSpace.m),
            Expanded(
              child: _choiceCard(
                icon: Icons.delivery_dining,
                title: 'Deliver to me',
                // Never a made-up price. Until the quote lands this says so;
                // it never guesses a number the server has not sent (§17.1:
                // "never send a fee the user did not see").
                subtitle: _deliveryCardSubtitle(),
                selected: _isDelivery,
                enabled: _deliveryOffered && !outOfRange,
                onTap: () => _chooseMethod(OrderDeliveryType.rider),
              ),
            ),
          ],
        ),

        // Out of range is a 200 carrying a reason, not an error (§17.2). The
        // delivery card is disabled above; pickup stays selectable.
        if (outOfRange) ...[
          const SizedBox(height: OrderSpace.m),
          _note(
            tone: OrderTone.warning,
            text: q.message ??
                'Delivery is only available near the shop'
                    '${q.maxDistanceKm != null ? ' (within ${q.maxDistanceKm} km)' : ''}.',
          ),
        ],

        // The quote could not be fetched at all — offer the retry rather than
        // pretending delivery is impossible.
        if (!_quoteLoading && q == null && _address != null) ...[
          const SizedBox(height: OrderSpace.m),
          _note(
            tone: OrderTone.muted,
            text: "We couldn't get a delivery price just now. "
                'You can retry, or collect the order from the shop.',
          ),
          TextButton(
            onPressed: _fetchQuoteNow,
            child: Text('Retry',
                style: OrderType.label.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
        ],

        if (q != null && q.feasible) ...[
          if (q.peak) ...[
            const SizedBox(height: OrderSpace.s),
            _note(
              tone: OrderTone.muted,
              text: 'Busy right now, so fares are higher than usual.',
            ),
          ],

          // "Delivery costs a lot compared to this order…" — the server's own
          // sentence, verbatim, never paraphrased.
          if (q.shouldWarnAboutFee) ...[
            const SizedBox(height: OrderSpace.s),
            _note(
              tone: OrderTone.warning,
              text: q.suggestion ??
                  'Delivery costs a lot compared to this order. '
                      'Picking it up is cheaper.',
            ),
          ],

          // An unexplained delivery fee is the commonest cause of checkout
          // abandonment, so the arithmetic is one tap away (§17.2).
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
        ],

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

  /// What the delivery card says under its title.
  ///
  /// Four honest answers and **no fifth invented one**. This used to read
  /// `from ₹40` — a number nothing had computed, shown before any address
  /// existed to compute it from.
  String _deliveryCardSubtitle() {
    if (!_deliveryOffered) return 'not available here';
    if (_quoteLoading) return 'checking…';
    final q = _quote;
    if (q == null) return 'price unavailable';
    if (!q.feasible) return 'too far to deliver';
    return [
      '₹${OrderMoneyRow.money(q.deliveryFee ?? 0)}',
      if (q.etaLabel.isNotEmpty) q.etaLabel,
    ].join(' · ');
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
        const SizedBox(height: 2),
        // Address-first is right for *pricing* delivery and wrong for someone
        // who was never going to want it. One tap out, rather than marching
        // them through a step they do not need (§17.3 puts the address first
        // because the fee depends on it — not to make collection harder).
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _skipAddressForPickup,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text("I'll collect it from the shop",
                style: OrderType.label.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: OrderSpace.s),
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
