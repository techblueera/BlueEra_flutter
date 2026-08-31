import 'package:get/get.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/controller/resume_controller.dart';

/// Bindings for the CreateResumeScreen route.
///
/// `fenix: true` where the controller is also read by something that can
/// outlive this route: GetX keeps the builder after a delete, so the next
/// Get.find rebuilds it (empty) instead of throwing.
///
/// App-wide controllers this screen also uses live in InitialBinding, not here.
class ResumeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResumeController>(() => ResumeController(), fenix: true);
    Get.lazyPut<ProfilePicController>(() => ProfilePicController(),
        fenix: true);
  }
}
