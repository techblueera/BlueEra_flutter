import 'package:get/get.dart';
import 'package:BlueEra/features/me/school/controller/campus_life_controller.dart';

/// Registers [CampusLifeController] for [CampusLifeListingScreen].
///
/// This screen is opened with Get.to (not a named route), so the binding is
/// passed at each call site. Every call site must pass it: without one the
/// screen's Get.find would throw.
class CampusLifeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CampusLifeController>(() => CampusLifeController());
  }
}
