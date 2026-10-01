import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('the home feed outlives a channel or profile screen that opened first',
      () {
    final feed = FeedController.to;

    // What GetX does when the route that first registered it closes.
    Get.delete<FeedController>();

    expect(FeedController.to, same(feed));
  });

  test('logout drops it, so the next account never sees these feeds', () {
    final feed = FeedController.to;

    LogoutHelper.resetAccountControllers();

    expect(Get.isRegistered<FeedController>(), isFalse);
    expect(FeedController.to, isNot(same(feed)));
  });
}
