import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/application_candidate_model.dart';
import 'package:BlueEra/core/api/model/user_application_listing_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:BlueEra/features/common/jobs/view/resume_preview.dart';
import 'package:BlueEra/features/common/jobs/widget/interview_schedule_dialog.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppliedJobController extends GetxController {
  Rx<ApiResponse> appliedAllJobResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> applicationJobCandidateJobResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> jobFeedBackPostResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> interviewFeedBackPostResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> clearAppliedJobPostResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> updateCandidateJobStatusResponse =
      ApiResponse.initial('Initial').obs;

  Rx<ApiResponse> candidateResumePreviewResponse =
      ApiResponse.initial('Initial').obs;

  /// SAVED JOB POST....
  RxList<UserApplications?> appliedJobListing = <UserApplications?>[].obs;
  RxList<ApplicationsCandidateList?> applicationsCandidateList =
      <ApplicationsCandidateList?>[].obs;
  Rx<JobDetails>? jobDetails = JobDetails().obs;

  // Checkbox selection variables
  // Add these properties for checkbox selection
  RxBool selectAll = false.obs;
  RxMap<String, bool> selectedApplications = <String, bool>{}.obs;

  // Get selected application IDs
  List<String> get selectedApplicationIds => selectedApplications.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

  // Get count of selected applications
  int get selectedCount =>
      selectedApplications.values.where((selected) => selected).length;

  // Toggle select all
  void toggleSelectAll() {
    selectAll.value = !selectAll.value;

    // Update all application selections
    if (selectAll.value) {
      for (var application in applicationsCandidateList) {
        if (application?.id != null) {
          selectedApplications[application!.id!] = true;
        }
      }
    } else {
      selectedApplications.clear();
    }
  }

  // Toggle select all
  void toggleSelectAllReschedule() {
    selectAll.value = !selectAll.value;

    // Update all application selections
    if (selectAll.value) {
      for (var application in applicationsCandidateList) {
        if (application?.interviewId != null) {
          selectedApplications[application!.interviewId!] = true;
        }
      }
    } else {
      selectedApplications.clear();
    }
  }

  // Toggle individual application selection
  void toggleApplicationSelection(String applicationId) {
    if (selectedApplications.containsKey(applicationId)) {
      selectedApplications[applicationId] =
          !selectedApplications[applicationId]!;
    } else {
      selectedApplications[applicationId] = true;
    }

    // Update selectAll based on whether all applications are selected
    selectAll.value = applicationsCandidateList.every((application) =>
        application?.id != null &&
        selectedApplications[application!.id!] == true);
  }

  // Toggle individual application selection
  void toggleApplicationSelectionReschedule(String interViewId) {
    if (selectedApplications.containsKey(interViewId)) {
      selectedApplications[interViewId] = !selectedApplications[interViewId]!;
    } else {
      selectedApplications[interViewId] = true;
    }

    // Update selectAll based on whether all applications are selected
    selectAll.value = applicationsCandidateList.every((application) =>
        application?.id != null &&
        selectedApplications[application!.interviewId!] == true);
  }

  // Clear selections
  void clearSelections() {
    selectAll.value = false;
    selectedApplications.clear();
  }

  // Reset selections when loading new data
  void resetSelections() {
    selectAll.value = false;
    selectedApplications.clear();
  }

  Future<void> getUserJobStatusController({required String? jobStatus}) async {
    try {
      appliedJobListing.clear();

      resetSelections(); // Reset selections when loading new data
      appliedAllJobResponse.value = ApiResponse.initial('Initial');

      ResponseModel responseModel =
          await JobRepo().getJobApplicationStatusRepo(status: jobStatus ?? "");

      if (responseModel.isSuccess) {
        UserApplicationListingModel applicationModel =
            UserApplicationListingModel.fromJson(responseModel.response?.data);
        appliedJobListing.addAll(applicationModel.applications ?? []);
        appliedAllJobResponse.value = ApiResponse.complete(responseModel);
      } else {
        appliedAllJobResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRO ${e}");
      appliedAllJobResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getCandidateJobStatusController({
    required String? jobStatus,
    required String? jobId,
  }) async {
    try {
      applicationsCandidateList.clear();
      resetSelections(); // Reset selections when loading new data
      applicationJobCandidateJobResponse.value = ApiResponse.initial('Initial');
      ResponseModel responseModel = await JobRepo()
          .getJobApplicationStatusServiceRepo(
              status: jobStatus ?? "", jobId: jobId ?? '');
      if (responseModel.isSuccess) {
        ApplicationCandidateModel applicationModel =
            ApplicationCandidateModel.fromJson(responseModel.response?.data);
        jobDetails?.value = applicationModel.jobDetails ?? JobDetails();

        applicationsCandidateList.addAll(applicationModel.applications ?? []);
        applicationJobCandidateJobResponse.value =
            ApiResponse.complete(responseModel);
      } else {
        applicationJobCandidateJobResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRO ${e}");
      applicationJobCandidateJobResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> jobFeedBackPostController(
      {required Map<String, dynamic>? bodyReq}) async {
    try {
      jobFeedBackPostResponse.value = ApiResponse.initial('Initial');
      ResponseModel responseModel =
          await JobRepo().feedbackPostRepo(reqParam: bodyReq ?? {});
      if (responseModel.isSuccess) {
        Get.back();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        jobFeedBackPostResponse.value = ApiResponse.complete(responseModel);
      } else {
        jobFeedBackPostResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRO ${e}");
      jobFeedBackPostResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> clearUserAppliedJobPostController(
      {required Map<String, dynamic>? bodyReq}) async {
    try {
      clearAppliedJobPostResponse.value = ApiResponse.initial('Initial');
      ResponseModel responseModel =
          await JobRepo().clearClosedAppliedRepo(reqParam: bodyReq ?? {});
      if (responseModel.isSuccess) {
        Get.back();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        clearAppliedJobPostResponse.value = ApiResponse.complete(responseModel);
      } else {
        clearAppliedJobPostResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRO ${e}");
      clearAppliedJobPostResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> updateCandidateJobStatusController(
      {required List<String>? applicationId,
      required String? applicationStatus}) async {
    try {
      updateCandidateJobStatusResponse.value = ApiResponse.initial('Initial');
      ResponseModel responseModel = await JobRepo()
          .updateCandidateJobStatusRepo(
              applicationId: applicationId,
              applicationStatus: applicationStatus);
      if (responseModel.isSuccess) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        updateCandidateJobStatusResponse.value =
            ApiResponse.complete(responseModel);
      } else {
        updateCandidateJobStatusResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRO ${e}");
      updateCandidateJobStatusResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> interviewFeedBackPostController(
      {required Map<String, dynamic>? bodyReq,
      required String? interviewId}) async {
    try {
      interviewFeedBackPostResponse.value = ApiResponse.initial('Initial');
      ResponseModel responseModel = await JobRepo().interviewFeedbackPostRepo(
          reqParam: bodyReq ?? {}, interviewID: interviewId ?? "");
      if (responseModel.isSuccess) {
        Get.back();
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        interviewFeedBackPostResponse.value =
            ApiResponse.complete(responseModel);
      } else {
        interviewFeedBackPostResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRO ${e}");
      interviewFeedBackPostResponse.value = ApiResponse.error('error');
    }
  }

  ///DOWNLOAD .
  Future<void> downloadCandidateList(
      {required String? jobID,
      required String? fileExtensions,
      required String? status}) async {
    // try {
    await JobRepo().downloadCandidateList(
        jobID: jobID, fileExtensions: fileExtensions, status: status);
    // } catch (e) {
    //   logs("GETTING ERRO ${e.toString()}");
    //   commonSnackBar(message: AppStrings.somethingWentWrong);
    // }
  }

  // Bulk actions for selected applications
  Future<void> bulkScheduleInterviews(
      BuildContext context, bool isRescheduleBulk) async {
    if (selectedApplicationIds.isEmpty) {
      commonSnackBar(message: "Please select at least one application");
      return;
    }
    logs("selectedApplicationIds==== ${selectedApplicationIds}");
    // For now, we'll just show the interview schedule dialog for the first selected application
    // In a real implementation, you might want to handle bulk scheduling differently
    if (selectedApplicationIds.isNotEmpty) {
      showInterviewScheduleDialog(context,
          applicationId: selectedApplicationIds, callBack: () {
        getCandidateJobStatusController(
            jobStatus: isRescheduleBulk
                ? AppConstants.InterviewScheduled
                : AppConstants.Shortlisted,
            jobId: jobDetails?.value.id);
      }, interviewId: '', isReschedule: isRescheduleBulk);
    }
  }

  Future<void> bulkSendMessage() async {
    commonSnackBar(message: "Coming soon");
    return;
  }

  Future<void> bulkSendAssignment() async {
    commonSnackBar(message: "Coming soon");
    return;

  }

  Future<void> bulkMarkNotInterested(BuildContext context) async {
    logs("logMsg");
    if (selectedApplicationIds.isEmpty) {
      commonSnackBar(message: "Please select at least one application");
      return;
    }

    await commonConformationDialog(
      context: context,
      text:
          "Are you sure you want to mark ${selectedApplicationIds.length} applications as not interested?",
      confirmCallback: () async {
        // Update status for each selected application
        await updateCandidateJobStatusController(
          applicationId: selectedApplicationIds,
          applicationStatus: AppConstants.Rejected,
        );

        // Refresh the list and clear selections
        getCandidateJobStatusController(
            jobStatus: jobDetails?.value.status, jobId: jobDetails?.value.id);
        clearSelections();
      },
      cancelCallback: () {
        Get.back();
      },
    );
  }

  Future<void> candidatePreviewResumeController(
      {required String? candidateResumeId}) async {
    try {
      candidateResumePreviewResponse.value = ApiResponse.initial('Initial');

      ///FOR NOW WE SET
      ResponseModel responseModel =
          await JobRepo().previewForAllPostRepo(reqParam: {
        ApiKeys.candidateResumeId: candidateResumeId,
        ApiKeys.template: "resumeTemplate1"
      });
      if (responseModel.isSuccess) {
        Get.to(ResumeWebPreview(
          htmlContent: '''${responseModel.response}''',
        ));
        candidateResumePreviewResponse.value =
            ApiResponse.complete(responseModel);
      } else {
        candidateResumePreviewResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      candidateResumePreviewResponse.value = ApiResponse.error('error');
    }
  }
}
