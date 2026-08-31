import 'package:get/get.dart';
import 'package:BlueEra/features/me/medical/controller/medical_gallery_controller.dart';

/// Registers [MedicalGalleryController].
///
/// `fenix: true`: it is also read outside the screen that owns it, so the
/// builder must survive a route pop and rebuild on the next Get.find.
///
/// NOTE: nothing calls Get.isRegistered<MedicalGalleryController>() — that was checked before
/// binding it. A binding (fenix especially) keeps the key registered, which would
/// permanently flip any such guard.
class MedicalGalleryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MedicalGalleryController>(() => MedicalGalleryController(),
        fenix: true);
  }
}
