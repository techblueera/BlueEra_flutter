import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/me/hospital/model/hospita_ai_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_repo.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_service_preview.dart';
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

  Rx<HospitalAiDetailsResModel>? aiHospitalResModel =
      HospitalAiDetailsResModel().obs;

  Future<void> aiHospitalFetchDetailsController() async {
    String hospitalName = searchController.text;
    labAddress.value = hospitalName;
    String website = websiteController.text;
    // Logic for AI generation goes here
    Get.back();
    try {
      ResponseModel response =
          await hospitalServiceRepo.aiHospitalFetchDetailsRepo(reqBody: {
        ApiKeys.name: hospitalName,
        ApiKeys.url: website,
        ApiKeys.address: hospitalName,
      });
      if (response.isSuccess) {
        final data = response.response?.data;
        aiHospitalResModel?.value = HospitalAiDetailsResModel.fromJson(data);

        Get.to(HospitalServicePreview());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      commonSnackBar(message: e.toString());
    }
  }

  Future<void> createHospitalServiceController() async {
    try {
      aiHospitalResModel?.value.data?.category = businessCategoryGlobal;
      ResponseModel response = await hospitalServiceRepo.createHospitalRepo(
          reqBody: {"aiOutput": aiHospitalResModel?.value.data});
      if (response.isSuccess) {
        commonSnackBar(message: "Hospital Service Created successfully");

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
        Get.until((route) =>
            route.settings.name ==
            RouteHelper.getBottomNavigationBarScreenRoute());
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      hasHospitalCreated.value = false;

      commonSnackBar(message: e.toString());
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
          commonSnackBar(message: "Added Successfully");
        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      }
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong);

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

      final ResponseModel res =
          await HospitalRepo().listHospitalProfiles(page: p, limit: limit,type:type );

      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        final items = data.map((e) => HospitalFullData.fromJson(e)).toList();
        if (items.isEmpty) {
          hasMore.value = false;
        } else {
          profiles.addAll(items);
        }
      } else {
        hasMore.value = false;
        error.value = res.message ?? AppStrings.somethingWentWrong;
        commonSnackBar(message: error.value);
      }
    } catch (e) {
      hasMore.value = false;
      error.value = e.toString();
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
}
