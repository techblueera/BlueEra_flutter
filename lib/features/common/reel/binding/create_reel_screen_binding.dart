import 'package:get/get.dart';
import 'package:BlueEra/features/common/reel/controller/reel_upload_details_controller.dart';

/// Bindings for the CreateReelScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class CreateReelScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReelUploadDetailsController>(
        () => ReelUploadDetailsController(),
        fenix: true);
  }
}
