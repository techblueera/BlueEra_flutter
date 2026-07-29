import 'package:BlueEra/core/api/model/personal_identity_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileIdentityController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final SocialProfileRepo _repo = SocialProfileRepo();

  // Text Controllers
  final bioController = TextEditingController();
  final journeyController = TextEditingController();
  final locationController = TextEditingController();
  var isAddingBackground = false.obs;
  final familyBackgroundController = TextEditingController();
  final RxString rxValue = "".obs;
  int maxChars = 500;
  // Rx Variables for AI Fields and Location
  var bioRx = "".obs;
  var journeyRx = "".obs;
  var lat = 0.0.obs;
  var lng = 0.0.obs;
  var isLoading = false.obs;

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
    familyBackgroundController.addListener(validateForm);

    // Fetch initial data
    getProfileIdentity();
  }

  void validateForm() {
    // Check if all fields are non-empty
    bool isValid = bioController.text.trim().isNotEmpty &&
        journeyController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty;

    isFormValid.value = isValid;
    // Update Rx values for AI fields if needed
    bioRx.value = bioController.text;
    journeyRx.value = journeyController.text;
  }

  @override
  void onClose() {
    bioController.dispose();
    journeyController.dispose();
    locationController.dispose();
    super.onClose();
  }

  Future<void> getProfileIdentity() async {
    try {
      isLoading.value = true;
      final response = await _repo.getPersonalIdentity();
      if (response.success == true && response.data != null) {
        final data = response.data ?? PersonalIdentityData();
        bioController.text = data.bio ?? "";
        journeyController.text = data.journey ?? "";

        if (data.location != null &&
            data.location?.coordinates != null &&
            (data.location?.coordinates?.length ?? 0) >= 2) {
          lat.value = data.location?.coordinates?[0] ?? 0.0;
          lng.value = data.location?.coordinates?[1] ?? 0.0;
          // Note: We might need reverse geocoding to get address string if API doesn't return it
          // keeping locationController text as is or setting it if we have address
          locationController.text = data.location?.name ?? "";
          familyBackgroundController.text = data.familyBackground ?? "";
          if ((data.familyBackground ?? "").isNotEmpty) {
            isAddingBackground.value = true;
            rxValue.value = data.familyBackground ?? "";
          }
        }

        // Only set edit mode if user has actually saved content before
        isEditMode.value = (data.bio ?? "").isNotEmpty ||
            (data.journey ?? "").isNotEmpty ||
            (data.familyBackground ?? "").isNotEmpty ||
            (data.location?.name ?? "").isNotEmpty;
      }
    } catch (e) {
      print("Error fetching profile: $e");
      // Don't show error snackbar on init as it might be first time user
    } finally {
      isLoading.value = false;
      validateForm();
    }
  }

  Future<void> validateAndSave() async {
    if (formKey.currentState!.validate()) {
      if (locationController.text.isEmpty) {
        commonSnackBar(message: AppStrings.locationRequired.tr);
        return;
      }

      try {
        isLoading.value = true;

        final body = {
          "bio": bioController.text,
          "journey": journeyController.text,
          "familyBackground": familyBackgroundController.text,
          "location": {
            "name": locationController.text,
            "type": "Point",
            "coordinates": [lat.value, lng.value]
          }
        };

        final response = await _repo.updatePersonalIdentity(body);

        if (response.success == true) {
          commonSnackBar(message: AppStrings.profileSavedSuccessfully.tr);
          isEditMode.value = true;
          Get.back();
        } else {
          commonSnackBar(message: AppStrings.failedToSaveProfile.tr);
        }
      } catch (e) {
        print("Error saving profile: $e");
        commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      } finally {
        isLoading.value = false;
      }
    }
  }
}
