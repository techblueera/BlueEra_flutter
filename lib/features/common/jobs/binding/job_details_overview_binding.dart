import 'package:get/get.dart';
import 'package:BlueEra/features/common/jobs/controller/job_details_overview_screen_controller.dart';

/// Registers [JobDetailsOverviewController] for the JobDetailsOverviewScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class JobDetailsOverviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobDetailsOverviewController>(
        () => JobDetailsOverviewController());
  }
}
