import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/others/model/staff_model.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StaffController extends GetxController {
  final OtherRepo _repo = OtherRepo();

  var staffList = <StaffData>[].obs;
  var isLoading = false.obs;
  var isUploading = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final positionController = TextEditingController();
  final qualificationController = TextEditingController();

  // Date selection for Joining Date (From)
  var fromDay = RxnInt();
  var fromMonth = RxnInt();
  var fromYear = RxnInt();

  // Date selection for Joining Date (To)
  var toDay = RxnInt();
  var toMonth = RxnInt();
  var toYear = RxnInt();

  var isPresent = false.obs;

  Rx<File?> selectedImage = Rx<File?>(null);
  String? currentImageUrl;
  String? editingId;

  @override
  void onInit() {
    super.onInit();
    getStaffData();
  }

  void clearForm() {
    nameController.clear();
    positionController.clear();
    qualificationController.clear();
    
    fromDay.value = null;
    fromMonth.value = null;
    fromYear.value = null;
    
    toDay.value = null;
    toMonth.value = null;
    toYear.value = null;
    
    isPresent.value = false;
    
    selectedImage.value = null;
    currentImageUrl = null;
    editingId = null;
  }

  void setFormData(StaffData data) {
    nameController.text = data.name ?? "";
    positionController.text = data.position ?? "";
    qualificationController.text = data.qualification ?? "";
    
    if (data.joinedFrom != null) {
      try {
        final date = DateTime.parse(data.joinedFrom!);
        fromDay.value = date.day;
        fromMonth.value = date.month;
        fromYear.value = date.year;
      } catch (e) {
        debugPrint("Error parsing joinedFrom: $e");
      }
    }

    if (data.joinedTo != null) {
      try {
        final date = DateTime.parse(data.joinedTo!);
        toDay.value = date.day;
        toMonth.value = date.month;
        toYear.value = date.year;
        isPresent.value = false;
      } catch (e) {
        debugPrint("Error parsing joinedTo: $e");
      }
    } else {
      // If joinedTo is null, assume Present? Or explicitly check?
      // Based on typical logic, if joinedTo is missing/null, they might be currently working there.
      // But let's assume if it's null it means Present.
      isPresent.value = true;
    }

    selectedImage.value = null;
    currentImageUrl = data.imageUrl;
    editingId = data.sId;
  }

  Future<void> pickImage(BuildContext context) async {
    final String? path = await SelectProfilePictureDialog.showLogoDialog(
        context, AppStrings.otherUploadPicture.tr);
    if (path != null && path.isNotEmpty) {
      selectedImage.value = File(path);
    }
  }

  Future<void> getStaffData() async {
    isLoading.value = true;
    ResponseModel res = await _repo.getStaffRepo();
    isLoading.value = false;

    if (res.isSuccess) {
      try {
        final model = StaffModel.fromJson(res.response?.data);
        staffList.value = model.data ?? [];
      } catch (e) {
        debugPrint("Error parsing staff data: $e");
      }
    } else {
      debugPrint("Failed to fetch staff data: ${res.message}");
    }
  }

  Future<void> saveStaff() async {
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

    if (fromDay.value == null || fromMonth.value == null || fromYear.value == null) {
      commonSnackBar(message: AppStrings.otherPleaseSelectJoiningDate.tr);
      return;
    }

    if (!isPresent.value) {
      if (toDay.value == null || toMonth.value == null || toYear.value == null) {
        commonSnackBar(message: AppStrings.otherPleaseSelectEndingDate.tr);
        return;
      }

      final fromDate = DateTime(fromYear.value!, fromMonth.value!, fromDay.value!);
      final toDate = DateTime(toYear.value!, toMonth.value!, toDay.value!);

      if (toDate.isBefore(fromDate)) {
        commonSnackBar(message: AppStrings.otherEndingBeforeJoining.tr);
        return;
      }
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

    // Format dates to ISO string
    final joinedFromDate = DateTime(fromYear.value!, fromMonth.value!, fromDay.value!);
    // Adding some time component to match the example format if needed, but ISO 8601 usually fine with just date part or T00:00:00
    // Example: "2026-01-23T11:22:41.199Z"
    
    String? joinedToIso;
    if (!isPresent.value) {
      final joinedToDate = DateTime(toYear.value!, toMonth.value!, toDay.value!);
      joinedToIso = joinedToDate.toIso8601String();
    }

    final Map<String, dynamic> body = {
      "name": nameController.text.trim(),
      "position": positionController.text.trim(),
      "qualification": qualificationController.text.trim(),
      "joinedFrom": joinedFromDate.toIso8601String(),
      if (joinedToIso != null) "joinedTo": joinedToIso,
      "imageUrl": imageUrl,
    };

    dynamic res;
    if (editingId != null) {
      res = await _repo.updateStaffRepo(editingId!, body);
    } else {
      res = await _repo.createStaffRepo(body);
    }

    isUploading.value = false;

    if (res.isSuccess) {
      Get.back(); // Go back to list
      commonSnackBar(message: res.message ?? AppStrings.genericSavedSuccess.tr);
      getStaffData();
    } else {
      commonSnackBar(message: res.message ?? AppStrings.labFailedToSave.tr);
    }
  }

  Future<void> deleteStaff(String id) async {
    final res = await _repo.deleteStaffRepo(id);
    if (res.isSuccess) {
      commonSnackBar(message: res.message ?? AppStrings.genericDeletedSuccess.tr);
      getStaffData();
    } else {
      commonSnackBar(message: res.message ?? AppStrings.labFailedToDelete.tr);
    }
  }
}
