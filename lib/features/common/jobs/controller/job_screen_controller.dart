import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/get_saved_job_model.dart';
import 'package:BlueEra/core/api/model/user_candidate_schedule_res.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/model/get_all_jobs_model.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:get/get.dart';

class JobScreenController extends GetxController {
  RxBool isHeaderVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;

  JobRepo _jobRepo = JobRepo();
  GetAllJobPostsModel? jobsModel;
  RxList<Jobs>? jobsData = <Jobs>[].obs;
  final RxBool isLoading = true.obs;
  Rx<ApiResponse> saveJobPostResponse = ApiResponse
      .initial('Initial')
      .obs;
  Rx<ApiResponse> saveJobPostDeleteResponse =
      ApiResponse
          .initial('Initial')
          .obs;
  Rx<ApiResponse> getSaveJobPostResponse = ApiResponse
      .initial('Initial')
      .obs;
  Rx<ApiResponse> getBusinessScheduleJobPostResponse =
      ApiResponse
          .initial('Initial')
          .obs;
  Rx<ApiResponse> getCandidateSelfScheduleJobPostResponse =
      ApiResponse
          .initial('Initial')
          .obs;


  Future<void> getAllJobsApi() async {
    try {
      isLoading.value = true;
      final response = await _jobRepo.getAllJobsRepo();
      if (response.isSuccess) {
        final rawData = response.response!.data;
        // Handle different response structures
        Map<String, dynamic> jobData;
        if (rawData['data'] != null &&
            rawData['data'] is Map<String, dynamic>) {
          jobData = {
            'message': rawData['message'],
            ...rawData['data'],
          };
        } else {
          jobData = Map<String, dynamic>.from(rawData);
        }
        jobsData?.clear();
        jobsModel = GetAllJobPostsModel.fromJson(jobData);
        jobsData?.value = jobsModel?.jobs ?? [];
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateJobPostDetailsApi(
      {required String jobId, required Map<String, dynamic> params}) async {
    try {
      final response = await _jobRepo.updateJobPostDetailsRepo(
        jobId: jobId,
        params: params,
      );

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      print('Exception in updateJobPostDetailsApi: $e');
      print('Exception stack trace: ${e.toString()}');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  /// SAVED JOB POST....

  Future<void> savedJobPostController({required String? jobId}) async {
    try {
      saveJobPostResponse.value = ApiResponse.initial('Initial');

      ResponseModel responseModel =
      await JobRepo().savedJobPostRepo(params: {ApiKeys.jobId: jobId});
      if (responseModel.isSuccess) {
        saveJobPostResponse.value = ApiResponse.complete(responseModel);
      } else {
        saveJobPostResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      saveJobPostResponse.value = ApiResponse.error('error');
    }
  }

  ///DELETE SAVED JOB POST....
  Future<void> savedJobDeleteController({required String? jobId}) async {
    try {
      saveJobPostDeleteResponse.value = ApiResponse.initial('Initial');

      ResponseModel responseModel =
      await JobRepo().savedJobPostDeleteRepo(jobId: jobId ?? "");
      if (responseModel.isSuccess) {
        saveJobPostDeleteResponse.value = ApiResponse.complete(responseModel);
      } else {
        saveJobPostDeleteResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      saveJobPostDeleteResponse.value = ApiResponse.error('error');
    }
  }

  /// SAVED JOB POST....
  RxList<SavedJobs?> saveJobsList = <SavedJobs?>[].obs;

  Future<void> getSavedJobController() async {
    try {
      saveJobsList.clear();
      getSaveJobPostResponse.value = ApiResponse.initial('Initial');
      ResponseModel responseModel = await JobRepo().getSavedJobPostRepo();
      if (responseModel.isSuccess) {
        GetSavedJobModel savedJobModel =
        GetSavedJobModel.fromJson(responseModel.response?.data);
        saveJobsList.addAll(savedJobModel.savedJobs ?? []);
        getSaveJobPostResponse.value = ApiResponse.complete(responseModel);
      } else {
        getSaveJobPostResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getSaveJobPostResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getBusinessScheduleJobController() async {
    try {
      saveJobsList.clear();
      getBusinessScheduleJobPostResponse.value = ApiResponse.initial('Initial');
      ResponseModel responseModel =
      await JobRepo().getScheduleInterviewJobsRepo();
      if (responseModel.isSuccess) {
        jobsData?.clear();
        jobsModel = GetAllJobPostsModel.fromJson(responseModel.response?.data);
        jobsData?.value = jobsModel?.jobs ?? [];

        getBusinessScheduleJobPostResponse.value =
            ApiResponse.complete(responseModel);
      } else {
        getBusinessScheduleJobPostResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getBusinessScheduleJobPostResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getCandidateScheduleJobController() async {
    try {
      saveJobsList.clear();
      getCandidateSelfScheduleJobPostResponse.value = ApiResponse.initial('Initial');
      ResponseModel responseModel =
      await JobRepo().getCandidateScheduleInterviewJobsRepo();
      if (responseModel.isSuccess) {
        jobsData?.clear();
        UserCandidateScheduleRes   jobsModel = UserCandidateScheduleRes.fromJson(responseModel.response?.data);
        jobsData?.value = jobsModel.interviews??[];

        getCandidateSelfScheduleJobPostResponse.value =
            ApiResponse.complete(responseModel);
      } else {
        getCandidateSelfScheduleJobPostResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getCandidateSelfScheduleJobPostResponse.value = ApiResponse.error('error');
    }
  }



  // Search-related variables
  RxBool isSearching = false.obs;
  RxList<Jobs>? searchResults = <Jobs>[].obs;
  Rx<ApiResponse> searchResponse = ApiResponse
      .initial('Initial')
      .obs;

  // Method to search jobs
  Future<void> searchJobsApi(String query, {String? status, int limit = 10, int page = 1}) async {
    try {
      if (query.isEmpty) {
        // If query is empty, clear search results
        searchResults?.clear();
        isSearching.value = false;
        return;
      }

      isSearching.value = true;
      
      final response = await _jobRepo.searchJobsRepo(
        query: query, 
        status: status,
        limit: limit, 
        page: page
      );
  
      if (response.isSuccess) {
        final rawData = response.response!.data;
        // Handle different response structures
        Map<String, dynamic> jobData;
        if (rawData['data'] != null &&
            rawData['data'] is Map<String, dynamic>) {
          jobData = {
            'message': rawData['message'],
            ...rawData['data'],
          };
        } else {
          jobData = Map<String, dynamic>.from(rawData);
        }
  
        searchResults?.clear();
        GetAllJobPostsModel searchModel = GetAllJobPostsModel.fromJson(jobData);
        searchResults?.value = searchModel.jobs ?? [];
        searchResponse.value = ApiResponse.complete(response);
      } else {
        searchResponse.value =
            ApiResponse.error(response.message ?? 'Error searching jobs');
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      searchResponse.value = ApiResponse.error('Error searching jobs');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isSearching.value = false;
    }
  }

  // Method to filter search results based on tab
  List<Jobs> getFilteredSearchResults(int selectedTabIndex, bool isIndividual) {
    if (searchResults == null || searchResults!.isEmpty) {
      return [];
    }

    if (isIndividual) {
      // Filter for individual tabs
      switch (selectedTabIndex) {
        case 0: // All Jobs
          return searchResults!;
        case 1: // Applied
          return searchResults!.where((job) => job.isApplied == true).toList();
        case 2: // Schedules - not implemented in search
          return searchResults!;

        case 3: // Saved
          return searchResults!;

          // We don't have a direct way to filter saved jobs from search results
        // This would require additional API or logic
        default:
          return searchResults!;
      }
    } else {
      // Filter for business tabs
      switch (selectedTabIndex) {
        case 0: // My Posts
          return searchResults!;
        case 1: // Active
          return searchResults!.where((job) => job.status == 'Open').toList();
        case 2: // Saved
        // We don't have a direct way to filter saved jobs from search results
          return [];
        default:
          return searchResults!;
      }
    }
  }

  // Clear search
  void clearSearch() {
    searchResults?.clear();
    isSearching.value = false;
    searchResponse.value = ApiResponse.initial('Initial');
  }
}
