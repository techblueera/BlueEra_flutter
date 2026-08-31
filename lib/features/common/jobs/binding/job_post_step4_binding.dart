import 'package:get/get.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step_4.dart';

/// Registers [JobPostStep4Controller] for the CreateJobPostStep4 route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class JobPostStep4Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobPostStep4Controller>(() => JobPostStep4Controller());
  }
}
