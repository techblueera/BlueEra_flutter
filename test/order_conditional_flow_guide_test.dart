import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_track_model.dart';
import 'package:BlueEra/features/chat/auth/model/order_vertical_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

/// The deltas `ORDER_UI_CONDITIONAL_FLOW_GUIDE.md` (verified against live
/// production on 27 Aug 2026) introduces over the v3 round.
///
/// Everything here is a fact the app previously had **wrong**, not a new
/// feature — which is exactly why each one is pinned: they were all inherited
/// from an older document that read the production data through a filter that
/// hid it.
void main() {
  /// A `/track` body with `riderLeg` supplied in whatever shape the caller
  /// wants to test — including the bare String the service actually sends.
  Map<String, dynamic> trackBody({dynamic riderLeg, dynamic rider}) => {
        'success': true,
        'data': {
          'orderId': 'o1',
          'orderStatus': 'dispatched',
          'deliveryType': 'rider',
          if (riderLeg != null) 'riderLeg': riderLeg,
          if (rider != null) 'rider': rider,
        },
      };

  OrderTrackModel track(Map<String, dynamic> body) =>
      OrderTrackModel.fromJson(body, fallbackOrderId: 'o1');

  group('§14.12 · riderLeg is a String, not an object', () {
    test('a bare status string is read, not silently dropped', () {
      // The bug: `_map('accepted')` is null, so the leg never reached the UI
      // and the customer's rider copy could never be chosen.
      final r = track(trackBody(riderLeg: 'accepted')).rider;
      expect(r, isNotNull);
      expect(r!.status, 'accepted');
    });

    test('every leg in the rider vocabulary survives the trip', () {
      for (final leg in [
        RiderLegStatus.pending,
        RiderLegStatus.accepted,
        RiderLegStatus.paymentPending,
        RiderLegStatus.confirmed,
        RiderLegStatus.inProgress,
        RiderLegStatus.pickedUp,
        RiderLegStatus.completed,
        RiderLegStatus.rejected,
        RiderLegStatus.cancelled,
      ]) {
        expect(track(trackBody(riderLeg: leg)).rider?.status, leg, reason: leg);
      }
    });

    test('an object riderLeg still parses — this is additive', () {
      final r = track(trackBody(riderLeg: {'name': 'A', 'status': 'picked-up'}))
          .rider;
      expect(r?.name, 'A');
      expect(r?.status, 'picked-up');
    });

    test('a richer `rider` block wins over the leg string it sits beside', () {
      final r = track(trackBody(
        riderLeg: 'accepted',
        rider: {'name': 'Ramesh', 'status': 'picked-up'},
      )).rider;
      expect(r?.name, 'Ramesh');
      expect(r?.status, 'picked-up');
    });

    test('an empty leg string is not a rider', () {
      // Otherwise every self-pickup order carrying `riderLeg: ""` would grow a
      // rider block with nothing in it (§6.3 S10).
      expect(track(trackBody(riderLeg: '')).rider, isNull);
      expect(track(trackBody(riderLeg: '   ')).rider, isNull);
    });

    test('no leg and no rider is still no rider block', () {
      expect(track(trackBody()).rider, isNull);
    });
  });

  group('§18.5 · the customer copy differs per leg', () {
    test('cancelled and rejected never share a sentence', () {
      final rejected = RiderLegStatus.customerCopy(RiderLegStatus.rejected);
      final cancelled = RiderLegStatus.customerCopy(RiderLegStatus.cancelled);
      expect(rejected, isNotNull);
      expect(cancelled, isNotNull);
      // "No rider accepted this order" ≠ "Order cancelled". Collapsing them
      // tells the customer their order is dead when it is still fulfillable.
      expect(rejected, isNot(cancelled));
    });

    test('in-progress and picked-up both read as on the way', () {
      expect(
        RiderLegStatus.customerCopy(RiderLegStatus.inProgress),
        RiderLegStatus.customerCopy(RiderLegStatus.pickedUp),
      );
    });

    test('a leg this build has never heard of draws nothing', () {
      // Never echo a raw code at a customer.
      expect(RiderLegStatus.customerCopy('quantum-dispatched'), isNull);
      expect(RiderLegStatus.customerCopy(null), isNull);
      expect(RiderLegStatus.customerCopy(''), isNull);
    });

    test('case and padding do not defeat the lookup', () {
      expect(RiderLegStatus.customerCopy('  Picked-Up '),
          RiderLegStatus.customerCopy(RiderLegStatus.pickedUp));
    });
  });

  group('§12 · the four facts the old audit got wrong', () {
    test('fact 2 · grocery emits socket events, so it is not focus-only', () {
      expect(
          OrderVerticalCapabilities.hasSocketUpdates(
              OrderServiceApi.groceryOrderService),
          isTrue);
    });

    test('all four grocery event names exist to subscribe to', () {
      expect(ChatEmitEvents.newSelfPickupOrderReceived,
          'newSelfPickupOrderReceived');
      expect(ChatEmitEvents.selfPickupOrderReady, 'selfPickupOrderReady');
      expect(ChatEmitEvents.groceryOrderDispatched, 'groceryOrderDispatched');
      expect(ChatEmitEvents.groceryOrderCompleted, 'groceryOrderCompleted');
    });

    test('the correction did not hand grocery a lifecycle it lacks', () {
      // Sockets and `/actions` are independent capabilities. Grocery gained
      // the first and still does not have the second.
      const grocery = OrderServiceApi.groceryOrderService;
      expect(OrderVerticalCapabilities.hasLifecycle(grocery), isFalse);
      expect(OrderVerticalCapabilities.hasActions(grocery), isFalse);
      expect(OrderVerticalCapabilities.hasTrack(grocery), isTrue);
    });

    test('a vertical nobody has ported gains nothing from this', () {
      expect(
          OrderVerticalCapabilities.hasSocketUpdates(
              OrderServiceApi.medicalOrderService),
          isFalse);
    });
  });

  group('§7 · ORDER_TERMINAL is not the truth about a refund', () {
    test('both halves of the refund handshake are recognised', () {
      // A refund exists *because* the order is dead: the money conversation
      // outlives it. These two are the only actions that legitimately run on
      // a terminal order.
      expect(
          OrderLifecycleController.isRefundAction(OrderAction.markRefundSent),
          isTrue);
      expect(
          OrderLifecycleController.isRefundAction(
              OrderAction.confirmRefundReceived),
          isTrue);
    });

    test('nothing else is treated as a refund', () {
      for (final a in [
        OrderAction.cancelOrder,
        OrderAction.confirmHandover,
        OrderAction.submitPayment,
        OrderAction.verifyPayment,
        OrderAction.markReady,
        null,
        '',
        'SOMETHING_NEWER',
      ]) {
        expect(OrderLifecycleController.isRefundAction(a), isFalse,
            reason: '$a');
      }
    });

    test('ORDER_TERMINAL is still a stale-state code for everything else', () {
      // The special case is about which *copy* a refund gets, not about
      // reclassifying the code. Nothing below may change.
      expect(OrderErrorCode.isStaleState(OrderErrorCode.orderTerminal), isTrue);
      expect(OrderErrorCode.isFieldLevel(OrderErrorCode.orderTerminal),
          isFalse);
    });
  });

  group('§12 · grocery has no server clock, so one is derived', () {
    final placed = DateTime(2026, 8, 27, 10, 0);
    const grocery = OrderServiceApi.groceryOrderService;

    // `createdAt` is a positional-style override so a test can pass a real
    // null; a `?? placed` default would make the null case untestable.
    DateTime? derive({
      String service = grocery,
      String? status = 'placed',
      bool withCreatedAt = true,
    }) =>
        OrderVerticalCapabilities.derivedPlacedExpiry(
          service: service,
          orderStatus: status,
          createdAt: withCreatedAt ? placed : null,
        );

    test('an hour after it was placed, and not a minute else', () {
      expect(derive(), placed.add(const Duration(hours: 1)));
      expect(OrderVerticalCapabilities.groceryPlacedWindow,
          const Duration(hours: 1));
    });

    test('only at placed — no other stage gets an invented clock', () {
      for (final s in [
        'accepted',
        'in-progress',
        'ready',
        'dispatched',
        'completed',
        'cancelled',
        'expired',
        null,
      ]) {
        expect(derive(status: s), isNull, reason: '$s');
      }
    });

    test('no other vertical derives anything — they have real deadlines', () {
      for (final s in [
        OrderServiceApi.productOrderService,
        OrderServiceApi.foodOrderService,
        OrderServiceApi.medicalOrderService,
      ]) {
        expect(derive(service: s), isNull, reason: s);
      }
    });

    test('no createdAt draws nothing rather than counting from now', () {
      // A clock anchored to "now" would restart on every rebuild and mean
      // nothing at all.
      expect(derive(withCreatedAt: false), isNull);
    });
  });
}
