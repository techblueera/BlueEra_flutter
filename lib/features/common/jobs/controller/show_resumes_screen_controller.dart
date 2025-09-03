import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/model/get_resume_by_id_model.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:BlueEra/features/common/jobs/view/job_qna_screen.dart';
import 'package:get/get.dart';

class ShowResumesScreenController extends GetxController{

  Rx<GetResumeById?> getResumeById = Rx<GetResumeById?>(null);
  final JobRepo _repo = JobRepo();
  RxBool isLoading = false.obs;
  RxString error = ''.obs;



  Future<void> getResumeByIdApi({required String resumeId,  required String jobId}) async {
    if (isLoading.value) {
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      final ResponseModel response = await _repo.getResumeByIdRepo(resumeId: resumeId);

      if (response.isSuccess && response.response?.data != null) {
        try {
          getResumeById.value = GetResumeById.fromJson(response.response!.data);
          commonSnackBar(message: "Resume submitted successfully!");
          Get.to(() => JobQNAScreen(),arguments: {
            "jobId":jobId,
            "resumeId":resumeId
          }

            ,);        } catch (parseError) {
          error.value = 'Error parsing job details: ${parseError.toString()}';
          commonSnackBar(message: "Error submitting resume: ${parseError.toString()}");

          getResumeById.value = null;
        }
      } else {
        error.value = response.message ?? 'Please select a resume first';
        commonSnackBar(message: response.message);
        getResumeById.value = null;
      }
    } catch (e) {
      print("Exception in fetchJobDetails: $e");
      print("Exception stack trace: ${e.toString()}");
      error.value = 'Something went wrong: $e';
      getResumeById.value = null;
    } finally {

    }
  }
}