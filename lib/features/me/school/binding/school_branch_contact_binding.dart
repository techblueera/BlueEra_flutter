import 'package:get/get.dart';
import 'package:BlueEra/features/me/school/controller/branch_contact_controller.dart';

/// Registers [BranchContactController] for [SchoolContactUs].
///
/// This screen is opened with Get.to (not a named route), so the binding is
/// passed at each call site. Every call site must pass it: without one the
/// screen's Get.find would throw.
class SchoolBranchContactBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BranchContactController>(() => BranchContactController());
  }
}
