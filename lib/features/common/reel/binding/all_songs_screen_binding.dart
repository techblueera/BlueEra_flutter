import 'package:get/get.dart';
import 'package:BlueEra/features/common/reel/controller/song_controller.dart';

/// Bindings for the allSongsScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class AllSongsScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SongController>(() => SongController(), fenix: true);
  }
}
