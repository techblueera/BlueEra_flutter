import 'package:get/get.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/reel/controller/reel_upload_details_controller.dart';

/// Bindings for the CreateMessagePostScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class CreateMessagePostScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReelUploadDetailsController>(
        () => ReelUploadDetailsController(),
        fenix: true);
    Get.lazyPut<TagUserController>(() => TagUserController(), fenix: true);
  }
}
