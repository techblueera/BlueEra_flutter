import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/health_camp_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Owns the multi-section "health camp" form: metadata, dates / time slot,
/// images (with S3 upload), and per-test discount picks across selected
/// pathology categories. Only one camp per lab is supported by the backend.
class HealthCampController extends GetxController {
  final HealthCampRepo _repo = HealthCampRepo();
  final LabTestRepo _testRepo = LabTestRepo();

  // ---- Lifecycle state ------------------------------------------------------

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isDetailLoading = false.obs;
  final RxBool isTestsLoading = false.obs;
  final RxBool isValid = false.obs;

  final RxList<HealthCamp> camps = <HealthCamp>[].obs;
  final Rxn<HealthCamp> campDetail = Rxn<HealthCamp>();

  /// `true` once at least one camp exists. Only one is allowed per lab.
  bool get hasCamp => camps.isNotEmpty;

  // ---- Form text fields -----------------------------------------------------

  final typeController = TextEditingController();
  final descController = TextEditingController();
  final sqFootController = TextEditingController();
  final priceController = TextEditingController();
  final discountPriceController = TextEditingController();
  final searchController = TextEditingController();
  final RxString activityType = "".obs;

  // ---- Date / time ----------------------------------------------------------

  final RxInt startDay = 1.obs;
  final RxInt startMonth = 1.obs;
  final RxInt startYear = DateTime.now().year.obs;
  final RxInt endDay = 1.obs;
  final RxInt endMonth = 1.obs;
  final RxInt endYear = DateTime.now().year.obs;

  final RxDouble lat = 0.0.obs;
  final RxDouble lng = 0.0.obs;

  final RxString selectedTime = "".obs;
  static const List<String> timeSlots = [
    '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM',
    '11:00 AM', '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
    '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM', '08:00 PM',
    '09:00 PM',
  ];

  // ---- Images ---------------------------------------------------------------

  final RxList<File> selectedImages = <File>[].obs;
  static const int maxImages = 5;
  static const int minImages = 1;

  // ---- Tests & discounts ----------------------------------------------------

  static const List<String> testCategoryOptions = [
    'Blood & Routine Tests',
    'Preventive & Wellness Checkups',
    'Women, Pregnancy & Child Health',
    'Diagnostics & Imaging',
    'Organ & System Health',
    'Infection, Cancer & Immunity',
  ];
  final RxList<String> selectedTestCategories = <String>[].obs;

  final RxMap<String, List<PathologyTest>> labTestsMap =
      <String, List<PathologyTest>>{}.obs;
  final RxList<TestDiscount> selectedTestDiscounts = <TestDiscount>[].obs;
  final RxBool addDiscountTestEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCamps();
  }

  @override
  void onClose() {
    typeController.dispose();
    descController.dispose();
    sqFootController.dispose();
    priceController.dispose();
    discountPriceController.dispose();
    searchController.dispose();
    super.onClose();
  }

  // ---- Validation -----------------------------------------------------------

  void validateForm() {
    final title = typeController.text.trim();
    final desc = descController.text.trim();
    final sq = _parseIntOrZero(sqFootController.text);
    final price = _parseIntOrZero(priceController.text);
    final discount = _parseIntOrZero(discountPriceController.text);

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

  int _parseIntOrZero(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 0;
    return int.tryParse(text) ?? 0;
  }

  // ---- Images ---------------------------------------------------------------

  void addImages(List<String> paths) {
    final remaining = maxImages - selectedImages.length;
    if (remaining <= 0) {
      commonSnackBar(
          message: "${AppStrings.labMaxImagesAllowed.tr} ($maxImages)");
      return;
    }
    selectedImages.addAll(paths.take(remaining).map((e) => File(e)));
    validateForm();
  }

  void removeImage(int index) {
    if (index < 0 || index >= selectedImages.length) return;
    selectedImages.removeAt(index);
    validateForm();
  }

  /// Uploads every picked file to S3 and returns the URLs.
  Future<List<String>> _uploadImagesToS3() async {
    final urls = <String>[];
    for (final file in selectedImages) {
      final UploadResult result = await S3UploadService.uploadFile(file);
      if (result.isSuccess) {
        urls.add(result.url);
      } else {
        commonSnackBar(
            message:
                "${AppStrings.labImageUploadFailed.tr} ${result.message}");
      }
    }
    return urls;
  }

  // ---- Test categories & discounts ------------------------------------------

  void toggleTestCategory(String category) {
    if (selectedTestCategories.contains(category)) {
      selectedTestCategories.remove(category);
    } else {
      selectedTestCategories.add(category);
    }
  }

  Future<void> fetchTestsForCategory(String category) async {
    if (labTestsMap.containsKey(category)) return;
    try {
      isTestsLoading.value = true;
      final ResponseModel res = await _testRepo.getPathologyTests(category);
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        labTestsMap[category] =
            data.map((e) => PathologyTest.fromJson(e)).toList();
      }
    } catch (e) {
      logs("HealthCampController.fetchTestsForCategory ERROR $e");
    } finally {
      isTestsLoading.value = false;
    }
  }

  Future<void> fetchAllSelectedTests() async {
    try {
      isTestsLoading.value = true;
      for (final cat in selectedTestCategories) {
        if (!labTestsMap.containsKey(cat)) {
          await fetchTestsForCategory(cat);
        }
      }
    } finally {
      isTestsLoading.value = false;
    }
  }

  List<PathologyTest> getTestsForCategory(String category) =>
      labTestsMap[category] ?? const [];

  bool isTestSelected(String testId) =>
      selectedTestDiscounts.any((d) => d.test?.id == testId);

  void toggleTestDiscount(PathologyTest item) {
    final index =
        selectedTestDiscounts.indexWhere((d) => d.test?.id == item.id);
    if (index >= 0) {
      selectedTestDiscounts.removeAt(index);
    } else {
      selectedTestDiscounts.add(TestDiscount(
        test: Test(id: item.id, testName: item.testName),
        discountType: "percentage",
        discountValue: 0,
      ));
    }
  }

  void updateDiscountValue(String testId, int value) {
    final index =
        selectedTestDiscounts.indexWhere((d) => d.test?.id == testId);
    if (index >= 0) {
      final current = selectedTestDiscounts[index];
      selectedTestDiscounts[index] = TestDiscount(
        test: current.test,
        discountType: current.discountType,
        discountValue: value,
      );
    }
  }

  void updateDiscountType(String testId, String type) {
    final index =
        selectedTestDiscounts.indexWhere((d) => d.test?.id == testId);
    if (index >= 0) {
      final current = selectedTestDiscounts[index];
      selectedTestDiscounts[index] = TestDiscount(
        test: current.test,
        discountType: type,
        discountValue: current.discountValue,
      );
    }
  }

  void removeTestDiscount(String testId) {
    selectedTestDiscounts.removeWhere((d) => d.test?.id == testId);
  }

  // ---- API: reads -----------------------------------------------------------

  Future<void> fetchCamps() async {
    if (labIDGlobal.isEmpty) return;
    try {
      isLoading.value = true;
      final ResponseModel res = await _repo.getHealthCampsByLab(labIDGlobal);
      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        camps.value = data.map((e) => HealthCamp.fromJson(e)).toList();
      }
    } catch (e) {
      logs("HealthCampController.fetchCamps ERROR $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCampFullDetails() async {
    if (labIDGlobal.isEmpty) return;
    try {
      isDetailLoading.value = true;
      final ResponseModel res = await _repo.getHealthCampsByLab(labIDGlobal);
      if (res.isSuccess) {
        final data = res.response?.data['data'];
        if (data is List && data.isNotEmpty) {
          // The "last" entry is the camp belonging to this lab — the
          // backend returns history-ordered results.
          campDetail.value = HealthCamp.fromJson(data.last);
        } else if (data is Map<String, dynamic>) {
          campDetail.value = HealthCamp.fromJson(data);
        } else {
          campDetail.value = null;
        }
      }
    } catch (e) {
      logs("HealthCampController.fetchCampFullDetails ERROR $e");
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ---- API: writes ----------------------------------------------------------

  Future<bool> createCamp() async {
    return _saveCamp(
      existing: null,
      successMessage: AppStrings.labHealthCampCreated.tr,
      failureFallback: AppStrings.labFailedToCreate.tr,
      operationLabel: 'CREATE',
    );
  }

  Future<bool> updateCamp(HealthCamp existing) async {
    if (existing.id == null) return false;
    return _saveCamp(
      existing: existing,
      successMessage: AppStrings.labHealthCampUpdated.tr,
      failureFallback: AppStrings.labFailedToUpdate.tr,
      operationLabel: 'UPDATE',
    );
  }

  Future<void> deleteCamp(String id) async {
    try {
      isSaving.value = true;
      final ResponseModel res = await _repo.deleteHealthCamp(id);
      if (res.isSuccess) {
        commonSnackBar(message: AppStrings.labHealthCampDeleted.tr);
        campDetail.value = null;
        await fetchCamps();
      } else {
        commonSnackBar(
            message: res.response?.data['message'] ??
                AppStrings.labFailedToDelete.tr);
      }
    } catch (e) {
      logs("HealthCampController.deleteCamp ERROR $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
    } finally {
      isSaving.value = false;
    }
  }

  /// Shared create + update path. When [existing] is null this issues a
  /// create; otherwise it falls back to existing values for numeric fields
  /// and keeps existing images if the user didn't pick new ones.
  Future<bool> _saveCamp({
    required HealthCamp? existing,
    required String successMessage,
    required String failureFallback,
    required String operationLabel,
  }) async {
    try {
      isSaving.value = true;
      final imageUrls = await _uploadImagesToS3();
      final payload = _buildCampPayload(existing: existing, imageUrls: imageUrls);
      logs("HealthCamp $operationLabel payload: $payload");

      final ResponseModel res = existing == null
          ? await _repo.createHealthCamp(payload)
          : await _repo.updateHealthCamp(existing.id!, payload);

      if (res.isSuccess) {
        commonSnackBar(message: successMessage);
        await fetchCamps();
        return true;
      }
      final errorMsg = res.response?.data['message'] ??
          res.response?.data['error'] ??
          failureFallback;
      logs("HealthCamp $operationLabel failed: ${res.response?.data}");
      commonSnackBar(message: errorMsg.toString());
      return false;
    } catch (e) {
      logs("HealthCamp $operationLabel exception: $e");
      commonSnackBar(message: "${AppStrings.hotelErrorPrefix.tr} $e");
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Map<String, dynamic> _buildCampPayload({
    required HealthCamp? existing,
    required List<String> imageUrls,
  }) {
    final start = DateTime(startYear.value, startMonth.value, startDay.value)
        .toIso8601String();
    final end = DateTime(endYear.value, endMonth.value, endDay.value)
        .toIso8601String();

    // For updates, fall back to the existing record's value if the user
    // didn't change a numeric field.
    int? fallback(int? value) => existing == null ? null : value;

    final List<String>? finalImages = imageUrls.isNotEmpty
        ? imageUrls
        : (existing?.images);

    final validDiscounts = selectedTestDiscounts
        .where((d) => d.test?.id != null && d.test!.id!.isNotEmpty)
        .toList();

    return HealthCamp(
      id: existing?.id,
      sqFoot: int.tryParse(sqFootController.text.trim()) ??
          fallback(existing?.sqFoot) ??
          0,
      title: typeController.text.trim(),
      description: descController.text.trim(),
      price: int.tryParse(priceController.text.trim()) ??
          fallback(existing?.price) ??
          0,
      discountPrice: int.tryParse(discountPriceController.text.trim()) ??
          fallback(existing?.discountPrice) ??
          0,
      startDate: start,
      endDate: end,
      startTime: selectedTime.value,
      laboratoryId: existing?.laboratoryId ?? labIDGlobal,
      images: finalImages,
      location: (lat.value != 0.0 || lng.value != 0.0)
          ? HealthCampLocation(
              name: searchController.text.trim(),
              type: "Point",
              coordinates: [lng.value, lat.value],
            )
          : null,
      testDiscounts: validDiscounts.isNotEmpty ? validDiscounts : null,
    ).toJson();
  }

  // ---- Form pre-fill --------------------------------------------------------

  /// Pre-fills the form with [camp] for edit, or clears every field for a
  /// fresh create.
  void preloadForm(HealthCamp? camp) {
    if (camp == null) {
      _resetFormFields();
    } else {
      _applyCampToForm(camp);
    }
    validateForm();
  }

  void _resetFormFields() {
    typeController.clear();
    descController.clear();
    sqFootController.clear();
    priceController.clear();
    discountPriceController.clear();
    searchController.clear();
    selectedTime.value = "";

    final now = DateTime.now();
    startDay.value = now.day;
    startMonth.value = now.month;
    startYear.value = now.year;
    endDay.value = now.day;
    endMonth.value = now.month;
    endYear.value = now.year;

    lat.value = 0.0;
    lng.value = 0.0;
    selectedImages.clear();
    selectedTestCategories.clear();
    selectedTestDiscounts.clear();
    labTestsMap.clear();
    addDiscountTestEnabled.value = false;
  }

  void _applyCampToForm(HealthCamp camp) {
    typeController.text = camp.title ?? '';
    descController.text = camp.description ?? '';
    sqFootController.text = (camp.sqFoot ?? 0).toString();
    priceController.text = (camp.price ?? 0).toString();
    discountPriceController.text = (camp.discountPrice ?? 0).toString();
    selectedTime.value = camp.startTime ?? '';
    selectedImages.clear();

    selectedTestDiscounts.value = (camp.testDiscounts ?? [])
        .where((d) => d.test?.testName != null && d.test!.testName!.isNotEmpty)
        .toList();

    final loc = camp.location;
    if (loc != null) {
      searchController.text = loc.name ?? '';
      final coords = loc.coordinates;
      lng.value = (coords != null && coords.isNotEmpty) ? coords[0] : 0.0;
      lat.value = (coords != null && coords.length >= 2) ? coords[1] : 0.0;
    } else {
      searchController.clear();
      lat.value = 0.0;
      lng.value = 0.0;
    }

    labTestsMap.clear();
    addDiscountTestEnabled.value = selectedTestDiscounts.isNotEmpty;

    _applyDateRange(camp.startDate, camp.endDate);
  }

  void _applyDateRange(String? startIso, String? endIso) {
    final s = DateTime.tryParse(startIso ?? '');
    if (s != null) {
      startDay.value = s.day;
      startMonth.value = s.month;
      startYear.value = s.year;
    }
    final e = DateTime.tryParse(endIso ?? '');
    if (e != null) {
      endDay.value = e.day;
      endMonth.value = e.month;
      endYear.value = e.year;
    }
  }
}
