import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_track_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_track_model.dart';
import 'package:BlueEra/features/chat/auth/model/self_pickup_order_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/order_track/order_steps_screen.dart';
import 'package:BlueEra/features/chat/view/order_track/widgets/order_status_chip.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **The chat order card for a grocery order** (`message_type: grocery_order`),
/// built to `ORDER_CHAT_AND_STEPS_UI_EDGE_CASES.md` §3 and §4.
///
/// ## Why this looks defensive
///
/// The audit found that the grocery vertical produces an order message with
/// `conversation_id: null`, `metadata.order` as a **bare id string**, no
/// `lifecycle` key at all, and no socket event to update it with. Every one of
/// those is the documented contract, not a transient bug, so this card:
///
/// * refuses to draw at all when there is no order data and no id — a card
///   with nothing in it is worse than no card, and the message falls back to a
///   plain text bubble (C1, C2);
/// * treats a String `metadata.order` as an id and hydrates it through
///   `/track`, and **never** property-accesses it (C3);
/// * renders status-only with **zero** buttons when `lifecycle` is null or
///   absent — the two are identical (C5);
/// * takes its buttons only from `customerActions` / `ownerActions`, checked
///   against the viewer's own role, and silently skips a key it does not know
///   (B1, B3);
/// * refreshes on focus rather than waiting for a socket that does not exist
///   (T7).
class GroceryOrderMsgCard extends StatefulWidget {
  final Messages message;
  final String time;
  final String? conversationId;

  const GroceryOrderMsgCard({
    super.key,
    required this.message,
    required this.time,
    this.conversationId,
  });

  /// The order id this message points at, from whichever key carries it.
  ///
  /// `metadata.order` is the interesting one: on this vertical it is a bare id
  /// **string**, which the metadata parser stores in `orderRefId` precisely so
  /// nothing downstream tries to read `order['grandTotal']` off it (C3).
  static String orderIdOf(Messages message) {
    final meta = message.metadata;
    return meta?.groceryOrderId ??
        meta?.groceryOrder?.orderId ??
        meta?.orderRefId ??
        meta?.selfPickupOrder?.orderId ??
        meta?.selfpickupOrderId ??
        meta?.orderId ??
        '';
  }

  /// The order snapshot, when one actually arrived as an object.
  static SelfPickupOrderModel? snapshotOf(Messages message) =>
      message.metadata?.groceryOrder ?? message.metadata?.selfPickupOrder;

  /// **C1 / C2 — whether there is anything to draw a card from.**
  ///
  /// No snapshot and no id means the message carries an order in name only.
  /// The caller renders the plain text bubble instead; it must not fabricate a
  /// card from the message text.
  static bool canRender(Messages message) {
    if (message.deleteFromEveryone == true) return false;
    return snapshotOf(message) != null || orderIdOf(message).isNotEmpty;
  }

  @override
  State<GroceryOrderMsgCard> createState() => _GroceryOrderMsgCardState();
}

class _GroceryOrderMsgCardState extends State<GroceryOrderMsgCard>
    with WidgetsBindingObserver {
  static const String _service = OrderServiceApi.groceryOrderService;

  OrderTrackController? _track;

  String get _orderId => GroceryOrderMsgCard.orderIdOf(widget.message);

  SelfPickupOrderModel? get _snapshot =>
      GroceryOrderMsgCard.snapshotOf(widget.message);

  /// `my_message` is the party who placed the order. A shop that ordered from
  /// itself is allowed, and then the card is outgoing AND the viewer is the
  /// owner — which is why the seller buttons are suppressed for it (C14).
  bool get _isMyMessage => widget.message.myMessage ?? false;

  bool get _isSelfOrder =>
      _isMyMessage && (_track?.track.value?.actorIsOwner ?? false);

  /// Server-first, guess-second (B3). The guess is that the customer is the
  /// one who sent the order message.
  bool get _isOwnerView => _track?.isOwner ?? !_isMyMessage;

  /// C10 — `is_cancelled` **wins** over `order_status`. A cancelled legacy card
  /// routinely arrives with `order_status: null`.
  bool get _isCancelled => widget.message.metadata?.is_cancelled == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_orderId.isNotEmpty) {
      // C13 — the card in the thread can be older than the order it describes,
      // because nothing pushes grocery updates. `/track` is the truth; the
      // metadata snapshot is only what was true when the message was written.
      _track = OrderTrackController.attach(
        orderId: _orderId,
        service: _service,
        isOwner: !_isMyMessage,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // T7 / T8 — no socket for this vertical, so resume is one of the two
    // moments the card can learn anything new.
    if (state == AppLifecycleState.resumed) _track?.silentRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_orderId.isNotEmpty) {
      OrderTrackController.detach(orderId: _orderId, service: _service);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _track;
    if (controller == null) return _card(context, null);
    return Obx(() => _card(context, controller.track.value));
  }

  // ── The card ─────────────────────────────────────────────────────────

  Widget _card(BuildContext context, OrderTrackModel? order) {
    final snapshot = _snapshot;

    // Everything the card shows, resolved once: `/track` first, the message
    // snapshot second. Never a total this card computed (§3.1).
    final orderNumber = order?.orderNumber;
    final grandTotal = order?.grandTotal ?? snapshot?.grandTotal;
    final items = _items(order, snapshot);
    final status = _statusText(order);

    final cancelled = _isCancelled || (order?.isCancelled ?? false);

    return Container(
      width: SizeConfig.screenWidth * 0.72,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: cancelled ? OrderTone.muted.surface : AppColors.white,
        borderRadius: BorderRadius.circular(OrderRadius.card),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(orderNumber, status, cancelled, order),
          const OrderZoneDivider(),
          if (items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  OrderSpace.m, OrderSpace.s, OrderSpace.m, OrderSpace.s),
              child: _itemList(items),
            ),
            const OrderZoneDivider(),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
                OrderSpace.m, OrderSpace.s, OrderSpace.m, OrderSpace.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderMoneyRow(
                  label: AppStrings.orderStepsTotal.tr,
                  amount: grandTotal,
                  emphasise: true,
                ),
                ..._paymentNote(order),
              ],
            ),
          ),
          ..._actions(order),
        ],
      ),
    );
  }

  Widget _header(String? orderNumber, String? status, bool cancelled,
      OrderTrackModel? order) {
    final stageKey =
        order != null && order.currentIndex >= 0 && order.stages.isNotEmpty
            ? order.stages[order.currentIndex].key
            : order?.currentStage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          OrderSpace.m, OrderSpace.m, OrderSpace.m, OrderSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 15, color: AppColors.grayText),
              const SizedBox(width: OrderSpace.xs),
              Expanded(
                child: Text(
                  // The envelope's own text — "New grocery order" — is the
                  // message, and the message is what the sender wrote.
                  (widget.message.message ?? '').trim().isNotEmpty
                      ? widget.message.message!.trim()
                      : AppStrings.orderCardNewOrder.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OrderType.body.copyWith(
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w700,
                    // C10 — a cancelled order is struck through, not hidden.
                    decoration: cancelled
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: OrderSpace.s),
              Text(widget.time,
                  style: OrderType.label.copyWith(color: AppColors.grayText)),
            ],
          ),
          if ((orderNumber ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 19),
              child: Text(orderNumber!,
                  style: OrderType.mono(size: 10)
                      .copyWith(color: AppColors.grayText)),
            ),
          const SizedBox(height: OrderSpace.s),
          Row(
            children: [
              // The status chip is the only colour on the card.
              OrderStatusChip(
                orderStatus: order?.orderStatus ??
                    widget.message.metadata?.orderStatusText,
                isCancelled: cancelled,
                stageKey: stageKey,
                compact: true,
              ),
              if (status != null) ...[
                const SizedBox(width: OrderSpace.s),
                Expanded(
                  child: Text(status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OrderType.label
                          .copyWith(color: AppColors.secondaryTextColor)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// The §8 copy table, and only where the server has not spoken for itself.
  String? _statusText(OrderTrackModel? order) {
    final banner = order?.lifecycle?.banner?.trim();
    if (banner != null && banner.isNotEmpty) return banner;
    if (_isCancelled || (order?.isCancelled ?? false)) {
      return AppStrings.orderCancelledCopy.tr;
    }
    if (order == null) return null;
    if (order.isCompleted) return AppStrings.orderCompletedCopy.tr;

    final stageKey = order.currentIndex >= 0 && order.stages.isNotEmpty
        ? order.stages[order.currentIndex].key.toLowerCase()
        : (order.currentStage ?? '').toLowerCase();
    final ready = order.orderStatus == OrderStatusValue.ready ||
        stageKey.contains('ready') ||
        stageKey.contains('pickup');
    if (ready) {
      return _isOwnerView
          ? AppStrings.orderWaitingCustomerCollect.tr
          : AppStrings.orderReadyCollectIt.tr;
    }
    if (order.orderStatus == OrderStatusValue.placed && !_isOwnerView) {
      return AppStrings.orderWaitingShopConfirm.tr;
    }
    return null;
  }

  // ── Items ────────────────────────────────────────────────────────────

  List<_CardItem> _items(
      OrderTrackModel? order, SelfPickupOrderModel? snapshot) {
    if (order != null && order.items.isNotEmpty) {
      return order.items
          .map((i) => _CardItem(
                name: i.name,
                variant: i.variantLabel,
                image: i.imageUrl,
                quantity: i.quantity,
                mrp: i.mrp,
                sellingPrice: i.sellingPrice,
              ))
          .toList();
    }
    final items = snapshot?.items ?? const <SelfPickupItem>[];
    return items
        .map((i) => _CardItem(
              name: i.productName ?? i.variantName,
              variant: i.quantityLabel ?? i.unit,
              // C15 — variant image, then nothing. The placeholder tile is
              // drawn by the row itself; an empty box is never acceptable.
              image:
                  (i.images?.isNotEmpty ?? false) ? i.images!.first.url : null,
              quantity: i.quantity ?? 1,
              mrp: i.mrp,
              sellingPrice: i.sellingPrice,
            ))
        .toList();
  }

  /// §3.1 — collapse at two rows. The full list belongs on the steps screen.
  Widget _itemList(List<_CardItem> items) {
    const maxRows = 2;
    final shown = items.take(maxRows).toList();
    final hidden = items.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...shown.map(_itemRow),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: OrderSpace.xs),
            child: Text(
              AppStrings.orderStepsMoreItems.trParams({'count': '$hidden'}),
              style: OrderType.label.copyWith(color: AppColors.primaryColor),
            ),
          ),
      ],
    );
  }

  Widget _itemRow(_CardItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(item.image),
          const SizedBox(width: OrderSpace.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [item.name, item.variant]
                      .where((e) => (e ?? '').isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      OrderType.label.copyWith(color: AppColors.mainTextColor),
                ),
                if (item.sellingPrice != null)
                  Row(
                    children: [
                      if (item.isDiscounted)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '₹${OrderMoneyRow.money(item.mrp!)}',
                            style: OrderType.label.copyWith(
                              fontSize: 10,
                              color: AppColors.grayText,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      Text('₹${OrderMoneyRow.money(item.sellingPrice!)}',
                          style: OrderType.label.copyWith(
                              fontSize: 11, color: AppColors.mainTextColor)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: OrderSpace.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('× ${OrderMoneyRow.money(item.quantity)}',
                  style: OrderType.mono(size: 11)
                      .copyWith(color: AppColors.grayText)),
              if (item.lineTotal != null)
                Text('₹${OrderMoneyRow.money(item.lineTotal!)}',
                    style: OrderType.mono(size: 11, weight: FontWeight.w700)
                        .copyWith(color: AppColors.mainTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumb(String? url) {
    const size = 32.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: size,
        height: size,
        child: (url == null || url.isEmpty)
            ? Container(
                color: AppColors.greyE5,
                child: const Icon(Icons.shopping_basket_outlined,
                    size: 15, color: AppColors.grayText),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.greyE5),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.greyE5,
                  child: const Icon(Icons.shopping_basket_outlined,
                      size: 15, color: AppColors.grayText),
                ),
              ),
      ),
    );
  }

  // ── Payment note (P1) ────────────────────────────────────────────────

  List<Widget> _paymentNote(OrderTrackModel? order) {
    final note = order?.payment?.customer?.note?.trim() ?? '';
    if (note.isEmpty) return const [];
    return [
      const SizedBox(height: OrderSpace.xs),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.payments_outlined,
              size: 13, color: AppColors.grayText),
          const SizedBox(width: OrderSpace.xs),
          // Verbatim. Never paraphrased, never "you will pay ₹48 at the shop".
          Expanded(
            child: Text(note,
                style: OrderType.label.copyWith(color: AppColors.grayText)),
          ),
        ],
      ),
    ];
  }

  // ── Actions (§4) ─────────────────────────────────────────────────────

  /// Buttons come **only** from the server's action lists. There is no
  /// hard-coded per-status button anywhere in here.
  ///
  /// "View order" is not one of them: it is navigation, not an order action —
  /// it changes nothing on the server and can never 409 — so it is always
  /// available, and for grocery it is the only thing the card can offer.
  List<Widget> _actions(OrderTrackModel? order) {
    final lifecycle = widget.message.metadata?.lifecycle ?? order?.lifecycle;

    final serverActions = order?.actionsFor(isOwner: _isOwnerView) ??
        lifecycle?.actionsFor(isOwner: _isOwnerView) ??
        const <String>[];

    // C14 — a shop that ordered from itself sees an outgoing card with no
    // seller controls on it; acting on your own order from the buyer's bubble
    // is how a shop marks an order ready by accident.
    final actions = _isSelfOrder ? const <String>[] : serverActions;

    final ctx = OrderCardContext(
      orderId: _orderId,
      service: _service,
      isOwner: _isOwnerView,
      conversationId: widget.conversationId,
      otherUserId: widget.message.sender?.id,
      otherUserName: widget.message.sender?.name,
      otherUserPhone: widget.message.sender?.contactNo,
      shopName: order?.businessName,
      shopAddress: order?.businessAddress,
      orderTotal: order?.grandTotal ?? _snapshot?.grandTotal,
      businessId: order?.businessId ?? _snapshot?.businessId,
      selfpickupType: widget.message.messageType ?? 'grocery_order',
      orderFor: 'grocery',
      // A refreshed card, never a locally advanced one (B11).
      onChanged: (_) => _track?.silentRefresh(),
    );

    return [
      const OrderZoneDivider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(
            OrderSpace.s, OrderSpace.xs, OrderSpace.s, OrderSpace.xs),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _orderId.isEmpty ? null : _openSteps,
                icon: const Icon(Icons.list_alt_outlined, size: 16),
                label: Text(AppStrings.orderStepsViewOrder.tr,
                    style:
                        OrderType.label.copyWith(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor),
              ),
            ),
            // B2 — no action row at all when the server offered nothing. The
            // action bar itself renders nothing for an empty list, so this
            // reserves no space either.
            if (actions.isNotEmpty)
              Expanded(child: OrderActionBar(actions: actions, ctx: ctx)),
          ],
        ),
      ),
    ];
  }

  Future<void> _openSteps() async {
    if (_orderId.isEmpty) {
      commonSnackBar(message: AppStrings.orderGenericError.tr);
      return;
    }
    await Get.to(() => OrderStepsScreen(
          args: OrderStepsArgs(
            orderId: _orderId,
            service: _service,
            isOwner: _isOwnerView,
          ),
        ));
    // T7 / S13 — coming back from the steps screen is a focus event, and focus
    // is one of the only two moments a grocery card can learn anything.
    if (mounted) _track?.silentRefresh();
  }
}

/// One item row, from whichever source had it.
class _CardItem {
  final String? name;
  final String? variant;
  final String? image;
  final num quantity;
  final num? mrp;
  final num? sellingPrice;

  const _CardItem({
    this.name,
    this.variant,
    this.image,
    this.quantity = 1,
    this.mrp,
    this.sellingPrice,
  });

  num? get lineTotal {
    final unit = sellingPrice ?? mrp;
    return unit == null ? null : unit * quantity;
  }

  bool get isDiscounted =>
      mrp != null && sellingPrice != null && mrp! > sellingPrice!;
}
