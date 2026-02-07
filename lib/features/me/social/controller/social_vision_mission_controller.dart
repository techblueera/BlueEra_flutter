import 'dart:io';

import 'package:BlueEra/core/api/model/social_vision_mission_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SocialVisionMissionController extends GetxController {
  final SocialProfileRepo _repo = SocialProfileRepo();
  final ImagePicker _picker = ImagePicker();

  final descriptionController = TextEditingController();
  
  var isLoading = false.obs;
  var isSaving = false.obs;
  
  var selectedImage = Rx<File?>(null);
  var serverImageUrl = Rxn<String>();
  var description = "".obs;

  String? existingId;

  @override
  void onInit() {
    super.onInit();
    getMissionVision();
  }

  Future<void> getMissionVision() async {
    isLoading.value = true;
    try {
      final response = await _repo.getMissionVision();
      if (response.success == true && response.data != null) {
        final data = response.data!;
        existingId = data.sId;
        descriptionController.text = data.description ?? "";
        if (data.mediaUrl != null && data.mediaUrl!.isNotEmpty) {
          serverImageUrl.value = data.mediaUrl;
        }
      }
    } catch (e) {
      commonSnackBar(message: "Error fetching data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      commonSnackBar(message: "Error picking image: $e");
    }
  }

  void removeImage() {
    selectedImage.value = null;
    serverImageUrl.value = null;
  }

  Future<void> save() async {
    if (descriptionController.text.trim().isEmpty) {
      commonSnackBar(message: "Please enter a description");
      return;
    }

    // Basic validation: User must have either an existing image or a new selected image
    if (selectedImage.value == null && serverImageUrl.value == null) {
        commonSnackBar(message: "Please select an image");
        return;
    }

    isSaving.value = true;
    try {
      String? finalImageUrl = serverImageUrl.value;

      // Upload image if selected
      if (selectedImage.value != null) {
        UploadResult result = await S3UploadService.uploadFile(selectedImage.value!);
        if (result.isSuccess) {
          finalImageUrl = result.url;
        } else {
          commonSnackBar(message: "Image upload failed: ${result.message}");
          return; 
        }
      }

      final body = {
        "description": descriptionController.text.trim(),
        "mediaUrl": finalImageUrl,
        "mediaType": "image" // Hardcoded as per user request
      };

      final response = await _repo.createMissionVision(body);
      
      if (response.success == true) {
        commonSnackBar(message: "Saved successfully");
        // Update local state with response data
        if (response.data != null) {
            existingId = response.data!.sId;
            descriptionController.text = response.data!.description ?? "";
            serverImageUrl.value = response.data!.mediaUrl;
            selectedImage.value = null; // Clear selected file as it's now on server
        }
      } else {
        commonSnackBar(message: "Failed to save");
      }
    } catch (e) {
      commonSnackBar(message: "Error saving: $e");
    } finally {
      isSaving.value = false;
    }
  }
}
