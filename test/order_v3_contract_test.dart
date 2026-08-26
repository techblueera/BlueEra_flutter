import 'package:BlueEra/features/chat/auth/controller/order_broadcast_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/me/product/model/order_checkout_payload.dart';
import 'package:flutter_test/flutter_test.dart';

/// The v3 contract, exercised against the shapes the services really send.
///
/// Every group here corresponds to one of the seven verified causes in the
/// guide's §0 — the reasons the app looked static while the backend was
/// already sending everything it needed.
void main() {
  // ── §0 cause 1 · §2.2 ────────────────────────────────────────────────
  group('actor is the role — not isOwner, not the message sender', () {
    OrderActionsModel parse(Map<String, dynamic> data) =>
        OrderActionsModel.fromJson({'success': true, 'data': data});

    test('actor:owner renders the shop', () {
      final m = parse({
        'orderId': 'o1',
        'actor': 'owner',
        'orderStatus': 'ready',
        'availableActions': ['CONFIRM_HANDOVER', 'REPORT_NO_SHOW'],
      });
      expect(m.isOwner, isTrue);
      expect(m.isOwnerOrNull, isTrue);
      expect(m.actionsFor(isOwner: true), ['CONFIRM_HANDOVER', 'REPORT_NO_SHOW']);
    });

    test('actor:customer renders the customer', () {
      final m = parse({
        'orderId': 'o1',
        'actor': 'customer',
        'orderStatus': 'ready',
        'availableActions': ['VIEW_PICKUP_CODE'],
      });
      expect(m.isOwner, isFalse);
      expect(m.isOwnerOrNull, isFalse);
    });

    test('actor:admin is neither, and never gets ADMIN_OVERRIDE UI', () {
      final m = parse({
        'orderId': 'o1',
        'actor': 'admin',
        'orderStatus': 'ready',
        'availableActions': ['ADMIN_OVERRIDE', 'CONTACT_SHOP'],
      });
      expect(m.isAdmin, isTrue);
      expect(m.isOwner, isFalse);
      // The action bar's switch has no ADMIN_OVERRIDE case, so it renders
      // nothing for it. The contract is checked here; the bar is checked in
      // order_action_bar_test.dart's unknown-action case.
      expect(m.availableActions, contains('ADMIN_OVERRIDE'));
    });

    test('no actor at all means the caller must fall back — not guess true',
        () {
      final m = parse({'orderId': 'o1', 'orderStatus': 'placed'});
      expect(m.isOwnerOrNull, isNull);
      expect(m.isOwner, isFalse);
    });

    test('availableActions is already caller-scoped and wins over the split',
        () {
      final m = parse({
        'orderId': 'o1',
        'actor': 'owner',
        'availableActions': ['MARK_READY'],
        'lifecycle': {
          'orderStatus': 'accepted',
          'ownerActions': ['MARK_READY', 'CANCEL_ORDER'],
          'customerActions': ['CANCEL_ORDER'],
        },
      });
      expect(m.actionsFor(isOwner: true), ['MARK_READY']);
    });
  });

  // ── §0 cause 2 · §2.3 ────────────────────────────────────────────────
  group('money lives in data.payment.*, and nowhere else', () {
    test('the shop verification card gets every field it needs', () {
      final m = OrderActionsModel.fromJson({
        'success': true,
        'data': {
          '_id': 'o1',
          'actor': 'owner',
          'orderStatus': 'accepted',
          'payment': {
            'method': 'upi',
            'state': 'submitted',
            'amountDue': 500,
            'amountPaid': 450,
            'utrNo': '4429XXXX9921',
            'screenshotUrl': 'https://s3/shot.png',
            'upiId': 'shop@upi',
            'submittedAt': '2026-08-26T10:00:00Z',
            'submissionCount': 1,
            'rejectionReason': null,
          },
        },
      });
      final p = m.paymentSummary!;
      expect(p.amountDue, 500);
      expect(p.amountPaid, 450);
      expect(p.utrNo, '4429XXXX9921');
      expect(p.screenshotUrl, 'https://s3/shot.png');
      expect(p.submissionCount, 1);
      expect(p.hasMismatch, isTrue);
    });

    test('the backend tolerates ±₹1, so ₹1 apart is NOT a mismatch', () {
      final p = OrderPaymentSummary.fromJson(
          {'amountDue': 500, 'amountPaid': 499});
      expect(p.hasMismatch, isFalse);
      final p2 = OrderPaymentSummary.fromJson(
          {'amountDue': 500, 'amountPaid': 498});
      expect(p2.hasMismatch, isTrue);
    });

    test('/actions carries no money at all — and that is not an error', () {
      final m = OrderActionsModel.fromJson({
        'success': true,
        'data': {
          'orderId': 'o1',
          'actor': 'customer',
          'orderStatus': 'accepted',
          'availableActions': ['SUBMIT_PAYMENT'],
        },
      });
      expect(m.paymentSummary, isNull);
    });

    test('an empty payment object does not masquerade as loaded money', () {
      final m = OrderActionsModel.fromJson({
        'data': {'orderId': 'o1', 'payment': <String, dynamic>{}}
      });
      expect(m.paymentSummary, isNull);
    });
  });

  // ── §0 cause 5 ───────────────────────────────────────────────────────
  group('warning is a SIBLING of data', () {
    test('the amount-mismatch warning is found at the response root', () {
      final m = OrderActionsModel.fromJson({
        'success': true,
        'data': {'orderId': 'o1', 'orderStatus': 'accepted'},
        'warning':
            'The amount you entered (450) does not match the order total (500).',
      });
      expect(m.warning, contains('450'));
    });

    test('a warning nested inside data is still read', () {
      final m = OrderActionsModel.fromJson({
        'data': {'orderId': 'o1', 'orderStatus': 'accepted', 'warning': 'x'}
      });
      expect(m.warning, 'x');
    });
  });

  group('envelope exceptions', () {
    test('PUT /ready answers a BARE order with no wrapper', () {
      final m = OrderActionsModel.fromJson({
        '_id': 'o1',
        'orderNumber': 'PROD260826',
        'orderStatus': 'ready',
        'deliveryType': 'rider',
        'grandTotal': 500,
        'totalItems': 3,
        'availableActions': ['CONFIRM_HANDOVER'],
      }, fallbackOrderId: 'o1');
      expect(m.orderId, 'o1');
      expect(m.orderNumber, 'PROD260826');
      expect(m.lifecycle.orderStatus, 'ready');
      expect(m.availableActions, ['CONFIRM_HANDOVER']);
      expect(m.grandTotal, 500);
    });

    test('/pickup-code answers only the code', () {
      final m = OrderActionsModel.fromJson({
        'success': true,
        'data': {'orderId': 'o1', 'orderNumber': 'P1', 'pickupCode': 'K7QP4M'},
      });
      expect(m.pickupCode, 'K7QP4M');
    });

    test('cancellationReasons arrive as BARE STRINGS and are humanised', () {
      final m = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'orderStatus': 'placed',
          'cancellationReasons': ['ITEM_UNAVAILABLE', 'SHOP_CLOSED'],
        }
      });
      expect(m.cancellationReasons.map((r) => r.code),
          ['ITEM_UNAVAILABLE', 'SHOP_CLOSED']);
      expect(m.cancellationReasons.first.label, 'Item unavailable');
    });
  });

  // ── §0 cause 6 · §5.4 ────────────────────────────────────────────────
  group('the delivery coordinate shape the gate actually reads', () {
    test('location.coordinates is GeoJSON — [lng, lat], LNG FIRST', () {
      final json = const OrderDeliveryDetails(
        addressLine: '12 MG Road',
        latitude: 12.97,
        longitude: 77.59,
      ).toJson();

      final loc = json['location'] as Map<String, dynamic>;
      expect(loc['type'], 'Point');
      expect(loc['coordinates'], [77.59, 12.97]);
    });

    test('a flat pair alone would 400 — so it is never the only form sent', () {
      final json = const OrderDeliveryDetails(latitude: 1, longitude: 2)
          .toJson();
      expect(json.containsKey('location'), isTrue);
    });

    test('no coordinate means no location block, and the gate says so', () {
      const d = OrderDeliveryDetails(addressLine: 'somewhere');
      expect(d.hasCoordinates, isFalse);
      expect(d.toJson().containsKey('location'), isFalse);
    });

    test('the quote rides INSIDE delivery — there is nowhere to attach it '
        'later', () {
      final json = const OrderDeliveryDetails(
        latitude: 1,
        longitude: 2,
        distanceKm: 4.2,
        feeEstimate: 84,
        etaMinutes: 22,
      ).toJson();
      expect(json['distanceKm'], 4.2);
      expect(json['feeEstimate'], 84);
      expect(json['etaMinutes'], 22);
    });

    test('the order reads its own drop point back, whichever shape it is in',
        () {
      final fromGeo = OrderDeliveryInfo.fromJson({
        'location': {
          'type': 'Point',
          'coordinates': [77.59, 12.97]
        }
      });
      expect(fromGeo.latitude, 12.97);
      expect(fromGeo.longitude, 77.59);
      expect(fromGeo.hasCoordinates, isTrue);

      final fromFlat =
          OrderDeliveryInfo.fromJson({'latitude': 12.97, 'longitude': 77.59});
      expect(fromFlat.hasCoordinates, isTrue);
    });
  });

  // ── §7.2 ─────────────────────────────────────────────────────────────
  group('a doorstep order dispatches itself — no button', () {
    OrderActionsModel order(
            {required String status,
            required String type,
            String? rideOrderId}) =>
        OrderActionsModel.fromJson({
          'data': {
            'orderId': 'o1',
            'actor': 'customer',
            'orderStatus': status,
            'deliveryType': type,
            if (rideOrderId != null) 'rideOrderId': rideOrderId,
          }
        });

    test('rider + ready + no ride attached is the trigger', () {
      expect(order(status: 'ready', type: 'rider').needsRiderDispatch, isTrue);
    });

    test('a ride already attached is not re-dispatched', () {
      expect(
        order(status: 'ready', type: 'rider', rideOrderId: 'ORD-1').
            needsRiderDispatch,
        isFalse,
      );
    });

    test('a self-pickup order never auto-dispatches', () {
      expect(order(status: 'ready', type: 'self-pickup').needsRiderDispatch,
          isFalse);
    });

    test('before ready there is nothing to collect', () {
      expect(order(status: 'accepted', type: 'rider').needsRiderDispatch,
          isFalse);
    });
  });

  // ── §7.4 ─────────────────────────────────────────────────────────────
  group('the live search counts only what actually arrived', () {
    BroadcastSearch search() => BroadcastSearch(
          productOrderId: 'o1',
          rideOrderId: 'ride1',
          startedAt: DateTime.now(),
        );

    test('partners called is CUMULATIVE across rounds', () {
      final s = search();
      s.applyRound(
          const BroadcastRound(index: 1, radiusKm: 3, notified: 9));
      s.applyRound(
          const BroadcastRound(index: 2, radiusKm: 6, notified: 8));
      expect(s.calledTotal, 17);
      expect(s.currentRound, 2);
      expect(s.radiusKm, 6);
    });

    test('a repeated event for the same round replaces, never double-counts',
        () {
      final s = search();
      s.applyRound(const BroadcastRound(index: 1, radiusKm: 3, notified: 9));
      s.applyRound(const BroadcastRound(index: 1, radiusKm: 3, notified: 9));
      expect(s.rounds.length, 1);
      expect(s.calledTotal, 9);
    });

    test('ridersNotified:0 is a real answer, and it says so', () {
      const row = BroadcastRound(index: 1, radiusKm: 3, notified: 0);
      expect(row.foundNobody, isTrue);
      final s = search()..applyRound(row);
      expect(s.calledTotal, 0);
    });

    test('rows are ordered by round, however they arrive', () {
      final s = search();
      s.applyRound(const BroadcastRound(index: 2, radiusKm: 6, notified: 4));
      s.applyRound(const BroadcastRound(index: 1, radiusKm: 3, notified: 2));
      expect(s.rounds.map((r) => r.index), [1, 2]);
    });

    test('the countdown is ONE 60s window from dispatch, not per round', () {
      final s = BroadcastSearch(
        productOrderId: 'o1',
        rideOrderId: 'r',
        startedAt: DateTime.now().subtract(const Duration(seconds: 25)),
      );
      s.applyRound(const BroadcastRound(index: 2, radiusKm: 6, notified: 3));
      expect(s.remaining.inSeconds, lessThanOrEqualTo(35));
      expect(s.remaining.inSeconds, greaterThan(30));
      expect(s.progress, greaterThan(0.3));
      expect(s.progress, lessThan(0.5));
    });

    test('progress is clamped, never negative and never past 1', () {
      final done = BroadcastSearch(
        productOrderId: 'o1',
        rideOrderId: 'r',
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(done.progress, 1.0);
      expect(done.remaining, Duration.zero);
    });

    test('exhausted is terminal for the search but NOT for the order', () {
      final s = search()..exhausted = true;
      expect(s.isSearching, isFalse);
      // Nothing here cancels or terminates the product order — the goods are
      // packed and the card offers collection instead (guide §7.6).
    });
  });

  // ── §5.3 ─────────────────────────────────────────────────────────────
  group('the quote is a UI state, not an error', () {
    test('feasible:false is a 200 carrying a reason', () {
      final q = DeliveryQuote.fromJson({
        'feasible': false,
        'reason': 'OUTSIDE_DELIVERY_RADIUS',
        'message': 'Delivery is only available within 12 km of the shop',
        'maxDistanceKm': 12,
      });
      expect(q.feasible, isFalse);
      expect(q.reason, 'OUTSIDE_DELIVERY_RADIUS');
      expect(q.maxDistanceKm, 12);
    });

    test('an ABSENT feasible key means feasible', () {
      final q = DeliveryQuote.fromJson({'deliveryFee': 84, 'distanceKm': 4.2});
      expect(q.feasible, isTrue);
    });

    test('a high fee warns and never blocks', () {
      final q = DeliveryQuote.fromJson({
        'feasible': true,
        'deliveryFee': 84,
        'economics': {
          'orderValue': 10,
          'feeToOrderRatio': 8.4,
          'feeExceedsOrderValue': true,
          'suggestion': 'Collecting it from the shop may be cheaper.',
        },
      });
      expect(q.shouldWarnAboutFee, isTrue);
      expect(q.feasible, isTrue, reason: 'a warning must never disable the order');
      expect(q.suggestion, contains('cheaper'));
    });

    test('the breakdown disclosure renders only the keys that came back', () {
      final q = DeliveryQuote.fromJson({
        'deliveryFee': 84,
        'breakdown': {
          'baseFee': 30,
          'baseKm': 2,
          'chargeableKm': 2.2,
          'perKmFee': 12,
          'peakMultiplier': 1,
          'minimumFeeApplied': false,
        },
      });
      final labels = q.breakdownRows.map((e) => e.key).toList();
      expect(labels, contains('Base fee'));
      expect(labels, contains('Extra distance'));
      // A multiplier of 1 and a false flag are noise, not information.
      expect(labels, isNot(contains('Peak multiplier')));
      expect(labels, isNot(contains('Minimum fee applied')));
    });

    test('etaRange is preferred over a single number', () {
      final q = DeliveryQuote.fromJson({
        'etaMinutes': 22,
        'etaRange': {'min': 17, 'max': 32},
      });
      expect(q.etaLabel, '17–32 min');
    });
  });

  // ── §8.1 ─────────────────────────────────────────────────────────────
  group('deadlines the delivery leg needs', () {
    test('dispatchBy and deliverBy are parsed and localised', () {
      final d = OrderDeadlines.fromJson({
        'dispatchBy': '2026-08-26T10:25:00Z',
        'deliverBy': '2026-08-26T11:30:00Z',
      });
      expect(d.dispatchBy, isNotNull);
      expect(d.deliverBy, isNotNull);
      expect(d.dispatchBy!.isUtc, isFalse, reason: 'rendered in local time');
      expect(d.isEmpty, isFalse);
    });

    test('all-null deadlines is empty — which is not the same as expired', () {
      expect(OrderDeadlines.fromJson(const {}).isEmpty, isTrue);
    });
  });

  // ── §9 ───────────────────────────────────────────────────────────────
  group('the states a sweeper produces at 3am', () {
    OrderLifecycle lc(Map<String, dynamic> o) => OrderLifecycle.fromJson({
          'orderStatus': 'ready',
          ...o,
        });

    test('a reminder is not a state change', () {
      expect(lc({'lastEvent': 'PRODUCT_ORDER_REMINDER'}).isReminderEvent,
          isTrue);
    });

    test('needs-attention never exposes its reason code', () {
      final l = lc({
        'lastEvent': 'PRODUCT_ORDER_NEEDS_ATTENTION',
        'reasonCode': 'PAYMENT_REVIEW',
      });
      expect(l.needsAttention, isTrue);
      // The section renders a fixed neutral string; the code stays in the
      // model, unreferenced by any widget.
      expect(l.reasonCode, 'PAYMENT_REVIEW');
    });

    test('needsAttention also arrives as an object on an action response', () {
      final m = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'orderStatus': 'ready',
          'needsAttention': {'flagged': true, 'reason': 'NO_RIDER'},
        }
      });
      expect(m.needsAttention, isTrue);
    });

    test('no rider found is a suggestion, not a cancellation', () {
      final l = lc({'suggestion': 'SELF_PICKUP_FALLBACK'});
      expect(l.isNoRider, isTrue);
      expect(l.isTerminal, isFalse);
      expect(l.isCancelledOrExpired, isFalse);
    });

    test('the 3-hour pickup decision changes the card shape', () {
      expect(
        lc({'lastEvent': 'PRODUCT_ORDER_PICKUP_OWNER_ACTION'})
            .needsPickupDecision,
        isTrue,
      );
    });

    test('a cancelled order that owes money is not finished business', () {
      final l = lc({
        'orderStatus': 'cancelled',
        'paymentState': 'refund_pending',
        'refundDue': true,
      });
      expect(l.isTerminal, isTrue);
      // Terminal, and still carrying actions — the section renders whatever
      // availableActions contains regardless.
      expect(l.refundDue, isTrue);
    });
  });

  // ── §10.1 ────────────────────────────────────────────────────────────
  group('error codes branch by code, never by message', () {
    test('the stale-state family is one decision, not five', () {
      for (final c in [
        'ACTION_NOT_AVAILABLE',
        'CONCURRENT_MODIFICATION',
        'PAYMENT_CONFLICT',
        'INVALID_SELLER_TRANSITION',
        'INVALID_PAYMENT_TRANSITION',
        'ORDER_TERMINAL',
      ]) {
        expect(OrderErrorCode.isStaleState(c), isTrue, reason: c);
      }
      expect(OrderErrorCode.isStaleState('UTR_ALREADY_USED'), isFalse);
    });

    test('field-level codes raise no toast — the sheet renders them inline',
        () {
      for (final c in [
        'UTR_REQUIRED',
        'SCREENSHOT_REQUIRED',
        'INVALID_AMOUNT',
        'PICKUP_CODE_REQUIRED',
        'PICKUP_CODE_MISMATCH',
        'REFUND_REFERENCE_REQUIRED',
        'REASON_REQUIRED',
        'INVALID_REASON',
        'INVALID_PREP_ETA',
        'CASH_NOT_COLLECTED',
      ]) {
        expect(OrderErrorCode.isFieldLevel(c), isTrue, reason: c);
      }
      expect(OrderErrorCode.isFieldLevel('ORDER_NOT_FOUND'), isFalse);
    });
  });

  // ── §2 · state merging ───────────────────────────────────────────────
  group('a refresh must not erase what only an action response carries', () {
    test('/actions merged over a Plane C state keeps the money', () {
      final withMoney = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'actor': 'owner',
          'orderStatus': 'accepted',
          'deliveryType': 'rider',
          'payment': {'amountDue': 500, 'amountPaid': 450, 'state': 'submitted'},
          'delivery': {
            'addressLine': '12 MG Road',
            'location': {
              'type': 'Point',
              'coordinates': [77.59, 12.97]
            }
          },
        }
      });

      final actionsOnly = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'actor': 'owner',
          'orderStatus': 'ready',
          'availableActions': ['CONFIRM_HANDOVER'],
        }
      });

      final merged = withMoney.mergedWith(actionsOnly);
      expect(merged.lifecycle.orderStatus, 'ready');
      expect(merged.availableActions, ['CONFIRM_HANDOVER']);
      expect(merged.paymentSummary?.amountDue, 500,
          reason: '/actions carries no money and must not wipe it');
      expect(merged.delivery?.hasCoordinates, isTrue,
          reason: 'the drop point is what dispatch reuses');
      expect(merged.deliveryType, 'rider');
    });

    test('a bare {pickupCode} response must not blank the card', () {
      final live = OrderActionsModel.fromJson({
        'data': {
          'orderId': 'o1',
          'actor': 'customer',
          'orderStatus': 'ready',
          'availableActions': ['VIEW_PICKUP_CODE', 'CONTACT_SHOP'],
          'lifecycle': {'orderStatus': 'ready', 'banner': 'Ready for pickup'},
        }
      });

      final codeOnly = OrderActionsModel.fromJson({
        'success': true,
        'data': {'orderId': 'o1', 'orderNumber': 'P1', 'pickupCode': 'K7QP4M'},
      });

      final merged = live.mergedWith(codeOnly);
      expect(merged.pickupCode, 'K7QP4M');
      expect(merged.lifecycle.banner, 'Ready for pickup',
          reason: 'a code lookup says nothing about the order state');
      expect(merged.availableActions, ['VIEW_PICKUP_CODE', 'CONTACT_SHOP']);
    });
  });
}
