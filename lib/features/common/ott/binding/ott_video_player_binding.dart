import 'package:get/get.dart';
import 'package:BlueEra/features/common/ott/controller/ott_video_player_controller.dart';

/// Registers [OttVideoPlayerController].
///
/// Owned by a single screen; nothing else reads it.
///
/// NOTE: nothing calls Get.isRegistered<OttVideoPlayerController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class OttVideoPlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OttVideoPlayerController>(() => OttVideoPlayerController());
  }
}
