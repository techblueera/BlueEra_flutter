import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/common/auth/model/business_category_response_model.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum BusinessHoursMode { selectedHours, alwaysOpen, appointmentsOnly }

class BusinessOnboardingController extends GetxController {
  static const int totalSteps = 6;
  static const int maxCategories = 1;
  static const int maxDescriptionChars = 512;

  static const List<String> weekDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  /// Step 1 — categories
  final RxBool isCategoriesLoading = false.obs;
  final RxList<BusinessCategory> allCategories = <BusinessCategory>[].obs;
  final RxList<BusinessCategory> selectedCategories = <BusinessCategory>[].obs;
  final RxBool showAllCategories = false.obs;

  /// Step 2 — hours mode
  final Rx<BusinessHoursMode?> hoursMode = Rx<BusinessHoursMode?>(null);

  /// Step 3 — per-day hours
  final RxMap<String, bool> dayOpen = <String, bool>{
    for (final d in weekDays) d: false,
  }.obs;
  final RxMap<String, List<DayHourSlot>> daySlots =
      <String, List<DayHourSlot>>{
    for (final d in weekDays) d: <DayHourSlot>[_defaultSlot()],
  }.obs;

  /// Step 4 — profile photo
  final RxString logoPath = ''.obs;

  /// Step 5 — address & website
  final TextEditingController addressController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final RxString fullAddress = ''.obs;
  final RxBool noPhysicalLocation = false.obs;
  final RxDouble lat = 0.0.obs;
  final RxDouble lng = 0.0.obs;
  final RxString pincode = ''.obs;

  /// Step 6 — description
  final TextEditingController descriptionController = TextEditingController();
  final RxInt descriptionLength = 0.obs;

  /// Submit
  final RxBool isSubmitting = false.obs;

  static DayHourSlot _defaultSlot() => DayHourSlot(
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 18, minute: 0),
      );

  @override
  void onClose() {
    addressController.dispose();
    websiteController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// ── Step 1 ───────────────────────────────────────────────────────────
  Future<void> loadCategories() async {
    if (allCategories.isNotEmpty) return;
    isCategoriesLoading.value = true;
    try {
      final ResponseModel res = await AuthRepo().getBusinessCategoriesRepo();
      if (res.isSuccess) {
        final model = BusinessCategoryResponseModel.fromJson(
          Map<String, dynamic>.from(res.response?.data ?? {}),
        );
        allCategories.assignAll(
          (model.businessCategory ?? [])
              .where((e) => (e.name ?? '').trim().isNotEmpty)
              .toList(),
        );
      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
      }
    } catch (e) {
      logs('loadCategories error: $e');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  void toggleCategory(BusinessCategory cat) {
    final exists = selectedCategories.any((c) => c.id == cat.id);
    if (exists) {
      selectedCategories.removeWhere((c) => c.id == cat.id);
      return;
    }
    selectedCategories
      ..clear()
      ..add(cat);
  }

  bool isCategorySelected(BusinessCategory cat) =>
      selectedCategories.any((c) => c.id == cat.id);

  bool get canProceedFromCategory => selectedCategories.isNotEmpty;

  /// ── Step 2 ───────────────────────────────────────────────────────────
  void setHoursMode(BusinessHoursMode mode) {
    hoursMode.value = mode;
    if (mode == BusinessHoursMode.alwaysOpen) {
      for (final d in weekDays) {
        dayOpen[d] = true;
        daySlots[d] = [
          DayHourSlot(
            start: const TimeOfDay(hour: 0, minute: 0),
            end: const TimeOfDay(hour: 23, minute: 59),
          ),
        ];
      }
    } else if (mode == BusinessHoursMode.appointmentsOnly) {
      for (final d in weekDays) {
        dayOpen[d] = false;
      }
    }
  }

  bool get canProceedFromHoursMode => hoursMode.value != null;

  /// ── Step 3 ───────────────────────────────────────────────────────────
  void toggleDayOpen(String day, bool isOpen) {
    dayOpen[day] = isOpen;
    if (isOpen && (daySlots[day]?.isEmpty ?? true)) {
      daySlots[day] = [_defaultSlot()];
    }
  }

  void addSlot(String day) {
    final list = List<DayHourSlot>.from(daySlots[day] ?? const []);
    list.add(_defaultSlot());
    daySlots[day] = list;
  }

  void removeSlot(String day, int index) {
    final list = List<DayHourSlot>.from(daySlots[day] ?? const []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      if (list.isEmpty) list.add(_defaultSlot());
      daySlots[day] = list;
    }
  }

  void setSlotTime(String day, int index, {TimeOfDay? start, TimeOfDay? end}) {
    final list = List<DayHourSlot>.from(daySlots[day] ?? const []);
    if (index < 0 || index >= list.length) return;
    final cur = list[index];
    list[index] = DayHourSlot(
      start: start ?? cur.start,
      end: end ?? cur.end,
    );
    daySlots[day] = list;
  }

  bool get hasAnyOpenDay => dayOpen.values.any((v) => v);

  bool get canProceedFromSelectHours {
    if (hoursMode.value != BusinessHoursMode.selectedHours) return true;
    return hasAnyOpenDay;
  }

  /// ── Step 5 ───────────────────────────────────────────────────────────
  void setAddress({
    required String address,
    double? latitude,
    double? longitude,
    String? pin,
  }) {
    fullAddress.value = address;
    addressController.text = address;
    if (latitude != null) lat.value = latitude;
    if (longitude != null) lng.value = longitude;
    if (pin != null) pincode.value = pin;
  }

  void clearAddress() {
    fullAddress.value = '';
    addressController.clear();
    lat.value = 0.0;
    lng.value = 0.0;
    pincode.value = '';
  }

  bool get canProceedFromAddress {
    if (noPhysicalLocation.value) return true;
    return fullAddress.value.trim().isNotEmpty;
  }

  /// ── Step 6 / submit ─────────────────────────────────────────────────
  void setDescription(String value) {
    descriptionController.text = value;
    descriptionLength.value = value.length;
  }

  /// Build the schedule payload for the API. Mirrors the shape used by
  /// the existing BookingController/BusinessHoursSheetContent flow.
  List<Map<String, dynamic>> buildSchedulePayload() {
    final List<Map<String, dynamic>> out = [];
    if (hoursMode.value == BusinessHoursMode.appointmentsOnly) return out;

    for (final day in weekDays) {
      final isOpen = dayOpen[day] == true;
      final slots = daySlots[day] ?? const <DayHourSlot>[];
      out.add({
        'day': day,
        'isOpen': isOpen,
        'timeSlots': isOpen
            ? slots
                .map((s) => {
                      'startTime': _fmtTime(s.start),
                      'endTime': _fmtTime(s.end),
                    })
                .toList()
            : <Map<String, dynamic>>[],
      });
    }
    return out;
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<bool> submit() async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      await getUserLoginBusinessId();

      dio.MultipartFile? logoPart;
      final logo = logoPath.value;
      if (logo.isNotEmpty && File(logo).existsSync()) {
        final fileName = logo.split('/').last;
        logoPart =
            await dio.MultipartFile.fromFile(logo, filename: fileName);
      }

      final categories = selectedCategories;
      final primaryCategoryId = categories.isNotEmpty ? categories.first.id : null;
      final extraCategoryNames = categories.length > 1
          ? categories
              .skip(1)
              .map((c) => c.name ?? '')
              .where((n) => n.isNotEmpty)
              .join(', ')
          : '';

      final schedule = buildSchedulePayload();

      final params = <String, dynamic>{
        ApiKeys.businessId: businessId,
        if (logoPart != null) ApiKeys.logo_image: logoPart,
        if (primaryCategoryId != null && primaryCategoryId.isNotEmpty)
          ApiKeys.category_Of_Business: primaryCategoryId,
        if (extraCategoryNames.isNotEmpty)
          ApiKeys.category_other: extraCategoryNames,
        if (schedule.isNotEmpty) ApiKeys.schedule: schedule,
        if (!noPhysicalLocation.value && fullAddress.value.trim().isNotEmpty)
          ApiKeys.address: fullAddress.value.trim(),
        if (!noPhysicalLocation.value && (lat.value != 0.0 || lng.value != 0.0))
          ApiKeys.business_location: jsonEncode({
            ApiKeys.lat: lat.value.toString(),
            ApiKeys.lon: lng.value.toString(),
          }),
        if (!noPhysicalLocation.value && pincode.value.isNotEmpty)
          ApiKeys.pincode: pincode.value,
        if (websiteController.text.trim().isNotEmpty)
          ApiKeys.website_url: websiteController.text.trim(),
        if (descriptionController.text.trim().isNotEmpty)
          ApiKeys.business_description: descriptionController.text.trim(),
      };

      final res = await BusinessProfileRepo().updateBusinessProfileDetails(params);
      if (res.isSuccess) {
        if (Get.isRegistered<ViewBusinessDetailsController>()) {
          Get.find<ViewBusinessDetailsController>().viewBusinessProfile();
        }
        commonSnackBar(message: res.message ?? AppStrings.success.tr);
        Get.until((route) =>
            route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute() ||
            route.isFirst);
        return true;
      }
      commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
      return false;
    } catch (e) {
      logs('BusinessOnboardingController.submit error: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}

class DayHourSlot {
  final TimeOfDay start;
  final TimeOfDay end;

  DayHourSlot({required this.start, required this.end});
}
