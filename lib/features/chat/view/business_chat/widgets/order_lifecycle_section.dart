import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_broadcast_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_journey.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_journey_strip.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/widget/upi_qr_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

        // ①b STEPS — the horizontal tracker every screen in the order PDFs
        // carries. Derived from this same lifecycle (see `OrderJourney`), so it
        // draws with no network call; a server stage list replaces it wherever
        // one exists. It sits above the banner because it answers "where is my
        // order" at a glance, and the banner answers "what does that mean".
        ..._stepsZone(state, lifecycle, isOwner),

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

  /// The step strip (PDF: the `● ─ ● ─ ○` row under the order number).
  ///
  /// Renders nothing rather than guessing when the status is one this build
  /// does not know — see [OrderJourney.resolve]. A strip that puts an unknown
  /// status in the wrong place tells the customer their order is somewhere it
  /// is not, which is worse than no strip at all.
  List<Widget> _stepsZone(
      OrderActionsModel? state, OrderLifecycle lifecycle, bool isOwner) {
    final journey = OrderJourney.resolve(
      OrderJourneySnapshot.fromState(
        isOwner: isOwner,
        state: state,
        fallbackLifecycle: lifecycle,
      ),
    );
    if (journey == null || journey.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            OrderSpace.s, OrderSpace.m, OrderSpace.s, 0),
        child: OrderJourneyStrip(journey: journey),
      ),
    ];
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

    // The delivery fee, settled with the rider at the door. Renders only when
    // the server actually sent the block — a QR with no VPA behind it is worse
    // than no QR.
    final riderPayment = _riderPaymentBlock(l, isOwner);
    if (riderPayment != null) out.add(riderPayment);

    // What to do when you get to the shop, and the code panel. Customer side,
    // self-pickup, once the order is ready.
    final arrival = _arrivalBlock(l, state, isOwner);
    if (arrival != null) out.add(arrival);

    final refund = _refundBlock(l, state, isOwner);
    if (refund != null) out.add(refund);

    // Who ended it, why, and what money changed hands. Last, because it is
    // the epitaph.
    final cancellation = _cancellationBlock(l, state);
    if (cancellation != null) out.add(cancellation);

    return out;
  }

  /// **"When you arrive at the shop"** — the numbered block on the customer's
  /// ready card, plus the pickup-code panel.
  ///
  /// Two decisions worth stating:
  ///
  /// * **The steps are conditional on how the order is paid.** The cash list
  ///   has five entries and includes *"Pay the final amount in cash"*; the UPI
  ///   list has four and must not, because that money is already with the
  ///   shop. Showing a paid customer a "pay at the counter" instruction is how
  ///   someone ends up paying twice.
  /// * **The panel has no button of its own.** The board draws a `Show Code`
  ///   link inside it, but the server already offers `VIEW_PICKUP_CODE` in the
  ///   action bar below, and two controls doing one thing is how a person ends
  ///   up tapping the wrong one. The panel carries the resting copy — *"Pickup
  ///   code will be available when you arrive"* — and the action bar carries
  ///   the tap.
  Widget? _arrivalBlock(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    if (isOwner || l.isTerminal) return null;
    if (l.orderStatus != OrderStatusValue.ready) return null;
    // A doorstep order is not collected by the customer — the rider does that,
    // with their own PIN.
    if (state?.isRiderOrder ?? false) return null;

    final steps = <String>[
      'Go to the shop counter',
      'Tell the shop your order',
      'Show your pickup verification code',
      if (l.isCash) 'Pay the final amount in cash',
      'Collect your order',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(
          OrderSpace.m, OrderSpace.s, OrderSpace.m, 0),
      padding: const EdgeInsets.all(OrderSpace.m),
      decoration: BoxDecoration(
        color: OrderTone.neutral.surface,
        borderRadius: BorderRadius.circular(OrderRadius.inner),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When you arrive at the shop',
              style: OrderType.title
                  .copyWith(color: AppColors.mainTextColor, fontSize: 15)),
          const SizedBox(height: OrderSpace.s),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 18,
                    child: Text('${i + 1}.',
                        style: OrderType.label
                            .copyWith(color: AppColors.grayText)),
                  ),
                  Expanded(
                    child: Text(steps[i],
                        style: OrderType.label
                            .copyWith(color: AppColors.secondaryTextColor)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: OrderSpace.s),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(OrderSpace.m),
            decoration: BoxDecoration(
              color: OrderTone.accent.surface,
              borderRadius: BorderRadius.circular(OrderRadius.inner),
            ),
            child: Column(
              children: [
                Icon(Icons.qr_code_2,
                    size: 22, color: OrderTone.accent.color),
                const SizedBox(height: OrderSpace.xs),
                Text(
                  'Pickup code will be available when you arrive',
                  textAlign: TextAlign.center,
                  style: OrderType.label
                      .copyWith(color: AppColors.secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The delivery fee, paid to the **rider** at the door (board: customer's
  /// *"Rider Payment Pending"* screen, and the rider's completion sheet which
  /// shows the same QR from the other side).
  ///
  /// This is a second payee, not a second instalment: the shop's QR was
  /// charged the product total only. The QR here is generated from the rider's
  /// VPA **with the amount written into the link**, so the figure is not the
  /// customer's to type — it is the fee they already agreed to at checkout.
  Widget? _riderPaymentBlock(OrderLifecycle l, bool isOwner) {
    if (isOwner) return null;
    if (!l.riderPaymentDue) return null;
    final upi = (l.riderPaymentUpiId ?? '').trim();
    final amount = l.riderPaymentAmount;
    // Nothing to scan and nothing to copy: render nothing rather than an empty
    // frame that looks broken.
    if (upi.isEmpty) return null;

    final submitted =
        l.riderPaymentState == OrderRiderPaymentState.submitted;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          OrderSpace.m, OrderSpace.s, OrderSpace.m, 0),
      padding: const EdgeInsets.all(OrderSpace.m),
      decoration: BoxDecoration(
        color: OrderTone.accent.surface,
        borderRadius: BorderRadius.circular(OrderRadius.inner),
        border: Border.all(color: OrderTone.accent.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery fee',
                        style: OrderType.label
                            .copyWith(color: AppColors.grayText)),
                    if (amount != null)
                      Text('₹${amount.toStringAsFixed(0)}',
                          style: OrderType.mono(size: 20)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: OrderSpace.s, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('UPI Payment',
                    style: OrderType.label
                        .copyWith(color: OrderTone.accent.color)),
              ),
            ],
          ),
          const SizedBox(height: OrderSpace.s),
          Text(
            submitted
                // Their claim is not the rider's confirmation. Same rule as
                // the shop leg: a submitted payment is never "paid".
                ? 'Waiting for your delivery partner to confirm the payment'
                : 'Pay your delivery partner to finish this order',
            style: OrderType.label
                .copyWith(color: AppColors.secondaryTextColor),
          ),
          const SizedBox(height: OrderSpace.m),
          Center(
            child: Container(
              padding: const EdgeInsets.all(OrderSpace.s),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(OrderRadius.inner),
              ),
              child: QrImageView(
                data: upiQrPayload(upi,
                    payeeName: l.riderPaymentPayeeName, amount: amount),
                version: QrVersions.auto,
                size: 132,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                gapless: true,
              ),
            ),
          ),
          const SizedBox(height: OrderSpace.s),
          // Long-press to copy, like the UTR row: a VPA typed by hand is a
          // payment sent to the wrong person.
          InkWell(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: upi));
              commonSnackBar(message: 'UPI ID copied');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(upi,
                    style: OrderType.label.copyWith(
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: OrderSpace.xs),
                Icon(Icons.copy_rounded, size: 13, color: AppColors.grayText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The cancelled card's **Cancellation details** table (board: customer's
  /// cancelled screen).
  ///
  /// The money line is the point of the whole block. It is stated, never
  /// implied: *"₹0 collected"* is what stops a customer who cancelled before
  /// paying from wondering whether they are owed something — and on an order
  /// where money WAS taken, the refund block above says so in its own words
  /// rather than this table pretending the sum is closed.
  Widget? _cancellationBlock(OrderLifecycle l, OrderActionsModel? state) {
    if (!l.isCancelledOrExpired) return null;

    final info = state?.cancellation;
    final by = (info?.cancelledBy ?? '').trim();
    final reason = (info?.comment?.trim().isNotEmpty ?? false)
        ? info!.comment!.trim()
        : _humaniseCode(info?.reasonCode ?? l.reasonCode);

    // Cash: nothing was collected unless the shop said it collected it. UPI:
    // whatever the customer actually paid, which is 0 when they never did.
    final num collected = l.isCash
        ? (l.isCashCollected ? (state?.paymentSummary?.amountDue ?? 0) : 0)
        : (state?.paymentSummary?.amountPaid ?? 0);

    // **One money line per card.** When a refund is in play, the refund block
    // above is already saying who owes what and how far along it is — and that
    // conversation outlives the order (guide §6.9). Repeating the figure here
    // would state the same rupees twice, in two different tenses, which is how
    // a customer ends up believing they are owed it twice or not at all.
    //
    // The board's `Cash collected ₹0` line is for the case it was drawn for:
    // an order that died before any money moved. That is the case this row
    // covers, and the only one.
    final refundInPlay = l.refundDue ||
        l.paymentState == PaymentStateValue.refundPending ||
        l.paymentState == PaymentStateValue.refunded;

    final rows = <List<String>>[
      if (by.isNotEmpty) ['Cancelled by', _humaniseCode(by)],
      if (reason.isNotEmpty) ['Reason', reason],
      [
        'Status',
        l.orderStatus == OrderStatusValue.expired ? 'Expired' : 'Cancelled'
      ],
      if (l.paymentMethod != null)
        ['Payment method', l.isCash ? 'Cash at shop' : 'UPI'],
      if (!refundInPlay)
        [
          l.isCash ? 'Cash collected' : 'Amount paid',
          '₹${collected.toStringAsFixed(0)}'
        ],
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(
          OrderSpace.m, OrderSpace.s, OrderSpace.m, 0),
      padding: const EdgeInsets.all(OrderSpace.m),
      decoration: BoxDecoration(
        color: OrderTone.muted.surface,
        borderRadius: BorderRadius.circular(OrderRadius.inner),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cancellation details',
              style: OrderType.title
                  .copyWith(color: AppColors.mainTextColor, fontSize: 15)),
          const SizedBox(height: OrderSpace.s),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(r[0],
                        style: OrderType.label
                            .copyWith(color: AppColors.grayText)),
                  ),
                  const SizedBox(width: OrderSpace.s),
                  Flexible(
                    child: Text(
                      r[1],
                      textAlign: TextAlign.right,
                      style: OrderType.label.copyWith(
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// `CHANGED_MY_MIND` → `Changed my mind`, `customer` → `Customer`. The
  /// service sends bare codes; nobody should read one.
  String _humaniseCode(String? code) {
    final c = (code ?? '').trim();
    if (c.isEmpty) return '';
    final words = c.replaceAll('_', ' ').toLowerCase().trim();
    if (words.isEmpty) return '';
    return words[0].toUpperCase() + words.substring(1);
  }

  /// "Doorstep delivery" / "Collect from the shop". Rendered only once the

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
