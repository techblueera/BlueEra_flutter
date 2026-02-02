import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/ai_professionals_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/repo/professionals_repo.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/profile_preview_screen.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiProfessionalsController extends GetxController {
  ProfessionalsRepo _repo = ProfessionalsRepo();
  RxBool hasProfile = false.obs;

  Rx<AiProfessionalsResModel>? aiServiceRes = AiProfessionalsResModel().obs;
  Rx<ProfessionalProfileResModel>? getProfessionalServiceRes =
      ProfessionalProfileResModel().obs;
  Rx<ApiResponse> generateViaAIResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> createProfProfileResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getFullProfessionalsResponse =
      ApiResponse.initial('Initial').obs;

  Future<void> aiGenerateServiceFetchController() async {
    try {
      ResponseModel response = await _repo.createAiProfessionalsRepo();
      if (response.isSuccess) {
        final data = response.response?.data;
        aiServiceRes?.value = AiProfessionalsResModel.fromJson(data);
        generateViaAIResponse.value = ApiResponse.complete(aiServiceRes);
        Get.to(ProfilePreviewScreen());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        generateViaAIResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      // TODO
      generateViaAIResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  ///GET FULL PROFILE...
  Future<void> professionalsFullDetailsController() async {
    try {
      ResponseModel response = await _repo.getByUserIdProfessionalsRepo();
      if (response.isSuccess) {
        hasProfile.value = true;
        final data = response.response?.data;
        getProfessionalServiceRes?.value =
            ProfessionalProfileResModel.fromJson(data);

        getFullProfessionalsResponse.value = ApiResponse.complete(aiServiceRes);
      } else {
        hasProfile.value = false;

        getFullProfessionalsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      hasProfile.value = false;

      // TODO
      getFullProfessionalsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> createServiceController() async {
    try {
      ResponseModel response = await _repo.createProfessionalsRepo(
          bodyREQ: aiServiceRes?.value.data);
      if (response.isSuccess) {
        createProfProfileResponse.value = ApiResponse.complete(aiServiceRes);
        await professionalsFullDetailsController();
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        createProfProfileResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception {
      // TODO
      createProfProfileResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  // --- Basic Profile Fields ---
  var selectedImage = Rxn<File>();
  var isImageEdit = false.obs;
  final nameController = TextEditingController();
  final titleController = TextEditingController();
  final taglineController = TextEditingController();
  final locationController = TextEditingController();
  var selectedLanguage = "".obs;

  // --- Professional Fields ---
  final expYearController = TextEditingController();
  final expMonthController = TextEditingController();
  final descriptionController = TextEditingController();
  var description = "".obs; // For AiDescriptionField

  // Dropdown Data
  final List<String> indianLanguages = [
    "Hindi",
    "English",
    "Bengali",
    "Marathi",
    "Telugu",
    "Tamil",
    "Gujarati",
    "Urdu",
    "Kannada",
    "Odia",
    "Malayalam",
    "Punjabi",
    "Sanskrit",
    "Assamese"
  ];

  // Validation
  var isBasicValid = false.obs;
  var isProfessionalValid = false.obs;
  double? selectedLat;
  double? selectedLng;

  // --- Pricing / Engagement Model Fields ---
  final feeTypeController = TextEditingController(); // E.g., Hourly
  final feeAmountController = TextEditingController(); // E.g., 600
  final minBookingController = TextEditingController(); // E.g., 600
  var selectedConsultationMode = "".obs;

  final List<String> consultationModes = ["Online", "Offline", "Hybrid"];

  // Validation for Pricing Screen
  var isPricingValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listeners for Basic Profile
    nameController.addListener(validateBasic);
    titleController.addListener(validateBasic);
    taglineController.addListener(validateBasic);
    locationController.addListener(validateBasic);
    ever(selectedLanguage, (_) => validateBasic());
    ever(selectedImage, (_) => validateBasic());

    // Listeners for Professional Profile
    expYearController.addListener(validateProfessional);
    expMonthController.addListener(validateProfessional);
    descriptionController.addListener(() {
      description.value = descriptionController.text;
      validateProfessional();
    });

    // Listeners for Pricing Profile
    feeTypeController.addListener(validatePricing);
    feeAmountController.addListener(validatePricing);
    minBookingController.addListener(validatePricing);
    ever(selectedConsultationMode, (_) => validatePricing());
  }

  clearPricing() {
    feeTypeController.clear();
    feeAmountController.clear();
    minBookingController.clear();
    selectedConsultationMode.value = "";
  }

  clearBasicProfile() {
    nameController.clear();
    titleController.clear();
    taglineController.clear();
    locationController.clear();
    selectedLanguage.value = "";
    selectedImage.value = null;
    isImageEdit.value = false;
  }

  clearAboutProfessional() {
    expYearController.clear();
    expMonthController.clear();
    descriptionController.clear();
  }

  void validatePricing() {
    isPricingValid.value = feeTypeController.text.isNotEmpty &&
        feeAmountController.text.isNotEmpty &&
        minBookingController.text.isNotEmpty &&
        selectedConsultationMode.value.isNotEmpty;
  }

  void validateBasic() {
    isBasicValid.value = nameController.text.isNotEmpty &&
        titleController.text.isNotEmpty &&
        taglineController.text.isNotEmpty &&
        locationController.text.isNotEmpty &&
        selectedLanguage.value.isNotEmpty &&
        selectedImage.value != null;
  }

  void validateProfessional() {
    isProfessionalValid.value = expYearController.text.isNotEmpty &&
        expMonthController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty;
  }

  void onLanguageChanged(String? val) {
    if (val != null) selectedLanguage.value = val;
  }

  refreshFullData() async {
    await Get.find<AiProfessionalsController>()
        .professionalsFullDetailsController();
  }

  Future<void> saveProfile() async {
    try {
      String mimeType = '', uploadUrl;
      if (isImageEdit.value) {
        mimeType = getMimeType(selectedImage.value?.path ?? "");
      }
      final bodyREQ = {
        "basicDetails": {
          "fullName": nameController.text.trim(),
          "professionalTitle": titleController.text.trim(),
          "shortTagline": taglineController.text.trim(),
          "location": locationController.text.trim(),
          "languagesSpoken": [selectedLanguage.value],
          if (isImageEdit.value) "profilePhotoContentType": mimeType,
        }
      };

      final repo = ProfessionalsRepo();
      ResponseModel response =
          await repo.createProfessionalsRepo(bodyREQ: bodyREQ);
      if (response.isSuccess && isImageEdit.value) {
        uploadUrl = response.response?.data['uploadUrl'];
        if (uploadUrl.isNotEmpty) {
          await ChannelRepo().uploadVideoToS3(
            file: selectedImage.value ?? File(""),
            fileType: mimeType,
            preSignedUrl: uploadUrl,
            onProgress: (sent) => print("Uploading: $sent"),
          );
        }
      }
      if (response.isSuccess) {
        refreshFullData();
        commonSnackBar(message: "Profile updated successfully");
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
    isImageEdit.value = false;
  }

  Future<void> saveAboutProfessional() async {
    try {
      final bodyReq = {
        "about": {
          "totalExperience": {
            "years": expYearController.text,
            "months": expMonthController.text
          },
          "description": description.value
        }
      };

      final repo = ProfessionalsRepo();
      ResponseModel response =
          await repo.createProfessionalsRepo(bodyREQ: bodyReq);

      if (response.isSuccess) {
        Get.back();
        refreshFullData();
        commonSnackBar(message: "Profile updated successfully");
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> savePricingModel() async {
    try {
      final bodyReq = {
        "pricing": {
          "type": feeTypeController.text,
          "amount": feeAmountController.text,
          "currency": "INR",
          "minimumBookingAmount": minBookingController.text,
          "consultationMode": selectedConsultationMode.value
        }
      };

      final repo = ProfessionalsRepo();
      ResponseModel response =
          await repo.createProfessionalsRepo(bodyREQ: bodyReq);

      if (response.isSuccess) {
        Get.back();
        refreshFullData();
        commonSnackBar(message: "Profile updated successfully");
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
