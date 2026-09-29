import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/analytics_service.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:BlueEra/core/constants/shared_preference_utils.dart';

import '../../../../core/api/apiService/response_model.dart';
import '../../auth/model/get_job_details_byId_model.dart';

/// State and API calls for the 4-step create/edit job flow. Registered by
/// CreateJobPostBinding on the flow's first route, so every step shares one
/// instance and a new flow always starts empty.
class CreateJobPostController extends GetxController {
  CreateJobPostController(
      {required JobRepo repo, String editJobId = '', String createJobVia = ''})
      : _repo = repo,
        _createJobVia = createJobVia {
    isEditMode.value = editJobId.isNotEmpty;
    jobID.value = editJobId;
  }

  final String _createJobVia;

  /// Bumped once the job being edited has been loaded into the form, so the
  /// view can refresh widgets that read the controller outside `Obx`.
  final RxInt formRevision = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (isEditMode.value) _loadJobForEdit();
  }

  // No onClose disposing the text controllers: "Edit" on the preview at the
  // end of a flow opens a second flow on top, whose binding deletes this
  // instance while the first flow's screens are still in the stack and still
  // show these fields. They need no disposal once those screens are gone.

  RxBool isLoading = false.obs;
  final companyName = ''.obs;
  final companyAddress = ''.obs;
  final jobTitle = ''.obs;
  final department = ''.obs;
  final jobType = ''.obs;
  final workMode = ''.obs;
  final payType = ''.obs;
  final minSalary = ''.obs;
  final maxSalary = ''.obs;
  final selectedCompensationPerks = <String>[].obs;
  final selectedJobDescriptionPerks = <String>[].obs;
  final jobHighlights = <String>[].obs;
  final jobDescription = ''.obs;

  // Initialize text controllers first
  TextEditingController companyNameController = TextEditingController();
  TextEditingController companyAddressController = TextEditingController();
  TextEditingController jobTitleController = TextEditingController();
  TextEditingController departmentController = TextEditingController();
  TextEditingController minSalaryController = TextEditingController();
  TextEditingController maxSalaryController = TextEditingController();
  TextEditingController jobHighlightsController = TextEditingController();
  TextEditingController jobDescriptionController = TextEditingController();

  RxString selectQualification = ''.obs;
  RxString selectTotalExperience = ''.obs;
  RxList<String> selectedLanguages = <String>['English'].obs;
  RxString error = ''.obs;
  Rx<GetJobDetailsByIdModel?> jobDetails = Rx<GetJobDetailsByIdModel?>(null);

  List<String> availableLanguages = [
    'English',
    'Hindi',
    'Tamil',
    'Bengali',
    'Telugu',
    'Marathi'
  ];
  final selectedSkills = <String>[].obs;
  final selectedGender = ''.obs;
  final walkInInterview = ''.obs;
  final communicationPreference = ''.obs;
  RxString jobID = ''.obs;
  final isEditMode = false.obs;

  final addressEditController = TextEditingController();
  // Added variables to store location data
  RxDouble? startLocationLat = 0.0.obs;
  RxDouble? startLocationLng = 0.0.obs;
  RxString startLocationAddress = "".obs;
  // Method to set start location data
  void setJobLocation(double? lat, double? lng, String address) {
    if (lat != null) startLocationLat?.value = lat;
    if (lng != null) startLocationLng?.value = lng;
    startLocationAddress.value = address;
  }

  final JobRepo _repo;

  Map<String, dynamic> _detailsParams() => {
        ApiKeys.jobTitle: jobTitleController.text,
        ApiKeys.companyName: companyNameController.text,
        ApiKeys.jobType: jobType.value,
        ApiKeys.workMode: workMode.value,
        ApiKeys.department: departmentController.text,
        ApiKeys.jobDescription: jobDescriptionController.text,
        ApiKeys.benefits: jsonEncode(selectedCompensationPerks),
        ApiKeys.jobHighlights: jsonEncode(selectedJobDescriptionPerks),
        ApiKeys.compensationType: payType.value,
        ApiKeys.compensationMinSalary:
            int.tryParse(minSalaryController.text) ?? 0,
        ApiKeys.compensationMaxSalary:
            int.tryParse(maxSalaryController.text) ?? 0,
        ApiKeys.locationLatitude: startLocationLat?.value ?? 0.0,
        ApiKeys.locationLongitude: startLocationLng?.value ?? 0.0,
        ApiKeys.locationAddress: addressEditController.text,
        ApiKeys.postedBy: userId,
      };

  /// Saves step 1: creates the draft job, or updates the one being edited.
  /// Returns true when the flow can move on to step 2.
  Future<bool> submitDetails({String? imagePath}) async {
    return isEditMode.value
        ? _updateJobPostDetails()
        : _postJob(imagePath: imagePath);
  }

  Future<bool> _postJob({String? imagePath}) async {
    try {
      await getUserLoginData();
      final params = {
        ..._detailsParams(),
        ApiKeys.postedFrom: _createJobVia,
      };
      if (imagePath != null && imagePath.isNotEmpty) {
        params[ApiKeys.jobPostImage] = await MultipartFile.fromFile(imagePath,
            filename: imagePath.split('/').last);
      }
      final response = await _repo.jobPostRepo(params: params);
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      final jobId = response.getExtraData('jobId') ??
          response.getExtraData('data')?['jobId'];
      jobID.value = jobId;
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  Future<bool> _updateJobPostDetails() async {
    try {
      final response = await _repo.updateJobPostDetailsRepo(
        jobId: jobID.value,
        params: _detailsParams(),
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Saves step 2. Returns true when the flow can move on to step 3.
  Future<bool> postJobStep2Api({required String jobId}) async {
    try {
      final params = {
        ApiKeys.qualifications: selectQualification.value,
        ApiKeys.experience:
            int.tryParse(selectTotalExperience.value.split(' ')[0]) ?? 0,
        ApiKeys.skills: selectedSkills.toList(),
        ApiKeys.languages: selectedLanguages.toList(),
        ApiKeys.gender: selectedGender.value,
      };
      final response = await _repo.jobPostStep2Repo(
        jobId: jobId,
        params: params,
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Saves step 3. Returns true when the flow can move on to step 4.
  Future<bool> postJobStep3Api(
      {required String jobId,
      required Map<String, dynamic> interviewDetails}) async {
    try {
      final params = {
        ApiKeys.interviewDetails: {
          ApiKeys.isWalkIn: interviewDetails[ApiKeys.isWalkIn],
          ApiKeys.interviewAddress: interviewDetails[ApiKeys.interviewAddress],
          ApiKeys.walkInStartDate: interviewDetails[ApiKeys.walkInStartDate],
          ApiKeys.walkInEndDate: interviewDetails[ApiKeys.walkInEndDate],
          ApiKeys.walkInStartTime: interviewDetails[ApiKeys.walkInStartTime],
          ApiKeys.walkInEndTime: interviewDetails[ApiKeys.walkInEndTime],
          ApiKeys.communicationPreferences:
              interviewDetails[ApiKeys.communicationPreferences],
          ApiKeys.otherInstructions:
              interviewDetails[ApiKeys.otherInstructions],
        },
      };

      final response = await _repo.jobPostStep3Repo(
        jobId: jobId,
        params: params,
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Saves step 4. Returns true when the job can be previewed.
  Future<bool> postJobStep4Api(
      {required String jobId,
      required List<Map<String, dynamic>> customQuestions}) async {
    try {
      final response = await _repo.jobPostStep4Repo(
        jobId: jobId,
        params: {ApiKeys.customQuestions: customQuestions},
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Publishes the drafted job. Returns true when it is live.
  Future<bool> publishJobApi({required String jobId}) async {
    try {
      final response = await _repo.publishJobRepo(
        jobId: jobId,
        params: {},
      );
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      // Publish is the step that makes the post visible to seekers — the
      // earlier draft steps are not a completed job posting.
      AnalyticsService.I.log(
          'job_post_published', AnalyticsService.params({'job_id': jobId}));
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  Future<void> fetchJobDetails(String jobId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final ResponseModel response =
          await _repo.getJobDetailsRepo(jobId: jobId);

      if (response.isSuccess && response.response?.data != null) {
        try {
          jobDetails.value =
              GetJobDetailsByIdModel.fromJson(response.response!.data);
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
      isLoading.value = false;
    }
  }

  /// Loads the job being edited and fills step 1's form from it.
  Future<void> _loadJobForEdit() async {
    await fetchJobDetails(jobID.value);
    final job = jobDetails.value?.job;
    addressEditController.text = job?.location?.addressString ?? "";
    companyNameController.text = job?.companyName ?? "";
    companyAddressController.text = job?.location?.addressString ?? "";
    jobTitleController.text = job?.jobTitle ?? "";
    departmentController.text = job?.department ?? "";
    jobDescriptionController.text = job?.jobDescription ?? "";
    jobType.value = job?.jobType ?? "";
    workMode.value = job?.workMode ?? "";
    payType.value = job?.compensation?.type ?? "";
    maxSalaryController.text = job?.compensation?.maxSalary.toString() ?? "";
    minSalaryController.text = job?.compensation?.minSalary.toString() ?? "";

    selectedCompensationPerks.assignAll(_perkList(job?.benefits));
    selectedJobDescriptionPerks.assignAll(_perkList(job?.jobHighlights));
    formRevision.value++;
  }

  /// The job's perks as a plain list. The app saves them as one
  /// JSON-encoded string (`jsonEncode(perks)`), so the API returns
  /// `['["a","b"]']`; a plain `['a', 'b']` is taken as it is.
  static List<String> _perkList(List<String>? stored) {
    if (stored == null || stored.isEmpty) return [];
    if (stored.length == 1) {
      try {
        final decoded = jsonDecode(stored.single);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return List<String>.from(stored);
  }
}
