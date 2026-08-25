import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `metadata.lifecycle` block exactly as documented in
/// lib/docs/FLUTTER_ORDER_FLOW_UI_GUIDE.md §1.2.
Map<String, dynamic> _lifecycleJson({
  String orderStatus = 'ready',
  String paymentState = 'verified',
  String paymentMethod = 'upi',
}) =>
    {
      'orderStatus': orderStatus,
      'sellerStatus': orderStatus,
      'paymentMethod': paymentMethod,
      'paymentState': paymentState,
      'customerActions': ['VIEW_PICKUP_CODE', 'CONTACT_SHOP', 'RAISE_ISSUE'],
      'ownerActions': [
        'CONFIRM_HANDOVER',
        'REPORT_NO_SHOW',
        'CANCEL_ORDER',
        'CONTACT_CUSTOMER'
      ],
      'deadlines': {
        'acceptBy': null,
        'payBy': null,
        'readyBy': null,
        'pickupBy': '2026-08-21T14:30:00Z',
        'hardExpiryAt': '2026-08-22T09:00:00Z',
      },
      'lastEvent': 'PRODUCT_ORDER_PAYMENT_VERIFIED',
      'lastEventAt': '2026-08-21T11:32:10Z',
      'banner': 'Payment verified by the shop',
      'reasonCode': null,
      'refundDue': false,
    };

void main() {
  group('OrderLifecycle parsing', () {
    test('reads the documented block verbatim', () {
      final l = OrderLifecycle.fromJson(_lifecycleJson());

      expect(l.orderStatus, 'ready');
      expect(l.paymentMethod, 'upi');
      expect(l.paymentState, 'verified');
      expect(l.banner, 'Payment verified by the shop');
      expect(l.refundDue, isFalse);
      expect(l.customerActions, contains('VIEW_PICKUP_CODE'));
      expect(l.ownerActions, contains('CONFIRM_HANDOVER'));
    });

    test('actionsFor returns the viewer\'s own list, never both', () {
      final l = OrderLifecycle.fromJson(_lifecycleJson());

      expect(l.actionsFor(isOwner: true), l.ownerActions);
      expect(l.actionsFor(isOwner: false), l.customerActions);
      // A customer must never be handed an owner action.
      expect(l.actionsFor(isOwner: false), isNot(contains('CONFIRM_HANDOVER')));
    });

    test('deadlines parse to local DateTimes; nulls stay null', () {
      final l = OrderLifecycle.fromJson(_lifecycleJson());

      expect(l.deadlines.pickupBy, isNotNull);
      expect(l.deadlines.pickupBy!.toUtc().hour, 14);
      // A null deadline means "no clock running for this step" — NOT expired.
      expect(l.deadlines.acceptBy, isNull);
      expect(l.deadlines.payBy, isNull);
    });

    test('a missing lifecycle block is null, not an empty object', () {
      final meta = MessageMetadata.fromJson({'productPickupOrderId': 'p1'});
      expect(meta.lifecycle, isNull);
    });

    test('MessageMetadata picks up a lifecycle when present', () {
      final meta = MessageMetadata.fromJson({
        'productPickupOrderId': 'p1',
        'lifecycle': _lifecycleJson(orderStatus: 'placed'),
      });
      expect(meta.lifecycle, isNotNull);
      expect(meta.lifecycle!.orderStatus, 'placed');
    });

    test('an unknown orderStatus does not throw and is not treated as terminal',
        () {
      final l = OrderLifecycle.fromJson(
          _lifecycleJson(orderStatus: 'awaiting_courier_v2'));
      expect(l.orderStatus, 'awaiting_courier_v2');
      expect(l.isTerminal, isFalse);
    });

    test('reminder and needs-attention events are recognised as non-state', () {
      final reminder = OrderLifecycle.fromJson({
        ..._lifecycleJson(),
        'lastEvent': 'PRODUCT_ORDER_REMINDER',
      });
      expect(reminder.isReminderEvent, isTrue);
      expect(reminder.needsAttention, isFalse);

      final attention = OrderLifecycle.fromJson({
        ..._lifecycleJson(),
        'lastEvent': 'PRODUCT_ORDER_NEEDS_ATTENTION',
      });
      expect(attention.needsAttention, isTrue);
    });

    test('applyFrom keeps the previous banner when the patch omits it', () {
      final l = OrderLifecycle.fromJson(_lifecycleJson());
      l.applyFrom(OrderLifecycle.fromJson({
        'orderStatus': 'completed',
        'customerActions': ['RAISE_ISSUE'],
        'ownerActions': <String>[],
      }));

      expect(l.orderStatus, 'completed');
      expect(l.banner, 'Payment verified by the shop');
      expect(l.customerActions, ['RAISE_ISSUE']);
      // A patch that empties the owner list must actually empty it — that is
      // how the server removes a button.
      expect(l.ownerActions, isEmpty);
    });
  });

  group('OrderActionsModel', () {
    test('prefers the flat role-scoped availableActions list', () {
      final m = OrderActionsModel.fromJson({
        'orderId': 'o1',
        'availableActions': ['ACCEPT_ORDER', 'REJECT_ORDER'],
        'lifecycle': _lifecycleJson(orderStatus: 'placed'),
      });

      expect(m.availableActions, ['ACCEPT_ORDER', 'REJECT_ORDER']);
      expect(m.actionsFor(isOwner: true), ['ACCEPT_ORDER', 'REJECT_ORDER']);
    });

    test('falls back to the role list when only the lifecycle is sent', () {
      final m = OrderActionsModel.fromJson({
        'orderId': 'o1',
        'lifecycle': _lifecycleJson(),
      });

      expect(m.availableActions, isEmpty);
      expect(m.actionsFor(isOwner: true), contains('CONFIRM_HANDOVER'));
      expect(m.actionsFor(isOwner: false), contains('VIEW_PICKUP_CODE'));
    });

    test('unwraps a { data: … } envelope', () {
      final m = OrderActionsModel.fromJson({
        'success': true,
        'data': {
          'orderId': 'o9',
          'availableActions': ['MARK_READY'],
          'lifecycle': _lifecycleJson(orderStatus: 'accepted'),
        },
      });

      expect(m.orderId, 'o9');
      expect(m.availableActions, ['MARK_READY']);
      expect(m.lifecycle.orderStatus, 'accepted');
    });

    test('reads a flattened lifecycle (no nested key)', () {
      final m = OrderActionsModel.fromJson({
        'orderId': 'o2',
        ..._lifecycleJson(orderStatus: 'accepted'),
      });
      expect(m.lifecycle.orderStatus, 'accepted');
      expect(m.lifecycle.banner, 'Payment verified by the shop');
    });

    test('cancellation reasons come from the server, in both shapes', () {
      final structured = OrderActionsModel.fromJson({
        'orderId': 'o1',
        'lifecycle': _lifecycleJson(),
        'cancellationReasons': [
          {'code': 'ITEM_UNAVAILABLE', 'label': 'Item not available'},
          {'code': 'OTHER', 'requiresComment': true},
        ],
      });
      expect(structured.cancellationReasons.length, 2);
      expect(structured.cancellationReasons.first.label, 'Item not available');
      expect(structured.cancellationReasons.last.requiresComment, isTrue);
      // A bare code still gets a readable label rather than being dropped.
      expect(structured.cancellationReasons.last.label, 'Other');

      final bare = OrderActionsModel.fromJson({
        'orderId': 'o1',
        'lifecycle': _lifecycleJson(),
        'cancellationReasons': ['CHANGED_MY_MIND'],
      });
      expect(bare.cancellationReasons.single.code, 'CHANGED_MY_MIND');
      expect(bare.cancellationReasons.single.label, 'Changed my mind');
    });
  });

  group('OrderPaymentSummary', () {
    test('flags a mismatch between paid and due', () {
      final s = OrderPaymentSummary.fromJson({
        'amountDue': 500,
        'amountPaid': 450,
        'utrNo': 'UTR123',
      });
      expect(s.hasMismatch, isTrue);
    });

    test('equal amounts are not a mismatch, including float noise', () {
      expect(
        OrderPaymentSummary.fromJson({'amountDue': 500, 'amountPaid': 500})
            .hasMismatch,
        isFalse,
      );
      expect(
        OrderPaymentSummary.fromJson(
                {'amountDue': 500.0, 'amountPaid': 500.001})
            .hasMismatch,
        isFalse,
      );
    });

    test('a missing amount is never a mismatch', () {
      expect(
        OrderPaymentSummary.fromJson({'amountDue': 500}).hasMismatch,
        isFalse,
      );
    });
  });

  group('DeliveryQuote', () {
    test('an infeasible quote is a UI state, not an error', () {
      final q = DeliveryQuote.fromJson({
        'feasible': false,
        'message': 'Delivery is only available within 12 km of the shop',
      });
      expect(q.feasible, isFalse);
      expect(q.message, contains('12 km'));
      expect(q.shouldWarnAboutFee, isFalse);
    });

    test('a high fee warns but stays feasible — it must never block', () {
      final q = DeliveryQuote.fromJson({
        'feasible': true,
        'distanceKm': 4.2,
        'deliveryFee': 84,
        'etaMinutes': 22,
        'etaRange': {'min': 17, 'max': 32},
        'economics': {
          'feeExceedsOrderValue': true,
          'feeToOrderRatio': 8.4,
          'suggestion': 'Delivery costs a lot compared to this order',
        },
      });

      expect(q.feasible, isTrue);
      expect(q.shouldWarnAboutFee, isTrue);
      expect(q.deliveryFee, 84);
      expect(q.etaLabel, '17–32 min');
      expect(q.suggestion, contains('costs a lot'));
    });

    test('a quote with no `feasible` key is treated as feasible', () {
      // Absent must not silently disable delivery.
      final q = DeliveryQuote.fromJson({'deliveryFee': 40, 'etaMinutes': 15});
      expect(q.feasible, isTrue);
      expect(q.etaLabel, '15 min');
    });
  });
}
