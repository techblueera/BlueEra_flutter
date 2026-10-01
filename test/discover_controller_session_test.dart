import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('an ongoing ride outlives the booking screen that started it', () {
    final discover = DiscoverController.to;
    discover.fareCallAcceptedRiderId.value = 'rider-1';

    // What GetX does when the booking route that registered it closes.
    Get.delete<DiscoverController>();

    expect(DiscoverController.to, same(discover));
    expect(DiscoverController.to.fareCallAcceptedRiderId.value, 'rider-1');
  });

  test('logout drops it, so the next account has no ride', () {
    DiscoverController.to.fareCallAcceptedRiderId.value = 'rider-1';

    LogoutHelper.resetAccountControllers();

    expect(Get.isRegistered<DiscoverController>(), isFalse);
    expect(DiscoverController.to.fareCallAcceptedRiderId.value, isEmpty);
  });
}
