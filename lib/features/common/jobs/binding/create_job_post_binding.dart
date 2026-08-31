import 'package:get/get.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';

/// Registers [CreateJobPostController] for the CreateJobPostScreen route.
///
/// lazyPut (not put): the controller is built when the screen first reads it
/// and disposed with the route, instead of being re-registered on every
/// widget construction the way the old field initialiser did.
class CreateJobPostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateJobPostController>(() => CreateJobPostController());
  }
}
