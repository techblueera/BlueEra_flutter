import 'package:BlueEra/features/chat/auth/model/order_journey.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The step strip on an order card, one test per column of the six-variant
/// table in `order_journey.dart` — and one per rule the three order PDFs show
/// but a reasonable implementation would get wrong.
///
/// Labels come back as translation **keys** here (no GetX translations are
/// loaded in a unit test), so the assertions are on keys, which is what makes
/// them stable: the English copy can be re-worded in `en.json` without
/// breaking a single test, and a key that stops being emitted breaks them all.
void main() {
  OrderJourneySnapshot snap({
    bool isOwner = false,
    bool isDelivery = false,
    bool isUpi = false,
    String? status,
    String? paymentState,
    bool riderAssigned = false,
    bool pickupVerified = false,
    bool cashCollected = false,
    String? riderPaymentState,
    DateTime? readyBy,
    bool? prepDelayed,
    DateTime? now,
  }) =>
      OrderJourneySnapshot(
        isOwner: isOwner,
        isDelivery: isDelivery,
        isUpi: isUpi,
        orderStatus: status,
        paymentState: paymentState,
        riderAssigned: riderAssigned,
        pickupVerified: pickupVerified,
        cashCollected: cashCollected,
        riderPaymentState: riderPaymentState,
        readyBy: readyBy,
        prepDelayed: prepDelayed,
        now: now ?? DateTime(2026, 9, 17, 10, 0),
      );

  List<String> keys(OrderJourney j) => j.steps.map((s) => s.key).toList();
  String? currentKey(OrderJourney j) => j.currentStep?.key;
  List<String> doneKeys(OrderJourney j) =>
      j.steps.where((s) => s.isDone).map((s) => s.key).toList();
  OrderJourneyStep stepOf(OrderJourney j, String key) =>
      j.steps.firstWhere((s) => s.key == key);

  group('which steps each viewer sees', () {
    test('customer · self-pickup · cash — six steps, no payment node', () {
      final j = OrderJourney.resolve(snap(status: OrderStatusValue.placed))!;
      expect(keys(j), [
        'placed',
        'accepted',
        'preparing',
        'ready',
        'picked_up',
        'completed',
      ]);
      // Cash has nothing to watch before the counter, so no payment node
      // anywhere in the strip.
      expect(keys(j), isNot(contains('payment')));
    });

    test('customer · self-pickup · UPI — payment lands after acceptance', () {
      final j = OrderJourney.resolve(
          snap(isUpi: true, status: OrderStatusValue.placed))!;
      expect(keys(j), [
        'placed',
        'accepted',
        'payment',
        'preparing',
        'ready',
        'picked_up',
        'completed',
      ]);
    });

    test('customer · delivery · UPI — delivery and the rider fee at the tail',
        () {
      final j = OrderJourney.resolve(snap(
          isUpi: true, isDelivery: true, status: OrderStatusValue.placed))!;
      expect(keys(j), [
        'placed',
        'accepted',
        'payment',
        'preparing',
        'ready',
        'picked_up',
        'delivery',
        'rider_payment',
        'completed',
      ]);
      // The rider hunt is the shop's business to watch, not the customer's:
      // they are told "preparing" throughout.
      expect(keys(j), isNot(contains('dispatch')));
    });

    test('owner · self-pickup · cash — cash collection is its own step', () {
      final j = OrderJourney.resolve(
          snap(isOwner: true, status: OrderStatusValue.placed))!;
      expect(keys(j), [
        'placed',
        'accepted',
        'preparing',
        'ready',
        'cash_collection',
        'picked_up',
        'completed',
      ]);
    });

    test('owner · self-pickup · UPI — paid up front, so no cash step', () {
      final j = OrderJourney.resolve(
          snap(isOwner: true, isUpi: true, status: OrderStatusValue.placed))!;
      expect(keys(j), [
        'placed',
        'accepted',
        'payment',
        'preparing',
        'ready',
        'picked_up',
        'completed',
      ]);
      expect(keys(j), isNot(contains('cash_collection')));
    });

    test('owner · delivery — dispatch sits BEFORE preparing', () {
      final j = OrderJourney.resolve(snap(
          isOwner: true,
          isUpi: true,
          isDelivery: true,
          status: OrderStatusValue.placed))!;
      expect(keys(j), [
        'placed',
        'accepted',
        'payment',
        'dispatch',
        'preparing',
        'ready',
        'picked_up',
        'completed',
      ]);
      // The ordering is the promise: the rider rides while the shop packs.
      expect(keys(j).indexOf('dispatch'),
          lessThan(keys(j).indexOf('preparing')));
    });
  });

  group('where the live node sits', () {
    test('placed — the shop is the one being waited on, for both parties', () {
      final c = OrderJourney.resolve(snap(status: OrderStatusValue.placed))!;
      expect(doneKeys(c), ['placed']);
      expect(currentKey(c), 'accepted');
      expect(stepOf(c, 'accepted').label,
          AppStringsUnderTest.waitingForShopAcceptance);

      final o = OrderJourney.resolve(
          snap(isOwner: true, status: OrderStatusValue.placed))!;
      expect(currentKey(o), 'accepted');
      expect(
          stepOf(o, 'accepted').label, AppStringsUnderTest.waitingAcceptance);
    });

    test('accepted + UPI unpaid — nothing is packed before the money', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        status: OrderStatusValue.accepted,
        paymentState: PaymentStateValue.pending,
      ))!;
      expect(currentKey(j), 'payment');
      expect(doneKeys(j), ['placed', 'accepted']);
      expect(stepOf(j, 'payment').label,
          AppStringsUnderTest.upiPaymentPending);
    });

    test('a submitted screenshot is not a paid order', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        status: OrderStatusValue.accepted,
        paymentState: PaymentStateValue.submitted,
      ))!;
      expect(currentKey(j), 'payment');
      expect(stepOf(j, 'payment').label,
          AppStringsUnderTest.upiPaymentVerification);
      expect(doneKeys(j), isNot(contains('payment')));
    });

    test('a rejected screenshot keeps the payment node live', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        status: OrderStatusValue.accepted,
        paymentState: PaymentStateValue.rejected,
      ))!;
      expect(currentKey(j), 'payment');
      expect(stepOf(j, 'payment').label,
          AppStringsUnderTest.upiPaymentRejected);
    });

    test('verified payment moves the customer on to preparing', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        status: OrderStatusValue.inProgress,
        paymentState: PaymentStateValue.verified,
      ))!;
      expect(doneKeys(j), ['placed', 'accepted', 'payment']);
      expect(currentKey(j), 'preparing');
    });

    test('owner + delivery: paid but no rider yet — the hunt is live', () {
      final j = OrderJourney.resolve(snap(
        isOwner: true,
        isUpi: true,
        isDelivery: true,
        status: OrderStatusValue.accepted,
        paymentState: PaymentStateValue.verified,
      ))!;
      expect(currentKey(j), 'dispatch');
      expect(stepOf(j, 'dispatch').label, AppStringsUnderTest.findingRider);
    });

    test('owner + delivery: rider assigned — packing is live, hunt is done',
        () {
      final j = OrderJourney.resolve(snap(
        isOwner: true,
        isUpi: true,
        isDelivery: true,
        status: OrderStatusValue.accepted,
        paymentState: PaymentStateValue.verified,
        riderAssigned: true,
      ))!;
      expect(doneKeys(j), ['placed', 'accepted', 'payment', 'dispatch']);
      expect(currentKey(j), 'preparing');
      expect(stepOf(j, 'dispatch').label, AppStringsUnderTest.riderFound);
    });

    test('ready — the customer has no live node, because they have to walk',
        () {
      final j = OrderJourney.resolve(snap(status: OrderStatusValue.ready))!;
      expect(doneKeys(j), ['placed', 'accepted', 'preparing', 'ready']);
      expect(j.currentStep, isNull);
    });

    test('ready — the owner DOES have one: type the code', () {
      final j = OrderJourney.resolve(
          snap(isOwner: true, status: OrderStatusValue.ready))!;
      expect(currentKey(j), 'ready');
      expect(doneKeys(j), ['placed', 'accepted', 'preparing']);
    });

    test('owner + cash: code verified → collect the money', () {
      final j = OrderJourney.resolve(snap(
        isOwner: true,
        status: OrderStatusValue.ready,
        pickupVerified: true,
      ))!;
      expect(currentKey(j), 'cash_collection');
      expect(doneKeys(j), contains('ready'));
    });

    test('owner + cash: money collected → the goods can move', () {
      final j = OrderJourney.resolve(snap(
        isOwner: true,
        status: OrderStatusValue.ready,
        pickupVerified: true,
        cashCollected: true,
      ))!;
      expect(currentKey(j), 'picked_up');
      expect(doneKeys(j), contains('cash_collection'));
    });

    test('owner + UPI: code verified → straight to picked up, no cash node',
        () {
      final j = OrderJourney.resolve(snap(
        isOwner: true,
        isUpi: true,
        status: OrderStatusValue.ready,
        paymentState: PaymentStateValue.verified,
        pickupVerified: true,
      ))!;
      expect(currentKey(j), 'picked_up');
    });

    test('picked up — the shop still has to close it; the customer does not',
        () {
      final o = OrderJourney.resolve(
          snap(isOwner: true, status: OrderStatusValue.pickedUp))!;
      expect(currentKey(o), 'picked_up');

      final c = OrderJourney.resolve(snap(status: OrderStatusValue.pickedUp))!;
      expect(doneKeys(c), contains('picked_up'));
      expect(c.currentStep, isNull);
    });

    test('delivery: picked up puts the customer on the delivery leg', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        isDelivery: true,
        status: OrderStatusValue.pickedUp,
        paymentState: PaymentStateValue.verified,
      ))!;
      expect(currentKey(j), 'delivery');
      expect(stepOf(j, 'delivery').label,
          AppStringsUnderTest.waitingForDelivery);
    });

    test('dispatched reads the same as picked up for the customer', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        isDelivery: true,
        status: OrderStatusValue.dispatched,
        paymentState: PaymentStateValue.verified,
      ))!;
      expect(currentKey(j), 'delivery');
    });

    test('delivered — the delivery fee is the last thing standing', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        isDelivery: true,
        status: OrderStatusValue.delivered,
        paymentState: PaymentStateValue.verified,
        riderPaymentState: OrderRiderPaymentState.pending,
      ))!;
      expect(doneKeys(j), contains('delivery'));
      expect(stepOf(j, 'delivery').label,
          AppStringsUnderTest.deliveryCompleted);
      expect(currentKey(j), 'rider_payment');
      expect(stepOf(j, 'rider_payment').label,
          AppStringsUnderTest.riderPaymentPending);
    });

    test('rider paid — only completion is left', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        isDelivery: true,
        status: OrderStatusValue.delivered,
        paymentState: PaymentStateValue.verified,
        riderPaymentState: OrderRiderPaymentState.paid,
      ))!;
      expect(doneKeys(j), contains('rider_payment'));
      expect(stepOf(j, 'rider_payment').label,
          AppStringsUnderTest.riderPaymentCompleted);
      expect(currentKey(j), 'completed');
    });

    test('completed — every node is green and nothing is live', () {
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        isDelivery: true,
        status: OrderStatusValue.completed,
        paymentState: PaymentStateValue.verified,
        riderPaymentState: OrderRiderPaymentState.paid,
      ))!;
      expect(doneKeys(j).length, j.steps.length);
      expect(j.currentStep, isNull);
    });
  });

  group('delay', () {
    test('an overdue prep ETA reads "(Delayed)" to the customer', () {
      final j = OrderJourney.resolve(snap(
        status: OrderStatusValue.inProgress,
        readyBy: DateTime(2026, 9, 17, 9, 45),
        now: DateTime(2026, 9, 17, 10, 0),
      ))!;
      expect(stepOf(j, 'preparing').label,
          AppStringsUnderTest.preparingDelayed);
    });

    test('an ETA still in the future does not', () {
      final j = OrderJourney.resolve(snap(
        status: OrderStatusValue.inProgress,
        readyBy: DateTime(2026, 9, 17, 10, 20),
        now: DateTime(2026, 9, 17, 10, 0),
      ))!;
      expect(stepOf(j, 'preparing').label, AppStringsUnderTest.preparingOrder);
    });

    test('the server saying "not delayed" beats an expired ETA', () {
      // A shop that revised its estimate is not late again because the first
      // one lapsed.
      final j = OrderJourney.resolve(snap(
        status: OrderStatusValue.inProgress,
        readyBy: DateTime(2026, 9, 17, 9, 45),
        prepDelayed: false,
        now: DateTime(2026, 9, 17, 10, 0),
      ))!;
      expect(stepOf(j, 'preparing').label, AppStringsUnderTest.preparingOrder);
    });

    test('the delay is the customer\'s news, not the shop\'s', () {
      final j = OrderJourney.resolve(snap(
        isOwner: true,
        status: OrderStatusValue.inProgress,
        prepDelayed: true,
      ))!;
      // The shop knows it is late — it is the one running late.
      expect(stepOf(j, 'preparing').label, AppStringsUnderTest.preparingOrder);
    });

    test('a done preparing step reads "Prepared order" on the shop side', () {
      final j = OrderJourney.resolve(
          snap(isOwner: true, status: OrderStatusValue.ready))!;
      expect(stepOf(j, 'preparing').label, AppStringsUnderTest.preparedOrder);
    });
  });

  group('cancelled and expired', () {
    test('one node turns red; the rest stay grey, never green', () {
      final j = OrderJourney.resolve(snap(
        status: OrderStatusValue.cancelled,
      ))!;
      expect(doneKeys(j), ['placed']);
      expect(stepOf(j, 'accepted').isCancelled, isTrue);
      expect(stepOf(j, 'accepted').label, 'orderStatusCancelled');
      // Steps after the cancellation did not happen.
      for (final k in ['preparing', 'ready', 'picked_up', 'completed']) {
        expect(stepOf(j, k).state, OrderJourneyStepState.pending,
            reason: '$k must not read as done or live on a dead order');
      }
      expect(j.currentStep, isNull);
    });

    test('the red node lands where the order actually died', () {
      // Cancelled after the money was verified: the payment stays green and
      // the red node moves down the strip.
      final j = OrderJourney.resolve(snap(
        isUpi: true,
        status: OrderStatusValue.cancelled,
        paymentState: PaymentStateValue.verified,
      ))!;
      expect(doneKeys(j), ['placed', 'accepted', 'payment']);
      expect(stepOf(j, 'preparing').isCancelled, isTrue);
    });

    test('a cancellation after pickup verification keeps ready green', () {
      final j = OrderJourney.resolve(snap(
        isOwner: true,
        status: OrderStatusValue.cancelled,
        pickupVerified: true,
      ))!;
      expect(doneKeys(j), contains('ready'));
      expect(stepOf(j, 'cash_collection').isCancelled, isTrue);
    });

    test('expired says "Expired", not "Cancelled"', () {
      final j = OrderJourney.resolve(snap(status: OrderStatusValue.expired))!;
      expect(stepOf(j, 'accepted').label, 'orderStatusExpired');
    });
  });

  group('refusing to guess', () {
    test('no status at all — no strip', () {
      expect(OrderJourney.resolve(snap(status: null)), isNull);
      expect(OrderJourney.resolve(snap(status: '')), isNull);
    });

    test('a status this build has never heard of — no strip', () {
      // Better than drawing it in the wrong place and telling the customer
      // their order is somewhere it is not.
      expect(OrderJourney.resolve(snap(status: 'awaiting_kyc')), isNull);
      expect(OrderJourney.resolve(snap(status: 'PLACED')), isNull);
    });
  });

  group('a server stage list wins', () {
    test('labels, order and unknown keys are all the server\'s', () {
      final j = OrderJourney.fromStages(const [
        OrderJourneyStageInput(key: 'placed', label: 'Order placed', done: true),
        OrderJourneyStageInput(
            key: 'quality_check', label: 'Quality check', current: true),
        OrderJourneyStageInput(key: 'done', label: 'Done'),
      ])!;
      expect(keys(j), ['placed', 'quality_check', 'done']);
      expect(j.currentStep?.label, 'Quality check');
      expect(stepOf(j, 'done').state, OrderJourneyStepState.pending);
    });

    test('an empty stage list falls through to the derived strip', () {
      expect(OrderJourney.fromStages(const []), isNull);
    });

    test('a failed order marks the node after the last done one', () {
      final j = OrderJourney.fromStages(
        const [
          OrderJourneyStageInput(key: 'a', label: 'A', done: true),
          OrderJourneyStageInput(key: 'b', label: 'B'),
          OrderJourneyStageInput(key: 'c', label: 'C'),
        ],
        failed: true,
        failedLabel: 'Cancelled',
      )!;
      expect(stepOf(j, 'b').isCancelled, isTrue);
      expect(stepOf(j, 'c').state, OrderJourneyStepState.pending);
      expect(j.currentStep, isNull);
    });
  });

  group('auto-dispatch timing (OrderActionsModel.needsRiderDispatch)', () {
    OrderActionsModel model(Map<String, dynamic> lifecycle,
            {String? deliveryType = 'rider', String? rideOrderId}) =>
        OrderActionsModel.fromJson({
          'data': {
            'orderId': 'o1',
            'deliveryType': deliveryType,
            if (rideOrderId != null) 'rideOrderId': rideOrderId,
            'lifecycle': lifecycle,
          }
        });

    test('UPI delivery dispatches as soon as the payment is verified', () {
      final m = model({
        'orderStatus': OrderStatusValue.accepted,
        'paymentMethod': 'upi',
        'paymentState': PaymentStateValue.verified,
      });
      // The whole point of the change: the rider rides while the shop packs.
      expect(m.needsRiderDispatch, isTrue);
    });

    test('never on an unpaid order — a rider sent for nothing is a real cost',
        () {
      for (final state in [
        PaymentStateValue.pending,
        PaymentStateValue.submitted,
        PaymentStateValue.rejected,
        PaymentStateValue.expired,
      ]) {
        final m = model({
          'orderStatus': OrderStatusValue.accepted,
          'paymentMethod': 'upi',
          'paymentState': state,
        });
        expect(m.needsRiderDispatch, isFalse, reason: 'paymentState=$state');
      }
    });

    test('never before the shop has accepted, even when paid', () {
      final m = model({
        'orderStatus': OrderStatusValue.placed,
        'paymentMethod': 'upi',
        'paymentState': PaymentStateValue.verified,
      });
      expect(m.needsRiderDispatch, isFalse);
    });

    test('still fires at ready for a paid order nobody dispatched earlier', () {
      final m = model({
        'orderStatus': OrderStatusValue.ready,
        'paymentMethod': 'upi',
        'paymentState': PaymentStateValue.verified,
      });
      expect(m.needsRiderDispatch, isTrue);
    });

    test('a ride already attached is never dispatched twice', () {
      final m = model({
        'orderStatus': OrderStatusValue.accepted,
        'paymentMethod': 'upi',
        'paymentState': PaymentStateValue.verified,
      }, rideOrderId: 'ride_1');
      expect(m.needsRiderDispatch, isFalse);
    });

    test('a terminal order is never dispatched', () {
      for (final s in [
        OrderStatusValue.cancelled,
        OrderStatusValue.expired,
        OrderStatusValue.completed,
      ]) {
        final m = model({
          'orderStatus': s,
          'paymentMethod': 'upi',
          'paymentState': PaymentStateValue.verified,
        });
        expect(m.needsRiderDispatch, isFalse, reason: s);
      }
    });

    test('self-pickup never dispatches', () {
      final m = model({
        'orderStatus': OrderStatusValue.ready,
        'paymentMethod': 'upi',
        'paymentState': PaymentStateValue.verified,
      }, deliveryType: 'self-pickup');
      expect(m.needsRiderDispatch, isFalse);
    });

    test('an unknown payment method keeps the old ready-only trigger', () {
      // Cash delivery is not offered at checkout and a null method is a flow
      // this build does not recognise: neither gains a new, untested trigger.
      final early = model({'orderStatus': OrderStatusValue.accepted});
      final atReady = model({'orderStatus': OrderStatusValue.ready});
      expect(early.needsRiderDispatch, isFalse);
      expect(atReady.needsRiderDispatch, isTrue);
    });
  });
}

/// The translation keys the strip emits, named so a failure reads as a
/// sentence instead of a string literal.
class AppStringsUnderTest {
  static const waitingForShopAcceptance =
      'orderJourneyWaitingForShopAcceptance';
  static const waitingAcceptance = 'orderJourneyWaitingForAcceptance';
  static const upiPaymentPending = 'orderJourneyUpiPaymentPending';
  static const upiPaymentVerification = 'orderJourneyUpiPaymentVerification';
  static const upiPaymentRejected = 'orderJourneyUpiPaymentRejected';
  static const findingRider = 'orderJourneyFindingRider';
  static const riderFound = 'orderJourneyRiderFound';
  static const preparingOrder = 'orderJourneyPreparingOrder';
  static const preparedOrder = 'orderJourneyPreparedOrder';
  static const preparingDelayed = 'orderJourneyPreparingDelayed';
  static const waitingForDelivery = 'orderJourneyWaitingForDelivery';
  static const deliveryCompleted = 'orderJourneyDeliveryCompleted';
  static const riderPaymentPending = 'orderJourneyRiderPaymentPending';
  static const riderPaymentCompleted = 'orderJourneyRiderPaymentCompleted';
}
