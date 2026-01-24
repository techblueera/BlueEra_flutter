import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/department_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/upload_init_response.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/common_methods.dart';

class DepartmentController extends GetxController {
  // Observables for Form
  var deptName = "".obs;
  var hodName = "".obs;
  var staffNames = "".obs; // We'll split this by comma for the API
  var description = "".obs;
  var selectedImages = <File>[].obs; // Local files picked
  var networkImages = <String>[].obs; // Existing images from API

  // Observables for Change Detection (Edit Mode)
  var originalData = {}.obs;
  var isFormValid = false.obs;
  var isUploading = false.obs;

  // API Responses
  Rx<ApiResponse> addEditDeptResponse = ApiResponse.initial('Initial').obs;

  void initEditData(DepartmentData data) {
    // data is the Department object/map from API
    deptName.value = data.name ?? "";
    hodName.value = data.hodName ?? "";
    staffNames.value = (data.staffNames as List).join(", ");
    description.value = data.description ?? "";
    networkImages.assignAll(List<String>.from(data.uploadImages ?? []));

    // Store original snapshot to compare later
    originalData.value = {
      'name': deptName.value,
      'hod': hodName.value,
      'staff': staffNames.value,
      'desc': description.value,
      'images': List<String>.from(networkImages),
    };
    validateForm(isEdit: true);
  }

  void validateForm({bool isEdit = false}) {
    bool basicValidation = deptName.isNotEmpty &&
        hodName.isNotEmpty &&
        description.isNotEmpty &&
        (selectedImages.isNotEmpty || networkImages.isNotEmpty);

    if (!isEdit) {
      isFormValid.value = basicValidation;
    } else {
      // Check if anything changed compared to originalData
      bool hasChanged = deptName.value != originalData['name'] ||
          hodName.value != originalData['hod'] ||
          staffNames.value != originalData['staff'] ||
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
        String? uploadedUrl = await _uploadToS3Workflow(file);
        finalImageUrls.add(uploadedUrl);
      }

      // 2. Prepare Payload
      Map<String, dynamic> reqParm = isEdit
          ? {
              ApiKeys.name: deptName.value,
              "hodName": hodName.value,
              "staffNames":
                  staffNames.value.split(',').map((e) => e.trim()).toList(),
              ApiKeys.description: description.value,
              "uploadImages": finalImageUrls,
            }
          : {
              ApiKeys.name: deptName.value,
              "hodName": hodName.value,
              "staffNames":
                  staffNames.value.split(',').map((e) => e.trim()).toList(),
              ApiKeys.description: description.value,
              "uploadImages": finalImageUrls,
              ApiKeys.schoolId: schoolIDGlobal // Replace with dynamic ID
            };

      ResponseModel response = isEdit
          ? await SchoolRepo().updateSchoolDepartmentRepo(
              deptId: deptId ?? "", reqBODY: reqParm)
          : await SchoolRepo().addSchoolDepartmentRepo(reqBODY: reqParm);

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

  Future<String> _uploadToS3Workflow(File file) async {
    try {
      isUploading.value = true;
      final imageFile = File(file.path);
      final vInfo = getFileInfo(imageFile);
      Map<String, dynamic> queryParams = {
        ApiKeys.fileName: vInfo['fileName'],
        ApiKeys.fileType: vInfo['mimeType']
      };

      ResponseModel? response =
          await SchoolRepo().uploadEducationDocRepo(queryParams: queryParams);

      if (response?.isSuccess ?? false) {
        uploadInit = UploadInitResponse.fromJson(response?.response?.data);
        final isStatus = await uploadFileToS3(
          file: imageFile,
          fileType: vInfo['mimeType']!,
          preSignedUrl: uploadInit.uploadUrl ?? "",
        );
        if (isStatus) {
          return uploadInit.publicUrl ?? "";
        }
        return "";
      } else {
        isUploading.value = false;

        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
        return "";
      }
    } catch (e) {
      isUploading.value = false;

      commonSnackBar(message: AppStrings.somethingWentWrong);
      return "";
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> uploadFileToS3(
      {required File file,
      required String fileType,
      required String preSignedUrl}) async {
    try {
      ResponseModel? response = await ChannelRepo().uploadVideoToS3(
        file: file,
        fileType: fileType,
        preSignedUrl: preSignedUrl,
        onProgress: (sent) {},
      );

      if (response?.isSuccess ?? false) {
        return true;
      } else {
        isUploading.value = false;

        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      isUploading.value = false;

      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  var departmentList = <DepartmentData>[].obs;
  var isLoading = false.obs;
  var currentPage = 1.obs;
  var hasNext = false.obs;

  @override
  void onInit() {
    fetchDepartments();
    super.onInit();
  }

  Future<void> fetchDepartments({bool isRefresh = false}) async {
    if (isRefresh) currentPage.value = 1;

    try {
      isLoading.value = true;
      ResponseModel response =
          await SchoolRepo().getSchoolDepartmentRepo(reqBODY: {
        "schoolId": schoolIDGlobal,
        "page": currentPage.value,
        "limit": "10",
      });

      // Simulation of parsing the response you provided
      if (response.isSuccess) {
        var data = DepartmentResModel.fromJson(response.response?.data);
        if (isRefresh) {
          departmentList.assignAll(data.data ?? []);
        } else {
          departmentList.addAll(data.data ?? []);
        }
        hasNext.value = data.pagination?.hasNext ?? false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void loadMore() {
    if (hasNext.value && !isLoading.value) {
      currentPage.value++;
      fetchDepartments();
    }
  }

  ///DELETE NOTICE....
  Future<void> deleteSchoolDepartmentController(
      {required String departmentId}) async {
    try {
      ResponseModel response = await SchoolRepo()
          .deleteSchoolDepartmentRepo(departmentID: departmentId);

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
