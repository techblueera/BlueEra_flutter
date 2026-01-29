import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  // --- Basic Profile Fields ---
  var selectedImage = Rxn<File>();
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

  final List<String> consultationModes = ["Online", "Offline", "Both"];

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

  void saveProfile() {
    // Implement API call here
    Get.snackbar("Success", "Profile updated successfully!");
  }
}

class BasicProfileController_ extends GetxController {
  // Image State
  var selectedImage = Rxn<File>();

  // Text Controllers
  final nameController = TextEditingController();
  final professionalTitleController = TextEditingController();
  final taglineController = TextEditingController();
  final locationController = TextEditingController();
  double? selectedLat;
  double? selectedLng;

  // Language Dropdown State
  var selectedLanguage = "".obs;
  final List<String> indianLanguages = [
    "Assamese",
    "Bengali",
    "Bodo",
    "Dogri",
    "Gujarati",
    "Hindi",
    "Kannada",
    "Kashmiri",
    "Konkani",
    "Maithili",
    "Malayalam",
    "Manipuri",
    "Marathi",
    "Nepali",
    "Odia",
    "Punjabi",
    "Sanskrit",
    "Santali",
    "Sindhi",
    "Tamil",
    "Telugu",
    "Urdu",
    "English"
  ].obs;

  // Validation State
  var isFormValid = false.obs;

// --- Professional Fields ---
  final expYearController = TextEditingController();
  final expMonthController = TextEditingController();
  final descriptionController = TextEditingController();
  var description = "".obs; // For AiDescriptionField
  @override
  void onInit() {
    super.onInit();
    // Listen to changes in all fields to trigger validation
    nameController.addListener(validateForm);
    professionalTitleController.addListener(validateForm);
    taglineController.addListener(validateForm);
    locationController.addListener(validateForm);
    ever(selectedImage, (_) => validateForm());
    ever(selectedLanguage, (_) => validateForm());
  }

  void validateForm() {
    isFormValid.value = selectedImage.value != null &&
        nameController.text.trim().isNotEmpty &&
        professionalTitleController.text.trim().isNotEmpty &&
        taglineController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty &&
        selectedLanguage.value.isNotEmpty;
  }

  void onLanguageChanged(String? value) {
    if (value != null) {
      selectedLanguage.value = value;
    }
  }

  void saveProfile() {
    // Implement API call here
    Get.snackbar("Success", "Profile updated successfully!");
  }

  @override
  void onClose() {
    nameController.dispose();
    professionalTitleController.dispose();
    taglineController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
