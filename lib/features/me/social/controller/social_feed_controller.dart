import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/upload_init_response.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/features/me/social/model/social_activity_feed_res_model.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/common_methods.dart';

class SocialFeedController extends GetxController {
  // Observables for Form
  var deptName = "".obs;
  var description = "".obs;
  var selectedImages = <File>[].obs; // Local files picked
  var networkImages = <String>[].obs; // Existing images from API
  // Observables for Change Detection (Edit Mode)
  var originalData = {}.obs;
  var isFormValid = false.obs;
  var isUploading = false.obs;
  final SocialProfileRepo _repo = SocialProfileRepo();

  // API Responses
  Rx<ApiResponse> addEditDeptResponse = ApiResponse.initial('Initial').obs;

  void initEditData(SocialActivityFeedData data) {
    deptName.value = data.title ?? "";
    description.value = data.description ?? "";
    networkImages.assignAll(List<String>.from(data.mediaUrls ?? []));
    // Store original snapshot to compare later
    originalData.value = {
      'title': deptName.value,
      'description': description.value,
      "mediaType": "image",
      'mediaUrls': List<String>.from(networkImages),
    };
    validateForm(isEdit: true);
  }

  void validateForm({bool isEdit = false}) {
    bool basicValidation = deptName.isNotEmpty &&
        // hodName.isNotEmpty &&
        description.isNotEmpty &&
        (selectedImages.isNotEmpty || networkImages.isNotEmpty);

    if (!isEdit) {
      isFormValid.value = basicValidation;
    } else {
      // Check if anything changed compared to originalData
      bool hasChanged = deptName.value != originalData['name'] ||
          // hodName.value != originalData['hod'] ||
          // staffNames.value != originalData['staff'] ||
          description.value != originalData['desc'] ||
          selectedImages.isNotEmpty ||
          networkImages.length != (originalData['images'] as List).length;

      isFormValid.value = basicValidation && hasChanged;
    }
  }

  /// Main Save Method
  Future<void> submitDepartment({bool isEdit = false, String? deptId}) async {
    try {
      isUploading.value = true;
      List<String> finalImageUrls = List.from(networkImages);

      // 1. Upload new local images to S3 if any
      for (File file in selectedImages) {
        // String? uploadedUrl = await _uploadToS3Workflow(file);
        UploadResult? uploadResult = await S3UploadService.uploadFile(file);
        if (uploadResult.isSuccess) {
          finalImageUrls.add(uploadResult.url);
        }
      }

      // 2. Prepare Payload
      Map<String, dynamic> reqParm = isEdit
          ? {
              ApiKeys.title: deptName.value,
              ApiKeys.description: description.value,
              "mediaType": "image",
              "mediaUrls": finalImageUrls,
            }
          : {
              ApiKeys.title: deptName.value,
              ApiKeys.description: description.value,
              "mediaUrls": finalImageUrls,
              "mediaType": "image"
            };

      ResponseModel response = isEdit
          ? await _repo.updateSchoolDepartmentRepo(
              deptId: deptId ?? "", reqBODY: reqParm)
          : await _repo.addSchoolDepartmentRepo(reqBODY: reqParm);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        addEditDeptResponse.value =
            ApiResponse.complete(response.response?.data);
        await fetchDepartments(isRefresh: true);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        addEditDeptResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } finally {
      isUploading.value = false;
    }
  }

  UploadInitResponse uploadInit = UploadInitResponse();

  var departmentList = <SocialActivityFeedData>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    fetchDepartments();
    super.onInit();
  }

  Future<void> fetchDepartments({bool isRefresh = false}) async {
    try {
      isLoading.value = true;
      ResponseModel response = await _repo.getSchoolDepartmentRepo(reqBODY: {});

      // Simulation of parsing the response you provided
      if (response.isSuccess) {
        var data = SocialActivityFeedResModel.fromJson(response.response?.data);
        if (isRefresh) {
          departmentList.assignAll(data.data ?? []);
        } else {
          departmentList.addAll(data.data ?? []);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  void loadMore() {
    fetchDepartments();
  }

  ///DELETE NOTICE....
  Future<void> deleteSchoolDepartmentController(
      {required String departmentId}) async {
    try {
      ResponseModel response =
          await _repo.deleteSchoolDepartmentRepo(departmentID: departmentId);

      if (response.isSuccess) {
        Get.back();
        commonSnackBar(
            message:
                response.response?.data['message'] ?? AppStrings.successful);
        await fetchDepartments(isRefresh: true);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
    }
  }
}
