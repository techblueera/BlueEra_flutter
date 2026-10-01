import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step3.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step_4.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:get/get.dart';

/// Scopes the job post flow's controllers to its first route
/// (CreateJobPostScreen). Steps 2–4 and the preview are pushed on top and share
/// them, so going back a step keeps that step's answers; GetX deletes them all
/// when the flow's first route closes, so the next job starts empty.
///
/// The step controllers are created here, not lazily: GetX ties an instance to
/// the route that is on top when it is first created, which for a lazy one
/// would be the step's own route.
class CreateJobPostBinding extends Bindings {
  CreateJobPostBinding({this.editJobId = '', this.createJobVia = ''});

  /// The job being edited, or empty for a new one.
  final String editJobId;
  final String createJobVia;

  @override
  void dependencies() {
    // The preview at the end of a flow can open another flow ("Edit") on top
    // of it. `Get.put` would hand the new flow the old flow's instances.
    deleteIfRegistered<CreateJobPostController>();
    deleteIfRegistered<JobPostStep3Controller>();
    deleteIfRegistered<JobPostStep4Controller>();
    Get.put(CreateJobPostController(
        repo: JobRepo(), editJobId: editJobId, createJobVia: createJobVia));
    Get.put(JobPostStep3Controller());
    Get.put(JobPostStep4Controller());
  }
}
