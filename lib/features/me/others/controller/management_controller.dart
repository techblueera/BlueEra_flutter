import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/other_profile_dirty.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/others/model/management_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagementController extends GetxController {
  final OtherRepo _repo = OtherRepo();

  var managementList = <ManagementData>[].obs;
  var isLoading = false.obs;
  var isUploading = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final positionController = TextEditingController();
  final qualificationController = TextEditingController();
  final messageController = TextEditingController();

  Rx<File?> selectedImage = Rx<File?>(null);
  String? currentImageUrl;
  String? editingId;
  var name = "".obs;
  var position = "".obs;
  var qualification = "".obs;
  var description = "".obs;

  @override
  void onInit() {
    super.onInit();
    getManagementData();
  }

  void clearForm() {
    name.value="";
    position.value="";
    qualification.value="";
    description.value="";
    nameController.clear();
    positionController.clear();
    qualificationController.clear();
    messageController.clear();
    selectedImage.value = null;
    currentImageUrl = null;
    editingId = null;
  }

  void setFormData(ManagementData data) {
    nameController.text = data.name ?? "";
    positionController.text = data.position ?? "";
    qualificationController.text = data.qualification ?? "";
    messageController.text = data.message ?? "";
    selectedImage.value = null;
    currentImageUrl = data.imageUrl;
    editingId = data.sId;
  }

  Future<void> pickImage(BuildContext context) async {
    final String? path = await PhotoPickerService.pickSinglePhoto(
        context, "Upload Picture");
    if (path != null && path.isNotEmpty) {
      selectedImage.value = File(path);
    }
  }

  Future<void> getManagementData() async {
    isLoading.value = true;
    ResponseModel res = await _repo.getManagementRepo();
    isLoading.value = false;

    if (res.isSuccess) {
      try {
        final model = ManagementModel.fromJson(res.response?.data);
        managementList.value = model.data ?? [];
      } catch (e) {
        debugPrint("Error parsing management data: $e");
      }
    } else {
      // Handle error if needed
      debugPrint("Failed to fetch management data: ${res.message}");
    }
  }

  Future<void> saveManagement() async {
    if (nameController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.otherPleaseEnterName.tr);
      return;
    }
    if (positionController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.otherPleaseEnterPosition.tr);
      return;
    }
    if (qualificationController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.otherPleaseEnterQualification.tr);
      return;
    }
    if (messageController.text.trim().isEmpty) {
      commonSnackBar(message: AppStrings.otherPleaseEnterMessage.tr);
      return;
    }

    if (editingId == null && selectedImage.value == null) {
      commonSnackBar(message: AppStrings.otherPleaseSelectImage.tr);
      return;
    }

    isUploading.value = true;
    String? imageUrl = currentImageUrl;

    if (selectedImage.value != null) {
      final uploadRes = await S3UploadService.uploadFile(selectedImage.value!);
      if (uploadRes.isSuccess) {
        imageUrl = uploadRes.url;
      } else {
        isUploading.value = false;
        commonSnackBar(message: uploadRes.message);
        return;
      }
    }

    final Map<String, dynamic> body = {
      "name": nameController.text.trim(),
      "position": positionController.text.trim(),
      "qualification": qualificationController.text.trim(),
      "message": messageController.text.trim(),
      "imageUrl": imageUrl,
    };

    dynamic res;
    if (editingId != null) {
      res = await _repo.updateManagementRepo(editingId!, body);
    } else {
      res = await _repo.createManagementRepo(body);
    }

    isUploading.value = false;

    if (res.isSuccess) {
      Get.back(); // Go back to list
      commonSnackBar(message: res.message ?? AppStrings.genericSavedSuccess.tr);
      // The Overview tab's Management card is now stale — see
      // [OtherProfileDirty].
      OtherProfileDirty.mark(OtherProfileSection.management);
      getManagementData();
    } else {
      commonSnackBar(message: res.message ?? AppStrings.labFailedToSave.tr);
    }
  }

  Future<void> deleteManagement(String id) async {
    // Show confirmation dialog before deleting?
    // The user requirement says: "DELETE API for record delete take delete conformation also"
    // I should handle confirmation in UI, but the controller method executes the deletion.

    final res = await _repo.deleteManagementRepo(id);
    if (res.isSuccess) {
      commonSnackBar(message: res.message ?? AppStrings.genericDeletedSuccess.tr);
      OtherProfileDirty.mark(OtherProfileSection.management);
      getManagementData();
    } else {
      commonSnackBar(message: res.message ?? AppStrings.labFailedToDelete.tr);
    }
  }
}
