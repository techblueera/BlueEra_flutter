import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_payment_submit_sheet.dart';
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

  const OrderActionBar({
    super.key,
    required this.actions,
    required this.ctx,
  });

  OrderLifecycleController get _controller => OrderLifecycleController.instance;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

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
      final ranked = [...actions]..sort((a, b) => _rank(a).compareTo(_rank(b)));

      // Icons never count against the cap — a call button that disappears into
      // an overflow menu is a call that does not get made.
      final icons = ranked.where(_isIcon).toList();
      final buttons = ranked.where((a) => !_isIcon(a)).toList();

      final visible = buttons.take(_maxVisible).toList();
      final overflow = buttons.skip(_maxVisible).toList();

      final widgets = <Widget>[];
      for (final a in [...visible, ...icons]) {
        final w = _widgetFor(context, a);
        if (w != null) widgets.add(w);
      }
      // Only offer the ⋯ for actions this build actually knows how to run.
      final knownOverflow =
          overflow.where((a) => _labelFor(a) != null).toList();
      if (knownOverflow.isNotEmpty) {
        widgets.add(_overflowButton(context, knownOverflow));
      }

      if (widgets.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Wrap(spacing: 8, runSpacing: 8, children: widgets),
      );
    });
  }

  /// At most three buttons stay on the card; the rest fold into `⋯`.
  static const int _maxVisible = 3;

  static bool _isIcon(String a) =>
      a == OrderAction.contactShop || a == OrderAction.contactCustomer;

  /// Lower sorts earlier. Primary work first, then the ways out.
  static int _rank(String a) {
    switch (a) {
      case OrderAction.acceptOrder:
      case OrderAction.markReady:
      case OrderAction.verifyPayment:
      case OrderAction.confirmHandover:
      case OrderAction.submitPayment:
      case OrderAction.viewPickupCode:
      case OrderAction.markRefundSent:
      case OrderAction.confirmRefundReceived:
        return 0; // primary
      case OrderAction.setPrepEta:
        return 1; // secondary
      case OrderAction.findRider:
        return 2; // low-emphasis link
      case OrderAction.rejectOrder:
      case OrderAction.rejectPayment:
      case OrderAction.reportNoShow:
      case OrderAction.cancelOrder:
        return 3; // destructive
      case OrderAction.raiseIssue:
        return 4;
      case OrderAction.contactShop:
      case OrderAction.contactCustomer:
        return 5; // icon
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
        return "Can't take it";
      case OrderAction.setPrepEta:
        return 'Update time';
      case OrderAction.markReady:
        return 'Order packed';
      case OrderAction.verifyPayment:
        return 'Payment received';
      case OrderAction.rejectPayment:
        return 'Not received';
      case OrderAction.confirmHandover:
        return 'Handed over';
      case OrderAction.reportNoShow:
        return "Customer didn't come";
      case OrderAction.markRefundSent:
        return 'I sent the refund';
      case OrderAction.submitPayment:
        return 'Pay now';
      case OrderAction.viewPickupCode:
        return 'Show pickup code';
      case OrderAction.findRider:
        return 'Get it delivered';
      case OrderAction.confirmRefundReceived:
        return 'I received the refund';
      case OrderAction.cancelOrder:
        return 'Cancel order';
      case OrderAction.raiseIssue:
        return 'Report a problem';
      default:
        return null;
    }
  }

  Widget _overflowButton(BuildContext context, List<String> actions) {
    return SizedBox(
      height: 38,
      width: 44,
      child: PopupMenuButton<String>(
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
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.greyE5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.more_horiz,
              size: 18, color: AppColors.secondaryTextColor),
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
        return _primary(action, 'Accept',
            onTap: () => _acceptFlow(context), color: const Color(0xFF1B9E4B));
      case OrderAction.rejectOrder:
        return _destructive(action, "Can't take it",
            onTap: () => _rejectFlow(context));
      case OrderAction.setPrepEta:
        return _text(action, 'Update time', onTap: () => _etaSheet(context));
      case OrderAction.markReady:
        return _primary(action, 'Order packed', onTap: _markReady);
      case OrderAction.verifyPayment:
        return _primary(action, 'Payment received',
            onTap: _verifyPayment, color: const Color(0xFF1B9E4B));
      case OrderAction.rejectPayment:
        return _destructive(action, 'Not received',
            onTap: () => _rejectPaymentFlow(context));
      case OrderAction.confirmHandover:
        return _primary(action, 'Handed over',
            onTap: () => _handoverFlow(context));
      case OrderAction.reportNoShow:
        return _text(action, "Customer didn't come", onTap: _noShow);
      case OrderAction.markRefundSent:
        return _primary(action, 'I sent the refund',
            onTap: () => _refundSentFlow(context));

      // ── Customer ─────────────────────────────────────────────────────
      case OrderAction.submitPayment:
        return _primary(action, 'Pay now', onTap: () => _payFlow(context));
      case OrderAction.viewPickupCode:
        return _primary(action, 'Show pickup code',
            onTap: () => _showPickupCode(context));
      case OrderAction.findRider:
        // A text link under the pickup code — never a primary button, and
        // never a navigation away from chat (guide §5.5). Delivery was already
        // offered at checkout; this is the "changed my mind" path.
        return _text(action, "Can't come? Get it delivered", onTap: _findRider);
      case OrderAction.confirmRefundReceived:
        return _primary(action, 'I received the refund',
            onTap: _confirmRefundReceived);

      // ── Either ───────────────────────────────────────────────────────
      case OrderAction.cancelOrder:
        return _text(action, 'Cancel order',
            onTap: () => _cancelFlow(context), destructive: true);
      case OrderAction.contactShop:
      case OrderAction.contactCustomer:
        return _iconCall(context);
      case OrderAction.raiseIssue:
        return _text(action, 'Report a problem', onTap: _raiseIssue);

      // Unknown action from a newer backend → render nothing. Never guess.
      default:
        return null;
    }
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
    final choice = await showOrderReasonSheet(
      context,
      title: 'Why is the payment not confirmed?',
      // The server does not scope payment-rejection reasons, so this is a
      // free-text form — the customer sees exactly what the shop typed.
      reasons: const [],
      confirmLabel: 'Not received',
      commentHint: 'e.g. Nothing has reached my account yet',
    );
    if (choice == null) return;
    final res = await _controller.rejectPayment(
      ctx.orderId,
      reason: choice.comment ?? choice.reasonCode,
      service: ctx.service,
    );
    _after(res);
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
    final choice = await showOrderReasonSheet(
      context,
      title: 'Cancel this order?',
      reasons: reasons,
      confirmLabel: 'Cancel order',
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

  Widget _primary(String action, String label,
      {required VoidCallback onTap, Color? color}) {
    final busy = _busy(action);
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primaryColor,
          disabledBackgroundColor:
              (color ?? AppColors.primaryColor).withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: busy
            ? _spinner(Colors.white)
            : CustomText(
                label,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _secondary(String action, String label,
      {required VoidCallback onTap}) {
    final busy = _busy(action);
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: busy
            ? _spinner(AppColors.primaryColor)
            : CustomText(
                label,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
      ),
    );
  }

  Widget _destructive(String action, String label,
      {required VoidCallback onTap}) {
    final busy = _busy(action);
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: busy
            ? _spinner(Colors.red)
            : CustomText(
                label,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
      ),
    );
  }

  Widget _text(String action, String label,
      {required VoidCallback onTap, bool destructive = false}) {
    final busy = _busy(action);
    final color = destructive ? Colors.red : AppColors.secondaryTextColor;
    return SizedBox(
      height: 38,
      child: TextButton(
        onPressed: busy ? null : onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 38),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: busy
            ? _spinner(color)
            : CustomText(
                label,
                fontSize: SizeConfig.size13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
      ),
    );
  }

  Widget _iconCall(BuildContext context) {
    return SizedBox(
      height: 38,
      width: 44,
      child: OutlinedButton(
        onPressed: () => _call(context),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.primaryColor),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Icon(Icons.call, size: 18, color: AppColors.primaryColor),
      ),
    );
  }

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

  static Widget _spinner(Color color) => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
}
