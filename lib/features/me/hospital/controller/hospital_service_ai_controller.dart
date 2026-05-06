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





    RxBool isaiResponseLoading=false.obs;

  Future<void> createHospitalServiceController({required Map<String,dynamic> reqData}) async {
    try {
      ResponseModel response = await hospitalServiceRepo.createHospitalRepo(
          reqBody: {"aiOutput": reqData});
      if (response.isSuccess) {
        commonSnackBar(message: AppStrings.hospitalCtrlServiceCreatedSuccess.tr);

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
      } else {
      }
    } on Exception {
      hasHospitalCreated.value = false;

    }
  }

  Rx<HospitalFullDetailsResModel>? hospitalDataResModel =
      HospitalFullDetailsResModel().obs;

  RxString selectedTab = "OPD".obs; // Tracks 'OPD' or 'IPD'
  RxInt selectedDeptIndex = 0.obs; // Tracks selected category chip
  RxInt selectedIpdDeptIndex = 0.obs; // Tracks selected category chip

  // 1. Get departments filtered by the current Tab (OPD or IPD)
  List<IpdOpdDepartments> get filteredOpdDepartments {
    var allDepts = hospitalDataResModel?.value.data?.departments ?? [];
    return allDepts.where((dept) => dept.type == "OPD").toList();
  }

  // 2. Get the actual list of doctors or beds based on selection
  List<dynamic> get currentCategoryItems {
    if (filteredOpdDepartments.isEmpty) return [];

    // Ensure index doesn't go out of bounds if tab switches
    if (selectedDeptIndex.value >= filteredOpdDepartments.length) {
      selectedDeptIndex.value = 0;
    }

    var dept = filteredOpdDepartments[selectedDeptIndex.value];
    return (dept.opd ?? []);
  }

  // 1. Get departments filtered by the current Tab (OPD or IPD)
  List<IpdOpdDepartments> get filteredIpdDepartments {
    var allDepts = hospitalDataResModel?.value.data?.departments ?? [];
    return allDepts.where((dept) => dept.type == "IPD").toList();
  }

  // 2. Get the actual list of doctors or beds based on selection
  List<dynamic> get currentCategoryItemsIpd {
    if (filteredIpdDepartments.isEmpty) return [];

    // Ensure index doesn't go out of bounds if tab switches
    if (selectedIpdDeptIndex.value >= filteredIpdDepartments.length) {
      selectedIpdDeptIndex.value = 0;
    }

    var dept = filteredIpdDepartments[selectedIpdDeptIndex.value];
    return (dept.ipd ?? []);
  }

  // Call this when switching tabs to reset the category selection
  void changeTab(String type) {
    selectedTab.value = type;
    selectedDeptIndex.value = 0;
    selectedIpdDeptIndex.value = 0;
  }

  getHospitalFullDetailsController() async {
    try {
      hospitalIDGlobal = "";
      if (hospitalIDGlobal.isEmpty) {
        ResponseModel response =
            await HospitalRepo().getHospitalFullDetailsRepo();
        if (response.isSuccess) {
          hospitalDataResModel?.value =
              HospitalFullDetailsResModel.fromJson(response.response?.data);
          hospitalIDGlobal = hospitalDataResModel?.value.data?.id ?? "";

          if (hospitalIDGlobal.isNotEmpty) {
            await setHospitalID(hospitalIDGlobal);
          } else {
            hospitalIDGlobal = "";
            await setHospitalID("");
          }
        } else {
          hospitalIDGlobal = "";
          await setHospitalID("");
        }
      }
      await getHospitalID();
      hasHospitalCreated.value = hospitalIDGlobal.isNotEmpty;
    } on Exception {
      // TODO
    }
  }

  uploadHospitalLogoOrBannerImage(
      {required File uploadFile, required String uploadVia}) async {
    try {
      UploadResult? result = await S3UploadService.uploadFile(uploadFile);
      if (result.isSuccess) {
        ResponseModel response =
            await HospitalRepo().updateHospitalInfoRepo(reqBODY: {
          uploadVia: result.url,
        });
        if (response.isSuccess) {
          commonSnackBar(message: AppStrings.hospitalCtrlAddedSuccessfully.tr);
        } else {
        }
      }
    } on Exception {

      // TODO
    }
  }

  final profiles = <HospitalFullData>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final error = ''.obs;

  int page = 1;
  final int limit = 10;

  // void onInit() {
  //   super.onInit();
  //   fetchInitial();
  // }

  Future<void> fetchInitial(String type) async {
    profiles.clear();
    page = 1;
    hasMore.value = true;
    await _fetch(page, isLoadMore: false,type: type);
  }

  Future<void> fetchMore(String type) async {
    if (!hasMore.value || isLoadingMore.value) return;
    page += 1;
    await _fetch(page, isLoadMore: true,type:type );
  }

  Future<void> _fetch(int p, {required bool isLoadMore,required String type}) async {
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
