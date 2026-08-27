import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_broadcast_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_broadcast_search_section.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_deadline_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// **Zones ② to ⑥ of an order card** (guide §4): status, live, detail, actions,
/// footnote. Zone ① — the identity line — belongs to the card itself, because
/// it never changes.
///
/// Zones appear and disappear; **nothing moves**. A card that reorders itself
/// on every event reads as a glitch.
///
/// It reads [OrderLifecycleController] first (authoritative — `/actions`,
/// action responses, and the `productOrderLifecycle` socket) and falls back to
/// the [fallbackLifecycle] the card parsed out of `metadata.lifecycle`, which
/// is why a card renders correctly with **no network call at all**.
///
/// When neither source has a lifecycle — an order created before the rollout,
/// or a vertical not yet ported — the section renders nothing and the card's
/// own legacy UI stays in charge.
class OrderLifecycleSection extends StatefulWidget {
  final OrderCardContext ctx;

  /// `metadata.lifecycle` as parsed by the card. May be null on legacy cards.
  final OrderLifecycle? fallbackLifecycle;

  /// The card's own legacy status row. Shown only while there is no lifecycle
  /// at all, so old orders keep their old look.
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
  OrderBroadcastController get _broadcast => OrderBroadcastController.instance;

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

    // The card has never spoken to `/actions`, so it does not yet know the
    // viewer's `actor`. Ask once — until it answers the card is rendering from
    // its own `myMessage` guess, and a wrong guess shows the other party's
    // buttons (guide §0 cause 1).
    //
    // Only for an order the server is actually driving. A legacy card has no
    // lifecycle to reconcile and its id may not be a lifecycle order at all,
    // so asking would be a request that can only 404.
    if (fallback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.actorIsOwner(orderId) == null) {
        _controller.refreshActions(orderId, service: widget.ctx.service);
      }
    });
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

  /// A deadline elapsed. The chip shows "Checking…" itself; this re-fetches
  /// **once**. It never flips the card to expired — the sweeper ticks every
  /// 60 s and sends the real card.
  void _onDeadlineElapsed() {
    _controller.refreshActions(widget.ctx.orderId, service: widget.ctx.service);
  }

  /// The viewer's role, server-first. `myMessage` is only a fallback: the
  /// customer is the one who placed the order, so the owner is the other
  /// party — true, but a guess, and it stops being used the moment `/actions`
  /// answers with `actor`.
  bool _isOwner(OrderActionsModel? state) =>
      state?.isOwnerOrNull ?? widget.ctx.isOwner;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.stateOf(widget.ctx.orderId);
      final lifecycle = state?.lifecycle ?? widget.fallbackLifecycle;

      if (lifecycle == null || lifecycle.orderStatus == null) {
        // Legacy order — no lifecycle anywhere. Leave the card's own UI alone.
        return widget.legacyFallback ?? const SizedBox.shrink();
      }

      final isOwner = _isOwner(state);
      final actions = state?.actionsFor(isOwner: isOwner) ??
          lifecycle.actionsFor(isOwner: isOwner);

      // A doorstep order that has just been packed dispatches itself. No
      // button, no second decision — the customer already chose delivery, gave
      // the address and saw the fee at checkout (guide §7.2).
      _maybeAutoDispatch(state, isOwner);

      final offline =
          _controller.networkFailedOrders.contains(widget.ctx.orderId);

      final children = <Widget>[
        // ① IDENTITY (tail) — how this order is being fulfilled. It never
        // changes for the life of the order, so it sits above the divider with
        // the items and the total rather than in the status zone, which is one
        // line of server text and at most one chip.
        ..._identityLine(state),

        const OrderZoneDivider(),

        // ② STATUS — server text, verbatim, plus at most one chip.
        _statusZone(lifecycle, state, isOwner),

        // ③ LIVE — only while something is actually happening.
        ..._liveZone(state, isOwner),

        // ④ DETAIL — role-specific body.
        ..._detailZone(lifecycle, state, isOwner),

        if (offline) _offlineStrip(),
      ];

      // ⑤ ACTIONS — terminal orders still render whatever `availableActions`
      // contains: a cancelled order that owes a refund is not finished
      // business (guide §6.9).
      children.add(
        AnimatedOpacity(
          duration: OrderMotion.actionShift,
          opacity: offline ? 0.5 : 1,
          child: IgnorePointer(
            ignoring: offline,
            child: OrderActionBar(actions: actions, ctx: widget.ctx),
          ),
        ),
      );

      // ⑥ FOOTNOTE.
      final footnote = _footnote(lifecycle);
      if (footnote != null) children.add(footnote);

      return AnimatedOpacity(
        duration: OrderMotion.terminal,
        opacity: lifecycle.isTerminal ? 0.85 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    });
  }

  // ── Auto-dispatch ──────────────────────────────────────────────────────

  void _maybeAutoDispatch(OrderActionsModel? state, bool isOwner) {
    final businessId = widget.ctx.businessId ?? '';
    if (businessId.isEmpty) return;
    // Deferred: this runs inside build().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _broadcast.autoDispatchIfNeeded(
        state: state,
        orderId: widget.ctx.orderId,
        isOwner: isOwner,
        service: widget.ctx.service,
        businessId: businessId,
        selfpickupType: widget.ctx.selfpickupType ?? 'product_selfpickup',
        orderFor: widget.ctx.orderFor,
        orderValue: widget.ctx.orderTotal,
      );
    });
  }

  /// "Doorstep delivery" / "Collect from the shop". Rendered only once the
  /// server has said which it is — the app never assumes self-pickup, which is
  /// what it did for every order before delivery existed at checkout.
  List<Widget> _identityLine(OrderActionsModel? state) {
    final type = state?.deliveryType;
    if (type == null) return const [];
    final isDelivery = type == OrderDeliveryTypeValue.rider;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            OrderSpace.m, 0, OrderSpace.m, OrderSpace.s),
        child: Row(
          children: [
            Icon(isDelivery ? Icons.delivery_dining : Icons.storefront,
                size: 14, color: AppColors.grayText),
            const SizedBox(width: OrderSpace.xs),
            Text(
              isDelivery ? 'Doorstep delivery' : 'Collect from the shop',
              style: OrderType.label.copyWith(color: AppColors.grayText),
            ),
          ],
        ),
      ),
    ];
  }

  // ── ② Status ───────────────────────────────────────────────────────────

  /// The banner is **server-authored** and rendered verbatim. Building a
  /// string from `orderStatus` here is exactly how the app and the server
  /// drifted apart before (guide §1 rule 2).
  Widget _statusZone(
      OrderLifecycle lifecycle, OrderActionsModel? state, bool isOwner) {
    final tone = _toneFor(lifecycle);
    final banner = (lifecycle.banner ?? '').trim();
    final chip = _deadlineChip(lifecycle, isOwner);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          OrderSpace.m, OrderSpace.m, OrderSpace.m, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: OrderStatusDot(
                  tone: tone,
                  // Pulses only while we are waiting on the other party.
                  pulse: _waitingOnOther(lifecycle, isOwner),
                ),
              ),
              const SizedBox(width: OrderSpace.s),
              Expanded(
                child: AnimatedSwitcher(
                  duration: OrderMotion.bannerFade,
                  child: Text(
                    // Only when the server sent no banner at all does a
                    // neutral placeholder appear — never a status string of
                    // our own making.
                    banner.isNotEmpty ? banner : 'Order update',
                    key: ValueKey(banner),
                    style: OrderType.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (chip != null)
            Padding(
              padding:
                  const EdgeInsets.only(left: OrderSpace.l, top: OrderSpace.s),
              child: chip,
            ),
        ],
      ),
    );
  }

  bool _waitingOnOther(OrderLifecycle l, bool isOwner) {
    if (l.isTerminal) return false;
    switch (l.orderStatus) {
      case OrderStatusValue.placed:
        // The shop is the one being waited on.
        return isOwner;
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        return l.isUpi && l.paymentState == PaymentStateValue.submitted
            ? isOwner
            : false;
      default:
        return false;
    }
  }

  OrderTone _toneFor(OrderLifecycle l) {
    switch (l.orderStatus) {
      case OrderStatusValue.completed:
        return OrderTone.success;
      case OrderStatusValue.cancelled:
      case OrderStatusValue.expired:
        return OrderTone.muted;
      case OrderStatusValue.ready:
      case OrderStatusValue.dispatched:
        return OrderTone.success;
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        return OrderTone.accent;
      default:
        return OrderTone.neutral;
    }
  }

  /// Exactly one countdown per state, chosen by which clock the server has
  /// running. A terminal order shows none.
  Widget? _deadlineChip(OrderLifecycle l, bool isOwner) {
    if (l.isTerminal) return null;
    final d = l.deadlines;

    DateTime? target;
    String label;
    bool pulse = false;
    String overdue = 'over';

    switch (l.orderStatus) {
      case OrderStatusValue.placed:
        target = d.acceptBy;
        label = isOwner ? 'Confirm within' : 'Shop replies within';
        pulse = isOwner;
        break;
      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        // A UPI order waiting on money shows the payment clock instead.
        if (l.isUpi &&
            l.paymentState == PaymentStateValue.pending &&
            d.payBy != null) {
          target = d.payBy;
          label = isOwner ? 'Payment due in' : 'Pay within';
        } else {
          target = d.readyBy;
          label = 'Ready in';
          // Past `readyBy` nobody is cancelled for being slow — the chip just
          // counts up (guide §6.4).
          overdue = 'over';
        }
        break;
      case OrderStatusValue.ready:
        // A doorstep order is waiting on a rider, not on the customer.
        if (l.deadlines.dispatchBy != null &&
            (widget.ctx.orderId.isNotEmpty) &&
            (_controller.stateOf(widget.ctx.orderId)?.isRiderOrder ?? false)) {
          target = d.dispatchBy;
          label = 'Rider expected within';
        } else {
          target = d.pickupBy;
          label = isOwner ? 'Holding until' : 'Collect within';
        }
        break;
      case OrderStatusValue.dispatched:
        target = d.deliverBy;
        label = 'Arriving within';
        break;
      default:
        target = null;
        label = '';
    }

    if (target == null) return null;

    return OrderDeadlineCountdown(
      deadline: target,
      label: label,
      pulse: pulse,
      overdueSuffix: overdue,
      onElapsed: _onDeadlineElapsed,
    );
  }

  // ── ③ Live ─────────────────────────────────────────────────────────────

  /// The only zone allowed to animate. It exists **only** while a rider search
  /// is actually running, and collapses the moment one is assigned.
  List<Widget> _liveZone(OrderActionsModel? state, bool isOwner) {
    if (isOwner) return const [];
    if (state == null || !state.isRiderOrder) return const [];
    return [
      OrderBroadcastSearchSection(
        orderId: widget.ctx.orderId,
        onCollectMyself: () => commonSnackBar(
          message: 'Your order is packed at the shop — '
              'use "Show pickup code" when you get there.',
        ),
        onTryAgain: () => _broadcast.retry(
          orderId: widget.ctx.orderId,
          service: widget.ctx.service,
          businessId: widget.ctx.businessId ?? '',
          selfpickupType: widget.ctx.selfpickupType ?? 'product_selfpickup',
          orderFor: widget.ctx.orderFor,
          orderValue: widget.ctx.orderTotal,
        ),
      ),
    ];
  }

  // ── ④ Detail ───────────────────────────────────────────────────────────

  List<Widget> _detailZone(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    final out = <Widget>[];

    // An admin is already looking at this order. Neutral on both cards, and
    // the internal reason code is never exposed (guide §9.3).
    if (l.needsAttention || (state?.needsAttention ?? false)) {
      out.add(_note(
        tone: OrderTone.neutral,
        icon: Icons.info_outline,
        text: "We're looking into this order.",
      ));
    }

    // The shop has been holding a ready order for three hours. The card
    // changes SHAPE, not just text: a question, then the three answers, no
    // default and no dismiss (guide §9.2).
    if (isOwner && l.needsPickupDecision && !l.isTerminal) {
      out.add(_note(
        tone: OrderTone.warning,
        icon: Icons.help_outline,
        text: 'This order has been ready for a while. What happened?',
      ));
    }

    final payment = _paymentBlock(l, state, isOwner);
    if (payment != null) out.add(payment);

    final refund = _refundBlock(l, state, isOwner);
    if (refund != null) out.add(refund);

    return out;
  }

  /// The UPI payment sub-states. This sequence must never look like a single
  /// step (guide §6.3).
  ///
  /// A `submitted` payment is **never** labelled "Paid". The word for
  /// `submitted` is "says they paid" — that single wording choice is what
  /// stops a shop handing over goods on a screenshot.
  Widget? _paymentBlock(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    if (!l.isUpi) return null;
    final summary = state?.paymentSummary;

    switch (l.paymentState) {
      case PaymentStateValue.submitted:
      case PaymentStateValue.underReview:
        return isOwner
            ? _ownerVerificationCard(summary)
            : _note(
                tone: OrderTone.warning,
                icon: Icons.hourglass_bottom,
                text: 'Waiting for the shop to confirm your payment',
              );

      case PaymentStateValue.verified:
        return _note(
          tone: OrderTone.success,
          icon: Icons.verified,
          text: 'Payment verified ✓',
        );

      case PaymentStateValue.rejected:
        final reason = summary?.rejectionReason;
        return _note(
          tone: OrderTone.danger,
          icon: Icons.error_outline,
          text: reason != null && reason.isNotEmpty
              ? 'Payment not confirmed: $reason'
              : 'Payment not confirmed',
        );

      case PaymentStateValue.expired:
        // The order stays alive — only the payment window closed.
        return _note(
          tone: OrderTone.muted,
          icon: Icons.timer_off_outlined,
          text: 'Payment window closed',
        );

      default:
        return null;
    }
  }

  /// The shop's verification card — the whole safety model in one block.
  ///
  /// Screenshot (tap to zoom), UTR (long-press to copy), and **amount paid vs
  /// amount due side by side**, amber when they differ. The point is that the
  /// shop checks their own bank app before tapping, so the comparison has to be
  /// effortless.
  Widget _ownerVerificationCard(OrderPaymentSummary? s) {
    final mismatch = s?.hasMismatch ?? false;
    final tone = mismatch ? OrderTone.warning : OrderTone.neutral;
    final screenshot = s?.screenshotUrl ?? '';
    final utr = s?.utrNo ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(
          OrderSpace.m, OrderSpace.s, OrderSpace.m, 0),
      padding: const EdgeInsets.all(OrderSpace.m),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(OrderRadius.inner),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: OrderTone.warning.color),
              const SizedBox(width: OrderSpace.s),
              Expanded(
                child: Text(
                  // Never "Paid". A submission is a claim, not money.
                  'Customer says they paid',
                  style: OrderType.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OrderSpace.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (screenshot.isNotEmpty)
                GestureDetector(
                  onTap: () => _zoom(screenshot),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(OrderRadius.inner),
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
              if (screenshot.isNotEmpty) const SizedBox(width: OrderSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _amountCell(
                            'Paid',
                            s?.amountPaid,
                            mismatch
                                ? OrderTone.warning.color
                                : AppColors.mainTextColor,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.greyE5,
                          margin: const EdgeInsets.symmetric(
                              horizontal: OrderSpace.s),
                        ),
                        Expanded(
                          child: _amountCell(
                              'Due', s?.amountDue, AppColors.mainTextColor),
                        ),
                      ],
                    ),
                    if (utr.isNotEmpty) ...[
                      const SizedBox(height: OrderSpace.xs),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: utr));
                          commonSnackBar(message: 'UTR copied');
                        },
                        child: Text(
                          'UTR $utr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OrderType.mono(
                                  size: 12, weight: FontWeight.w600)
                              .copyWith(color: AppColors.secondaryTextColor),
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
              padding: const EdgeInsets.only(top: OrderSpace.s),
              child: Text(
                'The amount does not match the order total.',
                style: OrderType.label.copyWith(
                  color: OrderTone.warning.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: OrderSpace.xs),
            child: Text(
              'Check your bank app before confirming.',
              style: OrderType.label.copyWith(color: AppColors.grayText),
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
        Text(label,
            style: OrderType.label
                .copyWith(fontSize: 10, color: AppColors.grayText)),
        Text(
          value == null ? '—' : '₹${OrderMoneyRow.money(value)}',
          style: OrderType.mono(size: 16, weight: FontWeight.w800)
              .copyWith(color: color),
        ),
      ],
    );
  }

  void _zoom(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(OrderSpace.m),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(OrderRadius.inner),
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

  /// The wording that matters most in the whole app (guide §6.9).
  ///
  /// With direct UPI the customer paid the shop's own VPA. The platform never
  /// held a paisa of it, has no balance to reverse and no gateway to call.
  /// "Your refund is being processed" implies we are sending it — we are not,
  /// and we cannot — which manufactures a complaint against us for someone
  /// else's inaction. So: **"the shop will return it"** → **"the shop says
  /// they've sent it"** → **"received"**.
  Widget? _refundBlock(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    final s = state?.paymentSummary;
    final amount = s?.amountPaid ?? l.refundAmount;
    final amountLabel =
        amount == null ? 'the money' : '₹${OrderMoneyRow.money(amount)}';
    final sentAt = l.refundInitiatedAt ?? s?.refundInitiatedAt;
    final reference = l.refundReference ?? s?.refundReference;
    // `refundOwedBy` is "shop" today, always — but read it rather than assume.
    final owedBy = (l.refundOwedBy ?? s?.refundOwedBy ?? 'shop') == 'shop'
        ? 'the shop'
        : (l.refundOwedBy ?? 'the shop');

    if (l.paymentState == PaymentStateValue.refunded) {
      return _note(
        tone: OrderTone.success,
        icon: Icons.check_circle,
        text: isOwner ? 'Refund settled ✓' : 'Refund received ✓',
      );
    }

    if (l.paymentState != PaymentStateValue.refundPending && !l.refundDue) {
      return null;
    }

    // Step 2 — the shop has claimed it sent the money. That is a claim,
    // exactly like the customer's screenshot was. The card does NOT grey out
    // here, and only CONFIRM_REFUND_RECEIVED ends it.
    if (sentAt != null && sentAt.isNotEmpty) {
      return _note(
        tone: OrderTone.warning,
        icon: Icons.schedule_send,
        text: isOwner
            ? 'Waiting for the customer to confirm they received $amountLabel'
            : '$owedBy says they\'ve sent $amountLabel'
                '${(reference ?? '').isNotEmpty ? ' (ref $reference)' : ''}. '
                'Confirm when it reaches you.',
      );
    }

    // Step 1 — nobody has sent anything yet.
    return _note(
      tone: OrderTone.warning,
      icon: Icons.currency_rupee,
      text: isOwner
          ? 'You need to return $amountLabel to the customer.'
          : '$amountLabel is to be returned by $owedBy. '
              'We\'ve asked them to send it.',
    );
  }

  // ── ⑥ Footnote ─────────────────────────────────────────────────────────

  Widget? _footnote(OrderLifecycle l) {
    final at = l.lastEventAt;
    if (at == null || at.isEmpty) return null;
    final parsed = DateTime.tryParse(at)?.toLocal();
    if (parsed == null) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          OrderSpace.m, 0, OrderSpace.m, OrderSpace.s),
      child: Text(
        'Updated ${_clockLabel(parsed)}',
        style:
            OrderType.label.copyWith(fontSize: 10, color: AppColors.grayText),
      ),
    );
  }

  static String _clockLabel(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  // ── Shared bits ────────────────────────────────────────────────────────

  Widget _note({
    required OrderTone tone,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          OrderSpace.m, OrderSpace.s, OrderSpace.m, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: OrderSpace.m, vertical: OrderSpace.s),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(OrderRadius.inner),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: tone.color),
          const SizedBox(width: OrderSpace.s),
          Expanded(
            child: Text(
              text,
              style: OrderType.label.copyWith(
                color: tone.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Offline (guide §10.3). The card renders from `metadata.lifecycle`, which
  /// is already local, so the user still sees the last known state — the
  /// buttons simply stop working and one strip says why.
  Widget _offlineStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          OrderSpace.m, OrderSpace.s, OrderSpace.m, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: OrderSpace.m, vertical: OrderSpace.s),
      decoration: BoxDecoration(
        color: OrderTone.muted.surface,
        borderRadius: BorderRadius.circular(OrderRadius.inner),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 15, color: AppColors.grayText),
          const SizedBox(width: OrderSpace.s),
          Expanded(
            child: Text(
              "You're offline — showing the last known status.",
              style: OrderType.label.copyWith(color: AppColors.grayText),
            ),
          ),
          // Retrying is always safe: every action is a server-side
          // compare-and-set, so a retry after an unknown outcome cannot
          // double-apply.
          TextButton(
            onPressed: () => _controller.refreshActions(widget.ctx.orderId,
                service: widget.ctx.service),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: OrderSpace.s),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: OrderType.label.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
