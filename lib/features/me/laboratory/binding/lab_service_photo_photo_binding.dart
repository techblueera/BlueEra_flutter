import 'package:get/get.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_photo_controller.dart';

/// Registers [LabServicePhotoPhotoController].
///
/// `fenix: true`: it is also read outside the screen that owns it, so the
/// builder must survive a route pop and rebuild on the next Get.find.
///
/// NOTE: nothing calls Get.isRegistered<LabServicePhotoPhotoController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class LabServicePhotoPhotoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LabServicePhotoPhotoController>(
        () => LabServicePhotoPhotoController(),
        fenix: true);
  }
}
