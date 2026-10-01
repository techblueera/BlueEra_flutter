import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('one playback manager, and its mute choice, for the whole session', () {
    final manager = SimplePriorityVideoManager.to;
    manager.isMuted.value = true;

    // What GetX does when the route that first registered it closes (e.g. a
    // channel whose feed card was the first video on screen).
    Get.delete<SimplePriorityVideoManager>();

    expect(SimplePriorityVideoManager.to, same(manager));
    expect(SimplePriorityVideoManager.to.isMuted.value, isTrue);
  });
}
