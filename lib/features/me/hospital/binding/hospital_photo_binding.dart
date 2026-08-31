import 'package:get/get.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_photo_controller.dart';

/// Registers [HospitalPhotoController] for [HospitalPhotosScreen].
///
/// This screen is opened with Get.to (not a named route), so the binding is
/// passed at each call site. Every call site must pass it: without one the
/// screen's Get.find would throw.
class HospitalPhotoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HospitalPhotoController>(() => HospitalPhotoController());
  }
}
