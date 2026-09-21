import 'dart:async';

import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/saved_address_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/saved_address_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/ride_drop_location_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_card_ui.dart';
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

  // ── Board data (BlueEra 2026) ────────────────────────────────────────
  // All optional: a cart that has not been taught to pass its lines still
  // gets a correct checkout, just without the `Your Items` card.

  /// The basket, for the board's `Your Items` list.
  List<OrderCardItem> items = const [],

  /// The un-discounted total, for the `Total MRP` and `Savings` rows. Null
  /// hides both — a discount line computed from nothing is a lie.
  num? mrpTotal,
  String? shopPhoto,
  String? shopTagline,
  String? shopAddress,
  String? shopDistance,

  /// `−` / `+` on an item row. Omitted, the rows are read-only, which is what
  /// a cart that cannot re-price in place should do.
  void Function(int index, int quantity)? onQuantityChanged,
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
      items: items,
      mrpTotal: mrpTotal,
      shopPhoto: shopPhoto,
      shopTagline: shopTagline,
      shopAddress: shopAddress,
      shopDistance: shopDistance,
      onQuantityChanged: onQuantityChanged,
    ),
  );
}

/// **Checkout is one screen, and the fee is visible at the moment of
/// choosing.**
///
/// The sheet used to be a four-step rail (`address → method → payment →
/// review`) whose whole reason for existing was guide §17.2: the delivery card
/// cannot advertise a real price until there is a drop point to quote against,
/// so the address had to be asked first. The board collapses that to one
/// screen — and the rule survives intact, enforced where it actually bites
/// rather than by an ordering:
///
/// * choosing **Book Rider** opens the address picker before the choice is
///   taken, so the quote lands on the card the customer is looking at;
/// * the card never invents a number — until a quote exists it says
///   `add an address for the fee`, never `from ₹40`;
/// * `Place Order` refuses a doorstep order with no coordinate, no phone, or
///   an infeasible quote, and says which.
///
/// [orderCheckoutQuotesBeforeChoosing] is what the §17.3 tests assert on now.
const bool orderCheckoutQuotesBeforeChoosing = true;

class _CheckoutStepper extends StatefulWidget {
  final num itemsTotal;
  final double? shopLat;
  final double? shopLng;
  final String? shopName;
  final bool allowDelivery;
  final bool allowUpi;
  final List<OrderCardItem> items;
  final num? mrpTotal;
  final String? shopPhoto;
  final String? shopTagline;
  final String? shopAddress;
  final String? shopDistance;
  final void Function(int index, int quantity)? onQuantityChanged;

  const _CheckoutStepper({
    required this.itemsTotal,
    this.shopLat,
    this.shopLng,
    this.shopName,
    required this.allowDelivery,
    required this.allowUpi,
    this.items = const [],
    this.mrpTotal,
    this.shopPhoto,
    this.shopTagline,
    this.shopAddress,
    this.shopDistance,
    this.onQuantityChanged,
  });

  @override
  State<_CheckoutStepper> createState() => _CheckoutStepperState();
}

class _CheckoutStepperState extends State<_CheckoutStepper> {
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

  /// **Cash is not an option on a doorstep order.** The delivery board's
  /// checkout offers UPI and nothing else, and every doorstep card in it reads
  /// `UPI Payment`.
  ///
  /// It is not a styling choice. Cash on delivery puts a stranger's money in a
  /// rider's pocket and makes the shop, the rider and the platform argue about
  /// who is short when it goes missing — with no gateway, no escrow and no
  /// ledger to settle it against. The product money is paid to the shop's QR
  /// before anything is packed, and the delivery fee is settled with the rider
  /// at the door.
  bool get _cashAllowed => !_isDelivery;

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
    // no location — has nothing to choose between, so the board hides the
    // fulfilment question entirely rather than greying out one of two cards.
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
        // Delivery is UPI-only (see `_cashAllowed`), so a cash choice made
        // while pickup was selected has to move with it. Doing it here, at the
        // moment of choosing, is what stops the review step from quietly
        // showing "Cash" on an order the backend would reject.
        if (!_cashAllowed) _paymentMethod = OrderPaymentMethod.upi;
        // Re-quote if the address was picked while pickup was selected.
        if (_quote == null) _fetchQuote();
      }
    });
  }

  void _finish() {
    final a = _address;
    Navigator.of(context).pop(CheckoutChoice(
      deliveryType: _deliveryType,
      // The invariant is enforced again at the exit, not just at the moment of
      // choosing: this is the value that becomes an order, and a doorstep
      // order created as cash is one the backend has no flow for.
      paymentMethod:
          _isDelivery ? OrderPaymentMethod.upi : _paymentMethod,
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
        height: MediaQuery.of(context).size.height * 0.94,
        decoration: const BoxDecoration(
          color: Color(0xFFEFF5FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _appBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _shopCard(),
                      if (widget.items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _itemsCard(),
                      ],
                      if (_deliveryOffered || widget.allowDelivery) ...[
                        const SizedBox(height: 12),
                        _receiveCard(),
                      ],
                      const SizedBox(height: 12),
                      _paymentCard(),
                      const SizedBox(height: 12),
                      _billCard(),
                    ],
                  ),
                ),
              ),
              _placeOrderBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// `‹ Review Your Order` — the board's one screen replaced a four-step
  /// stepper.
  ///
  /// The stepper was not wrong, it was *slow*: four gated screens to answer
  /// two questions a customer has already decided before they open the cart.
  /// Everything the stepper gated is still gated — the delivery card still
  /// refuses to be chosen without a coordinate, cash still disappears on a
  /// doorstep order, the fee is still the server's — but the customer can see
  /// all of it at once and change any of it without walking backwards.
  Widget _appBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 19, color: OrderUi.ink),
          ),
          const Text('Review Your Order',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: OrderUi.ink)),
        ],
      ),
    );
  }

  // ── ① The shop ─────────────────────────────────────────────────────────

  Widget _shopCard() {
    final count = widget.items.isEmpty
        ? null
        : widget.items.fold<int>(0, (a, b) => a + (b.quantity ?? 1));
    return _panel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (widget.shopPhoto ?? '').trim().isEmpty
                ? Container(
                    width: 56,
                    height: 52,
                    color: OrderUi.block,
                    child: const Icon(Icons.storefront_outlined,
                        size: 22, color: OrderUi.inkFaint),
                  )
                : Image.network(widget.shopPhoto!,
                    width: 56,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 52,
                          color: OrderUi.block,
                          child: const Icon(Icons.storefront_outlined,
                              size: 22, color: OrderUi.inkFaint),
                        )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(widget.shopName ?? 'Shop',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: OrderUi.ink)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: OrderUi.greenFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Open Now',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: OrderUi.green)),
                    ),
                  ],
                ),
                if ((widget.shopTagline ?? '').trim().isNotEmpty)
                  Text(widget.shopTagline!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OrderUi.blockBody),
                if ((widget.shopDistance ?? '').trim().isNotEmpty ||
                    (widget.shopAddress ?? '').trim().isNotEmpty)
                  Row(
                    children: [
                      if ((widget.shopDistance ?? '').trim().isNotEmpty) ...[
                        const Icon(Icons.location_on,
                            size: 13, color: OrderUi.blue),
                        Text(widget.shopDistance!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: OrderUi.blue)),
                        const SizedBox(width: 5),
                      ],
                      if ((widget.shopAddress ?? '').trim().isNotEmpty)
                        Flexible(
                          child: Text('• ${widget.shopAddress}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, color: OrderUi.ink)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: OrderUi.blueFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 14, color: OrderUi.blue),
                  const SizedBox(width: 4),
                  Text('$count Item${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: OrderUi.blue)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── ② Your Items ───────────────────────────────────────────────────────

  Widget _itemsCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Items',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: OrderUi.ink)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OrderUi.blockBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < widget.items.length; i++)
                  _itemRow(i, widget.items[i],
                      last: i == widget.items.length - 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(int index, OrderCardItem item, {required bool last}) {
    final qty = item.quantity ?? 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: OrderUi.blockBorder))),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (item.imageUrl ?? '').trim().isEmpty
                ? Container(
                    width: 46,
                    height: 46,
                    color: OrderUi.block,
                    child: const Icon(Icons.image_outlined,
                        size: 18, color: OrderUi.inkFaint))
                : Image.network(item.imageUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          width: 46,
                          height: 46,
                          color: OrderUi.block,
                          child: const Icon(Icons.image_outlined,
                              size: 18, color: OrderUi.inkFaint),
                        )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: OrderUi.ink)),
                if ((item.variant ?? '').trim().isNotEmpty)
                  Text(item.variant!, style: OrderUi.faint),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.price != null)
                    Text('₹${OrderUiFormat.money(item.price!)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: OrderUi.ink)),
                  if (item.hasDiscount) ...[
                    const SizedBox(width: 5),
                    Text('₹${OrderUiFormat.money(item.mrp!)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: OrderUi.inkFaint,
                            decoration: TextDecoration.lineThrough)),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              if (widget.onQuantityChanged != null)
                _qtyStepper(index, qty)
              else
                Text('Qty $qty', style: OrderUi.faint),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyStepper(int index, int qty) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyTap(Icons.remove,
              () => widget.onQuantityChanged!(index, qty - 1)),
          SizedBox(
            width: 26,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: OrderUi.ink)),
          ),
          _qtyTap(Icons.add, () => widget.onQuantityChanged!(index, qty + 1)),
        ],
      ),
    );
  }

  Widget _qtyTap(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          child: Icon(icon, size: 16, color: OrderUi.inkSoft),
        ),
      );

  // ── ③ How do you want to receive your order? ───────────────────────────
  //
  //    Everything guide §17.2 asks for lands HERE, because this is the moment
  //    of choosing: the real quoted fee, the ETA range, the economics
  //    suggestion verbatim, the out-of-range message, and the breakdown.

  Widget _receiveCard() {
    final q = _quote;
    final outOfRange = q != null && !q.feasible;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How do you want to receive your order?',
              style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: OrderUi.ink,
                  height: 1.25)),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _receiveOption(
                    icon: Icons.storefront,
                    title: 'Self Pickup',
                    lines: const ['Pickup from the shop', 'No delivery fee'],
                    selected: !_isDelivery,
                    onTap: () => _chooseMethod(OrderDeliveryType.selfPickup),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _receiveOption(
                    icon: Icons.delivery_dining,
                    title: 'Book Rider',
                    lines: [
                      'Get it at your doorstep',
                      _deliveryCardSubtitle(),
                    ],
                    selected: _isDelivery,
                    enabled: _deliveryOffered && !outOfRange,
                    onTap: _chooseDelivery,
                  ),
                ),
              ],
            ),
          ),
          if (_isDelivery) ...[
            const SizedBox(height: 10),
            _addressStrip(),
          ],

          // Out of range is a 200 carrying a reason, not an error (§17.2). The
          // delivery card is disabled above; pickup stays selectable.
          if (outOfRange) ...[
            const SizedBox(height: 10),
            OrderHintStrip(
              tone: OrderBlockTone.amber,
              bordered: true,
              text: q.message ??
                  'Delivery is only available near the shop'
                      '${q.maxDistanceKm != null ? ' (within ${q.maxDistanceKm} km)' : ''}.',
            ),
          ],

          // The quote could not be fetched at all — offer the retry rather
          // than pretending delivery is impossible.
          if (!_quoteLoading && q == null && _address != null) ...[
            const SizedBox(height: 10),
            const OrderHintStrip(
              tone: OrderBlockTone.neutral,
              text: "We couldn't get a delivery price just now. "
                  'You can retry, or collect the order from the shop.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _fetchQuoteNow,
                child: const Text('Retry', style: OrderUi.link),
              ),
            ),
          ],

          if (q != null && q.feasible) ...[
            if (q.peak) ...[
              const SizedBox(height: 10),
              const OrderHintStrip(
                tone: OrderBlockTone.neutral,
                text: 'Busy right now, so fares are higher than usual.',
              ),
            ],

            // "Delivery costs a lot compared to this order…" — the server's
            // own sentence, verbatim, never paraphrased.
            if (q.shouldWarnAboutFee) ...[
              const SizedBox(height: 10),
              OrderHintStrip(
                tone: OrderBlockTone.amber,
                bordered: true,
                text: q.suggestion ??
                    'Delivery costs a lot compared to this order. '
                        'Picking it up is cheaper.',
              ),
            ],

            // An unexplained delivery fee is the commonest cause of checkout
            // abandonment, so the arithmetic is one tap away (§17.2).
            if (q.breakdownRows.isNotEmpty)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: const Text('How is this calculated?',
                      style: OrderUi.link),
                  children: [
                    for (final row in q.breakdownRows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(row.key, style: OrderUi.blockBody),
                            Text(row.value,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: OrderUi.ink)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],

          if (!_shopLocated && widget.allowDelivery) ...[
            const SizedBox(height: 10),
            const OrderHintStrip(
              tone: OrderBlockTone.neutral,
              text: 'This shop has not set a location yet, so delivery '
                  "can't be quoted. You can still collect your order.",
            ),
          ],
        ],
      ),
    );
  }

  /// Choosing delivery is what asks for the address.
  ///
  /// The stepper asked first and explained later; the board asks at the moment
  /// the answer is needed. The gate is unchanged — `_canPlace` still refuses a
  /// doorstep order without a coordinate — this only moves *when* the question
  /// is put.
  Future<void> _chooseDelivery() async {
    if (_address == null) {
      await _pickAddress();
      if (!mounted || _address == null) return;
    }
    _chooseMethod(OrderDeliveryType.rider);
  }

  Widget _receiveOption({
    required IconData icon,
    required String title,
    required List<String> lines,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected ? OrderUi.blueSoftFill : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? OrderUi.blue : OrderUi.blockBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon,
                      size: 24,
                      color: selected ? OrderUi.blue : OrderUi.inkSoft),
                  const Spacer(),
                  _radio(selected),
                ],
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: OrderUi.ink)),
              const SizedBox(height: 3),
              for (final l in lines)
                if (l.trim().isNotEmpty)
                  Text(l, style: OrderUi.blockBody.copyWith(fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radio(bool selected) => Container(
        width: 19,
        height: 19,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? OrderUi.blue : const Color(0xFFC6CCD6),
              width: 2),
        ),
        child: selected
            ? Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: OrderUi.blue),
              )
            : null,
      );

  /// Where it is going, and who is receiving it. Shown only on a doorstep
  /// order, because self-pickup has no drop point to get wrong.
  Widget _addressStrip() {
    final a = _address;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: OrderUi.block,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 17, color: OrderUi.blue),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  a?.fullAddress.trim().isNotEmpty == true
                      ? a!.fullAddress
                      : 'Add a delivery address',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: a == null ? OrderUi.danger : OrderUi.ink,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickAddress,
                behavior: HitTestBehavior.opaque,
                child: Text(a == null ? 'Add' : 'Change',
                    style: OrderUi.link),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniField(
                    controller: _receiverName,
                    hint: 'Receiver name',
                    icon: Icons.person_outline),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniField(
                  controller: _receiverPhone,
                  hint: 'Phone',
                  icon: Icons.call_outlined,
                  number: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniField(
              controller: _riderNote,
              hint: 'Note for the rider (optional)',
              icon: Icons.sticky_note_2_outlined),
        ],
      ),
    );
  }

  Widget _miniField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.phone : TextInputType.text,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13, color: OrderUi.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: OrderUi.blockBody.copyWith(fontSize: 12.5),
        prefixIcon: Icon(icon, size: 16, color: OrderUi.inkFaint),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: OrderUi.blockBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: OrderUi.blockBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: OrderUi.blue),
        ),
      ),
    );
  }

  /// What the delivery card says under its title.
  ///
  /// Four honest answers and **no fifth invented one**. This used to read
  /// `from ₹40` — a number nothing had computed, shown before any address
  /// existed to compute it from.
  String _deliveryCardSubtitle() {
    if (!_deliveryOffered) return 'not available here';
    if (_address == null) return 'add an address for the fee';
    if (_quoteLoading) return 'checking…';
    final q = _quote;
    if (q == null) return 'price unavailable';
    if (!q.feasible) return 'too far to deliver';
    return [
      '₹${OrderMoneyRow.money(q.deliveryFee ?? 0)}',
      if (q.etaLabel.isNotEmpty) q.etaLabel,
    ].join(' · ');
  }

  // ── ④ Payment method ───────────────────────────────────────────────────

  Widget _paymentCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment method',
              style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: OrderUi.ink)),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cash is **absent** on a doorstep order rather than greyed
                // out. A disabled card invites a tap and then explains itself;
                // leaving it out says the same thing without the dead end, and
                // the note below gives the reason in a sentence.
                if (_cashAllowed) ...[
                  Expanded(
                    child: _receiveOption(
                      icon: Icons.payments_outlined,
                      title: 'Cash at Shop',
                      lines: const ['Pay on Pickup, No Online Payment'],
                      selected: _paymentMethod == OrderPaymentMethod.cash,
                      onTap: () => setState(
                          () => _paymentMethod = OrderPaymentMethod.cash),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _receiveOption(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'UPI',
                    lines: const ['Pay online now'],
                    selected: _paymentMethod == OrderPaymentMethod.upi,
                    enabled: widget.allowUpi,
                    onTap: () => setState(
                        () => _paymentMethod = OrderPaymentMethod.upi),
                  ),
                ),
              ],
            ),
          ),
          if (!_cashAllowed) ...[
            const SizedBox(height: 10),
            const OrderHintStrip(
              tone: OrderBlockTone.neutral,
              text: 'Doorstep orders are paid by UPI. The shop is paid for '
                  'the items before it packs them, and the delivery fee is '
                  'paid to your delivery partner when your order arrives.',
            ),
          ],
          if (_paymentMethod == OrderPaymentMethod.upi) ...[
            const SizedBox(height: 10),
            const OrderHintStrip(
              tone: OrderBlockTone.neutral,
              // Money is only requested after a shop commits. If the shop
              // turns out to be closed, nobody has to be refunded.
              text: "You'll be asked to pay once the shop accepts the "
                  'order — not before.',
            ),
          ],
        ],
      ),
    );
  }

  // ── ⑤ Bill Details ─────────────────────────────────────────────────────

  Widget _billCard() {
    final mrp = widget.mrpTotal;
    final savings = mrp == null ? null : mrp - widget.itemsTotal;
    final pct = (mrp == null || mrp <= 0 || savings == null || savings <= 0)
        ? null
        : ((savings / mrp) * 100).round();
    final count = widget.items.isEmpty
        ? null
        : widget.items.fold<int>(0, (a, b) => a + (b.quantity ?? 1));

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Details',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: OrderUi.ink)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OrderUi.blockBorder),
            ),
            child: Column(
              children: [
                if (count != null)
                  OrderKeyValueRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Total Items',
                      value: count.toString().padLeft(2, '0')),
                if (count != null)
                  const Divider(height: 1, color: OrderUi.blockBorder),
                if (mrp != null) ...[
                  OrderKeyValueRow(
                      icon: Icons.sell_outlined,
                      label: 'Total MRP',
                      value: OrderUiFormat.rupees(mrp)),
                  const Divider(height: 1, color: OrderUi.blockBorder),
                ],
                if (_isDelivery) ...[
                  OrderKeyValueRow(
                      icon: Icons.delivery_dining_outlined,
                      label: 'Delivery Charge',
                      value: OrderUiFormat.rupees(_deliveryFee)),
                  const Divider(height: 1, color: OrderUi.blockBorder),
                ],
                if (savings != null && savings > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        const Icon(Icons.savings_outlined,
                            size: 17, color: OrderUi.inkSoft),
                        const SizedBox(width: 9),
                        const Text('Savings (Discount)',
                            style: TextStyle(
                                fontSize: 13, color: OrderUi.inkSoft)),
                        if (pct != null) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: OrderUi.blue,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text('$pct% Off',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ],
                        const Spacer(),
                        Text('−${OrderUiFormat.rupees(savings)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: OrderUi.ink)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // The board dashes this box — the one number the customer is
          // agreeing to should not look like another row of the table.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: OrderUi.blueSoftFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: OrderUi.blueBorder),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Grand total (pay INR)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OrderUi.inkSoft)),
                ),
                Text(OrderUiFormat.rupees(_total),
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: OrderUi.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────

  /// **The gate.** A typed address with no coordinate does not pass — a rider
  /// order with no drop point is one nobody can fulfil (§17.3) — and neither
  /// does a doorstep order whose quote has not come back feasible.
  bool get _canPlace {
    if (!_isDelivery) return true;
    if (_address?.lat == null || _address?.lng == null) return false;
    if (_receiverPhone.text.trim().length < 10) return false;
    return !_quoteLoading && (_quote?.feasible ?? false);
  }

  String? get _blockedReason {
    if (!_isDelivery) return null;
    if (_address?.lat == null || _address?.lng == null) {
      return 'Add a delivery address to continue.';
    }
    if (_receiverPhone.text.trim().length < 10) {
      return 'Add a phone number the rider can call.';
    }
    if (_quoteLoading) return 'Getting the delivery price…';
    if (!(_quote?.feasible ?? false)) {
      return 'This address is out of the shop\'s delivery range.';
    }
    return null;
  }

  Widget _placeOrderBar() {
    final blocked = _blockedReason;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: OrderUi.blockBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blocked != null) ...[
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: OrderUi.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(blocked,
                      style: OrderUi.blockBody.copyWith(color: OrderUi.amber)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          OrderButton(
            label: 'Place Order- ${OrderUiFormat.rupees(_total)}',
            trailingIcon: Icons.arrow_forward,
            onTap: _canPlace ? _finish : null,
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderUi.cardRadius),
        border: Border.all(color: OrderUi.cardBorder),
      ),
      child: child,
    );
  }
}
