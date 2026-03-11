import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/repo/health_camp_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthCampController extends GetxController {
  final HealthCampRepo _repo = HealthCampRepo();

  var isLoading = false.obs;
  var camps = <HealthCamp>[].obs;
  var isValid = false.obs;

  final typeController = TextEditingController();
  final descController = TextEditingController();
  final sqFootController = TextEditingController();
  final priceController = TextEditingController();
  final discountPriceController = TextEditingController();
  final searchController = TextEditingController();
  RxString activityType = "".obs;

  RxInt startDay = 1.obs;
  RxInt startMonth = 1.obs;
  RxInt startYear = DateTime.now().year.obs;
  RxInt endDay = 1.obs;
  RxInt endMonth = 1.obs;
  RxInt endYear = DateTime.now().year.obs;

  // Image upload fields
  var selectedImages = <File>[].obs;
  final int maxImages = 5;
  final int minImages = 1;

  // Test category fields
  final List<String> testCategoryOptions = [
    "Blood & Routine Tests",
    "Preventive & Wellness Checkups",
    "Women, Pregnancy & Child Health",
    "Diagnostics & Imaging",
    "Organ & System Health",
    "Infection, Cancer & Immunity",
  ];
  var selectedTestCategories = <String>[].obs;

  RxString selectedTime = "".obs;
  final List<String> timeSlots = [
    "06:00 AM","07:00 AM","08:00 AM","09:00 AM","10:00 AM",
    "11:00 AM","12:00 PM","01:00 PM","02:00 PM","03:00 PM",
    "04:00 PM","05:00 PM","06:00 PM","07:00 PM","08:00 PM",
    "09:00 PM"
  ];

  // RxString laboratoryId = "698b225f2c44cc586fa1d5c2".obs;

  @override
  void onInit() {
    super.onInit();
    fetchCamps();
  }

  void validateForm() {
    final title = typeController.text.trim();
    final desc = descController.text.trim();
    final sq = int.tryParse(sqFootController.text.trim() == "" ? "0" : sqFootController.text.trim()) ?? 0;
    final price = int.tryParse(priceController.text.trim() == "" ? "0" : priceController.text.trim()) ?? 0;
    final discount = int.tryParse(discountPriceController.text.trim() == "" ? "0" : discountPriceController.text.trim()) ?? 0;
    final hasDate = startDay.value > 0 && startMonth.value > 0 && startYear.value > 0 && endDay.value > 0 && endMonth.value > 0 && endYear.value > 0;
    final hasTime = selectedTime.value.isNotEmpty;
    final hasImages = selectedImages.length >= minImages;
    isValid.value = title.isNotEmpty && desc.isNotEmpty && hasDate && hasTime && price >= 0 && discount >= 0 && sq >= 0 && hasImages;
  }

  void addImages(List<String> paths) {
    final remaining = maxImages - selectedImages.length;
    if (remaining <= 0) {
      commonSnackBar(message: "Maximum $maxImages images allowed");
      return;
    }
    final newFiles = paths.take(remaining).map((e) => File(e)).toList();
    selectedImages.addAll(newFiles);
    validateForm();
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      validateForm();
    }
  }

  void toggleTestCategory(String category) {
    if (selectedTestCategories.contains(category)) {
      selectedTestCategories.remove(category);
    } else {
      selectedTestCategories.add(category);
    }
  }

  Future<void> fetchCamps() async {
    isLoading.value = true;
    try {
      ResponseModel res = await _repo.getHealthCamps();
      if (res.isSuccess) {
        List data = res.response?.data['data'] ?? [];
        camps.value = data.map((e) => HealthCamp.fromJson(e)).toList();
      }
    } catch (e) {
      commonSnackBar(message: "Error fetching camps: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createCamp() async {
    isLoading.value = true;
    try {
      final start = DateTime(startYear.value, startMonth.value, startDay.value).toIso8601String();
      final end = DateTime(endYear.value, endMonth.value, endDay.value).toIso8601String();
      final payload = HealthCamp(
        sqFoot: int.tryParse(sqFootController.text.trim()) ?? 0,
        title: typeController.text.trim(),
        description: descController.text.trim(),
        price: int.tryParse(priceController.text.trim()) ?? 0,
        discountPrice: int.tryParse(discountPriceController.text.trim()) ?? 0,
        startDate: start,
        endDate: end,
        startTime: selectedTime.value,
        laboratoryId: labIDGlobal,
        testCategories: selectedTestCategories.isNotEmpty
            ? selectedTestCategories.toList()
            : null,
      ).toJson();

      final imageParts = await multiPartMultipleImages(
        arrImages: selectedImages.toList(),
      );
      if (imageParts.isNotEmpty) {
        payload['images'] = imageParts;
      }

      ResponseModel res = await _repo.createHealthCamp(
        payload,
        isMultipart: imageParts.isNotEmpty,
      );
      if (res.isSuccess) {
        commonSnackBar(message: "Health camp created");
        await fetchCamps();
        return true;
      } else {
        commonSnackBar(message: res.response?.data['message'] ?? "Failed to create");
        return false;
      }
    } catch (e) {
      commonSnackBar(message: "Error creating camp: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCamp(HealthCamp existing) async {
    isLoading.value = true;
    try {
      final start = DateTime(startYear.value, startMonth.value, startDay.value).toIso8601String();
      final end = DateTime(endYear.value, endMonth.value, endDay.value).toIso8601String();
      final payload = HealthCamp(
        id: existing.id,
        sqFoot: int.tryParse(sqFootController.text.trim()) ?? existing.sqFoot,
        title: typeController.text.trim(),
        description: descController.text.trim(),
        price: int.tryParse(priceController.text.trim()) ?? existing.price,
        discountPrice: int.tryParse(discountPriceController.text.trim()) ?? existing.discountPrice,
        startDate: start,
        endDate: end,
        startTime: selectedTime.value,
        laboratoryId: labIDGlobal,
        testCategories: selectedTestCategories.isNotEmpty
            ? selectedTestCategories.toList()
            : null,
      ).toJson();

      final imageParts = await multiPartMultipleImages(
        arrImages: selectedImages.toList(),
      );
      if (imageParts.isNotEmpty) {
        payload['images'] = imageParts;
      }

      ResponseModel res = await _repo.updateHealthCamp(
        existing.id!,
        payload,
        isMultipart: imageParts.isNotEmpty,
      );
      if (res.isSuccess) {
        commonSnackBar(message: "Health camp updated");
        await fetchCamps();
        return true;
      } else {
        commonSnackBar(message: res.response?.data['message'] ?? "Failed to update");
        return false;
      }
    } catch (e) {
      commonSnackBar(message: "Error updating camp: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCamp(String id) async {
    isLoading.value = true;
    try {
      ResponseModel res = await _repo.deleteHealthCamp(id);
      if (res.isSuccess) {
        commonSnackBar(message: "Health camp deleted");
        await fetchCamps();
      } else {
        commonSnackBar(message: res.response?.data['message'] ?? "Failed to delete");
      }
    } catch (e) {
      commonSnackBar(message: "Error deleting camp: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void preloadForm(HealthCamp? camp) {
    if (camp == null) {
      typeController.clear();
      descController.clear();
      sqFootController.clear();
      priceController.clear();
      discountPriceController.clear();
      selectedTime.value = "";
      startDay.value = DateTime.now().day;
      startMonth.value = DateTime.now().month;
      startYear.value = DateTime.now().year;
      endDay.value = DateTime.now().day;
      endMonth.value = DateTime.now().month;
      endYear.value = DateTime.now().year;
      selectedImages.clear();
      selectedTestCategories.clear();
    } else {
      typeController.text = camp.title ?? "";
      descController.text = camp.description ?? "";
      sqFootController.text = (camp.sqFoot ?? 0).toString();
      priceController.text = (camp.price ?? 0).toString();
      discountPriceController.text = (camp.discountPrice ?? 0).toString();
      selectedTime.value = camp.startTime ?? "";
      selectedImages.clear();
      selectedTestCategories.value =
          camp.testCategories?.toList() ?? [];
      try {
        final s = DateTime.tryParse(camp.startDate ?? "");
        final e = DateTime.tryParse(camp.endDate ?? "");
        if (s != null) {
          startDay.value = s.day;
          startMonth.value = s.month;
          startYear.value = s.year;
        }
        if (e != null) {
          endDay.value = e.day;
          endMonth.value = e.month;
          endYear.value = e.year;
        }
      } catch (_) {}
    }
    validateForm();
  }
}
