import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/individual_user_response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/profile_identity.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
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

  /// Sub-category filed-names that hang off the currently selected
  /// profession. Owned here (not on AuthController) because the only
  /// consumers are profession dialogs in this profile-edit flow — they
  /// drive the secondary "select work type / art skill" dropdowns.
  /// Mutated via `clearSubCategoryData()` and direct `addAll(...)` from
  /// the dropdown's `onChanged` callbacks.
  List<SubcategoriesFiledName> subcategoriesFiledNameList = [];

  /// Clear and ping GetBuilder consumers. Plain `List` (not `RxList`) so
  /// `Obx` won't auto-rebuild on its own — the dialogs that read it call
  /// `setState` after each pick, which keeps things in sync.
  void clearSubCategoryData() {
    subcategoriesFiledNameList.clear();
    update();
  }
  // Rx<ProfessionType?> selectedProfession = Rx<ProfessionType?>(null);
  // Rx<SelfEmploymentType?> selectedSelfEmployment =
  //     Rx<SelfEmploymentType?>(null);
  // Rx<ArtistCategory?> selectedArtistCategory = Rx<ArtistCategory?>(null);

  Rx<GenderType?> selectedGender = Rx<GenderType?>(null);
  final RxBool updateBtnLoading = false.obs;
  RxString? imagePath = "".obs;
  RxString? coverImagePath = "".obs;
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
    isFormValid.value = titleController.text.isNotEmpty && descriptionController.text.isNotEmpty;
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

  /// Which of the profile-category fields [params] would actually CHANGE.
  ///
  /// Presence alone is not the offence — the backend compares the profession
  /// through the catalog and the profileType across both vocabularies, so a
  /// screen echoing back the value it just read is explicitly not a change and
  /// does not 409. Several screens do exactly that (the bio card, the AI-bio
  /// screen, the profile header) and asserting on presence would fail every one
  /// of them for nothing.
  ///
  /// Comparison is done on a squashed key — letters and digits only, uppercased
  /// — because `user.profession` exists in the live data as BOTH `"Bike Rider"`
  /// and `"BIKE_RIDER"` depending on which onboarding path created the account.
  /// Comparing raw strings would report a change where there is none.
  static List<String> _profileCategoryFieldsChangedBy(
      Map<String, dynamic> params) {
    String squash(String? v) =>
        (v ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    final changed = <String>[];

    for (final key in [ApiKeys.profession]) {
      if (!params.containsKey(key)) continue;
      final sent = squash(params[key]?.toString());
      // A blank clears nothing here; treat it as "not asserting a value".
      if (sent.isEmpty) continue;
      if (sent != squash(userProfessionGlobal)) changed.add(key);
    }

    for (final key in [ApiKeys.profileType, ApiKeys.profile_type]) {
      if (!params.containsKey(key)) continue;
      final sent = normalizeProfileType(params[key]?.toString());
      if (sent.isEmpty) continue;
      if (sent != normalizeProfileType(userProfileTypeGlobal)) changed.add(key);
    }

    return changed;
  }

  /// Every write to `PUT /user/updateIndividualAccountUser/:id` funnels through
  /// here, which makes it the one place that can police what may go in it.
  ///
  /// A PROFESSION or PROFILE-TYPE change is no longer allowed on this endpoint:
  /// it answers `409 use_profile_category_endpoint` for a non-GUEST account,
  /// because those changes are one-per-account and need the counter and audit
  /// trail that `POST /user/me/profile-category/change` carries. See §3.4 of
  /// docs/backend/FLUTTER_PROFILE_CATEGORY_CHANGE_GUIDE.md.
  ///
  /// The assertion below is the enforcement. It is DEBUG-ONLY — `assert` is
  /// compiled out of release — and it is deliberately loud: a straggler caller
  /// that still sends `profession` fails here, on the developer's machine, with
  /// the fix in the message, instead of silently 409-ing in production where it
  /// reads to the user as "saving my profile is broken".
  ///
  /// Satellite edits are unaffected: bio, designation, photo, DOB,
  /// specialization, sector, department and the rest still belong here.
  /// GUEST accounts are exempt — first-time profile fill is not a change, and
  /// the backend guard does not fire for them either.
  Future<void> updateUserProfileDetails(
      {required Map<String, dynamic> params, bool isFromProfileOnly = false, bool? showProgress}) async {
    assert(() {
      if (isGuestUser()) return true;
      final offending = _profileCategoryFieldsChangedBy(params);
      if (offending.isEmpty) return true;
      throw FlutterError(
        'updateUserProfileDetails was given a CHANGED $offending for a '
        'non-GUEST account.\n'
        'The legacy endpoint answers 409 use_profile_category_endpoint for a '
        'profession / profileType change.\n'
        'Route it through ProfileCategoryController.changeCategory() '
        '(POST /user/me/profile-category/change) and send the satellite fields '
        'here AFTERWARDS — the change wipes them server-side.\n'
        'See update_personal_profession_dialog.dart for the worked example.',
      );
    }());

    try {
      updateBtnLoading.value = true;
      print("Params being sent to API: $params");
      ResponseModel responseModel =
          await PersonalProfileRepo().updateUser(formData: params, showProgress: showProgress);

      if (responseModel.isSuccess) {
        final upgraded = IndividualUserResponseModel.fromJson(responseModel.response?.data ?? {});
        updateUserProfileResponse = ApiResponse.complete(responseModel);

        await SharedPreferenceUtils.setSecureValue(SharedPreferenceUtils.authToken, upgraded.token);
        await getUserAuthToken();

        unawaited(Get.find<ViewPersonalDetailsController>()
            .viewPersonalProfile(forceRefresh: true));
        if (!isFromProfileOnly) {
          Get.back();
        }
        commonSnackBar(message: responseModel.response?.data?['message'] ?? "Update successfully");
      } else {
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      updateUserProfileResponse = ApiResponse.error('Update failed');
      // Surface the failure — a swallowed throw here reads to the user as
      // "nothing happened" after a profile/cover image update.
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      updateBtnLoading.value = false;
    }
  }

  ///FOR EXPERIENCE...
  final companyNameController = TextEditingController();
  final roleResController = TextEditingController();

  final isFormExperienceValid = false.obs;

  void validateExperienceForm() {
    isFormExperienceValid.value = companyNameController.text.isNotEmpty && roleResController.text.isNotEmpty;
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

      ResponseModel responseModel = await PersonalProfileRepo().deleteProjectRepo(projectID: projectId);

      if (responseModel.isSuccess) {
        deleteProjectResponse.value = ApiResponse.complete(responseModel);
        await Get.find<ViewPersonalDetailsController>()
            .viewPersonalProfile(forceRefresh: true);
        Get.back();
        commonSnackBar(message: responseModel.response?.data?['message'] ?? "Deleted successfully");
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

      ResponseModel responseModel =
          await PersonalProfileRepo().deleteExperienceRepo(experienceID: experienceId);

      if (responseModel.isSuccess) {
        deleteExperienceResponse.value = ApiResponse.complete(responseModel);
        await Get.find<ViewPersonalDetailsController>()
            .viewPersonalProfile(forceRefresh: true);
        Get.back();
        commonSnackBar(message: responseModel.response?.data?['message'] ?? "Deleted successfully");
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
