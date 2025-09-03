import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/model/get_all_resumes_model.dart';
import 'package:BlueEra/features/common/auth/model/get_job_details_byId_model.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:BlueEra/features/common/jobs/view/show_resumes.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: unused_import
import 'create_job_post_controller.dart';

class JobDetailsScreenController extends GetxController{

  final JobRepo _repo = JobRepo();

  // final JOBID = Get.arguments

  RxBool isLoading = false.obs;
  RxString error = ''.obs;
  Rx<GetJobDetailsByIdModel?> jobDetails = Rx<GetJobDetailsByIdModel?>(null);
  Rx<GetAllResumesModel?> getResumes = Rx<GetAllResumesModel?>(null);
  Rx<ApiResponse> getSelfResumeSelectionResponse = ApiResponse.initial('Initial').obs;

  // final jobId = Get.find<CreateJobPostController>().jobID;

  @override
  void onClose() {
    // Clean up any resources if needed
    super.onClose();
  }

  void openMap(double latitude, double longitude) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      commonSnackBar(message: 'Could not open Google Maps');
    }
  }

  Future<void> fetchJobDetails(String jobId) async {// Prevent multiple simultaneous calls
    if (isLoading.value) {
      print("Already loading job details, skipping...");
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';


      final ResponseModel response = await _repo.getJobDetailsRepo(jobId: jobId);

      if (response.isSuccess && response.response?.data != null) {
        try {
          jobDetails.value = GetJobDetailsByIdModel.fromJson(response.response!.data);
        logs("is saved job=====${    jobDetails.value?.isSavedByUser}");
        } catch (parseError) {
          error.value = 'Error parsing job details: ${parseError.toString()}';
          jobDetails.value = null;
        }
      } else {
        error.value = response.message ?? 'Failed to fetch job details';
        jobDetails.value = null;
      }
    } catch (e) {
      error.value = 'Something went wrong: $e';
      jobDetails.value = null;
    } finally {
      // Ensure we're still mounted before updating state
      if (Get.isRegistered<JobDetailsScreenController>()) {
        isLoading.value = false;
        print("Loading state set to false");
      }
    }
  }

  Future<void> getAllResumesApi({required String jobId}) async {// Prevent multiple simultaneous calls
    if (isLoading.value) {
      return;
    }
    getSelfResumeSelectionResponse.value = ApiResponse.initial('Initial');

    try {
      isLoading.value = true;
      error.value = '';

      final ResponseModel response = await _repo.getAllResumesRepo();

      if (response.isSuccess && response.response?.data != null) {
        try {
          getResumes.value = GetAllResumesModel.fromJson(response.response!.data);
          // final userId = getResumes.value?.resumes?[0].userId ?? "";
          getSelfResumeSelectionResponse.value = ApiResponse.complete(response);

          Get.to(()=>ShowResumes(),
          arguments: {
            "jobId": jobId,
          });
        } catch (parseError) {
          getSelfResumeSelectionResponse.value = ApiResponse.error('error');

          error.value = 'Error parsing job details: ${parseError.toString()}';
          jobDetails.value = null;
        }
      } else {
        getSelfResumeSelectionResponse.value = ApiResponse.error('error');

        error.value = response.message ?? 'Failed to fetch job details';
        jobDetails.value = null;
      }
    } catch (e) {
      getSelfResumeSelectionResponse.value = ApiResponse.error('error');

      error.value = 'Something went wrong: $e';
      jobDetails.value = null;
    } finally {

      // Ensure we're still mounted before updating state
      if (Get.isRegistered<JobDetailsScreenController>()) {
        isLoading.value = false;
        print("Loading state set to false");
      }
    }
  }

}