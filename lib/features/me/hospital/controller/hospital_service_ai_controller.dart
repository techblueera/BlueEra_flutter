import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/model/business_filter_res_model.dart';
import 'package:BlueEra/features/me/hospital/model/business_filter_to_hospital_adapter.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalServiceAiController extends GetxController {
  HospitalRepo hospitalServiceRepo = HospitalRepo();

  ///GENERATE VIA AI LAB DETAILS....
  final searchController = TextEditingController();
  final websiteController = TextEditingController();
  RxString labAddress = "".obs;
  RxBool hasHospitalCreated = false.obs;

  // Your existing Rx list of departments
  var departments = <dynamic>[].obs;

  // UI State
  var selectedType = 'OPD'.obs; // Toggle between OPD and IPD
  var selectedCategoryId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize first category if available
    if (departments.isNotEmpty) {
      selectedCategoryId.value = departments.first['_id'];
    }
  }

// Filtered Departments based on Type (OPD/IPD)
  List get filteredCategories =>
      departments.where((dept) => dept['type'] == selectedType.value).toList();

  // Get current list of items (Doctors or Beds)
  List get currentItems {
    final dept = departments.firstWhere(
      (d) => d['_id'] == selectedCategoryId.value,
      orElse: () => null,
    );
    if (dept == null) return [];
    return selectedType.value == 'OPD' ? dept['opd'] : dept['ipd'];
  }

  clearFiled() {
    searchController.clear();
    websiteController.clear();
    labAddress.value = "";
  }

  RxBool isaiResponseLoading = false.obs;

  Future<void> createHospitalServiceController(
      {required Map<String, dynamic> reqData}) async {
    try {
      ResponseModel response = await hospitalServiceRepo
          .createHospitalRepo(reqBody: {"aiOutput": reqData});
      if (response.isSuccess) {
        commonSnackBar(
            message: AppStrings.hospitalCtrlServiceCreatedSuccess.tr);

        labAddress.value = "";
        String? hospitalID = response.response?.data['hospitalId'];
        if (hospitalID != null && hospitalID.isNotEmpty) {
          await setHospitalID(hospitalID);
        } else {
          await setHospitalID("");
        }
        await getHospitalID();
        await Future.delayed(Duration(milliseconds: 200));
        hasHospitalCreated.value = true;
      } else {}
    } on Exception {
      hasHospitalCreated.value = false;
    }
  }

  Rx<HospitalFullDetailsResModel>? hospitalDataResModel =
      HospitalFullDetailsResModel().obs;

  RxString selectedTab = "OPD".obs; // Tracks 'OPD' or 'IPD'
  RxInt selectedDeptIndex = 0.obs; // Tracks selected category chip
  RxInt selectedIpdDeptIndex = 0.obs; // Tracks selected category chip

  /// Departments filtered by [type] ("OPD" or "IPD").
  List<IpdOpdDepartments> _departmentsOfType(String type) =>
      (hospitalDataResModel?.value.data?.departments ?? [])
          .where((dept) => dept.type == type)
          .toList();

  List<IpdOpdDepartments> get filteredOpdDepartments =>
      _departmentsOfType("OPD");
  List<IpdOpdDepartments> get filteredIpdDepartments =>
      _departmentsOfType("IPD");

  /// Items (doctors or beds) for the currently selected chip on the given
  /// tab — guards against stale index values when the user switches tabs.
  List<dynamic> _itemsFor({
    required List<IpdOpdDepartments> depts,
    required RxInt indexRx,
    required List<dynamic>? Function(IpdOpdDepartments) extract,
  }) {
    if (depts.isEmpty) return [];
    if (indexRx.value >= depts.length) indexRx.value = 0;
    return extract(depts[indexRx.value]) ?? [];
  }

  List<dynamic> get currentCategoryItems => _itemsFor(
        depts: filteredOpdDepartments,
        indexRx: selectedDeptIndex,
        extract: (d) => d.opd,
      );

  List<dynamic> get currentCategoryItemsIpd => _itemsFor(
        depts: filteredIpdDepartments,
        indexRx: selectedIpdDeptIndex,
        extract: (d) => d.ipd,
      );

  // Call this when switching tabs to reset the category selection
  void changeTab(String type) {
    selectedTab.value = type;
    selectedDeptIndex.value = 0;
    selectedIpdDeptIndex.value = 0;
  }

  Future<void> getHospitalFullDetailsController() async {
    try {
      final ResponseModel response =
          await HospitalRepo().getHospitalFullDetailsRepo();
      if (response.isSuccess) {
        final model =
            HospitalFullDetailsResModel.fromJson(response.response?.data);
        hospitalDataResModel?.value = model;
        hospitalIDGlobal = model.data?.id ?? "";
      } else {
        hospitalIDGlobal = "";
      }
      await setHospitalID(hospitalIDGlobal);
      await getHospitalID();
      hasHospitalCreated.value = hospitalIDGlobal.isNotEmpty;
    } on Exception {
      // Swallow; existing behaviour — UI falls back to empty hospital state.
    }
  }

  Future<void> uploadHospitalLogoOrBannerImage({
    required File uploadFile,
    required String uploadVia,
  }) async {
    try {
      final result = await S3UploadService.uploadFile(uploadFile);
      if (!result.isSuccess) return;
      final response = await HospitalRepo()
          .updateHospitalInfoRepo(reqBODY: {uploadVia: result.url});
      if (response.isSuccess) {
        commonSnackBar(message: AppStrings.hospitalCtrlAddedSuccessfully.tr);
      }
    } on Exception {
      // Swallow; matches prior behaviour.
    }
  }

  final profiles = <HospitalFullData>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final error = ''.obs;

  int page = 1;
  final int limit = 10;

  Future<void> fetchInitial(String type) async {
    profiles.clear();
    page = 1;
    hasMore.value = true;
    await _fetch(page, isLoadMore: false, type: type);
  }

  Future<void> fetchMore(String type) async {
    if (!hasMore.value || isLoadingMore.value) return;
    page += 1;
    await _fetch(page, isLoadMore: true, type: type);
  }

  Future<void> _fetch(int p,
      {required bool isLoadMore, required String type}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
      }
      error.value = '';

      // Switched from `hospital-service/hospitals` to the shared
      // `user-service/business/filter` endpoint:
      //   GET user-service/business/filter?category=<type>&page=<p>&limit=<limit>
      // (e.g. category=HOSPITAL_SECTOR). Records come back in the
      // generic `BusinessFilterResModel` shape, so we adapt each
      // record to `HospitalFullData` to preserve `_HospitalCard`'s
      // existing field reads (logo/cover/gallery/address/phone/etc.).
      final ResponseModel res =
          await HospitalRepo().fetchHospitalsBusinessFilterRepo(
        category: type,
        page: p,
        limit: limit,
      );

      if (res.isSuccess) {
        final parsed = BusinessFilterResModel.fromJson(res.response?.data);
        final records = parsed.data ?? <BusinessFilterData>[];
        final items = records.map((e) => e.toHospitalFullData()).toList();

        if (items.isEmpty) {
          hasMore.value = false;
        } else {
          profiles.addAll(items);
        }

        // Prefer the server's pagination metadata when present — more
        // reliable than waiting for an empty page to flip `hasMore`.
        final pagination = parsed.pagination;
        final totalPages = pagination?.totalPages;
        final currentPage = pagination?.page ?? p;
        if (totalPages != null && currentPage >= totalPages) {
          hasMore.value = false;
        }
      } else {
        hasMore.value = false;
        error.value = res.message ?? AppStrings.somethingWentWrong;
      }
    } catch (e) {
      hasMore.value = false;
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
}
