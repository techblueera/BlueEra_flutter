import 'package:get/get.dart';
import 'package:BlueEra/features/common/jobs/controller/application_card_controller.dart';

/// Registers [ApplicationsController] for [JobApplicationsScreen].
///
/// This screen is opened with Get.to (not a named route), so the binding is
/// passed at each call site. Every call site must pass it: without one the
/// screen's Get.find would throw.
class JobApplicationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApplicationsController>(() => ApplicationsController());
  }
}
