import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:BlueEra/features/common/jobs/view/job_details_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile;

import '../../../../core/api/apiService/response_model.dart';
import '../../auth/model/get_job_details_byId_model.dart';
import 'job_details_screen_controller.dart';


class CreateJobPostController extends GetxController {
  late String jobId;

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

  final addressEditController=TextEditingController();
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

  // Method to reset controller state
  void resetControllerState() {
    companyName.value = '';
    companyAddress.value = '';
    jobTitle.value = '';
    department.value = '';
    jobType.value = '';
    workMode.value = '';
    payType.value = '';
    minSalary.value = '';
    maxSalary.value = '';
    selectedCompensationPerks.clear();
    selectedJobDescriptionPerks.clear();
    jobHighlights.clear();
    jobDescription.value = '';
    selectQualification.value = '';
    selectTotalExperience.value = '';
    selectedLanguages.clear();
    selectedLanguages.add('English');
    selectedSkills.clear();
    selectedGender.value = '';
    walkInInterview.value = '';
    communicationPreference.value = '';
    jobID.value = '';
    isEditMode.value = false;
    jobDetails.value = null;
    startLocationLat?.value = 0.0;
    startLocationLng?.value = 0.0;
    startLocationAddress.value = '';
    addressEditController.clear();
    error.value = '';
  }

  final JobRepo _repo = JobRepo();

  ///POST JOB
  Future<void> postJobApi({String? imagePath}) async {
    try {
      final params = {
        ApiKeys.jobTitle: jobTitleController.text,
        ApiKeys.companyName: companyNameController.text,
        ApiKeys.jobType: jobType.value,
        ApiKeys.workMode: workMode.value,
        ApiKeys.department: departmentController.text,
        ApiKeys.jobDescription: jobDescriptionController.text,
        ApiKeys.benefits: jsonEncode(selectedCompensationPerks),
        ApiKeys.jobHighlights: jsonEncode(selectedJobDescriptionPerks),
        ApiKeys.compensationType: payType.value,
        ApiKeys.compensationMinSalary: int.tryParse(minSalaryController.text) ?? 0,
        ApiKeys.compensationMaxSalary: int.tryParse(maxSalaryController.text) ?? 0,
        ApiKeys.locationLatitude: startLocationLat?.value ?? 0.0,
        ApiKeys.locationLongitude: startLocationLng?.value ?? 0.0,
        ApiKeys.locationAddress: addressEditController.text,
      };
      if (imagePath != null && imagePath.isNotEmpty) {
        params[ApiKeys.jobPostImage] = await MultipartFile.fromFile(imagePath,
            filename: imagePath.split('/').last);
      }
      final response = await _repo.jobPostRepo(params: params);
      if (response.isSuccess) {
        final jobId = response.response?.data['jobId'] ??
            response.response?.data['data']?['jobId'];
        jobID.value = jobId;
        commonSnackBar(message: response.message ?? AppStrings.success);
        Get.toNamed(RouteHelper.getCreateJobPostStep2Route());
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> postJobStep2Api({required String jobId}) async {
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
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        Get.toNamed(RouteHelper.getCreateJobPostStep3Route());
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> postJobStep3Api({required String jobId, required Map<String, dynamic> interviewDetails}) async {
    try {
      // Debug logging for communication preference8
      
              final params = {
          ApiKeys.interviewDetails: {
            ApiKeys.isWalkIn : interviewDetails[ApiKeys.isWalkIn],
            ApiKeys.interviewAddress : interviewDetails[ApiKeys.interviewAddress],
            ApiKeys.walkInStartDate : interviewDetails[ApiKeys.walkInStartDate],
            ApiKeys.walkInEndDate : interviewDetails[ApiKeys.walkInEndDate],
            ApiKeys.walkInStartTime : interviewDetails[ApiKeys.walkInStartTime],
            ApiKeys.walkInEndTime : interviewDetails[ApiKeys.walkInEndTime],
            ApiKeys.communicationPreferences : interviewDetails[ApiKeys.communicationPreferences],
            ApiKeys.otherInstructions : interviewDetails[ApiKeys.otherInstructions],
          },
        };

      final response = await _repo.jobPostStep3Repo(
        jobId: jobId,
        params: params,
      );

      if (response.isSuccess) {
        Get.toNamed(RouteHelper.getCreateJobPostStep4Route());
        commonSnackBar(message: response.message ?? AppStrings.success);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }


  Future<void> postJobStep4Api({required String jobId, required List<Map<String, dynamic>> customQuestions}) async {
    try {
      final params = {
        ApiKeys.customQuestions: customQuestions,
      };
      final response = await _repo.jobPostStep4Repo(
        jobId: jobId,
        params: params,
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);

        Get.to(() => JobDetailScreen(isPostEdit: AppConstants.EDIT,isPostCreate: AppConstants.JOB_POST,jobId: jobId,isShowSaveJob: false, isPostDirection: '', isPostApply: '',));

      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

 Future<void> updateJobPostDetailsApi({required String jobId, required Map<String, dynamic> params}) async {
    try {
      
      final response = await _repo.updateJobPostDetailsRepo(
        jobId: jobId,
        params: params,
      );
      
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        Get.toNamed(RouteHelper.getCreateJobPostStep2Route());
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {

      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> publishJobApi({required String jobId}) async {
    try {
      final response = await _repo.publishJobRepo(
        jobId: jobId,
        params: {},
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        Get.offAllNamed(
          RouteHelper.getBottomNavigationBarScreenRoute(),
          arguments: {ApiKeys.initialIndex: 0},
        );
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> fetchJobDetails(String jobId) async {

    try {
      isLoading.value = true;
      error.value = '';

      final ResponseModel response = await _repo.getJobDetailsRepo(jobId: jobId);

      if (response.isSuccess && response.response?.data != null) {
        try {
          jobDetails.value = GetJobDetailsByIdModel.fromJson(response.response!.data);
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
        isLoading.value = false;}
    }
  }

}
