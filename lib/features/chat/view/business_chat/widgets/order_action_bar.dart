import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_card_ui.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_payment_submit_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_rating_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_prep_eta_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_reason_sheet.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/pickup_code_screen.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/pickup_handover_dialog.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_refund_dialog.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/widgets/app_popup_menu_button.dart';

/// Everything an action needs that the action string itself doesn't carry.
/// One instance per rendered order card.
class OrderCardContext {
  final String orderId;

  /// Vertical prefix — `product-service` today; grocery / food / medical once
  /// their services are ported. The card contract is identical.
  final String service;

  /// True when the viewer is the **shop** for this order.
  final bool isOwner;

  final String? conversationId;

  /// The other party — used for the call button and to look up their UPI QR.
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserPhoto;
  final String? otherUserPhone;

  final String? shopName;
  final String? shopAddress;

  /// Order total, used to pre-fill the payment sheet and the cash checkbox.
  final num? orderTotal;

  /// The shop's business id — the dispatch call resolves the pickup point from
  /// it, so delivery never re-asks for an address the order already has.
  final String? businessId;

  /// The chat `message_type` (`product_selfpickup`, `food_selfpickup`, …),
  /// sent as `selfpickupType` on dispatch.
  final String? selfpickupType;

  /// `product` | `grocery` | `food` | `medical` — the rider service's
  /// `orderFor`.
  final String orderFor;

  /// Opens the in-card "get it delivered" flow for a **self-pickup** order the
  /// customer changed their mind about (guide §5.5). A doorstep order never
  /// uses this: it dispatches automatically at `ready`.
  final Future<void> Function()? onFindRider;

  /// Existing support flow.
  final VoidCallback? onRaiseIssue;

  /// Called after any action that changed server state, so the card can patch
  /// its own legacy metadata flags and rebuild.
  final void Function(OrderActionsModel? fresh)? onChanged;

  // ── Board data (BlueEra 2026) ──────────────────────────────────────────
  // The card header and the order-summary block are part of the *design*, not
  // the state machine, so they are passed in rather than fetched: the card
  // already holds them in `metadata.order`, and a summary that waits on a
  // network call is a summary that flashes empty on every chat scroll.

  /// `0D1247` — rendered as `Order #0D1247`.
  final String? orderNumber;

  /// `Today, 9:30 AM` — the placed-at line under the order number.
  final String? placedAtLabel;

  /// The order's line items, newest-first as the shop sent them.
  final List<OrderCardItem> items;

  /// `metadata.order.totalItems` when it disagrees with `items.length`
  /// (the card only ever carries the first few).
  final int? totalItemCount;

  /// The shop's photo, for the party card on the ready / rider screens.
  final String? shopPhoto;

  /// `0.8km away`.
  final String? shopDistance;

  /// Opens the existing order-detail screen.
  final VoidCallback? onViewDetails;

  /// Board: `Shop Again` on the completed card.
  final VoidCallback? onShopAgain;

  /// Board: `Rate your experience` on the picked-up card.
  final VoidCallback? onRate;

  /// Board: `Get Direction` on the ready card.
  final VoidCallback? onGetDirection;

  const OrderCardContext({
    required this.orderId,
    this.service = OrderServiceApi.defaultOrderService,
    required this.isOwner,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserPhoto,
    this.otherUserPhone,
    this.shopName,
    this.shopAddress,
    this.orderTotal,
    this.businessId,
    this.selfpickupType,
    this.orderFor = 'product',
    this.onFindRider,
    this.onRaiseIssue,
    this.onChanged,
    this.orderNumber,
    this.placedAtLabel,
    this.items = const [],
    this.totalItemCount,
    this.shopPhoto,
    this.shopDistance,
    this.onViewDetails,
    this.onShopAgain,
    this.onRate,
    this.onGetDirection,
  });
}

/// **The single action renderer.** One switch, one source of truth, no
/// per-card copies (guide §2).
///
/// It renders exactly what `availableActions` contains and nothing else. An
/// action string this build does not know — a newer backend — renders
/// **nothing**; it is never guessed at, because a button the server did not
/// offer comes back as a typed 409.
///
/// Loading is per-button: only the tapped action shows a spinner and disables,
/// so the other party's updates keep landing on the same card. There are no
/// optimistic updates — every one of these calls can legitimately fail with a
/// 409, and an optimistically-hidden Accept button that comes back is worse
/// than a spinner (guide §6).
class OrderActionBar extends StatelessWidget {
  final List<String> actions;
  final OrderCardContext ctx;

  /// Actions a panel above has already drawn a control for.
  ///
  /// The board puts `Upload Screenshot` inside the payment panel and
  /// `Show Code` inside the pickup panel, because the control belongs next to
  /// the thing it acts on. Rendering them again down here would be two buttons
  /// for one action — so the section names them and the bar skips them. The
  /// server contract is untouched: the action is still only ever offered when
  /// `availableActions` contains it.
  final Set<String> hiddenActions;

  /// Buttons the board draws that the **state machine has no action for**.
  ///
  /// `Shop Again`, `Rate your experience`, `Get Direction`, `Continue
  /// Shopping`, `View Details` — every one of them is navigation, not a
  /// transition. They cannot come from `availableActions` because they change
  /// nothing on the server, and inventing action keys for them would blur the
  /// line the rest of this file exists to hold. They are appended to the right
  /// of the row, where the board puts them.
  final List<Widget> extraButtons;

  const OrderActionBar({
    super.key,
    required this.actions,
    required this.ctx,
    this.hiddenActions = const {},
    this.extraButtons = const [],
  });

  OrderLifecycleController get _controller => OrderLifecycleController.instance;

  @override
  Widget build(BuildContext context) {
    // Extras are not actions, so an order the state machine has nothing left
    // to offer — a completed one — still draws its `Shop Again`.
    if (actions.isEmpty && extraButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      // Touch the busy set unconditionally. Several actions (the call icon, an
      // unknown string from a newer backend) never read it, and an Obx that
      // reads no observable throws "improper use of a GetX" instead of
      // rendering — which would take the whole card down over a button we
      // deliberately chose not to draw.
      final busy = _controller.busyKeys;
      // ignore: unnecessary_statements
      busy.length;

      // Order: primary → secondary → destructive → icon (guide §3.3). The
      // server sends what is *allowed*; the ranking decides what reads first.
      //
      // The board draws the primary on the RIGHT, so the ranking is reversed
      // at layout time: rank still decides *which* buttons survive the cap,
      // the row decides where they sit.
      final offered =
          actions.where((a) => !hiddenActions.contains(a)).toList();
      final ranked = offered..sort((a, b) => _rank(a).compareTo(_rank(b)));

      // Two buttons is the board's limit for the whole row, so a card that
      // already carries a `Shop Again` has room for one server action beside
      // it and folds the rest.
      final cap =
          (_maxVisible - extraButtons.length).clamp(1, _maxVisible).toInt();
      final visible = ranked.take(cap).toList();
      final overflow = ranked.skip(cap).toList();

      final widgets = <Widget>[];
      // Reversed: `Cancel Order · Accept`, `Need Help · Payment Collected`,
      // `Contact Shop · Get Direction` — the board's pairing every time.
      for (final a in visible.reversed) {
        final w = _widgetFor(context, a);
        if (w != null) widgets.add(w);
      }
      // Only offer the ⋯ for actions this build actually knows how to run.
      final knownOverflow =
          overflow.where((a) => _labelFor(a) != null).toList();
      if (knownOverflow.isNotEmpty) {
        widgets.insert(0, _overflowButton(context, knownOverflow));
      }

      widgets.addAll(extraButtons);

      if (widgets.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: OrderButtonRow(buttons: widgets),
      );
    });
  }

  /// The board never draws more than two buttons on a card; a third folds into
  /// the `⋯`.
  static const int _maxVisible = 2;

  /// Lower sorts earlier. Primary work first, then the ways out.
  ///
  /// Only the *cap* reads this — the row reverses it so the primary lands on
  /// the right, where the board puts it.
  static int _rank(String a) {
    switch (a) {
      case OrderAction.acceptOrder:
      case OrderAction.markReady:
      case OrderAction.verifyPayment:
      case OrderAction.confirmHandover:
      case OrderAction.collectCash:
      case OrderAction.completeOrder:
      case OrderAction.startPreparing:
      case OrderAction.submitPayment:
      case OrderAction.viewPickupCode:
      case OrderAction.markRefundSent:
      case OrderAction.confirmRefundReceived:
        return 0; // primary
      case OrderAction.rateOrder:
        return 1;
      case OrderAction.setPrepEta:
        return 1; // secondary
      case OrderAction.contactShop:
      case OrderAction.contactCustomer:
        return 2; // the board's usual left-hand button
      case OrderAction.raiseIssue:
        return 3;
      case OrderAction.findRider:
        return 4;
      case OrderAction.rejectOrder:
      case OrderAction.rejectPayment:
      case OrderAction.reportNoShow:
      case OrderAction.cancelOrder:
        return 5; // destructive
      default:
        // An unknown action from a newer backend sorts last and renders
        // nothing anyway.
        return 9;
    }
  }

  /// The overflow menu's wording. Null for anything this build cannot run —
  /// an unknown action is never offered, not even in a menu.
  static String? _labelFor(String a) {
    switch (a) {
      case OrderAction.acceptOrder:
        return 'Accept';
      case OrderAction.rejectOrder:
        return 'Reject';
      case OrderAction.setPrepEta:
        return 'Update Ready Time';
      case OrderAction.markReady:
        return 'Mark as Ready';
      case OrderAction.verifyPayment:
        return 'Confirm';
      case OrderAction.rejectPayment:
        return 'Reject';
      case OrderAction.confirmHandover:
        return 'Verify & Continue';
      case OrderAction.collectCash:
        return 'Payment Collected';
      case OrderAction.completeOrder:
        return 'Complete Order';
      case OrderAction.startPreparing:
        return 'Start Preparing';
      case OrderAction.reportNoShow:
        return "Customer didn't come";
      case OrderAction.markRefundSent:
        return 'I sent the refund';
      case OrderAction.submitPayment:
        return 'Upload Screenshot';
      case OrderAction.viewPickupCode:
        return 'Show Code';
      case OrderAction.findRider:
        return 'Get it delivered';
      case OrderAction.confirmRefundReceived:
        return 'I received the refund';
      case OrderAction.cancelOrder:
        return 'Cancel Order';
      case OrderAction.rateOrder:
        return 'Rate your experience';
      case OrderAction.raiseIssue:
        return 'Need Help';
      default:
        return null;
    }
  }

  Widget _overflowButton(BuildContext context, List<String> actions) {
    return SizedBox(
      height: OrderUi.buttonHeight,
      child: AppPopupMenuButton<String>(
        tooltip: 'More',
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        itemBuilder: (_) => [
          for (final a in actions)
            PopupMenuItem<String>(
              value: a,
              child: CustomText(
                _labelFor(a) ?? a,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w600,
                color: a == OrderAction.cancelOrder ||
                        a == OrderAction.rejectOrder ||
                        a == OrderAction.rejectPayment
                    ? Colors.red
                    : AppColors.mainTextColor,
              ),
            ),
        ],
        onSelected: (a) => _runAction(context, a),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            border: Border.all(color: OrderUi.blockBorder),
            borderRadius: BorderRadius.circular(OrderUi.buttonRadius),
          ),
          child: const Icon(Icons.more_horiz, size: 20, color: OrderUi.inkSoft),
        ),
      ),
    );
  }

  /// Runs an action chosen from the overflow menu. Same flows, same guards —
  /// the menu is only a different way to reach them.
  void _runAction(BuildContext context, String action) {
    switch (action) {
      case OrderAction.acceptOrder:
        _acceptFlow(context);
        break;
      case OrderAction.rejectOrder:
        _rejectFlow(context);
        break;
      case OrderAction.setPrepEta:
        _etaSheet(context);
        break;
      case OrderAction.markReady:
        _markReady();
        break;
      case OrderAction.verifyPayment:
        _verifyPayment();
        break;
      case OrderAction.rejectPayment:
        _rejectPaymentFlow(context);
        break;
      case OrderAction.confirmHandover:
        _handoverFlow(context);
        break;
      case OrderAction.collectCash:
        _collectCash();
        break;
      case OrderAction.completeOrder:
        _completeOrder();
        break;
      case OrderAction.startPreparing:
        _startPreparing();
        break;
      case OrderAction.reportNoShow:
        _noShow();
        break;
      case OrderAction.markRefundSent:
        _refundSentFlow(context);
        break;
      case OrderAction.submitPayment:
        _payFlow(context);
        break;
      case OrderAction.viewPickupCode:
        _showPickupCode(context);
        break;
      case OrderAction.findRider:
        _findRider();
        break;
      case OrderAction.confirmRefundReceived:
        _confirmRefundReceived();
        break;
      case OrderAction.cancelOrder:
        _cancelFlow(context);
        break;
      case OrderAction.rateOrder:
        _rateFlow(context);
        break;
      case OrderAction.raiseIssue:
        _raiseIssue();
        break;
      default:
        break;
    }
  }

  Widget? _widgetFor(BuildContext context, String action) {
    switch (action) {
      // ── Owner ────────────────────────────────────────────────────────
      case OrderAction.acceptOrder:
        return _btn(action, 'Accept',
            onTap: () => _acceptFlow(context),
            icon: Icons.check_circle_outline);
      case OrderAction.rejectOrder:
        return _btn(action, 'Reject',
            onTap: () => _rejectFlow(context),
            style: OrderButtonStyle.danger,
            icon: Icons.cancel_outlined);
      case OrderAction.setPrepEta:
        return _btn(action, 'Update Ready Time',
            onTap: () => _etaSheet(context),
            style: OrderButtonStyle.secondary,
            icon: Icons.schedule);
      case OrderAction.markReady:
        return _btn(action, 'Mark as Ready',
            onTap: _markReady, icon: Icons.check_circle_outline);
      case OrderAction.verifyPayment:
        return _btn(action, 'Confirm',
            onTap: _verifyPayment, icon: Icons.check_circle_outline);
      case OrderAction.rejectPayment:
        return _btn(action, 'Reject',
            onTap: () => _rejectPaymentFlow(context),
            style: OrderButtonStyle.danger,
            icon: Icons.cancel_outlined);
      case OrderAction.confirmHandover:
        return _btn(action, 'Verify & Continue',
            onTap: () => _handoverFlow(context),
            trailingIcon: Icons.arrow_forward);
      // Cash at the counter, after the code matched. Worded as a fact the shop
      // is reporting rather than an instruction.
      case OrderAction.collectCash:
        return _btn(action, 'Payment Collected',
            onTap: _collectCash, trailingIcon: Icons.arrow_forward);
      case OrderAction.completeOrder:
        return _btn(action, 'Complete Order',
            onTap: _completeOrder, trailingIcon: Icons.arrow_forward);
      case OrderAction.startPreparing:
        return _btn(action, 'Start Preparing', onTap: _startPreparing);
      case OrderAction.reportNoShow:
        return _btn(action, "Customer didn't come",
            onTap: _noShow, style: OrderButtonStyle.secondary);
      case OrderAction.markRefundSent:
        return _btn(action, 'I sent the refund',
            onTap: () => _refundSentFlow(context));

      // ── Customer ─────────────────────────────────────────────────────
      case OrderAction.submitPayment:
        return _btn(action, 'Upload Screenshot',
            onTap: () => _payFlow(context), icon: Icons.attach_file);
      case OrderAction.viewPickupCode:
        return _btn(action, 'Show Code',
            onTap: () => _showPickupCode(context),
            icon: Icons.qr_code_2_outlined);
      case OrderAction.findRider:
        // Delivery was already offered at checkout; this is the "changed my
        // mind" path, so it stays low-emphasis (guide §5.5).
        return _btn(action, 'Get it delivered',
            onTap: _findRider,
            style: OrderButtonStyle.secondary,
            icon: Icons.delivery_dining_outlined);
      case OrderAction.confirmRefundReceived:
        return _btn(action, 'I received the refund',
            onTap: _confirmRefundReceived);

      // ── Either ───────────────────────────────────────────────────────
      case OrderAction.cancelOrder:
        return _btn(action, 'Cancel Order',
            onTap: () => _cancelFlow(context),
            style: OrderButtonStyle.danger,
            icon: Icons.cancel_outlined);
      case OrderAction.contactShop:
      case OrderAction.contactCustomer:
        // The board gives this a label, not a bare handset: on the ready and
        // payment screens "Contact Shop" is half of the button pair.
        return _btn(
          action,
          ctx.isOwner ? 'Contact Customer' : 'Contact Shop',
          onTap: () => _call(context),
          style: OrderButtonStyle.secondary,
          icon: Icons.call_outlined,
        );
      case OrderAction.rateOrder:
        return _btn(action, 'Rate your experience',
            onTap: () => _rateFlow(context),
            style: OrderButtonStyle.secondary,
            icon: Icons.star_border_rounded);
      case OrderAction.raiseIssue:
        return _btn(action, 'Need Help',
            onTap: _raiseIssue,
            style: OrderButtonStyle.secondary,
            icon: Icons.help_outline);

      // Unknown action from a newer backend → render nothing. Never guess.
      default:
        return null;
    }
  }

  /// Every button on an order card, in one place.
  ///
  /// `OrderButton` carries the board's shape; this only binds it to the busy
  /// set, so the tapped action spins and the rest of the card stays live.
  Widget _btn(
    String action,
    String label, {
    required VoidCallback onTap,
    OrderButtonStyle style = OrderButtonStyle.primary,
    IconData? icon,
    IconData? trailingIcon,
  }) {
    final busy = _busy(action);
    return OrderButton(
      label: label,
      style: style,
      icon: icon,
      trailingIcon: trailingIcon,
      busy: busy,
      onTap: busy ? null : onTap,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Flows
  // ─────────────────────────────────────────────────────────────────────

  /// Reasons always come from `/actions`, scoped to this caller's role. If the
  /// card was rendered straight from `metadata.lifecycle` the list isn't loaded
  /// yet, so fetch it before opening the sheet.
  Future<List<OrderCancellationReason>> _reasons() async {
    final cached = _controller.stateOf(ctx.orderId)?.cancellationReasons;
    if (cached != null && cached.isNotEmpty) return cached;
    final res =
        await _controller.refreshActions(ctx.orderId, service: ctx.service);
    return res.model?.cancellationReasons ??
        _controller.stateOf(ctx.orderId)?.cancellationReasons ??
        const [];
  }

  Future<void> _acceptFlow(BuildContext context) async {
    final minutes = await showPrepEtaSheet(context);
    if (minutes == null) return;
    final res = await _controller.acceptOrder(
      ctx.orderId,
      prepEtaMinutes: minutes == kPrepEtaSkipped ? null : minutes,
      service: ctx.service,
    );
    _after(res);
  }

  Future<void> _rejectFlow(BuildContext context) async {
    final reasons = await _reasons();
    if (!context.mounted) return;
    final choice = await showOrderReasonSheet(
      context,
      title: "Why can't you take this order?",
      reasons: reasons,
      confirmLabel: "Can't take it",
      fallbackReasonCode: 'OTHER',
    );
    if (choice == null) return;
    final res = await _controller.rejectOrder(
      ctx.orderId,
      reasonCode: choice.reasonCode,
      comment: choice.comment,
      service: ctx.service,
    );
    _after(res);
  }

  Future<void> _etaSheet(BuildContext context) async {
    final minutes = await showPrepEtaSheet(
      context,
      title: 'New ready time',
      confirmLabel: 'Update time',
      allowSkip: false,
    );
    if (minutes == null || minutes == kPrepEtaSkipped) return;
    final res = await _controller.setPrepEta(ctx.orderId,
        prepEtaMinutes: minutes, service: ctx.service);
    _after(res);
  }

  Future<void> _markReady() async {
    final res = await _controller.markReady(ctx.orderId, service: ctx.service);
    _after(res);
  }

  /// The amount is the server's, never a local sum: the shop confirms what it
  /// was told to collect, and a client-computed total that disagreed would be
  /// a dispute at the counter.
  Future<void> _collectCash() async {
    final due = _controller.stateOf(ctx.orderId)?.paymentSummary?.amountDue;
    final res = await _controller.collectCash(
      ctx.orderId,
      amountCollected: due,
      service: ctx.service,
    );
    _after(res);
  }

  Future<void> _completeOrder() async {
    final res =
        await _controller.completeOrder(ctx.orderId, service: ctx.service);
    _after(res);
  }

  Future<void> _startPreparing() async {
    final res =
        await _controller.startPreparing(ctx.orderId, service: ctx.service);
    _after(res);
  }

  Future<void> _verifyPayment() async {
    final summary = _controller.stateOf(ctx.orderId)?.paymentSummary;
    final res = await _controller.verifyPayment(
      ctx.orderId,
      amountReceived: summary?.amountPaid,
      service: ctx.service,
    );
    _after(res);
  }

  Future<void> _rejectPaymentFlow(BuildContext context) async {
    final summary = _controller.stateOf(ctx.orderId)?.paymentSummary;
    final choice = await showOrderReasonSheet(
      context,
      title: 'Reject Payment Screenshot?',
      subtitle: "This screenshot doesn't match the order payment. "
          'Please choose a reason to continue.',
      // The server does not scope payment-rejection reasons, so these five are
      // the board's own list, submitted as free text. The customer sees
      // exactly what the shop picked.
      reasons: const [
        OrderCancellationReason(
            code: 'WRONG_AMOUNT', label: 'Wrong payment amount'),
        OrderCancellationReason(
            code: 'INVALID_SCREENSHOT', label: 'Invalid screenshot'),
        OrderCancellationReason(
            code: 'NOT_RECEIVED', label: 'Payment not received'),
        OrderCancellationReason(
            code: 'UNCLEAR', label: 'Screenshot unclear'),
        OrderCancellationReason(
            code: 'OTHER', label: 'Other', requiresComment: true),
      ],
      reasonPrompt: 'Why are you rejecting it? (Required)',
      preview: _screenshotPreview(summary),
      confirmLabel: 'Reject Payment Screenshot',
      keepLabel: 'Keep Order',
      commentHint: 'e.g. Nothing has reached my account yet',
    );
    if (choice == null) return;
    final res = await _controller.rejectPayment(
      ctx.orderId,
      // The customer reads this, so a typed note wins over a bare code and a
      // code is humanised before it is sent.
      reason: choice.comment ?? _humanReason(choice.reasonCode),
      service: ctx.service,
    );
    _after(res);
  }

  static String _humanReason(String code) {
    final words = code.replaceAll('_', ' ').toLowerCase().trim();
    if (words.isEmpty) return code;
    return words[0].toUpperCase() + words.substring(1);
  }

  /// The screenshot the shop is about to reject, shown at the size it was
  /// judged at — rejecting a payment on a 46dp thumbnail is how a real
  /// transfer gets bounced.
  Widget? _screenshotPreview(OrderPaymentSummary? s) {
    final url = (s?.screenshotUrl ?? '').trim();
    if (url.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          height: 180,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            height: 120,
            color: OrderUi.block,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined,
                size: 22, color: OrderUi.inkFaint),
          ),
        ),
      ),
    );
  }

  Future<void> _handoverFlow(BuildContext context) async {
    final state = _controller.stateOf(ctx.orderId);
    final isCash = state?.lifecycle.isCash ?? false;
    final ok = await showPickupHandoverDialog(
      context,
      orderId: ctx.orderId,
      service: ctx.service,
      isCashOrder: isCash,
      cashAmount: state?.paymentSummary?.amountDue ?? ctx.orderTotal,
    );
    if (ok) {
      ctx.onChanged?.call(_controller.stateOf(ctx.orderId));
    } else {
      // The dialog closes on ACTION_NOT_AVAILABLE — say why, once.
      final fresh = _controller.stateOf(ctx.orderId);
      if (fresh?.lifecycle.paymentState == PaymentStateValue.submitted ||
          fresh?.lifecycle.paymentState == PaymentStateValue.underReview) {
        commonSnackBar(message: 'Confirm the payment first.');
      }
    }
  }

  Future<void> _noShow() async {
    final res =
        await _controller.reportNoShow(ctx.orderId, service: ctx.service);
    _after(res);
  }

  Future<void> _refundSentFlow(BuildContext context) async {
    final state = _controller.stateOf(ctx.orderId);
    final ok = await showRefundSentDialog(
      context,
      orderId: ctx.orderId,
      service: ctx.service,
      amount: state?.paymentSummary?.amountPaid ??
          state?.lifecycle.refundAmount ??
          ctx.orderTotal,
      customerUpiId: state?.paymentSummary?.upiId,
    );
    if (ok) ctx.onChanged?.call(_controller.stateOf(ctx.orderId));
  }

  /// The screenshot uploader, reachable from a panel that draws its own
  /// `Upload Screenshot` control.
  ///
  /// One code path for the actual POST: the panel owns where the button sits,
  /// this owns what it does, and the `/payment/submit` call stays in one place.
  Future<void> openPaymentSheet(BuildContext context) => _payFlow(context);

  Future<void> _payFlow(BuildContext context) async {
    // The sheet needs the authoritative amount due, and `/actions` carries no
    // money at all — so hydrate from `/track`, which does (guide §2.4).
    final payment =
        await _controller.ensurePayment(ctx.orderId, service: ctx.service);
    if (!context.mounted) return;
    final ok = await showOrderPaymentSheet(
      context,
      orderId: ctx.orderId,
      service: ctx.service,
      payeeUserId: ctx.otherUserId,
      amountDue: payment?.amountDue ?? ctx.orderTotal,
      shopName: ctx.shopName ?? ctx.otherUserName,
    );
    if (ok) {
      await _controller.refreshActions(ctx.orderId, service: ctx.service);
      ctx.onChanged?.call(_controller.stateOf(ctx.orderId));
    }
  }

  Future<void> _showPickupCode(BuildContext context) async {
    final res =
        await _controller.fetchPickupCode(ctx.orderId, service: ctx.service);
    if (!res.ok) return;
    final code = res.model?.pickupCode ??
        res.raw?['pickupCode']?.toString() ??
        (res.raw?['data'] is Map
            ? (res.raw!['data'] as Map)['pickupCode']?.toString()
            : null);
    if (code == null || code.isEmpty) {
      commonSnackBar(message: 'Pickup code is not ready yet.');
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PickupCodeScreen(
        pickupCode: code,
        shopName: ctx.shopName ?? ctx.otherUserName,
        shopAddress: ctx.shopAddress,
      ),
    ));
  }

  Future<void> _findRider() async {
    final handler = ctx.onFindRider;
    if (handler == null) {
      commonSnackBar(message: 'Delivery is not available from here.');
      return;
    }
    await handler();
  }

  Future<void> _confirmRefundReceived() async {
    final res = await _controller.confirmRefundReceived(ctx.orderId,
        service: ctx.service);
    if (res.ok) commonSnackBar(message: 'Thanks — refund closed.');
    _after(res);
  }

  Future<void> _cancelFlow(BuildContext context) async {
    final reasons = await _reasons();
    if (!context.mounted) return;
    final state = _controller.stateOf(ctx.orderId);
    final l = state?.lifecycle;
    final choice = await showOrderReasonSheet(
      context,
      title: 'Cancel this order?',
      // What the shop is doing right now decides whether cancelling is even
      // reasonable, so the sheet says it rather than making the customer
      // remember which screen they came from.
      subtitle: _cancelSubtitle(l),
      caption: 'Cancellation may not be available once preparation has '
          'reached a certain stage.',
      reasonPrompt: 'Why are you cancelling? (optional)',
      preview: _cancelPreview(state),
      reasons: reasons,
      confirmLabel: 'Cancel Order',
      keepLabel: 'Keep Order',
      fallbackReasonCode: 'OTHER',
    );
    if (choice == null) return;
    final res = await _controller.cancelOrder(
      ctx.orderId,
      reasonCode: choice.reasonCode,
      comment: choice.comment,
      service: ctx.service,
    );
    _after(res);
  }

  /// The board's second line: what is happening to the order right now.
  static String _cancelSubtitle(OrderLifecycle? l) {
    switch (l?.orderStatus) {
      case OrderStatusValue.placed:
        return 'The shop has not accepted this order yet.';
      case OrderStatusValue.ready:
        return 'Your order is packed and waiting at the shop.';
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        return 'Your order is currently being prepared by the shop.';
      default:
        return 'This will end the order for both of you.';
    }
  }

  /// The mini-card between the question and the answers.
  ///
  /// The money line is the whole reason it is here: a customer cancelling
  /// before they paid needs to be told, in the same breath, that there is
  /// nothing to get back — and one who *has* paid needs to know a refund is
  /// what happens next, not silence.
  Widget _cancelPreview(OrderActionsModel? state) {
    final l = state?.lifecycle;
    final paid = state?.paymentSummary?.amountPaid ?? 0;
    final collected = (l?.isCash ?? true)
        ? ((l?.isCashCollected ?? false)
            ? (state?.paymentSummary?.amountDue ?? 0)
            : 0)
        : paid;

    return OrderCancelPreview(
      orderNo: _previewOrderNo(state),
      isDelivery: state?.isRiderOrder ?? false,
      isCash: l?.isCash ?? true,
      totalAmount: OrderUiFormat.rupees(
          state?.grandTotal ?? ctx.orderTotal),
      thumbnails: [
        for (final i in ctx.items)
          if ((i.imageUrl ?? '').trim().isNotEmpty) i.imageUrl!.trim(),
      ],
      moneyNote: collected > 0
          ? '${OrderUiFormat.rupees(collected)} has been paid. '
              'The shop will return it.'
          : 'No payment has been collected yet.',
    );
  }

  String _previewOrderNo(OrderActionsModel? state) {
    final n = (ctx.orderNumber ?? state?.orderNumber ?? '').trim();
    if (n.isNotEmpty) return n.replaceFirst(RegExp(r'^#'), '');
    final id = ctx.orderId;
    return id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
  }

  /// `Rate your experience`.
  ///
  /// Rating is not an order transition — it posts to the business's own rating
  /// endpoint and the order is already finished — so nothing here refreshes
  /// the card. It is offered both as a server action (`RATE_ORDER`) and, on a
  /// completed card, as one of the board's local buttons; both land here so
  /// there is one sheet and one POST.
  Future<void> _rateFlow(BuildContext context) async {
    await showOrderRatingSheet(
      context,
      businessId: ctx.businessId ?? '',
      shopName: ctx.shopName ?? ctx.otherUserName,
    );
  }

  void _raiseIssue() {
    final handler = ctx.onRaiseIssue;
    if (handler != null) {
      handler();
      return;
    }
    commonSnackBar(
        message: 'Tell the shop here in the chat, or contact support.');
  }

  void _after(OrderCallResult res) {
    if (!res.ok) return;
    // A light tap on a successful action (guide §3.5) — the shop is often
    // holding the phone rather than watching it.
    HapticFeedback.lightImpact();
    ctx.onChanged?.call(res.model);

    // A success can still carry a caveat: an amount that doesn't match, for
    // instance. Amber note, never an error.
    final warning = res.warning;
    if (warning != null && warning.isNotEmpty) {
      commonSnackBar(message: warning);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Button styles
  // ─────────────────────────────────────────────────────────────────────

  bool _busy(String action) => _controller.isBusy(ctx.orderId, action);






  void _call(BuildContext context) {
    final otherId = ctx.otherUserId ?? '';
    final phone = (ctx.otherUserPhone ?? '').trim();
    if (otherId.isEmpty && phone.isEmpty) {
      commonSnackBar(message: 'No contact details for this order.');
      return;
    }
    // One tap → the sheet, so the user picks in-app voice vs the dialler. The
    // existing chat call machinery handles both.
    showChatCallOptionsBottomSheet(
      context: context,
      otherUserId: otherId.isEmpty ? null : otherId,
      conversationId: ctx.conversationId,
      userName: ctx.otherUserName ?? '',
      userImage: ctx.otherUserPhoto ?? '',
      contactNo: phone,
    );
  }

}
