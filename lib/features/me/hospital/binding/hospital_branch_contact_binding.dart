import 'package:get/get.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_branch_contact_controller.dart';

/// Registers [HospitalBranchContactController] for [HospitalContactUs].
///
/// This screen is opened with Get.to (not a named route), so the binding is
/// passed at each call site. Every call site must pass it: without one the
/// screen's Get.find would throw.
class HospitalBranchContactBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HospitalBranchContactController>(
        () => HospitalBranchContactController());
  }
}
