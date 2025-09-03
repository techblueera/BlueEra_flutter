import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

class JobRepo extends BaseService {
  /// JOB POST
  Future<ResponseModel> jobPostRepo({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      jobPost,
      isMultipart: true,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> jobPostStep2Repo({
    required String jobId,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      jobPostStep2(jobId),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> jobPostStep3Repo({
    required String jobId,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      jobPostStep3(jobId),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> jobPostStep4Repo({
    required String jobId,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      jobPostStep4(jobId),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> updateJobPostDetailsRepo({
    required String jobId,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      updateJobDetails(jobId),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> publishJobRepo({
    required String jobId,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().patchHTTP(
      publishJob(jobId),
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// GET All JOBS
  Future<ResponseModel> getAllJobsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      ((accountTypeGlobal.toUpperCase() == AppConstants.business))
          ? "$getAllJobs?postedBy=$userId"
          : "$getAllJobs?status=Open",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// GET JOB DETAILS BY ID
  Future<ResponseModel> getJobDetailsRepo({required String jobId}) async {
    final response = await ApiBaseHelper().getHTTP(
      getJobDetails(jobId),
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// GET All RESUMES
  Future<ResponseModel> getAllResumesRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      getAllResumes,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// GET RESUME DETAILS BY ID
  Future<ResponseModel> getResumeByIdRepo({required String resumeId}) async {
    final response = await ApiBaseHelper().getHTTP(
      getResumeById(resumeId),
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// SUBMIT NEW JOB APPLICATION
  Future<ResponseModel> submitNewJobApplicationRepo({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      jobApplication,
      isMultipart: false,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// SAVED JOB POST
  Future<ResponseModel> savedJobPostRepo({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      savedJob,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  ///DELETE SAVED POST
  Future<ResponseModel> savedJobPostDeleteRepo({
    required String jobId,
  }) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "${savedJob}/$jobId",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  ///GET SAVED POST
  Future<ResponseModel> getSavedJobPostRepo() async {
    final response = await ApiBaseHelper().getHTTP("${savedJob}",
        onError: (error) {}, onSuccess: (res) {}, showProgress: true);
    return response;
  }

  /// SUBMIT NEW JOB APPLICATION
  Future<ResponseModel> getJobApplicationStatusRepo({
    required String status,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      status.isNotEmpty ? "${jobApplication}?status=$status" : jobApplication,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// POST JOB FEEDBACK APPLICATION
  Future<ResponseModel> feedbackPostRepo({
    required Map<String, dynamic> reqParam,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      jobServiceFeedback,
      params: reqParam,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// CLEAR JOB POST WHERE USER APPLIED...
  Future<ResponseModel> clearClosedAppliedRepo({
    required Map<String, dynamic> reqParam,
  }) async {
    final response = await ApiBaseHelper().patchHTTP(
      applicationBulkClear,
      params: reqParam,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// SUBMIT NEW JOB APPLICATION
  Future<ResponseModel> getJobApplicationStatusServiceRepo({
    required String status,
    required String jobId,
  }) async {
    final response = await ApiBaseHelper().getHTTP(
      status.isNotEmpty
          ? "${applicationJobService}${jobId}?status=$status"
          : "${applicationJobService}$jobId",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  ///UPDATE CANDIDATE JOB STATUS....
  Future<ResponseModel> updateCandidateJobStatusRepo({
    required List<String>? applicationId,
    required String? applicationStatus,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "${jobApplicationStatusBulk}",
      params: {ApiKeys.status: applicationStatus,"applicationIds":applicationId},
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  ///UPDATE CANDIDATE JOB STATUS....
  Future<ResponseModel> scheduleInterViewRepo(
      {required Map<String, dynamic> reqParam}) async {
    final response = await ApiBaseHelper().postHTTP(
      jobServiceInterviews,
      params: reqParam,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  ///Reschedule CANDIDATE INTERVIEW STATUS....
  Future<ResponseModel> rescheduleInterViewRepo(
      {required Map<String, dynamic> reqParam,
    }) async {
    final response = await ApiBaseHelper().putHTTP(
      "${jobServiceInterviewsReschedule}",
      params: reqParam,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// POST JOB FEEDBACK APPLICATION
  Future<ResponseModel> interviewFeedbackPostRepo({
    required Map<String, dynamic> reqParam,
    required String interviewID,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "${jobServiceInterviewsFeedback}$interviewID/feedback",
      params: reqParam,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> downloadCandidateList(
      {required String? jobID,
      required String? fileExtensions,
      required String? status}) async {
    return await ApiBaseHelper().postFileDownloadHTTP(
      (status?.isNotEmpty??false)? "${jobApplicationJob}$jobID/export?format=$fileExtensions&status=$status":"${jobApplicationJob}$jobID/export?format=$fileExtensions",
      isGetReq: true,
      successMessage: "Candidate List Download successfully",
      fileExtensions: fileExtensions,
      containerName: '',
    );
  }

  /// SEARCH JOBS
  Future<ResponseModel> searchJobsRepo({required String query, String? status, int limit = 10, int page = 1}) async {
    // Build the URL with query parameters
    String url = "$jobSearch?query=$query&limit=$limit&page=$page";
    
    // Add status filter if provided
    if (status != null && status.isNotEmpty && status != '') {
    // if (status != null && status.isNotEmpty && status != 'all') {
      url += "&status=$status";
    }
    
    final response = await ApiBaseHelper().getHTTP(
      url,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// GET SCHEDULE JOBS
  Future<ResponseModel> getScheduleInterviewJobsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      "$jobWithScheduleInterview",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// GET CANDIDATE SCHEDULE JOBS LISTING
  Future<ResponseModel> getCandidateScheduleInterviewJobsRepo() async {
    final response = await ApiBaseHelper().getHTTP(
      "$candidateWithScheduleInterview",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }
  /// POST JOB FEEDBACK APPLICATION
  Future<ResponseModel> previewForAllPostRepo({
    required Map<String, dynamic> reqParam,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "${previewForAll}",
      params: reqParam,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }
}
