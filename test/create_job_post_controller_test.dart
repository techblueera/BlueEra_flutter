import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/jobs/binding/create_job_post_binding.dart';
import 'package:BlueEra/features/common/jobs/controller/create_job_post_controller.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step3.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job_post_step_4.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

/// Returns [job] from the job-details endpoint.
class _FakeJobRepo extends JobRepo {
  _FakeJobRepo(this.job);

  final Map<String, dynamic> job;

  @override
  Future<ResponseModel> getJobDetailsRepo({required String jobId}) async =>
      ResponseModel(
        statusCode: 200,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {'job': job},
        ),
      );
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('a new job starts empty and not in edit mode', () {
    final c = Get.put(CreateJobPostController(repo: JobRepo()));

    expect(c.isEditMode.value, isFalse);
    expect(c.jobID.value, isEmpty);
    expect(c.selectedLanguages, ['English']);
  });

  test('editing loads the job into the form, perks included', () async {
    final c = Get.put(CreateJobPostController(
      editJobId: 'job1',
      repo: _FakeJobRepo({
        '_id': 'job1',
        'jobTitle': 'Chef',
        'companyName': 'Spice Hub',
        'jobType': 'Full-time',
        'workMode': 'On-site',
        'location': {'addressString': 'MG Road'},
        'compensation': {'type': 'Monthly', 'minSalary': 20000, 'maxSalary': 30000},
        // Saved by the app as jsonEncode(perks).
        'benefits': ['["Meals","Bonus"]'],
        'jobHighlights': ['Growth'],
      }),
    ));
    var revisions = 0;
    ever(c.formRevision, (_) => revisions++);
    await _settle();

    expect(c.isEditMode.value, isTrue);
    expect(c.jobID.value, 'job1');
    expect(c.jobTitleController.text, 'Chef');
    expect(c.companyNameController.text, 'Spice Hub');
    expect(c.addressEditController.text, 'MG Road');
    expect(c.minSalaryController.text, '20000');
    expect(c.maxSalaryController.text, '30000');
    expect(c.workMode.value, 'On-site');
    expect(c.selectedCompensationPerks, ['Meals', 'Bonus']);
    expect(c.selectedJobDescriptionPerks, ['Growth']);
    expect(revisions, 1);
  });

  test('the binding gives a new flow fresh controllers', () {
    CreateJobPostBinding().dependencies();
    final first = Get.find<CreateJobPostController>();
    Get.find<JobPostStep3Controller>().walkInInterview.value = 'Yes';

    // e.g. "Edit" on the preview at the end of the first flow.
    CreateJobPostBinding(createJobVia: 'profile').dependencies();

    expect(Get.find<CreateJobPostController>(), isNot(same(first)));
    expect(Get.find<JobPostStep3Controller>().walkInInterview.value, 'No');
    expect(Get.isRegistered<JobPostStep4Controller>(), isTrue);
  });
}
