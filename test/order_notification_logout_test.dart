import 'dart:io';

import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/active_orders_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_broadcast_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/notification_chat/controller/blueera_notification_controller.dart';
import 'package:BlueEra/features/chat/view/call_screen/rider_call/ride_navigation_overlay_controller.dart';
import 'package:BlueEra/features/common/notification/service/notification_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

void main() {
  // The notification controllers hydrate from Hive boxes on init.
  setUpAll(() => Hive.init(Directory.systemTemp.createTempSync().path));
  setUp(Get.reset);
  tearDown(Get.reset);

  test('logout drops the order and notification state', () {
    ActiveOrdersController.instance;
    OrderBroadcastController.instance;
    OrderLifecycleController.instance;
    BlueEraNotificationController.to;
    NotificationCacheService.to;

    LogoutHelper.resetAccountControllers();

    expect(Get.isRegistered<ActiveOrdersController>(), isFalse);
    expect(Get.isRegistered<OrderBroadcastController>(), isFalse);
    expect(Get.isRegistered<OrderLifecycleController>(), isFalse);
    expect(Get.isRegistered<BlueEraNotificationController>(), isFalse);
    expect(Get.isRegistered<NotificationCacheService>(), isFalse);
  });

  test('logout clears the ride overlay but keeps the instance', () {
    final overlay = Get.put(RideNavigationOverlayController(), permanent: true);
    overlay.isOverlayVisible.value = true;
    overlay.customerName.value = 'Previous rider';

    LogoutHelper.resetAccountControllers();

    expect(Get.find<RideNavigationOverlayController>(), same(overlay));
    expect(overlay.isOverlayVisible.value, isFalse);
    expect(overlay.customerName.value, isEmpty);
  });
}
