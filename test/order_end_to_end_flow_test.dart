import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/features/chat/auth/model/active_order_summary.dart';
import 'package:BlueEra/features/common/Discover/widget/pending_order_chip.dart';
import 'package:BlueEra/features/me/product/view/customer/widget/order_checkout_stepper_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three flows walked end to end, from all three ends.
///
/// Flow A — self-pickup + cash. Flow B — self-pickup + UPI. Flow C — delivery.
/// Each is replayed as the sequence of server states it actually passes
/// through, asserting what the customer is told at every one.
///
/// **Why the assertions are all about the customer's rail:** the buttons were
/// already pinned by `order_action_bar_test.dart` and the money copy by
/// `order_lifecycle_section_test.dart`. What had never been tested is the
/// question the flows are really about — *does the person who has to act know
/// they have to act, and by when?* — because until now there was no surface
/// that answered it outside a chat thread.
void main() {
  const product = OrderServiceApi.productOrderService;
  const grocery = OrderServiceApi.groceryOrderService;

  final placedAt = DateTime(2026, 8, 27, 10, 0);

  /// One row of `/orders/me`, shaped the way an order document actually is.
  ActiveOrderSummary order({
    String service = product,
    String? status = 'placed',
    String paymentMethod = 'cash',
    String? paymentState,
    String deliveryType = 'self-pickup',
    Map<String, dynamic> deadlines = const {},
    bool isTerminal = false,
    dynamic riderLeg,
    String shop = 'Singh Store',
    DateTime? createdAt,
  }) =>
      ActiveOrderSummary.fromJson({
        'orderId': 'o1',
        'orderNumber': 'ORD1',
        'businessName': shop,
        if (status != null) 'orderStatus': status,
        'paymentMethod': paymentMethod,
        if (paymentState != null) 'paymentState': paymentState,
        'deliveryType': deliveryType,
        'deadlines': deadlines,
        'isTerminal': isTerminal,
        if (riderLeg != null) 'riderLeg': riderLeg,
        'createdAt': (createdAt ?? placedAt).toIso8601String(),
      }, service: service);

  String title(ActiveOrderSummary o) => PendingOrderCopy.of(o).title;

  // ───────────────────────────────────────────────────────────────────────
  //  Flow A — self-pickup + CASH
  // ───────────────────────────────────────────────────────────────────────

  group('Flow A · self-pickup + cash, customer end', () {
    test('placed → waiting on the shop, counting to acceptBy', () {
      final o = order(deadlines: {
        'acceptBy': placedAt.add(const Duration(minutes: 20)).toIso8601String(),
      });
      expect(title(o), contains('Waiting for the shop to accept'));
      expect(o.deadline, placedAt.add(const Duration(minutes: 20)));
      // The shop is the one being waited on — the customer is not chased.
      expect(PendingOrderCopy.of(o).urgent, isFalse);
    });

    test('accepted → being prepared, counting to readyBy', () {
      final o = order(status: 'accepted', deadlines: {
        'readyBy': placedAt.add(const Duration(hours: 1)).toIso8601String(),
      });
      expect(title(o), contains('being prepared'));
      expect(o.deadline, placedAt.add(const Duration(hours: 1)));
    });

    test('ready → THE case: go and collect it, counting to pickupBy', () {
      final o = order(status: 'ready', deadlines: {
        'pickupBy': placedAt.add(const Duration(hours: 3)).toIso8601String(),
      });
      expect(title(o), contains('Ready'));
      expect(title(o), contains('collect'));
      expect(o.deadline, placedAt.add(const Duration(hours: 3)));
      // The customer is now the only person who can move this forward, and if
      // they do not it expires. This one is allowed to be loud.
      expect(PendingOrderCopy.of(o).urgent, isTrue);
      expect(o.urgency, 0);
    });

    test('a cash order never shows a pay prompt at any state', () {
      // §4: on a cash order the server never returns SUBMIT_PAYMENT and never
      // puts a UPI payment state on it — so no state can produce pay copy.
      for (final s in ['placed', 'accepted', 'in-progress', 'ready']) {
        final t = title(order(status: s));
        expect(t.toLowerCase(), isNot(contains('pay')), reason: s);
      }
    });

    test('completed drops off the rail entirely', () {
      final o = order(status: 'completed', isTerminal: true);
      expect(o.isLive, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  //  Flow B — self-pickup + UPI
  // ───────────────────────────────────────────────────────────────────────

  group('Flow B · self-pickup + UPI, customer end', () {
    ActiveOrderSummary upi({
      String? status = 'accepted',
      String? paymentState,
      Map<String, dynamic> deadlines = const {},
      bool isTerminal = false,
    }) =>
        order(
          status: status,
          paymentMethod: 'upi',
          paymentState: paymentState,
          deadlines: deadlines,
          isTerminal: isTerminal,
        );

    test('accepted + payment pending → pay, counting to payBy', () {
      final o = upi(paymentState: 'pending', deadlines: {
        'payBy': placedAt.add(const Duration(minutes: 30)).toIso8601String(),
        'readyBy': placedAt.add(const Duration(hours: 1)).toIso8601String(),
      });
      expect(title(o), contains('Pay to confirm'));
      expect(PendingOrderCopy.of(o).urgent, isTrue);
      // payBy wins over readyBy: the money is the thing they can act on.
      expect(o.deadline, placedAt.add(const Duration(minutes: 30)));
    });

    test('submitted → waiting, and NEVER the word paid', () {
      // §5: "a screenshot is not a payment". This is the single most important
      // string in the whole flow.
      final o = upi(paymentState: 'submitted');
      final t = title(o);
      expect(t, contains('Waiting for the shop to confirm'));
      expect(t.toLowerCase(), isNot(contains('paid')));
      expect(PendingOrderCopy.of(o).urgent, isFalse);
    });

    test('under_review reads the same as submitted', () {
      expect(title(upi(paymentState: 'under_review')),
          title(upi(paymentState: 'submitted')));
    });

    test('rejected → can pay again, and says so', () {
      final o = upi(paymentState: 'rejected');
      expect(title(o), contains("wasn't confirmed"));
      expect(PendingOrderCopy.of(o).subtitle, contains('again'));
      expect(PendingOrderCopy.of(o).urgent, isTrue);
    });

    test('verified + ready → collect it; the money row is done talking', () {
      final o = upi(status: 'ready', paymentState: 'verified', deadlines: {
        'pickupBy': placedAt.add(const Duration(hours: 3)).toIso8601String(),
      });
      expect(title(o), contains('collect'));
    });

    test('an unpaid ready order still asks for money first', () {
      // The shop cannot hand over until the payment verifies (§5), so the
      // customer's next move is paying, not walking to the shop.
      final o = upi(status: 'ready', paymentState: 'pending', deadlines: {
        'payBy': placedAt.add(const Duration(minutes: 30)).toIso8601String(),
        'pickupBy': placedAt.add(const Duration(hours: 3)).toIso8601String(),
      });
      expect(title(o), contains('Pay to confirm'));
      expect(o.deadline, placedAt.add(const Duration(minutes: 30)));
    });

    test('cancelled with a refund owed stays on the rail (§7)', () {
      final o = upi(
          status: 'cancelled', paymentState: 'refund_pending', isTerminal: true);
      expect(o.isTerminal, isTrue);
      // The order is dead; the money conversation is not.
      expect(o.isLive, isTrue);
      expect(title(o), contains('Refund pending'));
      // A refund has no countdown — and a null deadline draws nothing.
      expect(o.deadline, isNull);
    });

    test('cancelled owing nothing is genuinely over', () {
      final o = upi(status: 'cancelled', isTerminal: true);
      expect(o.isLive, isFalse);
    });

    test('once the shop says it sent the refund, the copy changes', () {
      final before = ActiveOrderSummary.fromJson({
        'orderId': 'o1',
        'orderStatus': 'cancelled',
        'paymentState': 'refund_pending',
        'isTerminal': true,
      }, service: product);
      final after = ActiveOrderSummary.fromJson({
        'orderId': 'o1',
        'orderStatus': 'cancelled',
        'paymentState': 'refund_pending',
        'isTerminal': true,
        'refundInitiatedAt': '2026-08-27T12:00:00.000Z',
      }, service: product);
      expect(PendingOrderCopy.of(before).subtitle,
          isNot(PendingOrderCopy.of(after).subtitle));
      expect(PendingOrderCopy.of(after).subtitle, contains('confirm'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  //  Flow C — delivery
  // ───────────────────────────────────────────────────────────────────────

  group('Flow C · delivery, customer end', () {
    ActiveOrderSummary delivery({
      String? status = 'ready',
      dynamic riderLeg,
      Map<String, dynamic> deadlines = const {},
    }) =>
        order(
          status: status,
          deliveryType: 'rider',
          riderLeg: riderLeg,
          deadlines: deadlines,
        );

    test('packed, no rider yet → still looking, never a failure', () {
      final o = delivery();
      expect(o.riderAssigned, isFalse);
      expect(title(o), contains('Finding a delivery partner'));
      // Not the customer's problem to solve — the platform is searching.
      expect(PendingOrderCopy.of(o).urgent, isFalse);
    });

    test('a rider is assigned → the block flips, never both', () {
      final o = delivery(riderLeg: 'accepted');
      expect(o.riderAssigned, isTrue);
      expect(title(o), contains('collecting your order'));
      expect(title(o), isNot(contains('Finding')));
    });

    test('not-started is not an assignment', () {
      // The leg exists as a string but names the absence of a rider (§18.5).
      final o = delivery(riderLeg: 'not-started');
      expect(o.riderAssigned, isFalse);
      expect(title(o), contains('Finding'));
    });

    test('dispatched → on the way, counting to deliverBy', () {
      final o = delivery(status: 'dispatched', riderLeg: 'picked-up', deadlines: {
        'deliverBy': placedAt.add(const Duration(hours: 2)).toIso8601String(),
      });
      expect(title(o), contains('On the way'));
      expect(o.deadline, placedAt.add(const Duration(hours: 2)));
    });

    test('a delivery order never shows the self-pickup collect copy', () {
      // §14 item 7: a delivery order used to render the self-pickup card.
      for (final leg in [null, 'accepted', 'picked-up']) {
        final t = title(delivery(riderLeg: leg));
        expect(t, isNot(contains('go and collect')), reason: '$leg');
      }
    });

    test('a packed delivery order counts to dispatchBy, not pickupBy', () {
      final o = delivery(deadlines: {
        'dispatchBy': placedAt.add(const Duration(minutes: 25)).toIso8601String(),
        'pickupBy': placedAt.add(const Duration(hours: 3)).toIso8601String(),
      });
      expect(o.deadline, placedAt.add(const Duration(minutes: 25)));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  //  Cross-cutting
  // ───────────────────────────────────────────────────────────────────────

  group('the rail never decides anything the server owns', () {
    test('a status this build has never heard of still opens the order', () {
      final o = order(status: 'quantum-packed');
      final copy = PendingOrderCopy.of(o);
      // Described in what we do know, never by echoing the raw code.
      expect(copy.title, isNot(contains('quantum')));
      expect(copy.title, contains('ORD1'));
      // And with no clock, because no rule of ours applies to it.
      expect(o.deadline, isNull);
    });

    test('a missing status is not a crash', () {
      final o = order(status: null);
      expect(PendingOrderCopy.of(o).title, isNotEmpty);
      expect(o.deadline, isNull);
    });

    test('a null deadline draws nothing — never a dash, never a zero', () {
      // §8.1 rule 2. Every state with no matching deadline yields null rather
      // than something the widget would have to special-case.
      for (final s in ['placed', 'accepted', 'ready', 'dispatched']) {
        expect(order(status: s).deadline, isNull, reason: s);
      }
    });

    test('grocery derives its clock; product never does', () {
      final g = order(service: grocery, status: 'placed');
      expect(g.deadline, placedAt.add(const Duration(hours: 1)));
      // Product has real deadlines and must never be given a fake one.
      expect(order(service: product, status: 'placed').deadline, isNull);
    });

    test("a server deadline always beats the derived one", () {
      final g = order(service: grocery, status: 'placed', deadlines: {
        'acceptBy': placedAt.add(const Duration(minutes: 20)).toIso8601String(),
      });
      expect(g.deadline, placedAt.add(const Duration(minutes: 20)));
    });

    test('urgency puts what the customer must do above what the shop must', () {
      final collect = order(status: 'ready');
      final pay = order(
          status: 'accepted', paymentMethod: 'upi', paymentState: 'pending');
      final waiting = order(status: 'placed');
      final refund = order(
          status: 'cancelled', paymentState: 'refund_pending', isTerminal: true);

      expect(collect.urgency, lessThan(pay.urgency));
      expect(pay.urgency, lessThan(waiting.urgency));
      expect(refund.urgency, lessThan(waiting.urgency));
    });
  });

  group('list parsing survives whatever envelope arrives', () {
    test('bare array, {data}, {data:{orders}} and {orders} all parse', () {
      const row = {'orderId': 'a', 'orderStatus': 'ready'};
      for (final body in <dynamic>[
        [row],
        {'data': [row]},
        {'data': {'orders': [row]}},
        {'orders': [row]},
      ]) {
        final list = ActiveOrderSummary.listFrom(body, service: product);
        expect(list.length, 1, reason: '$body');
        expect(list.single.orderId, 'a');
      }
    });

    test('a row with no id is dropped, not rendered as an orphan', () {
      final list = ActiveOrderSummary.listFrom([
        {'orderStatus': 'ready'},
        {'orderId': 'b', 'orderStatus': 'ready'},
      ], service: product);
      expect(list.map((e) => e.orderId), ['b']);
    });

    test('an unparseable body is an empty list, never a crash', () {
      for (final body in <dynamic>[null, 'nope', 42, {}, {'data': null}]) {
        expect(ActiveOrderSummary.listFrom(body, service: product), isEmpty,
            reason: '$body');
      }
    });
  });

  group('the shop end and the rider end are not this rail', () {
    test('the rail is the customer lane only', () {
      // /orders/me is the caller's own orders as a CUSTOMER. The shop's lane
      // is /orders/business/me and the rider's is rider-service entirely —
      // one screen must never mix the three, because role is per order and
      // the same person holds all three at once (§18.6).
      expect(kPendingOrderServices,
          [OrderServiceApi.productOrderService, OrderServiceApi.groceryOrderService]);
    });

    test('a rider leg never turns a self-pickup order into a delivery', () {
      final o = order(status: 'ready', riderLeg: 'accepted');
      // deliveryType is what decides the shape, not the presence of a leg.
      expect(o.isSelfPickup, isTrue);
      expect(title(o), contains('collect'));
    });
  });

  group('§17.3 · checkout asks in the order that makes the fee visible', () {
    test('address is asked before the fulfilment choice', () {
      // The whole point. With method first, the delivery card can only
      // advertise a number nothing computed, and §17.2's "self-pickup becomes
      // the default when the fee exceeds the basket" is unreachable because
      // the choice has already been made.
      expect(orderCheckoutAsksAddressFirst, isTrue);
      expect(kOrderCheckoutSteps.first.name, 'address');
    });

    test('payment is chosen after fulfilment, and review is last', () {
      final names = kOrderCheckoutSteps.map((e) => e.name).toList();
      expect(names, ['address', 'method', 'payment', 'review']);
    });

    test('no separate quote step — it renders on the delivery card', () {
      expect(kOrderCheckoutSteps.map((e) => e.name), isNot(contains('quote')));
    });

    test('a shop with no location is never asked for a delivery address', () {
      // Nothing to price, so the address step would be a dead gate.
      final names = kOrderCheckoutStepsNoDelivery.map((e) => e.name).toList();
      expect(names, ['payment', 'review']);
      expect(names, isNot(contains('address')));
      expect(names, isNot(contains('method')));
    });
  });
}
