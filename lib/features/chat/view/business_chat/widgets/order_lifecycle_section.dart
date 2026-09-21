import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/auth/controller/order_broadcast_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_journey.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_card_ui.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_journey_strip.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_rating_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/widget/upi_qr_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_action_bar.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_broadcast_search_section.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_deadline_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// **The order card, as the BlueEra 2026 board draws it.**
///
/// This section owns the *whole* card body once an order is server-driven:
/// the `Order #0D1247` header, the step strip, the stage panel, the order
/// summary and the buttons. The card shells around it (`SelfPickupMsgCard`,
/// `ProductSelfPickupMsgCard`, `FoodSelfPickupMsgCard`) supply the data and
/// the bubble; they no longer draw a second header of their own, which is what
/// used to make the same order look different in three verticals.
///
/// Two rules survive from the previous build and are load-bearing:
///
/// * **The buttons are still the server's.** `availableActions` decides what
///   exists; the board decides only where it sits and what it is called. An
///   action a panel already draws a control for (`Upload Screenshot` inside
///   the payment panel, `Show Code` inside the pickup panel) is named in
///   [OrderActionBar.hiddenActions] rather than invented or duplicated.
/// * **The banner is server text.** It is rendered verbatim under the step
///   strip whenever it says something the panels do not already say. Building
///   a status string on the client is exactly how the app and the server drift.
///
/// It reads [OrderLifecycleController] first (authoritative — `/actions`,
/// action responses, and the `productOrderLifecycle` socket) and falls back to
/// the [fallbackLifecycle] the card parsed out of `metadata.lifecycle`, which
/// is why a card renders correctly with **no network call at all**.
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

  /// The customer tapped `Show Code` and we are fetching it.
  bool _revealingCode = false;

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

  // ═══════════════════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════════════════

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

      // Actions the panels below already draw a control for.
      final hidden = <String>{};
      final panels = _panels(lifecycle, state, isOwner, hidden);

      final children = <Widget>[
        _header(lifecycle, state, isOwner),
        const SizedBox(height: 12),
        ..._stepsZone(state, lifecycle, isOwner),
        ..._banner(lifecycle),
        for (final p in panels) ...[p, const SizedBox(height: 10)],
        if (offline) ...[_offlineStrip(), const SizedBox(height: 10)],
        ..._summary(lifecycle, state, isOwner),
      ];

      // ACTIONS — terminal orders still render whatever `availableActions`
      // contains: a cancelled order that owes a refund is not finished
      // business (guide §6.9).
      children.add(
        AnimatedOpacity(
          duration: OrderMotion.actionShift,
          opacity: offline ? 0.5 : 1,
          child: IgnorePointer(
            ignoring: offline,
            child: OrderActionBar(
              actions: actions,
              ctx: widget.ctx,
              hiddenActions: hidden,
              extraButtons: _localButtons(lifecycle, state, isOwner),
            ),
          ),
        ),
      );

      return Padding(
        padding: OrderUi.cardPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      );
    });
  }

  // ── Header ─────────────────────────────────────────────────────────────

  /// `Order #0D1247` with the status pill (customer) or the placed-at time
  /// (owner), and the `🛍 Self Pickup · 💵 Cash at Shop` identity row.
  ///
  /// The identity row appears only once the order has moved past `placed`:
  /// the board's opening card states the method inside the summary instead,
  /// where the customer is still able to take it in.
  Widget _header(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    final isDelivery = _isDelivery(state);
    final opening = l.orderStatus == OrderStatusValue.placed;
    final pill = _statusPill(l, state, isOwner);

    return OrderCardHeader(
      orderNo: 'Order #${_orderNumber(state)}',
      trailing: isOwner ? null : pill,
      trailingText: isOwner ? widget.ctx.placedAtLabel : null,
      subtitle:
          (!isOwner && opening) ? widget.ctx.placedAtLabel : null,
      meta: opening && !isOwner
          ? null
          : OrderMetaRow(
              isDelivery: isDelivery,
              isCash: l.isCash,
              deliveryLabelOverride:
                  isDelivery ? 'Order By Rider' : 'Self Pickup',
            ),
    );
  }

  String _orderNumber(OrderActionsModel? state) {
    final n = (widget.ctx.orderNumber ?? state?.orderNumber ?? '').trim();
    if (n.isNotEmpty) return n.replaceFirst(RegExp(r'^#'), '');
    final id = widget.ctx.orderId;
    // Last six characters of the id is what the shop and the customer can both
    // read out loud over a counter.
    return id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
  }

  bool _isDelivery(OrderActionsModel? state) =>
      state?.isRiderOrder ??
      (state?.deliveryType == OrderDeliveryTypeValue.rider);

  /// The board's pill. Every string here is a *label for a state the server
  /// already declared* — never a status this build decided.
  OrderStatusPill? _statusPill(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    switch (l.orderStatus) {
      case OrderStatusValue.placed:
        return const OrderStatusPill(
            label: 'Waiting for acceptance', icon: Icons.schedule);

      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        if (l.isUpi) {
          switch (l.paymentState) {
            case PaymentStateValue.pending:
              return const OrderStatusPill(
                  label: 'Payment Pending', icon: Icons.schedule);
            case PaymentStateValue.submitted:
            case PaymentStateValue.underReview:
            case PaymentStateValue.rejected:
              return const OrderStatusPill(
                  label: 'Payment Verification', icon: Icons.schedule);
            case PaymentStateValue.verified:
              // The board shows `Payment Valid` on the beat the shop approves
              // the screenshot, then `Preparing` once packing starts.
              if (l.orderStatus == OrderStatusValue.accepted) {
                return const OrderStatusPill(
                  label: 'Payment Valid',
                  tone: OrderPillTone.green,
                  icon: Icons.check_circle_outline,
                );
              }
              break;
            case PaymentStateValue.expired:
              return const OrderStatusPill(
                  label: 'Payment expired',
                  tone: OrderPillTone.danger,
                  icon: Icons.timer_off_outlined);
            default:
              break;
          }
        }
        return const OrderStatusPill(
            label: 'Preparing', icon: Icons.restaurant_menu);

      case OrderStatusValue.ready:
        return const OrderStatusPill(
          label: 'Ready for pickup',
          tone: OrderPillTone.green,
          icon: Icons.check_circle_outline,
        );

      case OrderStatusValue.dispatched:
        return OrderStatusPill(
          label: _isDelivery(state) ? 'Out for delivery' : 'Order Picked Up',
          tone: OrderPillTone.green,
          icon: Icons.check_circle_outline,
        );

      case OrderStatusValue.completed:
        return const OrderStatusPill(
          label: 'Completed',
          tone: OrderPillTone.green,
          icon: Icons.check_circle_outline,
        );

      case OrderStatusValue.cancelled:
        return const OrderStatusPill(
          label: 'Cancelled',
          tone: OrderPillTone.danger,
          icon: Icons.cancel_outlined,
        );

      case OrderStatusValue.expired:
        return const OrderStatusPill(
          label: 'Expired',
          tone: OrderPillTone.danger,
          icon: Icons.timer_off_outlined,
        );

      default:
        return null;
    }
  }

  // ── Steps ──────────────────────────────────────────────────────────────

  /// The step strip (board: the `● ─ ● ─ ○` row under the order number).
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
      OrderJourneyStrip(journey: journey),
      const SizedBox(height: 14),
    ];
  }

  // ── Banner + countdown ─────────────────────────────────────────────────

  /// The server's own status line, **always rendered when it is sent**.
  ///
  /// The panels below say what the *state* is; the banner is the only place
  /// the backend can say something the panels have no shape for — the 60-second
  /// sweep's nudges, an elapsed payment window, a prep that has run over, a
  /// rider search that found nobody (guide §8). Those arrive as banner text and
  /// nothing else, so suppressing it because a panel is on screen is how an
  /// order silently stops explaining itself.
  ///
  /// It sits under the step strip, above the panels: one line, secondary
  /// weight, so it reads as a caption on the strip rather than competing with
  /// the panel headline.
  List<Widget> _banner(OrderLifecycle l) {
    final banner = (l.banner ?? '').trim();
    final chip = _deadlineChip(l, widget.ctx.isOwner);
    if (banner.isEmpty && chip == null) return const [];

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner.isNotEmpty)
            Expanded(
              child: Text(banner,
                  style: OrderUi.blockBody.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: OrderUi.ink)),
            )
          else
            const Spacer(),
          if (chip != null) ...[
            const SizedBox(width: 8),
            chip,
          ],
        ],
      ),
      const SizedBox(height: 12),
    ];
  }

  /// Exactly one countdown per state, chosen by which clock the server has
  /// running. A terminal order shows none.
  Widget? _deadlineChip(OrderLifecycle l, bool isOwner) {
    if (l.isTerminal) return null;
    final d = l.deadlines;

    DateTime? target;
    String label;
    bool pulse = false;
    const overdue = 'over';

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
          // The ETA panel already states the ready time in words; a second
          // clock beside it counts the same minutes twice.
          return null;
        }
        break;
      case OrderStatusValue.ready:
        if (d.dispatchBy != null &&
            widget.ctx.orderId.isNotEmpty &&
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

  // ═══════════════════════════════════════════════════════════════════════
  //  Panels — one board screen each
  // ═══════════════════════════════════════════════════════════════════════

  /// Every stage panel the card should show right now, in board order.
  ///
  /// [hidden] collects the actions a panel has drawn its own control for, so
  /// the action bar below does not draw them a second time.
  List<Widget> _panels(
    OrderLifecycle l,
    OrderActionsModel? state,
    bool isOwner,
    Set<String> hidden,
  ) {
    final out = <Widget>[];

    // An admin is already looking at this order. Neutral on both cards, and
    // the internal reason code is never exposed (guide §9.3).
    if (l.needsAttention || (state?.needsAttention ?? false)) {
      out.add(const OrderHintStrip(
        text: "We're looking into this order.",
        tone: OrderBlockTone.neutral,
        icon: Icons.info_outline,
      ));
    }

    // The shop has been holding a ready order for hours. The card changes
    // SHAPE, not just text: a question, then the answers (guide §9.2).
    if (isOwner && l.needsPickupDecision && !l.isTerminal) {
      out.add(const OrderHintStrip(
        text: 'This order has been ready for a while. What happened?',
        tone: OrderBlockTone.amber,
        icon: Icons.help_outline,
        bordered: true,
      ));
    }

    if (l.isCancelledOrExpired) {
      out.addAll(_cancelledPanels(l, state));
      out.addAll(_refundPanels(l, state, isOwner));
      return out;
    }

    if (l.orderStatus == OrderStatusValue.completed) {
      out.add(OrderOutcomePanel(
        title: 'Order Completed!',
        body: isOwner
            ? 'Order #${_orderNumber(state)} has been completed successfully'
            : 'Your order has been completed successfully!',
      ));
      return out;
    }

    // ① The money conversation. It gates everything after it on a UPI order,
    //    so it is drawn first and alone.
    final payment = _paymentPanel(l, state, isOwner, hidden);
    if (payment != null) {
      out.add(payment);
      // While the shop's money is unresolved nothing else on the card is the
      // customer's business — the board draws the payment screen on its own.
      if (_paymentBlocksTheCard(l)) {
        out.addAll(_refundPanels(l, state, isOwner));
        return out;
      }
    }

    // ② Preparing — the ETA panel.
    final eta = _etaPanel(l);
    if (eta != null) out.add(eta);

    // ③ The rider leg.
    out.addAll(_riderPanels(l, state, isOwner));

    // ④ Collection.
    out.addAll(_collectionPanels(l, state, isOwner, hidden));

    out.addAll(_refundPanels(l, state, isOwner));
    return out;
  }

  /// A UPI order that has not cleared payment shows only the payment screen.
  bool _paymentBlocksTheCard(OrderLifecycle l) {
    if (!l.isUpi) return false;
    switch (l.paymentState) {
      case PaymentStateValue.pending:
      case PaymentStateValue.submitted:
      case PaymentStateValue.underReview:
      case PaymentStateValue.rejected:
      case PaymentStateValue.expired:
        return true;
      default:
        return false;
    }
  }

  // ── Preparing ──────────────────────────────────────────────────────────

  /// `Estimated ready time · Ready in: 15—20 min`, and the board's amber
  /// `(Delayed)` variant with `Your order is taking longer than the original
  /// estimate.`
  Widget? _etaPanel(OrderLifecycle l) {
    final status = l.orderStatus;
    if (status != OrderStatusValue.accepted &&
        status != OrderStatusValue.inProgress) {
      return null;
    }
    // A UPI order that has not been paid is not being prepared yet.
    if (l.isUpi && l.paymentState != PaymentStateValue.verified) return null;

    final readyBy = l.deadlines.readyBy;
    final delayed = l.prepDelayed ??
        (readyBy != null && readyBy.isBefore(DateTime.now()));

    final minutes = readyBy?.difference(DateTime.now()).inMinutes;

    // The board writes a range, because a shop's "fifteen minutes" is never
    // fifteen minutes. A single server figure is shown as a range around it
    // only when we have one; otherwise the panel simply says it is being made.
    String headline;
    if (delayed) {
      headline = minutes != null && minutes > 0
          ? '${_roundUp(minutes)} min'
          : 'Almost ready';
    } else if (minutes != null && minutes > 0) {
      final hi = _roundUp(minutes);
      final lo = hi <= 5 ? hi : hi - 5;
      headline = 'Ready in: $lo—$hi min';
    } else {
      headline = 'Ready soon';
    }

    return OrderInfoBlock(
      tone: delayed ? OrderBlockTone.amber : OrderBlockTone.blue,
      bordered: delayed,
      icon: delayed ? Icons.history_toggle_off : Icons.schedule,
      overline: delayed ? 'Updated ready time' : 'Estimated ready time',
      title: headline,
      body: delayed
          ? "We'll notify you as soon as your order is ready."
          : "This is an estimate. We'll notify you once your order is ready.",
      children: [
        if (delayed)
          const OrderHintStrip(
            text: 'Your order is taking longer than the original estimate.',
            tone: OrderBlockTone.amber,
            icon: Icons.hourglass_bottom,
          ),
      ],
    );
  }

  /// Ready times are an estimate; showing `13 min` implies a precision nobody
  /// has. The board's figures are all multiples of five.
  static int _roundUp(int minutes) => ((minutes + 4) ~/ 5) * 5;

  // ── Payment (UPI) ──────────────────────────────────────────────────────

  Widget? _paymentPanel(
    OrderLifecycle l,
    OrderActionsModel? state,
    bool isOwner,
    Set<String> hidden,
  ) {
    if (!l.isUpi) return null;
    final s = state?.paymentSummary;

    switch (l.paymentState) {
      case PaymentStateValue.pending:
        return isOwner
            ? const OrderInfoBlock(
                icon: Icons.hourglass_bottom,
                title: 'Waiting for the payment',
                body: 'The customer is paying on their UPI app. '
                    "You'll see their screenshot here to verify.",
              )
            : _customerPayPanel(l, s, hidden);

      case PaymentStateValue.submitted:
      case PaymentStateValue.underReview:
        return isOwner
            ? _ownerVerifyPanel(s, reshared: (s?.submissionCount ?? 1) > 1)
            : _customerSubmittedPanel(s, hidden);

      case PaymentStateValue.rejected:
        return isOwner ? _ownerRejectedPanel(s) : _customerRejectedPanel(s, hidden);

      case PaymentStateValue.verified:
        // The board gives this its own celebratory panel on the customer's
        // card the moment it clears, and then gets out of the way.
        if (!isOwner && l.orderStatus == OrderStatusValue.accepted) {
          return const OrderOutcomePanel(
            title: 'Payment Verified',
            body: 'Your UPI payment screenshot has been approved. '
                "We're now preparing your order.",
            bordered: true,
          );
        }
        return null;

      case PaymentStateValue.expired:
        return const OrderInfoBlock(
          tone: OrderBlockTone.danger,
          bordered: true,
          icon: Icons.timer_off_outlined,
          title: 'Payment window closed',
          body: 'The time to pay for this order has passed. '
              'Contact the shop if you still want it.',
        );

      default:
        return null;
    }
  }

  /// **Payment Required** — the board's QR screen.
  ///
  /// Two ways to pay side by side, because a customer on the *same* phone
  /// cannot scan their own screen: `Scan & Pay` for a second device, `Or Pay
  /// To ID` with a one-tap copy for this one.
  Widget _customerPayPanel(
      OrderLifecycle l, OrderPaymentSummary? s, Set<String> hidden) {
    final upi = (s?.upiId ?? '').trim();
    final amount = s?.amountDue ?? widget.ctx.orderTotal;
    hidden.add(OrderAction.submitPayment);

    return OrderInfoBlock(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OrderGlyph(icon: Icons.currency_rupee, color: OrderUi.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Required', style: OrderUi.blockTitle),
                  Text(OrderUiFormat.rupees(amount),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: OrderUi.ink)),
                  const SizedBox(height: 4),
                  const Text(
                    'Complete the payment and submit the payment details '
                    'for shop verification.',
                    style: OrderUi.blockBody,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const OrderStatusPill(
              label: 'UPI Payment',
              tone: OrderPillTone.blue,
              compact: true,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upi.isEmpty)
          const OrderHintStrip(
            text: 'The shop has not published a UPI ID yet. '
                'Ask them for it in this chat before paying.',
            tone: OrderBlockTone.amber,
            bordered: true,
          )
        else
          _payWays(upi, amount, s?.paymentQrId),
        const SizedBox(height: 10),
        _uploadRow(),
      ],
    );
  }

  /// The two payment cards, side by side on a wide card and stacked on a
  /// narrow one — a QR squeezed under 110dp stops being scannable.
  Widget _payWays(String upi, num? amount, String? qrId) {
    return LayoutBuilder(builder: (context, c) {
      final scan = _scanCard(upi, amount);
      final payTo = _payToIdCard(upi);
      if (c.maxWidth < 300) {
        return Column(children: [scan, const SizedBox(height: 10), payTo]);
      }
      // Top-aligned rather than equal-height: `IntrinsicHeight` cannot measure
      // the QR widget, which builds through a `LayoutBuilder` of its own, and
      // asking it to try throws during layout.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: scan),
          const SizedBox(width: 10),
          Expanded(flex: 5, child: payTo),
        ],
      );
    });
  }

  Widget _scanCard(String upi, num? amount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner,
                  size: 17, color: OrderUi.inkSoft),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan & Pay',
                        style: OrderUi.blockTitle.copyWith(fontSize: 14)),
                    const Text('Use any UPI app', style: OrderUi.faint),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: QrImageView(
              data: upiQrPayload(upi, amount: amount),
              version: QrVersions.auto,
              size: 108,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              gapless: true,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: OrderUi.blueFill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(OrderUiFormat.rupees(amount),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: OrderUi.ink)),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Scan this QR code to pay', style: OrderUi.faint),
          ),
        ],
      ),
    );
  }

  Widget _payToIdCard(String upi) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 17, color: OrderUi.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Or Pay To ID',
                        style: OrderUi.blockTitle.copyWith(fontSize: 14)),
                    const Text('open any UPI app and pay to this ID',
                        style: OrderUi.faint),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tap to copy, not long-press: a VPA typed by hand is a payment sent
          // to the wrong person, so copying has to be the easy thing.
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: upi));
              commonSnackBar(message: 'UPI ID copied');
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: OrderUi.block,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(upi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: OrderUi.inkSoft)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded,
                      size: 15, color: OrderUi.inkFaint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const OrderHintStrip(
            text: 'After paying, you may need to submit the transaction '
                'details for shop verification.',
          ),
        ],
      ),
    );
  }

  /// `Share UPI Payment Screenshot · [Upload Screenshot]`.
  Widget _uploadRow({
    String title = 'Share UPI Payment Screenshot',
    String body = 'Upload your payment screenshot after payment.',
    String button = 'Upload Screenshot',
    IconData icon = Icons.image_outlined,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: Row(
        children: [
          OrderGlyph(icon: icon, color: OrderUi.inkFaint, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OrderUi.blockTitle.copyWith(fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(body, style: OrderUi.blockBody.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _OutlineChipButton(
            label: button,
            icon: Icons.attach_file,
            onTap: () => _openPaymentSheet(),
          ),
        ],
      ),
    );
  }

  void _openPaymentSheet() {
    // The submit sheet is the action bar's flow; reuse it rather than keeping
    // a second uploader alive. Rendering the bar with the action hidden and
    // calling into it here keeps one code path for the actual POST.
    OrderActionBar(actions: const [], ctx: widget.ctx)
        .openPaymentSheet(context);
  }

  /// `Payment Details Submitted` + `Please wait`.
  Widget _customerSubmittedPanel(
      OrderPaymentSummary? s, Set<String> hidden) {
    hidden.add(OrderAction.submitPayment);
    final shot = (s?.screenshotUrl ?? '').trim();
    final at = _parseStamp(s?.submittedAt);

    return OrderInfoBlock(
      icon: Icons.check_circle_outline,
      title: 'Payment Details Submitted',
      body: 'Complete the payment and submit the payment details for '
          'shop verification.',
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(OrderUi.blockRadius),
            border: Border.all(color: OrderUi.blockBorder),
          ),
          child: Row(
            children: [
              _screenshotThumb(shot),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Screenshot Submitted',
                        style: OrderUi.blockTitle
                            .copyWith(fontSize: 13.5, color: OrderUi.green)),
                    if (at != null) ...[
                      const SizedBox(height: 2),
                      Text(OrderUiFormat.dayAndClock(at),
                          style: OrderUi.faint),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _OutlineChipButton(
                label: 'Change Screenshot',
                icon: Icons.edit_outlined,
                onTap: _openPaymentSheet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OrderInfoBlock(
          tone: OrderBlockTone.amber,
          bordered: true,
          icon: Icons.schedule,
          title: 'Please wait',
          body: "We'll notify you as soon as the shop verifies your payment.",
          padding: const EdgeInsets.all(12),
        ),
      ],
    );
  }

  /// `Payment Screenshot Not Verified` + `Re - Upload Screenshot`.
  Widget _customerRejectedPanel(
      OrderPaymentSummary? s, Set<String> hidden) {
    hidden.add(OrderAction.submitPayment);
    final reason = (s?.rejectionReason ?? '').trim();

    return OrderInfoBlock(
      tone: OrderBlockTone.danger,
      bordered: true,
      icon: Icons.error_outline,
      title: 'Payment Screenshot Not Verified',
      body: reason.isEmpty
          ? 'The screenshot could not be verified. '
              'Please upload a valid payment screenshot!'
          : 'The screenshot could not be verified: $reason',
      children: [
        _uploadRow(
          title: 'Please upload a valid payment screenshot to continue.',
          body: '',
          button: 'Re - Upload Screenshot',
          icon: Icons.add_photo_alternate_outlined,
        ),
      ],
    );
  }

  /// The shop's verification card — the whole safety model in one block.
  ///
  /// Screenshot (tap to zoom), UTR (tap to copy), and **amount paid vs amount
  /// due side by side**, amber when they differ. The point is that the shop
  /// checks their own bank app before tapping, so the comparison has to be
  /// effortless. A `submitted` payment is **never** labelled "Paid" — that one
  /// wording choice is what stops a shop handing over goods on a screenshot.
  Widget _ownerVerifyPanel(OrderPaymentSummary? s, {bool reshared = false}) {
    final mismatch = s?.hasMismatch ?? false;
    return OrderInfoBlock(
      icon: reshared ? Icons.autorenew : Icons.check_circle_outline,
      title: reshared
          ? 'Customer Re-shared Payment Screenshot'
          : 'Payment Screenshot Received',
      body: 'Verify the payment before preparing the product.',
      children: [
        _screenshotEvidence(s, mismatch: mismatch),
        const SizedBox(height: 10),
        OrderHintStrip(
          text: mismatch
              ? 'The amount does not match the order total. '
                  'Check your bank app before confirming.'
              : 'Verify the payment screenshot before preparing the product.',
          tone: OrderBlockTone.amber,
          bordered: true,
        ),
      ],
    );
  }

  /// `Payment Screenshot Rejected` — what the shop sees after it says no.
  Widget _ownerRejectedPanel(OrderPaymentSummary? s) {
    final reason = (s?.rejectionReason ?? '').trim();
    return OrderInfoBlock(
      tone: OrderBlockTone.danger,
      bordered: true,
      icon: Icons.cancel_outlined,
      title: 'Payment Screenshot Rejected',
      body: 'The screenshot the customer shared does not match the order '
          'payment. They have been asked to upload a valid one.',
      children: [
        _screenshotEvidence(s, mismatch: false),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: 10),
          OrderInfoBlock(
            tone: OrderBlockTone.danger,
            padding: const EdgeInsets.all(12),
            icon: Icons.image_not_supported_outlined,
            title: 'Rejected Screenshot',
            body: 'Reason: $reason',
          ),
        ],
      ],
    );
  }

  /// The screenshot itself plus the two figures that decide the question.
  Widget _screenshotEvidence(OrderPaymentSummary? s,
      {required bool mismatch}) {
    final shot = (s?.screenshotUrl ?? '').trim();
    final utr = (s?.utrNo ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
        border: Border.all(color: OrderUi.blockBorder),
      ),
      child: Column(
        children: [
          if (shot.isNotEmpty)
            GestureDetector(
              onTap: () => _zoom(shot),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  shot,
                  width: double.infinity,
                  height: 170,
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
            ),
          if (shot.isNotEmpty) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _amountCell('Paid', s?.amountPaid,
                    mismatch ? OrderUi.amber : OrderUi.ink),
              ),
              Container(
                  width: 1,
                  height: 30,
                  color: OrderUi.blockBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(child: _amountCell('Due', s?.amountDue, OrderUi.ink)),
            ],
          ),
          if (utr.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: utr));
                commonSnackBar(message: 'UTR copied');
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text('UTR $utr',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OrderUi.blockBody.copyWith(fontSize: 12)),
                  ),
                  const Icon(Icons.copy_rounded,
                      size: 14, color: OrderUi.inkFaint),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountCell(String label, num? value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: OrderUi.faint.copyWith(fontSize: 10.5)),
        Text(OrderUiFormat.rupees(value),
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _screenshotThumb(String url) {
    if (url.isEmpty) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
            color: OrderUi.block, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.image_outlined,
            size: 18, color: OrderUi.inkFaint),
      );
    }
    return GestureDetector(
      onTap: () => _zoom(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 46,
            height: 46,
            color: OrderUi.block,
            child: const Icon(Icons.broken_image_outlined,
                size: 16, color: OrderUi.inkFaint),
          ),
        ),
      ),
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

  // ── Collection (self-pickup) ───────────────────────────────────────────

  /// The board's collection sequence, which is **four** screens on the owner's
  /// side and two on the customer's:
  ///
  /// ```
  /// owner:     enter code → collect cash → both verified → complete
  /// customer:  how to collect → show code → collected
  /// ```
  ///
  /// The owner's cash step exists because a shop that hands the bag over first
  /// has no leverage left to collect with.
  List<Widget> _collectionPanels(
    OrderLifecycle l,
    OrderActionsModel? state,
    bool isOwner,
    Set<String> hidden,
  ) {
    final status = l.orderStatus;
    final ready = status == OrderStatusValue.ready;
    final handed = status == OrderStatusValue.dispatched;
    if (!ready && !handed) return const [];

    // A doorstep order is collected by the rider, with their own PIN.
    if (_isDelivery(state)) return const [];

    if (isOwner) return _ownerCollectionPanels(l, state, hidden);
    return _customerCollectionPanels(l, state, ready, hidden);
  }

  List<Widget> _ownerCollectionPanels(
      OrderLifecycle l, OrderActionsModel? state, Set<String> hidden) {
    final verified = l.isPickupVerified;
    final cashDone = !l.isCash || l.isCashCollected;

    // ① The code has not been matched yet — the board's `Verify Pickup Code`.
    if (!verified) {
      final canHandover =
          (state?.actionsFor(isOwner: true) ?? l.ownerActions)
              .contains(OrderAction.confirmHandover);
      if (!canHandover) return const [];
      hidden.add(OrderAction.confirmHandover);
      return [
        OrderCodeInput(
          busy: _controller.busyKeys
              .contains('${widget.ctx.orderId}:${OrderAction.confirmHandover}'),
          onSubmit: (code) => _handover(code),
        ),
      ];
    }

    // ② Code matched, money not in — `Collect ₹600 from Customer`.
    if (!cashDone) {
      final due = state?.paymentSummary?.amountDue ?? widget.ctx.orderTotal;
      return [
        OrderInfoBlock(
          tone: OrderBlockTone.amber,
          bordered: true,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const OrderGlyph(
                icon: Icons.payments_outlined, color: OrderUi.amber, size: 64),
            const SizedBox(height: 12),
            Text('Collect ${OrderUiFormat.rupees(due)} from Customer',
                textAlign: TextAlign.center,
                style: OrderUi.blockTitle.copyWith(fontSize: 17)),
            const SizedBox(height: 4),
            const Text('Receive the payment before handing over the order.',
                textAlign: TextAlign.center, style: OrderUi.blockBody),
            const SizedBox(height: 12),
            const OrderHintStrip(
              text: "After receiving the cash, then tap 'Payment Collected'",
              tone: OrderBlockTone.amber,
              bordered: true,
            ),
          ],
        ),
      ];
    }

    // ③ Both done — the two green receipts and `Complete Order`.
    return [
      const _VerifiedStrip(
        icon: Icons.verified_user_outlined,
        title: 'Pickup Verification',
        subtitle: 'Code Matched Successfully',
        pill: 'Pickup Verified',
      ),
      const SizedBox(height: 10),
      _VerifiedStrip(
        icon: l.isCash
            ? Icons.payments_outlined
            : Icons.account_balance_wallet_outlined,
        title: l.isCash ? 'Cash Payment' : 'UPI Payment',
        subtitle: l.isCash
            ? 'Cash Collected Successfully'
            : 'Payment Verified Successfully',
        pill: 'Payment Completed',
      ),
    ];
  }

  List<Widget> _customerCollectionPanels(
    OrderLifecycle l,
    OrderActionsModel? state,
    bool ready,
    Set<String> hidden,
  ) {
    // The order has left the counter.
    if (!ready) {
      return [
        const OrderInfoBlock(
          tone: OrderBlockTone.green,
          icon: Icons.verified_user_outlined,
          title: 'Pickup Verification Done',
          body: 'Your order was collected successfully.',
        ),
      ];
    }

    final out = <Widget>[];

    // The shop, so the customer knows where they are going.
    final shopName = (widget.ctx.shopName ?? widget.ctx.otherUserName ?? '').trim();
    if (shopName.isNotEmpty) {
      out.add(OrderPartyCard(
        name: shopName,
        photoUrl: widget.ctx.shopPhoto,
        address: widget.ctx.shopAddress,
        distance: widget.ctx.shopDistance,
        badge: 'Open Now',
        trailing: widget.ctx.onGetDirection == null
            ? null
            : IconButton(
                onPressed: widget.ctx.onGetDirection,
                icon: const Icon(Icons.map_outlined,
                    size: 20, color: OrderUi.blue),
              ),
      ));
      out.add(const SizedBox(height: 10));
    }

    final code = (state?.pickupCode ?? '').trim();
    hidden.add(OrderAction.viewPickupCode);

    if (code.isNotEmpty) {
      // `Pickup Verification` — the code, big, with the order it belongs to.
      out.add(OrderInfoBlock(
        icon: Icons.verified_user_outlined,
        title: 'Pickup Verification',
        body: 'Show this code to the shop to confirm your order.',
        children: [
          OrderCodeBoxes(code: code),
          const SizedBox(height: 10),
          Center(
            child: Text('Order #${_orderNumber(state)}',
                style: OrderUi.blockBody.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OrderUi.ink)),
          ),
          const SizedBox(height: 6),
          Center(
            child: OrderMetaRow(
                isDelivery: false, isCash: l.isCash),
          ),
          const SizedBox(height: 10),
          const OrderHintStrip(
            text: 'Only share this code with the shop when collecting '
                'your order.',
          ),
        ],
      ));
      return out;
    }

    // `When you arrive at the shop` — the numbered list and the resting code
    // panel. The cash list has five entries and includes "Pay the final amount
    // in cash"; the UPI list has four and must not, because that money is
    // already with the shop.
    out.add(OrderInfoBlock(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('When you arrive at the shop',
                      style: OrderUi.blockTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 10),
                  OrderStepsList(steps: [
                    'Go to the shop counter',
                    'Tell the shop your order',
                    'Show your pickup verification code',
                    if (l.isCash) 'Pay the final amount in cash',
                    'Collect your order',
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 4, child: _restingCodePanel()),
          ],
        ),
      ],
    ));
    return out;
  }

  /// The board's `Pickup code will be available when you arrive · Show Code`.
  Widget _restingCodePanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: OrderUi.blueFill,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_2, size: 26, color: OrderUi.ink),
          const SizedBox(height: 8),
          const Text('Pickup code will be available when you arrive.',
              textAlign: TextAlign.center, style: OrderUi.blockBody),
          const SizedBox(height: 10),
          if (_revealingCode)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: _revealCode,
              behavior: HitTestBehavior.opaque,
              child: const Text('Show Code',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: OrderUi.blue)),
            ),
        ],
      ),
    );
  }

  /// `GET /:id/pickup-code`. The code lands on the merged state and the panel
  /// above re-renders as the board's code screen — no navigation, because the
  /// customer is standing at a counter with one hand full.
  Future<void> _revealCode() async {
    if (_revealingCode) return;
    setState(() => _revealingCode = true);
    try {
      final res = await _controller.fetchPickupCode(widget.ctx.orderId,
          service: widget.ctx.service);
      if (!mounted) return;
      final code = res.model?.pickupCode ??
          res.raw?['pickupCode']?.toString() ??
          (res.raw?['data'] is Map
              ? (res.raw!['data'] as Map)['pickupCode']?.toString()
              : null);
      if (!res.ok || (code ?? '').isEmpty) {
        commonSnackBar(message: 'Pickup code is not ready yet.');
      }
    } finally {
      if (mounted) setState(() => _revealingCode = false);
    }
  }

  Future<void> _handover(String code) async {
    final res = await _controller.confirmHandover(widget.ctx.orderId,
        pickupCode: code, service: widget.ctx.service);
    if (res.ok) {
      widget.ctx.onChanged?.call(res.model);
    } else {
      commonSnackBar(message: res.message ?? 'That code did not match.');
    }
  }

  // ── Rider leg ──────────────────────────────────────────────────────────

  List<Widget> _riderPanels(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    if (!_isDelivery(state)) return const [];
    final out = <Widget>[];

    // `Finding Your Nearest Rider` — the search, with its own radar.
    if (!isOwner && state != null && state.isRiderOrder) {
      out.add(OrderBroadcastSearchSection(
        orderId: widget.ctx.orderId,
        onCollectMyself: () => commonSnackBar(
          message: 'Your order is packed at the shop — '
              'use "Show Code" when you get there.',
        ),
        onTryAgain: () => _broadcast.retry(
          orderId: widget.ctx.orderId,
          service: widget.ctx.service,
          businessId: widget.ctx.businessId ?? '',
          selfpickupType: widget.ctx.selfpickupType ?? 'product_selfpickup',
          orderFor: widget.ctx.orderFor,
          orderValue: widget.ctx.orderTotal,
        ),
      ));
    }

    // The delivery fee, settled with the **rider** at the door.
    final riderPay = _riderPaymentPanel(l, isOwner);
    if (riderPay != null) {
      if (out.isNotEmpty) out.add(const SizedBox(height: 10));
      out.add(riderPay);
    }
    return out;
  }

  /// This is a second payee, not a second instalment: the shop's QR was
  /// charged the product total only. The QR here is generated from the rider's
  /// VPA **with the amount written into the link**, so the figure is not the
  /// customer's to type — it is the fee they agreed to at checkout.
  Widget? _riderPaymentPanel(OrderLifecycle l, bool isOwner) {
    if (isOwner) return null;
    if (!l.riderPaymentDue) return null;
    final upi = (l.riderPaymentUpiId ?? '').trim();
    // Nothing to scan and nothing to copy: render nothing rather than an empty
    // frame that looks broken.
    if (upi.isEmpty) return null;

    final amount = l.riderPaymentAmount;
    final submitted = l.riderPaymentState == OrderRiderPaymentState.submitted;

    return OrderInfoBlock(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OrderGlyph(icon: Icons.currency_rupee, color: OrderUi.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Required', style: OrderUi.blockTitle),
                  Text(OrderUiFormat.rupees(amount),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: OrderUi.ink)),
                  const SizedBox(height: 4),
                  Text(
                    submitted
                        // Their claim is not the rider's confirmation. Same
                        // rule as the shop leg: submitted is never "paid".
                        ? 'Waiting for your delivery partner to confirm '
                            'the payment.'
                        : 'Please complete the payment to the delivery '
                            'partner before completing your order.',
                    style: OrderUi.blockBody,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const OrderStatusPill(
              label: 'UPI Payment',
              tone: OrderPillTone.blue,
              compact: true,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _payWays(upi, amount, null),
      ],
    );
  }

  // ── Cancellation ───────────────────────────────────────────────────────

  /// `Order Cancelled` plus the **Cancellation details** table.
  ///
  /// The money line is the point of the whole block. It is stated, never
  /// implied: *"₹0 collected"* is what stops a customer who cancelled before
  /// paying from wondering whether they are owed something.
  List<Widget> _cancelledPanels(OrderLifecycle l, OrderActionsModel? state) {
    final info = state?.cancellation;
    final by = (info?.cancelledBy ?? '').trim();
    final reason = (info?.comment?.trim().isNotEmpty ?? false)
        ? info!.comment!.trim()
        : _humaniseCode(info?.reasonCode ?? l.reasonCode);

    final num collected = l.isCash
        ? (l.isCashCollected ? (state?.paymentSummary?.amountDue ?? 0) : 0)
        : (state?.paymentSummary?.amountPaid ?? 0);

    // **One money line per card.** When a refund is in play the refund panel
    // is already saying who owes what; repeating the figure here would state
    // the same rupees twice, in two different tenses.
    final refundInPlay = l.refundDue ||
        l.paymentState == PaymentStateValue.refundPending ||
        l.paymentState == PaymentStateValue.refunded;

    final expired = l.orderStatus == OrderStatusValue.expired;

    return [
      OrderInfoBlock(
        tone: OrderBlockTone.danger,
        bordered: true,
        icon: Icons.cancel_outlined,
        title: expired ? 'Order Expired' : 'Order Cancelled',
        body: collected == 0 && !refundInPlay
            ? 'Your order was cancelled successfully.\n'
                'No payment was collected for this order.'
            : 'Your order was cancelled.',
      ),
      const SizedBox(height: 10),
      OrderInfoBlock(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 18, color: OrderUi.ink),
              const SizedBox(width: 8),
              Text('Cancellation details',
                  style: OrderUi.blockTitle.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: OrderUi.blockBorder),
            ),
            child: Column(
              children: [
                if (by.isNotEmpty)
                  OrderKeyValueRow(
                      label: 'Cancelled by', value: _humaniseCode(by)),
                if (reason.isNotEmpty)
                  OrderKeyValueRow(label: 'Reason', value: reason),
                OrderKeyValueRow(
                  label: 'Status',
                  value: expired ? 'Expired' : 'Cancelled',
                  valueColor: OrderUi.danger,
                ),
                if (l.paymentMethod != null)
                  OrderKeyValueRow(
                      label: 'Payment method',
                      value: l.isCash ? 'Cash at Shop' : 'UPI'),
                if (!refundInPlay)
                  OrderKeyValueRow(
                    label: l.isCash ? 'Cash collected' : 'Amount paid',
                    value: OrderUiFormat.rupees(collected),
                  ),
              ],
            ),
          ),
        ],
      ),
    ];
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

  // ── Refunds ────────────────────────────────────────────────────────────

  /// The wording that matters most in the whole app (guide §6.9).
  ///
  /// With direct UPI the customer paid the shop's own VPA. The platform never
  /// held a paisa of it, has no balance to reverse and no gateway to call.
  /// "Your refund is being processed" implies we are sending it — we are not,
  /// and we cannot — which manufactures a complaint against us for someone
  /// else's inaction.
  List<Widget> _refundPanels(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    final s = state?.paymentSummary;
    final amount = s?.amountPaid ?? l.refundAmount;
    final amountLabel =
        amount == null ? 'the money' : OrderUiFormat.rupees(amount);
    final sentAt = l.refundInitiatedAt ?? s?.refundInitiatedAt;
    final reference = l.refundReference ?? s?.refundReference;
    final owedBy = (l.refundOwedBy ?? s?.refundOwedBy ?? 'shop') == 'shop'
        ? 'the shop'
        : (l.refundOwedBy ?? 'the shop');

    if (l.paymentState == PaymentStateValue.refunded) {
      return [
        OrderInfoBlock(
          tone: OrderBlockTone.green,
          icon: Icons.check_circle_outline,
          title: isOwner ? 'Refund settled' : 'Refund received',
          body: isOwner
              ? 'The customer has confirmed they got the money back.'
              : 'You confirmed the money reached you.',
        ),
      ];
    }

    if (l.paymentState != PaymentStateValue.refundPending && !l.refundDue) {
      return const [];
    }

    // Step 2 — the shop has claimed it sent the money. That is a claim,
    // exactly like the customer's screenshot was, and only
    // CONFIRM_REFUND_RECEIVED ends it.
    if ((sentAt ?? '').isNotEmpty) {
      return [
        OrderInfoBlock(
          tone: OrderBlockTone.amber,
          bordered: true,
          icon: Icons.schedule_send,
          title: isOwner ? 'Refund sent' : 'Refund on its way',
          body: isOwner
              ? 'Waiting for the customer to confirm they received '
                  '$amountLabel.'
              : '$owedBy says they\'ve sent $amountLabel'
                  '${(reference ?? '').isNotEmpty ? ' (ref $reference)' : ''}. '
                  'Confirm when it reaches you.',
        ),
      ];
    }

    // Step 1 — nobody has sent anything yet.
    return [
      OrderInfoBlock(
        tone: OrderBlockTone.amber,
        bordered: true,
        icon: Icons.currency_rupee,
        title: isOwner ? 'Refund due' : 'Refund due to you',
        body: isOwner
            ? 'You need to return $amountLabel to the customer.'
            : '$amountLabel is to be returned by $owedBy. '
                "We've asked them to send it.",
      ),
    ];
  }

  // ── Order summary ──────────────────────────────────────────────────────

  /// The block that closes almost every card.
  ///
  /// Expanded — full item rows and the three method rows — only while the
  /// order is still `placed` and the customer may still change their mind
  /// about it. From `accepted` onwards the board compresses it to a thumbnail
  /// strip and a total, because by then the question is "where is it", not
  /// "what did I order".
  List<Widget> _summary(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    // The completed and cancelled boards still carry a summary; the payment
    // screens do not, except for the compact one under the QR.
    final items = widget.ctx.items;
    final total = state?.grandTotal ?? widget.ctx.orderTotal;
    final expanded = l.orderStatus == OrderStatusValue.placed;

    final strip = _paymentStrip(l, state, isOwner);

    return [
      OrderSummaryBlock(
        showReceiptIcon: expanded,
        totalAmount: OrderUiFormat.rupees(total),
        onViewDetails: expanded ? null : widget.ctx.onViewDetails,
        thumbnails: [
          for (final i in items)
            if ((i.imageUrl ?? '').trim().isNotEmpty) i.imageUrl!.trim(),
        ],
        paymentStrip: strip,
        expandedRows: !expanded
            ? null
            : [
                for (var i = 0; i < items.length && i < 3; i++)
                  OrderItemRow(
                      item: items[i],
                      showDivider: i < items.length - 1 && i < 2),
                // The card carries at most a few lines; the order may have
                // more. `totalItemCount` is the order's own figure, so the
                // "+N more" is the truth rather than a count of what happened
                // to fit in the chat payload.
                if (_hiddenItemCount(items.length) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${_hiddenItemCount(items.length)} more '
                      'item${_hiddenItemCount(items.length) == 1 ? '' : 's'}',
                      style: OrderUi.faint,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OrderUi.blockBorder),
                  ),
                  child: Column(
                    children: [
                      OrderKeyValueRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Total Amount',
                        value: OrderUiFormat.rupees(total),
                        emphasise: true,
                      ),
                      const Divider(height: 1, color: OrderUi.blockBorder),
                      OrderKeyValueRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Pickup Method',
                        value: _isDelivery(state) ? 'Rider' : 'Self Pickup',
                      ),
                      const Divider(height: 1, color: OrderUi.blockBorder),
                      OrderKeyValueRow(
                        icon: Icons.payments_outlined,
                        label: 'Payment Method',
                        value: l.isCash ? 'Cash at shop' : 'UPI Payment',
                      ),
                    ],
                  ),
                ),
              ],
      ),
    ];
  }

  /// How many lines the board's three-row list is not showing.
  int _hiddenItemCount(int shown) {
    final total = widget.ctx.totalItemCount ?? shown;
    return (total > shown ? total : shown) - 3;
  }

  /// The payment line inside the summary. Amber while money is owed, green
  /// once it is in — and never green on a `submitted` screenshot.
  Widget? _paymentStrip(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    if (l.orderStatus == OrderStatusValue.placed) return null;

    final due = state?.paymentSummary?.amountDue ?? widget.ctx.orderTotal;
    final settled = l.orderStatus == OrderStatusValue.completed ||
        (l.isCash && l.isCashCollected) ||
        (!l.isCash && l.paymentState == PaymentStateValue.verified);

    if (l.isCash) {
      if (settled) {
        return const OrderPaymentStrip(
          icon: Icons.payments_outlined,
          title: 'Cash Payment',
          subtitle: 'Paid at Shop',
          statusLabel: 'Payment Completed',
          tone: OrderPillTone.green,
        );
      }
      if (l.orderStatus == OrderStatusValue.ready) {
        return OrderPaymentStrip(
          icon: Icons.payments_outlined,
          title: 'Cash payment at pickup',
          subtitle: 'Pay at the shop when you collect your order. '
              'No online payment has been made.',
          statusLabel: isOwner ? 'To Collect' : 'Pending at Shop',
          tone: OrderPillTone.amber,
        );
      }
      return OrderPaymentStrip(
        icon: Icons.payments_outlined,
        title: 'Cash at Shop',
        subtitle: 'Pay ${OrderUiFormat.rupees(due)} when you collect your '
            'order. No online payment is required.',
        statusLabel: 'Not Paid Yet',
        tone: OrderPillTone.amber,
      );
    }

    if (settled) {
      return const OrderPaymentStrip(
        icon: Icons.account_balance_wallet_outlined,
        title: 'UPI Payment',
        subtitle: 'Paid online and verified by the shop',
        statusLabel: 'Payment Completed',
        tone: OrderPillTone.green,
      );
    }
    return null;
  }

  // ── Local buttons ──────────────────────────────────────────────────────

  /// The board's buttons that are **navigation, not transitions**.
  ///
  /// `Get Direction`, `Rate your experience`, `Shop Again`, `Continue
  /// Shopping` change nothing on the server, so they can never appear in
  /// `availableActions` — and inventing action keys for them would blur the
  /// line that keeps every real button server-driven. They are rendered here,
  /// beside the server's, and each one is dropped when the card has nowhere
  /// for it to go.
  List<Widget> _localButtons(
      OrderLifecycle l, OrderActionsModel? state, bool isOwner) {
    if (isOwner) return const [];
    final out = <Widget>[];

    switch (l.orderStatus) {
      case OrderStatusValue.ready:
        if (!_isDelivery(state) && widget.ctx.onGetDirection != null) {
          out.add(OrderButton(
            label: 'Get Direction',
            icon: Icons.navigation_outlined,
            onTap: widget.ctx.onGetDirection,
          ));
        }
        break;

      case OrderStatusValue.dispatched:
        // The card can always rate the shop it is attached to — the business
        // id is on the context and the rating endpoint is the business's own,
        // so this needs no host wiring. `onRate` only overrides where it goes.
        final rate = widget.ctx.onRate ?? _openRatingSheet;
        if (widget.ctx.onRate != null || _canRate) {
          out.add(OrderButton(
            label: 'Rate your experience',
            icon: Icons.star_border_rounded,
            style: OrderButtonStyle.secondary,
            onTap: rate,
          ));
        }
        if (widget.ctx.onViewDetails != null) {
          out.add(OrderButton(
            label: 'View Details',
            icon: Icons.receipt_long_outlined,
            onTap: widget.ctx.onViewDetails,
          ));
        }
        break;

      case OrderStatusValue.completed:
        if (widget.ctx.onViewDetails != null) {
          out.add(OrderButton(
            label: 'View Details',
            icon: Icons.receipt_long_outlined,
            style: OrderButtonStyle.secondary,
            onTap: widget.ctx.onViewDetails,
          ));
        } else if (widget.ctx.onRate != null || _canRate) {
          out.add(OrderButton(
            label: 'Rate your experience',
            icon: Icons.star_border_rounded,
            style: OrderButtonStyle.secondary,
            onTap: widget.ctx.onRate ?? _openRatingSheet,
          ));
        }
        if (widget.ctx.onShopAgain != null) {
          out.add(OrderButton(
            label: 'Shop Again',
            icon: Icons.shopping_cart_outlined,
            onTap: widget.ctx.onShopAgain,
          ));
        }
        break;

      case OrderStatusValue.cancelled:
      case OrderStatusValue.expired:
        if (widget.ctx.onShopAgain != null) {
          out.add(OrderButton(
            label: 'Continue Shopping',
            icon: Icons.shopping_cart_outlined,
            onTap: widget.ctx.onShopAgain,
          ));
        }
        break;

      default:
        break;
    }
    return out;
  }

  /// Whether there is a shop to rate. No business id, no button — better a
  /// missing control than one that opens a sheet it cannot submit.
  bool get _canRate => (widget.ctx.businessId ?? '').trim().isNotEmpty;

  void _openRatingSheet() {
    showOrderRatingSheet(
      context,
      businessId: widget.ctx.businessId ?? '',
      shopName: widget.ctx.shopName ?? widget.ctx.otherUserName,
    );
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

  // ── Offline ────────────────────────────────────────────────────────────

  /// The card renders from `metadata.lifecycle`, which is already local, so the
  /// user still sees the last known state — the buttons simply stop working and
  /// one strip says why (guide §10.3).
  Widget _offlineStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OrderUi.block,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 15, color: OrderUi.inkFaint),
          const SizedBox(width: 8),
          const Expanded(
            child: Text("You're offline — showing the last known status.",
                style: OrderUi.blockBody),
          ),
          // Retrying is always safe: every action is a server-side
          // compare-and-set, so a retry after an unknown outcome cannot
          // double-apply.
          GestureDetector(
            onTap: () => _controller.refreshActions(widget.ctx.orderId,
                service: widget.ctx.service),
            behavior: HitTestBehavior.opaque,
            child: const Text('Retry', style: OrderUi.link),
          ),
        ],
      ),
    );
  }

  static DateTime? _parseStamp(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }
}

/// A green `Pickup Verification · Pickup Verified` receipt row.
class _VerifiedStrip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String pill;

  const _VerifiedStrip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OrderUi.greenSoftFill,
        borderRadius: BorderRadius.circular(OrderUi.blockRadius),
      ),
      child: Row(
        children: [
          OrderGlyph(icon: icon, color: OrderUi.green, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: OrderUi.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: OrderUi.blockBody.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OrderStatusPill(
            label: pill,
            tone: OrderPillTone.green,
            compact: true,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

/// The small outlined pill button the board draws inside panels —
/// `Upload Screenshot`, `Change Screenshot`, `Re - Upload Screenshot`.
class _OutlineChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OrderUi.blue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: OrderUi.blue),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: OrderUi.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
