import 'package:BlueEra/core/api/apiService/order_service_api.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/me/product/model/order_checkout_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

OrderLifecycle _lifecycle({
  String status = 'placed',
  List<String> owner = const ['ACCEPT_ORDER', 'REJECT_ORDER'],
  List<String> customer = const ['CANCEL_ORDER', 'CONTACT_SHOP'],
  String? banner = 'Waiting for the shop to confirm',
}) =>
    OrderLifecycle.fromJson({
      'orderStatus': status,
      'ownerActions': owner,
      'customerActions': customer,
      'banner': banner,
    });

void main() {
  late OrderLifecycleController controller;

  setUp(() {
    Get.testMode = true;
    controller = Get.put(OrderLifecycleController(), permanent: true);
  });

  tearDown(Get.reset);

  group('seeding from a chat card', () {
    test('renders buttons with no network call', () {
      controller.seedFromLifecycle('o1', _lifecycle());

      final state = controller.stateOf('o1');
      expect(state, isNotNull);
      expect(state!.actionsFor(isOwner: true), ['ACCEPT_ORDER', 'REJECT_ORDER']);
      expect(state.actionsFor(isOwner: false), ['CANCEL_ORDER', 'CONTACT_SHOP']);
      expect(state.lifecycle.banner, 'Waiting for the shop to confirm');
    });

    test('does not clobber authoritative state unless forced', () {
      controller.seedFromLifecycle('o1', _lifecycle(status: 'placed'));
      // A second card build with stale metadata must not undo a newer state.
      controller.seedFromLifecycle('o1', _lifecycle(status: 'accepted'));
      expect(controller.stateOf('o1')!.lifecycle.orderStatus, 'placed');

      controller.seedFromLifecycle('o1', _lifecycle(status: 'accepted'),
          force: true);
      expect(controller.stateOf('o1')!.lifecycle.orderStatus, 'accepted');
    });

    test('remembers the vertical so a later refresh hits the right service',
        () {
      controller.seedFromLifecycle('g1', _lifecycle(),
          service: OrderServiceApi.groceryOrderService);
      expect(controller.serviceOf('g1'), 'grocery-service');
      // An unknown order falls back to the ported vertical, never to empty.
      expect(controller.serviceOf('unknown'), 'product-service');
    });
  });

  group('socket patches', () {
    test('a lifecycle event replaces the action lists', () {
      controller.seedFromLifecycle('o1', _lifecycle());

      controller.applySocketLifecycle('o1', {
        'orderStatus': 'accepted',
        'banner': 'Order accepted — ready in about 20 min',
        'ownerActions': ['MARK_READY', 'SET_PREP_ETA', 'CANCEL_ORDER'],
        'customerActions': ['CANCEL_ORDER', 'CONTACT_SHOP'],
      });

      final state = controller.stateOf('o1')!;
      expect(state.lifecycle.orderStatus, 'accepted');
      expect(state.lifecycle.banner, 'Order accepted — ready in about 20 min');
      expect(state.actionsFor(isOwner: true), contains('MARK_READY'));
      // The stale Accept button must be gone, not merged in.
      expect(state.actionsFor(isOwner: true), isNot(contains('ACCEPT_ORDER')));
    });

    test('a patch for an unseen order seeds it rather than dropping it', () {
      controller.applySocketLifecycle('new1', {
        'orderStatus': 'ready',
        'customerActions': ['VIEW_PICKUP_CODE'],
      });
      expect(controller.stateOf('new1')!.actionsFor(isOwner: false),
          ['VIEW_PICKUP_CODE']);
    });

    test('an empty orderId is ignored, not stored under ""', () {
      controller.applySocketLifecycle('', {'orderStatus': 'ready'});
      expect(controller.orders.containsKey(''), isFalse);
    });
  });

  group('busy keys', () {
    test('are scoped per (order, action), not per order', () {
      controller.busyKeys.add('o1:ACCEPT_ORDER');

      expect(controller.isBusy('o1', 'ACCEPT_ORDER'), isTrue);
      expect(controller.isBusy('o1', 'REJECT_ORDER'), isFalse);
      expect(controller.isBusy('o2', 'ACCEPT_ORDER'), isFalse);
      expect(controller.isOrderBusy('o1'), isTrue);
      expect(controller.isOrderBusy('o2'), isFalse);
    });
  });

  group('visible-order tracking', () {
    test('tracks and untracks cards for the resume/reconnect sweep', () {
      controller.trackVisibleOrder('o1');
      controller.trackVisibleOrder('o2',
          service: OrderServiceApi.foodOrderService);
      expect(controller.serviceOf('o2'), 'food-service');

      controller.untrackVisibleOrder('o1');
      // Untracking must not lose the remembered service — the card may come
      // back on screen.
      expect(controller.serviceOf('o2'), 'food-service');
    });

    test('an empty order id is never tracked', () {
      controller.trackVisibleOrder('');
      expect(controller.serviceOf(''), 'product-service');
    });
  });

  group('OrderCallResult.isStaleState', () {
    test('treats every "the other party moved first" code as a refresh cue',
        () {
      for (final code in [
        OrderErrorCode.actionNotAvailable,
        OrderErrorCode.concurrentModification,
        OrderErrorCode.paymentConflict,
        OrderErrorCode.orderTerminal,
      ]) {
        expect(OrderCallResult(ok: false, code: code).isStaleState, isTrue,
            reason: '$code should be a refresh cue, not a crash');
      }
    });

    test('a field-level or transport error is NOT a stale state', () {
      expect(
        const OrderCallResult(ok: false, code: OrderErrorCode.utrAlreadyUsed)
            .isStaleState,
        isFalse,
      );
      expect(
        const OrderCallResult(ok: false, code: OrderErrorCode.network)
            .isStaleState,
        isFalse,
      );
    });
  });

  group('CheckoutAttempt', () {
    test('one key survives repeated taps within an attempt', () {
      final attempt = CheckoutAttempt();
      attempt.begin();
      final first = attempt.key;
      expect(attempt.key, first, reason: 'a retry must reuse the same key');
      expect(attempt.key, first);
    });

    test('a NEW order gets a NEW key', () {
      final attempt = CheckoutAttempt();
      attempt.begin();
      final first = attempt.key;
      attempt.complete();
      attempt.begin();
      expect(attempt.key, isNot(first));
    });

    test('a caller that forgets begin() still gets retry safety', () {
      final attempt = CheckoutAttempt();
      final key = attempt.key;
      expect(key, isNotEmpty);
      expect(attempt.key, key);
    });

    test('complete() clears the attempt', () {
      final attempt = CheckoutAttempt();
      attempt.begin();
      expect(attempt.isActive, isTrue);
      attempt.complete();
      expect(attempt.isActive, isFalse);
    });
  });

  group('OrderDeliveryDetails', () {
    test('omits empty keys rather than sending nulls', () {
      final json = const OrderDeliveryDetails(
        addressLine: '12 MG Road',
        landmark: '',
        latitude: 12.97,
        longitude: 77.59,
        distanceKm: 4.2,
        feeEstimate: 84,
        etaMinutes: 22,
      ).toJson();

      expect(json['addressLine'], '12 MG Road');
      expect(json.containsKey('landmark'), isFalse);
      expect(json.containsKey('city'), isFalse);
      expect(json['distanceKm'], 4.2);
      expect(json['feeEstimate'], 84);
      expect(json['etaMinutes'], 22);
    });

    test('an all-empty block reports itself as empty so it is not sent', () {
      expect(const OrderDeliveryDetails().isEmpty, isTrue);
    });
  });
}
