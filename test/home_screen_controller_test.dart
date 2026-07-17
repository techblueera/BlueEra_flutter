import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('HomeScreenController.to', () {
    test('resolves when nothing has been registered', () {
      // FeedScreen is embedded in routes that never Get.put this controller;
      // a bare Get.find there threw "HomeScreenController not found".
      expect(Get.isRegistered<HomeScreenController>(), isFalse);
      expect(HomeScreenController.to.headerOffset.value, 0.0);
    });

    test('returns the same instance across calls, sharing header state', () {
      HomeScreenController.to.headerOffset.value = 1.0;

      expect(HomeScreenController.to, same(HomeScreenController.to));
      expect(HomeScreenController.to.headerOffset.value, 1.0);
    });

    test('reuses an instance registered by an earlier screen', () {
      final existing = Get.put(HomeScreenController());

      expect(HomeScreenController.to, same(existing));
    });

    test('survives a route-scoped cleanup of non-permanent controllers', () {
      final first = HomeScreenController.to;

      // What SmartManagement.full does when the registering route is popped.
      Get.delete<HomeScreenController>();

      expect(HomeScreenController.to, same(first));
    });
  });
}
