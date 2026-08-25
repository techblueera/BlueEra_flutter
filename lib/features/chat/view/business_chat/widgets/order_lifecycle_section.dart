import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_deadline_countdown.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// The whole server-driven part of an order card: status banner, deadline
/// countdown, payment sub-state, refund wording, attention strip and the
/// action bar.
///
/// Drop this into any order card in place of its hand-built status row and
/// action buttons. It reads [OrderLifecycleController] first (authoritative,
/// updated by `/actions`, action responses and the `productOrderLifecycle`
/// socket) and falls back to the [fallbackLifecycle] the card parsed out of
/// `metadata.lifecycle` — which is why a card renders correctly with **no
/// network call at all** (guide §1.1).
///
/// When neither source has a lifecycle — an order created before the backend
/// change, or a vertical not yet ported — the section renders nothing and the
/// card's own legacy UI stays in charge.
class OrderLifecycleSection extends StatefulWidget {
  final OrderCardContext ctx;

  /// `metadata.lifecycle` as parsed by the card. May be null on legacy cards.
  final OrderLifecycle? fallbackLifecycle;

  /// Rendered above the banner — the card's own legacy status row. Shown only
  /// while there is no lifecycle at all, so old orders keep their old look.
  final Widget? legacyFallback;

  const OrderLifecycleSection({
    super.key,
    required this.ctx,
    this.fallbackLifecycle,
    this.legacyFallback,
  });

  @override
  State<OrderLifecycleSection> createState() => _OrderLifecycleSectionState();
}

class _OrderLifecycleSectionState extends State<OrderLifecycleSection> {
  OrderLifecycleController get _controller => OrderLifecycleController.instance;

  @override
  void initState() {
    super.initState();
    final orderId = widget.ctx.orderId;
    if (orderId.isEmpty) return;

    // Seed from the card's metadata so buttons appear immediately, then
    // register for the resume / reconnect sweep.
    final fallback = widget.fallbackLifecycle;
    if (fallback != null) {
      _controller.seedFromLifecycle(orderId, fallback,
          service: widget.ctx.service);
    }
    _controller.trackVisibleOrder(orderId, service: widget.ctx.service);
  }

  @override
  void didUpdateWidget(covariant OrderLifecycleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fallback = widget.fallbackLifecycle;
    // A socket-delivered metadata patch arrives as a new fallback — push it
    // into the store so the buttons follow.
    if (fallback != null && fallback != oldWidget.fallbackLifecycle) {
      _controller.seedFromLifecycle(widget.ctx.orderId, fallback,
          service: widget.ctx.service, force: true);
    }
  }

  @override
  void dispose() {
    _controller.untrackVisibleOrder(widget.ctx.orderId);
    super.dispose();
  }

  /// A deadline elapsed. Show "Checking…" (the countdown does that itself) and
  /// re-fetch **once**. Never flip the card to expired here — the sweeper
  /// cancels within a minute and the real card follows.
  void _onDeadlineElapsed() {
    _controller.refreshActions(widget.ctx.orderId, service: widget.ctx.service);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.stateOf(widget.ctx.orderId);
      final lifecycle = state?.lifecycle ?? widget.fallbackLifecycle;

      if (lifecycle == null || lifecycle.orderStatus == null) {
        // Legacy order — no lifecycle anywhere. Leave the card's own UI alone.
        return widget.legacyFallback ?? const SizedBox.shrink();
      }

      final actions = state?.actionsFor(isOwner: widget.ctx.isOwner) ??
          lifecycle.actionsFor(isOwner: widget.ctx.isOwner);

      final children = <Widget>[
        const Divider(height: 1, color: Color(0xFFE5E5E5)),
        _bannerRow(lifecycle),
      ];

      final deadlineRow = _deadlineRow(lifecycle);
      if (deadlineRow != null) children.add(deadlineRow);

      if (lifecycle.needsAttention) children.add(_attentionStrip());

      final payment = _paymentBlock(lifecycle, state);
      if (payment != null) children.add(payment);

      final refund = _refundBlock(lifecycle, state);
      if (refund != null) children.add(refund);

      if (_controller.networkFailedOrders.contains(widget.ctx.orderId)) {
        children.add(_retryRow());
      }

      // Terminal orders still render whatever `availableActions` contains — a
      // cancelled order that owes money is not finished business (guide §3.6.1).
      children.add(OrderActionBar(actions: actions, ctx: widget.ctx));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    });
  }

  // ── Banner ─────────────────────────────────────────────────────────────

  /// The banner is **server-authored** and rendered verbatim. Building a
  /// string from `orderStatus` here is exactly how the app and the server
  /// drifted apart before (guide §1.2).
  Widget _bannerRow(OrderLifecycle lifecycle) {
    final tone = _toneFor(lifecycle);
    final banner = (lifecycle.banner ?? '').trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(tone.icon, size: 16, color: tone.color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              // Only when the server sent no banner at all does a neutral
              // placeholder appear — never a status string of our own making.
              banner.isNotEmpty ? banner : 'Order update',
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w600,
              color: tone.color,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  _BannerTone _toneFor(OrderLifecycle l) {
    switch (l.orderStatus) {
      case OrderStatusValue.completed:
        return const _BannerTone(Color(0xFF1B9E4B), Icons.check_circle);
      case OrderStatusValue.cancelled:
      case OrderStatusValue.expired:
        return const _BannerTone(AppColors.grayText, Icons.cancel_outlined);
      case OrderStatusValue.ready:
      case OrderStatusValue.dispatched:
        return const _BannerTone(Color(0xFF1B9E4B), Icons.inventory_2_outlined);
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        return const _BannerTone(AppColors.primaryColor, Icons.timelapse);
      default:
        return const _BannerTone(Colors.deepOrange, Icons.hourglass_top);
    }
  }

  // ── Deadlines ──────────────────────────────────────────────────────────

  /// Exactly one countdown per state, chosen by which clock the server has
  /// running. A terminal order shows none.
  Widget? _deadlineRow(OrderLifecycle l) {
    if (l.isTerminal) return null;
    final d = l.deadlines;

    DateTime? target;
    String label;
    bool pulse = false;

    switch (l.orderStatus) {
      case OrderStatusValue.placed:
        target = d.acceptBy;
        label = widget.ctx.isOwner ? 'Confirm within' : 'Shop replies within';
        pulse = widget.ctx.isOwner;
        break;
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        // A UPI order waiting on money shows the payment clock instead.
        if (l.isUpi &&
            l.paymentState == PaymentStateValue.pending &&
            d.payBy != null) {
          target = d.payBy;
          label = widget.ctx.isOwner ? 'Payment due in' : 'Pay within';
        } else {
          target = d.readyBy;
          label = 'Ready in';
        }
        break;
      case OrderStatusValue.ready:
        target = d.pickupBy;
        label = widget.ctx.isOwner ? 'Holding until' : 'Collect within';
        break;
      default:
        target = null;
        label = '';
    }

    if (target == null) return null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: OrderDeadlineCountdown(
        deadline: target,
        label: label,
        pulse: pulse,
        onElapsed: _onDeadlineElapsed,
      ),
    );
  }

  Widget _attentionStrip() {
    // Neutral by design — the internal reason code is never exposed to either
    // party (guide §3.7).
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.grayText),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              "We're looking into this order.",
              fontSize: SizeConfig.size12,
              color: AppColors.grayText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment ────────────────────────────────────────────────────────────

  /// The UPI payment sub-states. This sequence must never look like a single
  /// step (guide §3.3).
  ///
  /// A `submitted` payment is **never** labelled "Paid". The word for
  /// `submitted` is "says they paid" — that single wording choice is what
  /// stops a shop handing over goods on a screenshot.
  Widget? _paymentBlock(OrderLifecycle l, OrderActionsModel? state) {
    if (!l.isUpi) return null;
    final summary = state?.paymentSummary;

    switch (l.paymentState) {
      case PaymentStateValue.submitted:
      case PaymentStateValue.underReview:
        return widget.ctx.isOwner
            ? _ownerVerificationCard(summary)
            : _note(
                icon: Icons.hourglass_bottom,
                color: Colors.deepOrange,
                text: 'Waiting for the shop to confirm your payment',
              );

      case PaymentStateValue.verified:
        return _note(
          icon: Icons.verified,
          color: const Color(0xFF1B9E4B),
          text: widget.ctx.isOwner
              ? 'Payment verified ✓'
              : 'Payment verified ✓',
        );

      case PaymentStateValue.rejected:
        final reason = summary?.rejectedReason;
        return _note(
          icon: Icons.error_outline,
          color: Colors.red,
          text: reason != null && reason.isNotEmpty
              ? 'Payment not confirmed: $reason'
              : 'Payment not confirmed',
        );

      case PaymentStateValue.expired:
        return _note(
          icon: Icons.timer_off_outlined,
          color: AppColors.grayText,
          text: 'Payment window closed',
        );

      default:
        return null;
    }
  }

  /// The shop's verification card: screenshot (tap to zoom), UTR (long-press
  /// to copy), and **amount paid vs amount due side by side**, amber when they
  /// differ. The whole point is that the shop checks their own bank app before
  /// tapping — the comparison must be effortless.
  Widget _ownerVerificationCard(OrderPaymentSummary? s) {
    final mismatch = s?.hasMismatch ?? false;
    final screenshot = s?.screenshotUrl ?? '';
    final utr = s?.utrNo ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: mismatch ? const Color(0xFFFFF8E6) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: mismatch ? const Color(0xFFE9A100) : AppColors.greyE5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions,
                  size: 16, color: Colors.deepOrange),
              const SizedBox(width: 6),
              Expanded(
                child: CustomText(
                  // Never "Paid".
                  'Customer says they paid',
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (screenshot.isNotEmpty)
                GestureDetector(
                  onTap: () => _zoom(screenshot),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      screenshot,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 58,
                        height: 58,
                        color: Colors.black12,
                        child: const Icon(Icons.broken_image_outlined,
                            size: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              if (screenshot.isNotEmpty) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _amountCell('They paid',
                              s?.amountPaid, mismatch ? const Color(0xFFA96A00) : AppColors.mainTextColor),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.greyE5,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Expanded(
                          child: _amountCell(
                              'Order total', s?.amountDue, AppColors.mainTextColor),
                        ),
                      ],
                    ),
                    if (utr.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: utr));
                          commonSnackBar(message: 'UTR copied');
                        },
                        child: CustomText(
                          'UTR $utr',
                          fontSize: SizeConfig.size11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CustomText(
                'The amount does not match the order total. Check your bank '
                'app before confirming.',
                fontSize: SizeConfig.size11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFA96A00),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: CustomText(
              'Confirm only after you see the money in your account.',
              fontSize: SizeConfig.size11,
              color: AppColors.grayText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCell(String label, num? value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.size10,
          color: AppColors.grayText,
        ),
        CustomText(
          value == null ? '—' : '₹${_money(value)}',
          fontSize: SizeConfig.size15,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ],
    );
  }

  void _zoom(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Refunds ────────────────────────────────────────────────────────────

  /// The wording that matters most in the whole app.
  ///
  /// With direct UPI the customer paid the shop's own VPA. The platform never
  /// held a paisa of it, has no balance to reverse and no gateway to call.
  /// "Your refund is being processed" implies we are sending it — we are not,
  /// and we cannot — which manufactures a complaint against us for someone
  /// else's inaction. So: **"the shop will return it"** → **"the shop says
  /// they've sent it"** → **"received"**.
  Widget? _refundBlock(OrderLifecycle l, OrderActionsModel? state) {
    final s = state?.paymentSummary;
    final amount = s?.amountPaid ?? l.refundAmount;
    final amountLabel = amount == null ? 'the money' : '₹${_money(amount)}';
    final sentAt = l.refundInitiatedAt ?? s?.refundInitiatedAt;
    final reference = l.refundReference ?? s?.refundReference;
    // `refundOwedBy` is "shop" today, always — but read it rather than assume.
    final owedBy = (l.refundOwedBy ?? s?.refundOwedBy ?? 'shop') == 'shop'
        ? 'the shop'
        : (l.refundOwedBy ?? 'the shop');

    if (l.paymentState == PaymentStateValue.refunded) {
      return _note(
        icon: Icons.check_circle,
        color: const Color(0xFF1B9E4B),
        text: widget.ctx.isOwner ? 'Refund settled ✓' : 'Refund received ✓',
      );
    }

    if (l.paymentState != PaymentStateValue.refundPending && !l.refundDue) {
      return null;
    }

    // Step 2 — the owner has claimed they sent it. That is a claim, exactly
    // like the customer's screenshot was. The card does NOT grey out here.
    if (sentAt != null && sentAt.isNotEmpty) {
      return _note(
        icon: Icons.schedule_send,
        color: Colors.deepOrange,
        text: widget.ctx.isOwner
            ? 'Waiting for the customer to confirm they received $amountLabel'
            : '$owedBy says they\'ve sent $amountLabel'
                '${(reference ?? '').isNotEmpty ? ' (ref $reference)' : ''}. '
                'Confirm when it reaches you.',
      );
    }

    // Step 1 — nobody has sent anything yet.
    return _note(
      icon: Icons.currency_rupee,
      color: Colors.deepOrange,
      text: widget.ctx.isOwner
          ? 'You need to return $amountLabel to the customer.'
          : '$amountLabel is to be returned by $owedBy. '
              'We\'ve asked them to send it.',
    );
  }

  // ── Shared bits ────────────────────────────────────────────────────────

  Widget _note({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              text,
              fontSize: SizeConfig.size12,
              fontWeight: FontWeight.w600,
              color: color,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// Retry after a transport failure. Always safe: every action is idempotent
  /// server-side, so a retry after an unknown outcome cannot double-apply.
  Widget _retryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 15, color: AppColors.grayText),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              "Couldn't reach the server.",
              fontSize: SizeConfig.size12,
              color: AppColors.grayText,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(
            onPressed: () => _controller.refreshActions(widget.ctx.orderId,
                service: widget.ctx.service),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: CustomText(
              'Retry',
              fontSize: SizeConfig.size12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

class _BannerTone {
  final Color color;
  final IconData icon;
  const _BannerTone(this.color, this.icon);
}
