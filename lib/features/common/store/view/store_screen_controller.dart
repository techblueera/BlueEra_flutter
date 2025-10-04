import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/common/business_service/repo/service_ai_repo.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class StoreScreenController extends GetxController {
  Rx<ApiResponse> getAllStoreResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreProductResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreServiceResponse =
      ApiResponse.initial('Initial').obs;

  RxList<GetAllStoreResModel> getAllStore = <GetAllStoreResModel>[].obs;
  RxList<GetProductData> storeProductDataList = <GetProductData>[].obs;
  RxList<GetServiceModel> serviceDataList = <GetServiceModel>[].obs;
  RxBool isLoading = false.obs;

  Future<void> fetchStoresAndProducts() async {
    try {
      isLoading.value = true;

      // Run both APIs in parallel
      await LocationService.fetchLocation();

    await Future.wait([
        getAllStoreNearBy(),
        getAllServiceNearBy(),
        getAllStoreProductNearBy(),

      ]);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print("Error: $e");
      getAllStoreResponse.value = ApiResponse.error('error');
      getAllStoreProductResponse.value = ApiResponse.error('error');
    }
  }

  Future<void> getAllStoreNearBy() async {
    try {
      // isLoading.value = true;
      // await LocationService.fetchLocation();

      final response = await StoreRepo().getStore(
          lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
          long: LocationService.lng != 0.0
              ? "${LocationService.lng}"
              : ""); // Make sure repo uses params
      if (response.statusCode == 200) {
        final List<GetAllStoreResModel> places = List<GetAllStoreResModel>.from(
          (response.response!.data as List)
              .map((e) => GetAllStoreResModel.fromJson(e)),
        );

        getAllStore.value = places;
        getAllStoreResponse.value = ApiResponse.complete(response);
        // isLoading.value = false;
      } else {
        // isLoading.value = false;

        getAllStoreResponse.value = ApiResponse.error('error');

        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      // isLoading.value = false;

      print("Error: $e");

      getAllStoreResponse.value = ApiResponse.error('error');
    }
  }

  ///GET STORE PRODUCT ONLY....
  Future<void> getAllStoreProductNearBy() async {
    try {
      storeProductDataList.clear();
      final response = await StoreRepo().homePageProductRepo(
          lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
          long: LocationService.lng != 0.0
              ? "${LocationService.lng}"
              : ""); // Make sure repo uses params
      if (response.isSuccess) {
        final getOwnProductModel =
            GetProductModel.fromJson(response.response!.data);

        storeProductDataList.value = getOwnProductModel.data;
        getAllStoreProductResponse.value = ApiResponse.complete(response);
      } else {
        getAllStoreProductResponse.value = ApiResponse.error('error');

        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");

      getAllStoreProductResponse.value = ApiResponse.error('error');
    }
  }
///GET ALL SERVICE....
  Future<void> getAllServiceNearBy() async {
    try {
      serviceDataList.clear();
      final response =
          await ServiceAiRepo().getServiceRepo(); // Make sure repo uses params
      if (response.isSuccess) {
        // final getOwnProductModel =
        // GetServiceModel.fromJson(response.response!.data);
        //
        // serviceDataList.value = getOwnProductModel??[];


        List<dynamic> jsonData = json.decode(jsonEncode(response.response?.data));
        serviceDataList.value  =
        jsonData.map((e) => GetServiceModel.fromJson(e)).toList();

        getAllStoreServiceResponse.value = ApiResponse.complete(response);
      } else {
        getAllStoreServiceResponse.value = ApiResponse.error('error');

        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");

      getAllStoreServiceResponse.value = ApiResponse.error('error');
    }
  }

  // Scroll and Header Management
  final GlobalKey headerKey = GlobalKey();
  final ScrollController scrollController = ScrollController();
  final RxDouble headerHeight = 0.0.obs;
  final RxBool isHeaderVisible = true.obs;

  // Search Management
  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;

  // Categories Data
  // final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;

  // Stores Data
  final RxList<Map<String, dynamic>> stores = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    _calculateHeaderHeight();
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _setupListeners() {
    // Search controller listener
    searchController.addListener(() {
      searchText.value = searchController.text;
    });

    // Scroll controller listener
    scrollController.addListener(_onScroll);
  }

  void _calculateHeaderHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        headerHeight.value = renderBox.size.height;
      }
    });
  }

  void _onScroll() {
    if (scrollController.offset > 50 && isHeaderVisible.value) {
      toggleAppBarAndBottomNav(false);
    } else if (scrollController.offset <= 50 && !isHeaderVisible.value) {
      toggleAppBarAndBottomNav(true);
    }
  }

  void toggleAppBarAndBottomNav(bool visible) {
    if (isHeaderVisible.value != visible) {
      isHeaderVisible.value = visible;
      // Notify parent about visibility change
      Get.find<StoreScreenController>()
          .onHeaderVisibilityChanged
          ?.call(visible);
    }
  }

  // Callback for header visibility changes
  Function(bool isVisible)? onHeaderVisibilityChanged;
}
