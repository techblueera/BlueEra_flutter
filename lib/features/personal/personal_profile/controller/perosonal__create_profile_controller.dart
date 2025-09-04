import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/auth/repo/personal_profile_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class PersonalCreateProfileController extends GetxController {
  ApiResponse updateUserProfileResponse = ApiResponse.initial('Initial');
  Rx<ApiResponse> deleteProjectResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> deleteExperienceResponse = ApiResponse.initial('Initial').obs;

  RxInt? selectedDay = 0.obs, selectedMonth = 0.obs, selectedYear = 0.obs;
  Rx<String?> selectedProfession = Rx<String?>(null);
    Rx<String?> selectedSubProfession = Rx<String?>(null);
  Rx<ProfessionTypeData?> selectedProfessionObj = Rx<ProfessionTypeData?>(null);
  Rx<SubcategoriesFiledName?> selectedSubProfessionObj = Rx<SubcategoriesFiledName?>(null);
  // Rx<ProfessionType?> selectedProfession = Rx<ProfessionType?>(null);
  // Rx<SelfEmploymentType?> selectedSelfEmployment =
  //     Rx<SelfEmploymentType?>(null);
  // Rx<ArtistCategory?> selectedArtistCategory = Rx<ArtistCategory?>(null);

  Rx<GenderType?> selectedGender = Rx<GenderType?>(null);

  RxString? imagePath = "".obs;
  RxBool isImageUpdated = false.obs;

  RxDouble? locationLat = 0.0.obs;
  RxDouble? locationLng = 0.0.obs;
  RxString locationAddress = "".obs;

  ///ADD OVERVIEW...
  Rx<TextEditingController> addOverview = TextEditingController().obs;

  ///ADD SKILL...
  final skillsList = <String>[].obs;
  final skillController = TextEditingController();
  final isValidate = false.obs;

  void validateForm() {
    isValidate.value = skillsList.isNotEmpty;
  }

  void addSkill(String skill) {
    if (skill.isNotEmpty && !skillsList.contains(skill)) {
      skillsList.add(skill);
      skillController.clear();
      validateForm();
    }
  }

  void removeSkill(String skill) {
    skillsList.remove(skill);
    validateForm();
  }

  void setSkillsFromModel(List<String>? skills) {
    skillsList.clear();
    if (skills != null && skills.isNotEmpty) {
      skillsList.addAll(skills.whereType<String>());
    }
    validateForm();
  }

  ///FOR PROJECT

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  final isFormValid = false.obs;

  void validateProjectForm() {
    isFormValid.value = titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty;
  }

  // Method to set start location data
  void setStartLocation(double? lat, double? lng, String address) {
    if (lat != null) locationLat?.value = lat;
    if (lng != null) locationLng?.value = lng;
    locationAddress.value = address;
  }

  void clearProjectFields() {
    isFormValid.value = false;
    titleController.clear();
    descriptionController.clear();
  }

  Future<void> updateUserProfileDetails({
    required Map<String, dynamic> params,
  }) async {
    try {
      print("Params being sent to API: $params");
      ResponseModel responseModel = await PersonalProfileRepo().updateUser(
        formData: params,
      );

      if (responseModel.isSuccess) {
        updateUserProfileResponse = ApiResponse.complete(responseModel);
        await Get.find<ViewPersonalDetailsController>().viewPersonalProfile();
        Get.back();
        commonSnackBar(
            message: responseModel.response?.data?['message'] ??
                "Update successfully");
      } else {
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      updateUserProfileResponse = ApiResponse.error('Update failed');
    }
  }

  ///FOR EXPERIENCE...

  final companyNameController = TextEditingController();
  final roleResController = TextEditingController();

  final isFormExperienceValid = false.obs;

  void validateExperienceForm() {
    isFormExperienceValid.value = companyNameController.text.isNotEmpty &&
        roleResController.text.isNotEmpty;
  }

  void clearExperienceFields() {
    isFormExperienceValid.value = false;
    companyNameController.clear();
    descriptionController.clear();
  }

  Future<void> deleteProjectDetails({
    required String? projectId,
  }) async {
    try {
      deleteProjectResponse.value = ApiResponse.initial('Initial');

      ResponseModel responseModel =
          await PersonalProfileRepo().deleteProjectRepo(projectID: projectId);

      if (responseModel.isSuccess) {
        deleteProjectResponse.value = ApiResponse.complete(responseModel);
        await Get.find<ViewPersonalDetailsController>().viewPersonalProfile();
        Get.back();
        commonSnackBar(
            message: responseModel.response?.data?['message'] ??
                "Deleted successfully");
      } else {
        deleteProjectResponse.value = ApiResponse.error('Delete failed');

        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      deleteProjectResponse.value = ApiResponse.error('Delete failed');
    }
  }

  Future<void> deleteExperienceDetails({
    required String? experienceId,
  }) async {
    try {
      deleteExperienceResponse.value = ApiResponse.initial('Initial');

      ResponseModel responseModel = await PersonalProfileRepo()
          .deleteExperienceRepo(experienceID: experienceId);

      if (responseModel.isSuccess) {
        deleteExperienceResponse.value = ApiResponse.complete(responseModel);
        await Get.find<ViewPersonalDetailsController>().viewPersonalProfile();
        Get.back();
        commonSnackBar(
            message: responseModel.response?.data?['message'] ??
                "Deleted successfully");
      } else {
        deleteExperienceResponse.value = ApiResponse.error('Delete failed');

        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      deleteExperienceResponse.value = ApiResponse.error('Delete failed');
    }
  }
}
