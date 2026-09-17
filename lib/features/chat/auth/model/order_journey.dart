import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:get/get.dart';

/// The **step tracker on an order chat card** — the horizontal
/// `● ─ ● ─ ○ ─ ○` strip every screen in the three order PDFs carries directly
/// under the order number.
///
/// ## Why this is derived and not server copy
///
/// `OrderStepper` (order_track/widgets/order_stepper.dart) renders the
/// **server's** `stages[]` from `GET /:id/track` verbatim, and that stays the
/// rule wherever stages exist: a stage list the server sends wins, because a
/// fourth step must be able to ship without an app release.
///
/// The card is the one surface that has no stages. It renders from
/// `metadata.lifecycle`, which carries `orderStatus` / `paymentState` and no
/// step list at all, and it has to draw correctly **with no network call** —
/// that is the whole point of the card (see `OrderLifecycleSection`). So the
/// strip on the card is derived here, from the same lifecycle the card already
/// has, and [OrderJourney.fromStages] lets a server stage list replace it the
/// moment one is available.
///
/// ## The six variants
///
/// The PDFs do not show one stepper. They show **six**, because the steps a
/// person needs to see depend on who they are and how the order is paid and
/// collected:
///
/// | Viewer | Receive | Pay | Steps |
/// |---|---|---|---|
/// | customer | pickup | cash | placed · accepted · preparing · ready · picked up · completed |
/// | customer | pickup | UPI | + payment, after accepted |
/// | customer | delivery | UPI | + delivery + rider payment, after picked up |
/// | owner | pickup | cash | placed · accepted · preparing · ready · **cash collection** · picked up · completed |
/// | owner | pickup | UPI | placed · accepted · payment · preparing · ready · picked up · completed |
/// | owner | delivery | UPI | + **rider dispatch**, between payment and preparing |
///
/// Two of those columns are the load-bearing ones:
///
/// * The owner's cash flow has a **cash-collection step of its own**, between
///   "ready" and "picked up". The shop verifies the code, *then* takes the
///   money, and the PDF gives that its own node because a shop that hands the
///   bag over first has no leverage left to collect with.
/// * The owner's delivery flow puts **rider dispatch before preparing**, so
///   the rider is riding to the shop while the shop packs instead of after.
///   That ordering is a promise to the customer about total time, and it is
///   why [OrderActionsModel.needsRiderDispatch] fires on a verified payment
///   rather than on `ready`.
///
/// Everything here is a pure function of a snapshot. No `DateTime.now()`
/// except through [OrderJourneySnapshot.now], no widgets, no controllers — so
/// every row of every table above is a unit test.
enum OrderJourneyPhase {
  /// The order exists. "Order Placed" / "Order Received".
  placed,

  /// The shop has been asked. "Waiting for shop acceptance" → "Shop Accepted".
  accepted,

  /// UPI only: the money conversation, from QR to verified.
  payment,

  /// Owner + delivery only: the rider race. "Finding Your Rider" → "Your
  /// Rider Found".
  dispatch,

  /// Packing. "Preparing order" (customer sees "(Delayed)" when it runs over).
  preparing,

  /// "Ready for pickup" — and, for the owner, the code-verification step.
  ready,

  /// Owner + cash only: "Payment Confirmation" — collect the cash.
  cashCollection,

  /// The goods left the shop. "Picked up".
  pickedUp,

  /// Delivery only: rider in transit to the customer.
  delivery,

  /// Delivery only: the customer settles the delivery fee with the rider.
  riderPayment,

  /// "Completed".
  completed,
}

/// How one node draws.
enum OrderJourneyStepState {
  /// Green, ticked.
  done,

  /// Orange ring — the step someone is acting on right now. A journey may
  /// legitimately have **none**: a customer whose order is `ready` has nothing
  /// to do in the app, and the PDF's ready screen shows no orange node.
  current,

  /// Grey, hollow.
  pending,

  /// Red. Replaces the node the order died on; later nodes stay grey, because
  /// they never happened.
  cancelled,
}

class OrderJourneyStep {
  final OrderJourneyPhase phase;

  /// Stable key for tests and for matching a server stage.
  final String key;

  /// Already localised, ready to render.
  final String label;
  final OrderJourneyStepState state;

  const OrderJourneyStep({
    required this.phase,
    required this.key,
    required this.label,
    required this.state,
  });

  bool get isDone => state == OrderJourneyStepState.done;
  bool get isCurrent => state == OrderJourneyStepState.current;
  bool get isCancelled => state == OrderJourneyStepState.cancelled;

  @override
  String toString() => '$key:${state.name}("$label")';
}

/// Everything the strip needs, and nothing it does not.
///
/// Built from a lifecycle by [OrderJourney.resolve]; constructed directly in
/// tests. `now` is injected so an overdue prep ETA is testable without
/// waiting.
class OrderJourneySnapshot {
  final bool isOwner;
  final bool isDelivery;
  final bool isUpi;

  /// `lifecycle.orderStatus`. An unrecognised value resolves to no journey
  /// rather than a wrong one — see [OrderJourney.resolve].
  final String? orderStatus;

  /// `lifecycle.paymentState` — the **shop** leg. Never the rider leg.
  final String? paymentState;

  /// A rider is attached to this order (`rideOrderId`, or a rider leg that has
  /// a status). Drives "Finding Your Rider" → "Your Rider Found".
  final bool riderAssigned;

  /// The shop has matched the 4-digit code. For the owner this is what turns
  /// "Ready for pickup" from the current step into a completed one.
  final bool pickupVerified;

  /// Cash in hand (owner + cash). Only meaningful once [pickupVerified].
  final bool cashCollected;

  /// The rider-fee leg: `pending` → `verified`/`paid`. Null on pickup orders.
  final String? riderPaymentState;

  /// The shop said it would be ready by this time. Past + still preparing is
  /// what the PDF calls "Preparing (Delayed)".
  final DateTime? readyBy;

  /// The server said so outright. Wins over [readyBy] arithmetic.
  final bool? prepDelayed;

  final DateTime now;

  OrderJourneySnapshot({
    required this.isOwner,
    this.isDelivery = false,
    this.isUpi = false,
    this.orderStatus,
    this.paymentState,
    this.riderAssigned = false,
    this.pickupVerified = false,
    this.cashCollected = false,
    this.riderPaymentState,
    this.readyBy,
    this.prepDelayed,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  /// The snapshot for a live card.
  ///
  /// Reads the merged three-plane state the controller keeps ([state]) and
  /// falls back to the lifecycle the card itself parsed out of
  /// `metadata.lifecycle`, so a card with no network call still draws a strip.
  ///
  /// The direction of this dependency is deliberate: the journey knows about
  /// the lifecycle model, never the other way round. The model is plain Dart
  /// with no imports at all, and it stays that way.
  /// [isDeliveryHint] comes from the card's own `metadata.order.deliveryType`
  /// and is used **only** while the server has not said. `deliveryType` is
  /// null on a card that has never been to `/actions` or `/track`, and null is
  /// not "self-pickup" — reading it as one is what used to draw a doorstep
  /// order with a pickup strip.
  factory OrderJourneySnapshot.fromState({
    required bool isOwner,
    OrderActionsModel? state,
    OrderLifecycle? fallbackLifecycle,
    bool? isDeliveryHint,
    DateTime? now,
  }) {
    final l = state?.lifecycle ?? fallbackLifecycle;
    final serverType = state?.deliveryType;
    final isDelivery = serverType != null
        ? serverType == OrderDeliveryTypeValue.rider
        : (isDeliveryHint ?? false);
    return OrderJourneySnapshot(
      isOwner: isOwner,
      isDelivery: isDelivery,
      isUpi: l?.isUpi ?? false,
      orderStatus: l?.orderStatus,
      paymentState: l?.paymentState ?? state?.paymentSummary?.state,
      // A ride id is the unambiguous "a rider owns this leg" signal.
      riderAssigned: (state?.rideOrderId ?? '').isNotEmpty,
      pickupVerified: l?.isPickupVerified ?? false,
      cashCollected: l?.isCashCollected ?? false,
      riderPaymentState: l?.riderPaymentState,
      readyBy: l?.deadlines.readyBy,
      prepDelayed: l?.prepDelayed,
      now: now,
    );
  }

  bool get isPaymentVerified => paymentState == PaymentStateValue.verified;
  bool get isPaymentRejected => paymentState == PaymentStateValue.rejected;
  bool get isPaymentSubmitted =>
      paymentState == PaymentStateValue.submitted ||
      paymentState == PaymentStateValue.underReview;

  /// The rider has been paid (or there was never anything to pay).
  bool get isRiderPaid =>
      riderPaymentState == PaymentStateValue.verified ||
      riderPaymentState == OrderRiderPaymentState.paid;

  /// Cash is "collected" the moment the goods move on a cash order — a shop
  /// that marked the order picked up without taking the money has a problem
  /// the stepper cannot fix, and showing the cash node as unfinished forever
  /// would only hide the rest of the journey.
  bool get cashSettled => cashCollected || _atOrPast(OrderStatusValue.pickedUp);

  bool get isDelayed {
    if (prepDelayed != null) return prepDelayed!;
    final by = readyBy;
    if (by == null) return false;
    return now.isAfter(by);
  }

  bool _atOrPast(String status) {
    final here = OrderJourney._rank(orderStatus);
    final there = OrderJourney._rank(status);
    if (here == null || there == null) return false;
    return here >= there;
  }
}

/// The resolved strip.
class OrderJourney {
  final List<OrderJourneyStep> steps;

  const OrderJourney(this.steps);

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;

  /// The node someone is acting on, or null when nobody is (see
  /// [OrderJourneyStepState.current]).
  OrderJourneyStep? get currentStep {
    for (final s in steps) {
      if (s.isCurrent) return s;
    }
    return null;
  }

  int get doneCount => steps.where((s) => s.isDone).length;

  /// Derives the strip from a lifecycle snapshot.
  ///
  /// Returns null — and the card draws no strip at all — when the status is
  /// absent or is a value this build has never heard of. A strip that puts an
  /// unknown status in the wrong place is worse than no strip: it tells the
  /// customer their order is somewhere it is not.
  static OrderJourney? resolve(OrderJourneySnapshot s) {
    final status = s.orderStatus;
    if (status == null || status.isEmpty) return null;
    if (_rank(status) == null && !_isTerminalFailure(status)) return null;

    final phases = _phasesFor(s);

    // How far the order has actually got, as an index into `phases`, plus
    // which phase (if any) somebody is acting on right now.
    final progress = _progress(s, phases);

    final failed = _isTerminalFailure(status);
    final steps = <OrderJourneyStep>[];
    for (var i = 0; i < phases.length; i++) {
      final phase = phases[i];
      final isDone = i <= progress.lastDoneIndex;
      final isCurrent = !failed && phase == progress.currentPhase;

      OrderJourneyStepState state;
      if (failed && i == progress.lastDoneIndex + 1) {
        // The node the order died on. The PDF turns exactly one node red and
        // leaves the rest grey — a cancelled order did not "complete" the
        // steps after it, and greying them is how the card says so.
        state = OrderJourneyStepState.cancelled;
      } else if (isDone) {
        state = OrderJourneyStepState.done;
      } else if (isCurrent) {
        state = OrderJourneyStepState.current;
      } else {
        state = OrderJourneyStepState.pending;
      }

      steps.add(OrderJourneyStep(
        phase: phase,
        key: _keyFor(phase),
        label: state == OrderJourneyStepState.cancelled
            ? (status == OrderStatusValue.expired
                ? AppStrings.orderStatusExpired.tr
                : AppStrings.orderStatusCancelled.tr)
            : _labelFor(phase, s, isDone: isDone, isCurrent: isCurrent),
        state: state,
      ));
    }

    return OrderJourney(steps);
  }

  /// A server-sent stage list, rendered as-is.
  ///
  /// Labels are the server's copy, order is the server's order, and a key this
  /// build does not recognise still draws — the same three rules
  /// [OrderStepper] follows, so the two surfaces can never disagree about an
  /// order they are both looking at.
  static OrderJourney? fromStages(
    List<OrderJourneyStageInput> stages, {
    bool failed = false,
    String? failedLabel,
  }) {
    if (stages.isEmpty) return null;
    final lastDone =
        stages.lastIndexWhere((st) => st.done); // -1 when nothing is done
    final steps = <OrderJourneyStep>[];
    for (var i = 0; i < stages.length; i++) {
      final st = stages[i];
      OrderJourneyStepState state;
      if (failed && i == lastDone + 1) {
        state = OrderJourneyStepState.cancelled;
      } else if (st.done) {
        state = OrderJourneyStepState.done;
      } else if (!failed && st.current) {
        state = OrderJourneyStepState.current;
      } else {
        state = OrderJourneyStepState.pending;
      }
      steps.add(OrderJourneyStep(
        phase: OrderJourneyPhase.placed, // not meaningful for a server stage
        key: st.key,
        label: state == OrderJourneyStepState.cancelled
            ? (failedLabel ?? AppStrings.orderStatusCancelled.tr)
            : st.label,
        state: state,
      ));
    }
    return OrderJourney(steps);
  }

  // ───────────────────────────────────────────────────────────────────
  //  Which steps this viewer, on this order, should see
  // ───────────────────────────────────────────────────────────────────

  static List<OrderJourneyPhase> _phasesFor(OrderJourneySnapshot s) {
    final p = <OrderJourneyPhase>[
      OrderJourneyPhase.placed,
      OrderJourneyPhase.accepted,
    ];

    // Cash never shows a payment node before pickup: there is nothing to
    // watch. The money appears at the counter, which on the owner's side is
    // the `cashCollection` node further down.
    if (s.isUpi) p.add(OrderJourneyPhase.payment);

    // The rider race is the **shop's** job to watch, not the customer's: the
    // customer is told "preparing" throughout (PDF, customer delivery strip),
    // because a rider hunt they cannot influence is not progress they can use.
    if (s.isOwner && s.isDelivery) p.add(OrderJourneyPhase.dispatch);

    p.addAll([OrderJourneyPhase.preparing, OrderJourneyPhase.ready]);

    if (s.isOwner && !s.isUpi) p.add(OrderJourneyPhase.cashCollection);

    p.add(OrderJourneyPhase.pickedUp);

    if (s.isDelivery && !s.isOwner) {
      // The customer's tail: the rider's journey to them, then the fee they
      // settle with the rider directly.
      p.addAll([OrderJourneyPhase.delivery, OrderJourneyPhase.riderPayment]);
    }

    p.add(OrderJourneyPhase.completed);
    return p;
  }

  // ───────────────────────────────────────────────────────────────────
  //  How far it has got
  // ───────────────────────────────────────────────────────────────────

  static _Progress _progress(
      OrderJourneySnapshot s, List<OrderJourneyPhase> phases) {
    final status = s.orderStatus;

    OrderJourneyPhase? current;
    OrderJourneyPhase lastDone = OrderJourneyPhase.placed;

    switch (status) {
      case OrderStatusValue.placed:
        // Placed is done the moment it exists; the shop is the one who has to
        // move, so `accepted` is the live node for both parties.
        lastDone = OrderJourneyPhase.placed;
        current = OrderJourneyPhase.accepted;
        break;

      case OrderStatusValue.accepted:
      case OrderStatusValue.inProgress:
        lastDone = OrderJourneyPhase.accepted;
        if (s.isUpi && !s.isPaymentVerified) {
          // Nothing is packed until the money is real. This is the state the
          // rejected screenshot also sits in — the node reads "rejected" and
          // stays current, because it is still the thing to fix.
          current = OrderJourneyPhase.payment;
        } else {
          if (s.isUpi) lastDone = OrderJourneyPhase.payment;
          if (s.isOwner && s.isDelivery && !s.riderAssigned) {
            // Dispatch runs while the shop packs, so the shop watches the
            // hunt before it is told to prepare.
            current = OrderJourneyPhase.dispatch;
          } else {
            if (s.isOwner && s.isDelivery) {
              lastDone = OrderJourneyPhase.dispatch;
            }
            current = OrderJourneyPhase.preparing;
          }
        }
        break;

      case OrderStatusValue.ready:
        lastDone = OrderJourneyPhase.preparing;
        if (s.isOwner) {
          if (!s.pickupVerified) {
            // The shop's live step: type the code the customer (or rider)
            // reads out.
            current = OrderJourneyPhase.ready;
          } else if (!s.isUpi && !s.cashSettled) {
            lastDone = OrderJourneyPhase.ready;
            current = OrderJourneyPhase.cashCollection;
          } else {
            lastDone = s.isUpi
                ? OrderJourneyPhase.ready
                : OrderJourneyPhase.cashCollection;
            current = OrderJourneyPhase.pickedUp;
          }
        } else {
          // The customer has nothing left to tap — they have to walk to the
          // shop. No current node, by design.
          lastDone = OrderJourneyPhase.ready;
        }
        break;

      case OrderStatusValue.pickedUp:
        lastDone = s.isOwner && !s.isUpi
            ? OrderJourneyPhase.cashCollection
            : OrderJourneyPhase.ready;
        if (s.isOwner) {
          // The shop still has to close the order (or the sweeper closes it
          // for them), so "Picked up" is their live node.
          current = OrderJourneyPhase.pickedUp;
        } else if (s.isDelivery) {
          lastDone = OrderJourneyPhase.pickedUp;
          current = OrderJourneyPhase.delivery;
        } else {
          lastDone = OrderJourneyPhase.pickedUp;
        }
        break;

      case OrderStatusValue.dispatched:
        // Out for delivery. The shop's part is finished; the customer is
        // waiting at the door.
        lastDone = OrderJourneyPhase.pickedUp;
        current = s.isOwner ? null : OrderJourneyPhase.delivery;
        break;

      case OrderStatusValue.delivered:
        lastDone = OrderJourneyPhase.delivery;
        if (!s.isOwner) {
          if (s.isRiderPaid) {
            lastDone = OrderJourneyPhase.riderPayment;
            current = OrderJourneyPhase.completed;
          } else {
            // The last thing standing between a delivered order and a closed
            // one: the delivery fee, settled with the rider.
            current = OrderJourneyPhase.riderPayment;
          }
        }
        break;

      case OrderStatusValue.completed:
        lastDone = phases.last;
        break;

      default:
        // Cancelled / expired. Everything the order genuinely finished stays
        // green; `resolve` paints the next node red.
        lastDone = _lastDoneBeforeFailure(s);
        break;
    }

    // Clamp to the phases this viewer actually sees — an owner has no
    // `delivery` node, and a cash order has no `payment` node, so a lastDone
    // that names one has to fall back to the nearest node in front of it.
    return _Progress(
      lastDoneIndex: _indexAtOrBefore(phases, lastDone),
      currentPhase:
          current != null && phases.contains(current) ? current : null,
    );
  }

  /// Where a cancelled or expired order stopped.
  ///
  /// Read from the state it still carries rather than from the status, which
  /// only says "dead": a cancellation at `placed` and one during packing are
  /// different stories, and the PDF's cancelled card puts the red node in a
  /// different place for each.
  static OrderJourneyPhase _lastDoneBeforeFailure(OrderJourneySnapshot s) {
    if (s.pickupVerified) return OrderJourneyPhase.ready;
    if (s.isUpi && s.isPaymentVerified) return OrderJourneyPhase.payment;
    if (s.isUpi && (s.isPaymentSubmitted || s.isPaymentRejected)) {
      return OrderJourneyPhase.accepted;
    }
    if (s.riderAssigned) return OrderJourneyPhase.dispatch;
    // A cancellation while the shop was still deciding is the common one, and
    // it leaves exactly one node green.
    return OrderJourneyPhase.placed;
  }

  static int _indexAtOrBefore(
      List<OrderJourneyPhase> phases, OrderJourneyPhase target) {
    final exact = phases.indexOf(target);
    if (exact >= 0) return exact;
    // Not a phase this viewer sees: walk back through the canonical order
    // until we hit one they do.
    final order = _canonicalOrder;
    var i = order.indexOf(target);
    while (i > 0) {
      i -= 1;
      final idx = phases.indexOf(order[i]);
      if (idx >= 0) return idx;
    }
    return 0;
  }

  static const List<OrderJourneyPhase> _canonicalOrder = [
    OrderJourneyPhase.placed,
    OrderJourneyPhase.accepted,
    OrderJourneyPhase.payment,
    OrderJourneyPhase.dispatch,
    OrderJourneyPhase.preparing,
    OrderJourneyPhase.ready,
    OrderJourneyPhase.cashCollection,
    OrderJourneyPhase.pickedUp,
    OrderJourneyPhase.delivery,
    OrderJourneyPhase.riderPayment,
    OrderJourneyPhase.completed,
  ];

  /// Order-of-progress rank for a status, used for "are we at or past X".
  /// Terminal failures have no rank — they are not a position on the line.
  static int? _rank(String? status) {
    switch (status) {
      case OrderStatusValue.placed:
        return 0;
      case OrderStatusValue.accepted:
        return 1;
      case OrderStatusValue.inProgress:
        return 2;
      case OrderStatusValue.ready:
        return 3;
      case OrderStatusValue.pickedUp:
        return 4;
      case OrderStatusValue.dispatched:
        return 5;
      case OrderStatusValue.delivered:
        return 6;
      case OrderStatusValue.completed:
        return 7;
    }
    return null;
  }

  static bool _isTerminalFailure(String? status) =>
      status == OrderStatusValue.cancelled ||
      status == OrderStatusValue.expired;

  // ───────────────────────────────────────────────────────────────────
  //  Copy
  // ───────────────────────────────────────────────────────────────────

  static String _keyFor(OrderJourneyPhase phase) {
    switch (phase) {
      case OrderJourneyPhase.placed:
        return 'placed';
      case OrderJourneyPhase.accepted:
        return 'accepted';
      case OrderJourneyPhase.payment:
        return 'payment';
      case OrderJourneyPhase.dispatch:
        return 'dispatch';
      case OrderJourneyPhase.preparing:
        return 'preparing';
      case OrderJourneyPhase.ready:
        return 'ready';
      case OrderJourneyPhase.cashCollection:
        return 'cash_collection';
      case OrderJourneyPhase.pickedUp:
        return 'picked_up';
      case OrderJourneyPhase.delivery:
        return 'delivery';
      case OrderJourneyPhase.riderPayment:
        return 'rider_payment';
      case OrderJourneyPhase.completed:
        return 'completed';
    }
  }

  static String _labelFor(
    OrderJourneyPhase phase,
    OrderJourneySnapshot s, {
    required bool isDone,
    required bool isCurrent,
  }) {
    switch (phase) {
      case OrderJourneyPhase.placed:
        return (s.isOwner
                ? AppStrings.orderJourneyOrderReceived
                : AppStrings.orderJourneyOrderPlaced)
            .tr;

      case OrderJourneyPhase.accepted:
        if (isDone) {
          return (s.isOwner
                  ? AppStrings.orderJourneyOrderAccepted
                  : AppStrings.orderJourneyShopAccepted)
              .tr;
        }
        return (s.isOwner
                ? AppStrings.orderJourneyWaitingForAcceptance
                : AppStrings.orderJourneyWaitingForShopAcceptance)
            .tr;

      case OrderJourneyPhase.payment:
        if (s.isOwner) {
          if (isDone || s.isPaymentVerified) {
            return AppStrings.orderJourneyPaymentConfirmed.tr;
          }
          if (s.isPaymentRejected) {
            return AppStrings.orderJourneyPaymentRejected.tr;
          }
          if (s.isPaymentSubmitted) {
            return AppStrings.orderJourneyPaymentConfirmation.tr;
          }
          // Nothing submitted yet: the shop's job is to put its QR in front of
          // the customer.
          return AppStrings.orderJourneyShareUpiQrCode.tr;
        }
        if (isDone || s.isPaymentVerified) {
          return AppStrings.orderJourneyUpiPaymentVerified.tr;
        }
        if (s.isPaymentRejected) {
          return AppStrings.orderJourneyUpiPaymentRejected.tr;
        }
        if (s.isPaymentSubmitted) {
          return AppStrings.orderJourneyUpiPaymentVerification.tr;
        }
        return AppStrings.orderJourneyUpiPaymentPending.tr;

      case OrderJourneyPhase.dispatch:
        return (isDone || s.riderAssigned
                ? AppStrings.orderJourneyRiderFound
                : AppStrings.orderJourneyFindingRider)
            .tr;

      case OrderJourneyPhase.preparing:
        if (isDone) {
          return (s.isOwner
                  ? AppStrings.orderJourneyPreparedOrder
                  : AppStrings.orderJourneyPreparingOrder)
              .tr;
        }
        // The delay is the customer's news, not the shop's — the shop knows;
        // it is the one running late.
        if (isCurrent && !s.isOwner && s.isDelayed) {
          return AppStrings.orderJourneyPreparingDelayed.tr;
        }
        return AppStrings.orderJourneyPreparingOrder.tr;

      case OrderJourneyPhase.ready:
        return AppStrings.orderStatusReadyForPickup.tr;

      case OrderJourneyPhase.cashCollection:
        return AppStrings.orderJourneyPaymentConfirmation.tr;

      case OrderJourneyPhase.pickedUp:
        return AppStrings.orderJourneyPickedUp.tr;

      case OrderJourneyPhase.delivery:
        return (isDone
                ? AppStrings.orderJourneyDeliveryCompleted
                : AppStrings.orderJourneyWaitingForDelivery)
            .tr;

      case OrderJourneyPhase.riderPayment:
        return (isDone || s.isRiderPaid
                ? AppStrings.orderJourneyRiderPaymentCompleted
                : AppStrings.orderJourneyRiderPaymentPending)
            .tr;

      case OrderJourneyPhase.completed:
        return AppStrings.orderStatusCompleted.tr;
    }
  }
}

/// One server stage, reduced to what the strip needs.
class OrderJourneyStageInput {
  final String key;
  final String label;
  final bool done;
  final bool current;

  const OrderJourneyStageInput({
    required this.key,
    required this.label,
    this.done = false,
    this.current = false,
  });
}

class _Progress {
  final int lastDoneIndex;
  final OrderJourneyPhase? currentPhase;

  const _Progress({required this.lastDoneIndex, this.currentPhase});
}
