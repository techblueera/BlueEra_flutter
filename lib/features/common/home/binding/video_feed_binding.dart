import 'package:get/get.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_feed_controller.dart';

/// Registers [VideoFeedController].
///
/// Owned by a single screen; nothing else reads it.
///
/// NOTE: nothing calls Get.isRegistered<VideoFeedController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class VideoFeedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoFeedController>(() => VideoFeedController());
  }
}
