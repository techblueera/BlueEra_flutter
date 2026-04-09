import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/health_camp_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthCampController extends GetxController {
  final HealthCampRepo _repo = HealthCampRepo();
  final LabTestRepo _testRepo = LabTestRepo();

  var isLoading = false.obs;
  var camps = <HealthCamp>[].obs;
  var isValid = false.obs;
  var campDetail = Rxn<HealthCamp>();
  var isDetailLoading = false.obs;

  /// Whether a camp already exists (only single camp allowed)
  bool get hasCamp => camps.isNotEmpty;

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
  RxDouble lat = 0.0.obs;
  RxDouble lng = 0.0.obs;

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

  // Test & discount fields
  var isTestsLoading = false.obs;
  var labTestsMap = <String, List<PathologyTest>>{}.obs;
  var selectedTestDiscounts = <TestDiscount>[].obs;
  RxBool addDiscountTestEnabled = false.obs;

  RxString selectedTime = "".obs;
  final List<String> timeSlots = [
    "06:00 AM",
    "07:00 AM",
    "08:00 AM",
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "01:00 PM",
    "02:00 PM",
    "03:00 PM",
    "04:00 PM",
    "05:00 PM",
    "06:00 PM",
    "07:00 PM",
    "08:00 PM",
    "09:00 PM"
  ];

  @override
  void onInit() {
    super.onInit();
    fetchCamps();
  }

  void validateForm() {
    final title = typeController.text.trim();
    final desc = descController.text.trim();
    final sq = int.tryParse(sqFootController.text.trim() == ""
            ? "0"
            : sqFootController.text.trim()) ??
        0;
    final price = int.tryParse(priceController.text.trim() == ""
            ? "0"
            : priceController.text.trim()) ??
        0;
    final discount = int.tryParse(discountPriceController.text.trim() == ""
            ? "0"
            : discountPriceController.text.trim()) ??
        0;
    final hasDate = startDay.value > 0 &&
        startMonth.value > 0 &&
        startYear.value > 0 &&
        endDay.value > 0 &&
        endMonth.value > 0 &&
        endYear.value > 0;
    final hasTime = selectedTime.value.isNotEmpty;
    final hasImages = selectedImages.length >= minImages;
    isValid.value = title.isNotEmpty &&
        desc.isNotEmpty &&
        hasDate &&
        hasTime &&
        price >= 0 &&
        discount >= 0 &&
        sq >= 0 &&
        hasImages;
  }

  void addImages(List<String> paths) {
    final remaining = maxImages - selectedImages.length;
    if (remaining <= 0) {
      commonSnackBar(message: "${AppStrings.labMaxImagesAllowed.tr} ($maxImages)");
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

  // --- S3 image upload ---
  Future<List<String>> _uploadImagesToS3() async {
    final List<String> urls = [];
    for (final file in selectedImages) {
      UploadResult result = await S3UploadService.uploadFile(file);
      if (result.isSuccess) {
        urls.add(result.url);
      } else {
        commonSnackBar(message: "${AppStrings.labImageUploadFailed.tr} ${result.message}");
      }
    }
    return urls;
  }

  // --- Lab tests (user-created) ---
  Future<void> fetchTestsForCategory(String category) async {
    if (labTestsMap.containsKey(category)) return;
    isTestsLoading.value = true;
    try {
      ResponseModel res = await _testRepo.getPathologyTests(category);
      if (res.isSuccess) {
        List data = res.response?.data['data'] ?? [];
        labTestsMap[category] =
            data.map((e) => PathologyTest.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching tests: $e");
    } finally {
      isTestsLoading.value = false;
    }
  }

  Future<void> fetchAllSelectedTests() async {
    isTestsLoading.value = true;
    for (final cat in selectedTestCategories) {
      if (!labTestsMap.containsKey(cat)) {
        await fetchTestsForCategory(cat);
      }
    }
    isTestsLoading.value = false;
  }

  List<PathologyTest> getTestsForCategory(String category) {
    return labTestsMap[category] ?? [];
  }

  bool isTestSelected(String testId) {
    return selectedTestDiscounts.any((d) => d.test?.id == testId);
  }

  void toggleTestDiscount(PathologyTest item) {
    final index = selectedTestDiscounts.indexWhere((d) => d.test?.id == item.id);
    if (index >= 0) {
      selectedTestDiscounts.removeAt(index);
    } else {
      selectedTestDiscounts.add(TestDiscount(
        test: Test(
          id: item.id,
          testName: item.testName,
        ),
        discountType: "percentage",
        discountValue: 0,
      ));
    }
  }

  void updateDiscountValue(String testId, int value) {
    final index = selectedTestDiscounts.indexWhere((d) => d.test?.id == testId);
    if (index >= 0) {
      selectedTestDiscounts[index] = TestDiscount(
        test: selectedTestDiscounts[index].test,
        discountType: selectedTestDiscounts[index].discountType,
        discountValue: value,
      );
    }
  }

  void updateDiscountType(String testId, String type) {
    final index = selectedTestDiscounts.indexWhere((d) => d.test?.id == testId);
    if (index >= 0) {
      selectedTestDiscounts[index] = TestDiscount(
        test: selectedTestDiscounts[index].test,
        discountType: type,
        discountValue: selectedTestDiscounts[index].discountValue,
      );
    }
  }

  void removeTestDiscount(String testId) {
    selectedTestDiscounts.removeWhere((d) => d.test?.id == testId);
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createCamp() async {
    isLoading.value = true;
    try {
      // Upload images to S3
      final imageUrls = await _uploadImagesToS3();

      final start = DateTime(startYear.value, startMonth.value, startDay.value)
          .toIso8601String();
      final end = DateTime(endYear.value, endMonth.value, endDay.value)
          .toIso8601String();
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
        images: imageUrls.isNotEmpty ? imageUrls : null,
        // testCategories: selectedTestCategories.isNotEmpty
        //     ? selectedTestCategories.toList()
        //     : null,
        location: (lat.value != 0.0 || lng.value != 0.0)
            ? HealthCampLocation(
                name: searchController.text.trim(),
                type: "Point",
                coordinates: [lng.value, lat.value],
              )
            : null,
        testDiscounts: selectedTestDiscounts.isNotEmpty
            ? selectedTestDiscounts.toList()
            : null,
      ).toJson();

      ResponseModel res = await _repo.createHealthCamp(payload);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labHealthCampCreated.tr);
        await fetchCamps();
        return true;
      } else {
        commonSnackBar(
            message: res.response?.data['message'] ?? AppStrings.labFailedToCreate.tr);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCamp(HealthCamp existing) async {
    isLoading.value = true;
    try {
      // Upload images to S3
      final imageUrls = await _uploadImagesToS3();

      final start = DateTime(startYear.value, startMonth.value, startDay.value)
          .toIso8601String();
      final end = DateTime(endYear.value, endMonth.value, endDay.value)
          .toIso8601String();
      final payload = HealthCamp(
        id: existing.id,
        sqFoot: int.tryParse(sqFootController.text.trim()) ?? existing.sqFoot,
        title: typeController.text.trim(),
        description: descController.text.trim(),
        price: int.tryParse(priceController.text.trim()) ?? existing.price,
        discountPrice: int.tryParse(discountPriceController.text.trim()) ??
            existing.discountPrice,
        startDate: start,
        endDate: end,
        startTime: selectedTime.value,
        laboratoryId: labIDGlobal,
        images: imageUrls.isNotEmpty ? imageUrls : null,
        // testCategories: selectedTestCategories.isNotEmpty
        //     ? selectedTestCategories.toList()
        //     : null,
        location: (lat.value != 0.0 || lng.value != 0.0)
            ? HealthCampLocation(
                name: searchController.text.trim(),
                type: "Point",
                coordinates: [lng.value, lat.value],
              )
            : null,
        testDiscounts: selectedTestDiscounts.isNotEmpty
            ? selectedTestDiscounts.toList()
            : null,
      ).toJson();

      ResponseModel res = await _repo.updateHealthCamp(existing.id!, payload);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labHealthCampUpdated.tr);
        await fetchCamps();
        return true;
      } else {
        commonSnackBar(
            message: res.response?.data['message'] ?? AppStrings.labFailedToUpdate.tr);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
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
        commonSnackBar(message: AppStrings.labHealthCampDeleted.tr);
        campDetail.value = null;
        await fetchCamps();
      } else {
        commonSnackBar(
            message: res.response?.data['message'] ?? AppStrings.labFailedToDelete.tr);
      }
    } catch (e) {
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCampFullDetails() async {
    isDetailLoading.value = true;
    try {
      ResponseModel res = await _repo.getHealthCampFullDetails();
      if (res.isSuccess) {
        final data = res.response?.data['data'];

        if (data != null && data is List && data.isNotEmpty) {
          // CHANGED: Using .last instead of [0]
          campDetail.value = HealthCamp.fromJson(data.last);
        } else if (data != null && data is Map<String, dynamic>) {
          campDetail.value = HealthCamp.fromJson(data);
        } else {
          campDetail.value = null;
        }
      }
    } catch (e) {
      print("Error fetching camp full details: $e");
    } finally {
      isDetailLoading.value = false;
    }
  }
  void preloadForm(HealthCamp? camp) {
    if (camp == null) {
      typeController.clear();
      descController.clear();
      sqFootController.clear();
      priceController.clear();
      discountPriceController.clear();
      searchController.clear();
      selectedTime.value = "";
      startDay.value = DateTime.now().day;
      startMonth.value = DateTime.now().month;
      startYear.value = DateTime.now().year;
      endDay.value = DateTime.now().day;
      endMonth.value = DateTime.now().month;
      endYear.value = DateTime.now().year;
      lat.value = 0.0;
      lng.value = 0.0;
      selectedImages.clear();
      selectedTestCategories.clear();
      selectedTestDiscounts.clear();
      labTestsMap.clear();
      addDiscountTestEnabled.value = false;
    } else {
      typeController.text = camp.title ?? "";
      descController.text = camp.description ?? "";
      sqFootController.text = (camp.sqFoot ?? 0).toString();
      priceController.text = (camp.price ?? 0).toString();
      discountPriceController.text = (camp.discountPrice ?? 0).toString();
      selectedTime.value = camp.startTime ?? "";
      selectedImages.clear();
      // selectedTestCategories.value =
      //     camp.testCategories?.toList() ?? [];
      selectedTestDiscounts.value = camp.testDiscounts?.toList() ?? [];
      if (camp.location != null) {
        searchController.text = camp.location?.name ?? "";
        lat.value = (camp.location?.coordinates != null &&
                camp.location!.coordinates!.length >= 2)
            ? camp.location!.coordinates![1]
            : 0.0;
        lng.value = (camp.location?.coordinates != null &&
                camp.location!.coordinates!.isNotEmpty)
            ? camp.location!.coordinates![0]
            : 0.0;
      } else {
        searchController.clear();
        lat.value = 0.0;
        lng.value = 0.0;
      }
      labTestsMap.clear();
      addDiscountTestEnabled.value = camp.testDiscounts?.isNotEmpty ?? false;
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
