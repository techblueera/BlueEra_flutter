import 'package:get/get.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step3.dart';

/// Registers [JobPostStep3Controller] for the CreateJobPostStep3 route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class JobPostStep3Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobPostStep3Controller>(() => JobPostStep3Controller());
  }
}
