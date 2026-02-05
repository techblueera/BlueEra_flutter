import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileIdentityController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final bioController = TextEditingController();
  final journeyController = TextEditingController();
  final locationController = TextEditingController();

  // Rx Variables for AI Fields and Location
  var bioRx = "".obs;
  var journeyRx = "".obs;
  var lat = 0.0.obs;
  var lng = 0.0.obs;

  // Track if we are editing or adding
  var isEditMode = false.obs;
// Observable for button state
  var isFormValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Add listeners to all controllers to trigger validation on every keystroke
    bioController.addListener(validateForm);
    journeyController.addListener(validateForm);
    locationController.addListener(validateForm);
  }

  void validateForm() {
    // Check if all fields are non-empty
    bool isValid = bioController.text.trim().isNotEmpty &&
        journeyController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty;

    isFormValid.value = isValid;
  }

  @override
  void onClose() {
    bioController.dispose();
    journeyController.dispose();
    locationController.dispose();
    super.onClose();
  }


  void validateAndSave() {
    if (formKey.currentState!.validate()) {
      if (locationController.text.isEmpty) {
        commonSnackBar(message: "Error Location is required",);
        return;
      }

      // Logic for Add vs Edit
      if (isEditMode.value) {
        print("Updating Profile...");
      } else {
        print("Creating Profile...");
      }

      commonSnackBar(message:"Success Profile Saved Successfully",);
    }
  }
}