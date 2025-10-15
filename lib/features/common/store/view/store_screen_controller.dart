import 'dart:convert';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/auth/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/common/business_service/repo/service_ai_repo.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/all_stores_feed_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/response_model.dart';
import '../../food/model/get_food_details_model.dart';
import '../../food/repo/food_ai_repo.dart';

class StoreScreenController extends GetxController {
  Rx<ApiResponse> getAllStoreFeedResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreProductResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllFoodServiceResponse =
      ApiResponse.initial('Initial').obs;


  /// All Stores feed data(Product, stores, food, services)
  RxList<AllStoresFeedData> allNearByStoresFeed = <AllStoresFeedData>[].obs;
  RxBool isAllStoreFeedLoadingMore = false.obs;
  RxBool isAllStoreFeedFirstLoading = false.obs;
  int allStoreFeedPage = 1;
  bool allStoreFeedHasMore = true;

  /// All Stores data
  RxList<GetAllStoreResModel> allStore = <GetAllStoreResModel>[].obs;
  RxBool isAllStoreLoadingMore = false.obs;
  RxBool isAllStoreFirstLoading = false.obs;
  int allStorePage = 1;
  bool allStoreHasMore = true;

  /// Stores Product data
  RxList<GetProductData> storeProductDataList = <GetProductData>[].obs;
  RxBool isStoreProductDataLoadingMore = false.obs;
  RxBool isStoreProductDataFirstLoading = false.obs;
  int storeProductDataPage = 1;
  bool storeProductDataHasMore = true;

  /// All Service data
  RxList<GetServiceModel> serviceDataList = <GetServiceModel>[].obs;
  RxBool isServiceDataLoadingMore = false.obs;
  RxBool isServiceDataFirstLoading = false.obs;
  int serviceDataPage = 1;
  bool serviceDataHasMore = true;

  /// All Food service data
  RxList<GetFoodDetailsModel> foodDataList = <GetFoodDetailsModel>[].obs;
  RxBool isFoodDataLoadingMore = false.obs;
  RxBool isFoodDataFirstLoading = false.obs;
  int foodDataPage = 1;
  bool foodDataHasMore = true;

  Future<void> checkAndFetchAllStoresFeed() async {
    try {
      isAllStoreFeedFirstLoading.value = true;

      final locationData = await LocationService.fetchLocation(
        isPermissionRequired: true,
      );

      if (locationData != null) {
        // Permission granted and GPS enabled → fetch stores
        await getAllStoresFeedNearBy();
      } else {
        // Permission or GPS not enabled
        print("Location not granted or GPS not enabled");

        Get.find<BottomBarController>().currentIndex.value = 0;

        // Show a dialog and retry after user action
        // await Get.dialog(
        //   AlertDialog(
        //     backgroundColor: AppColors.white,
        //     title: CustomText(
        //       "Location Required",
        //       color: AppColors.black28,
        //       fontWeight: FontWeight.w700,
        //     ),
        //     content: CustomText(
        //       "This feature requires location access. Please enable location and try again.",
        //       color: AppColors.black28,
        //     ),
        //     actions: [
        //       TextButton(
        //         onPressed: () {
        //           Get.back(); // close dialog
        //           checkAndFetchAllStoresFeed(); // retry
        //         },
        //         child: CustomText(
        //           "OK",
        //           color: AppColors.primaryColor,
        //           fontWeight: FontWeight.w600,
        //         ),
        //       ),
        //     ],
        //   ),
        //   barrierDismissible: false,
        // );
      }
    } catch (e) {
      getAllStoreFeedResponse.value = ApiResponse.error('error');
    } finally {
      isAllStoreFeedFirstLoading.value = false;
    }
  }


  ///GET All Stores feed data(Product, stores, food, services)...
  Future<void> getAllStoresFeedNearBy({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isAllStoreFeedLoadingMore.value || !allStoreFeedHasMore) return;
      isAllStoreFeedLoadingMore.value = true;
    } else {
      isAllStoreFeedFirstLoading.value = true;
      allStoreFeedPage = 1;
      allStoreFeedHasMore = true;
      allNearByStoresFeed.clear();
    }
    try {
      final response = await StoreRepo().getAllStoresFeed(
          page: allStoreFeedPage,
          lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
          long: LocationService.lng != 0.0
              ? "${LocationService.lng}"
              : "");

      if (response.isSuccess) {
        getAllStoreFeedResponse.value = ApiResponse.complete(response);
        final AllStoresFeedResponseModel allStoresFeedResponseModel =
        AllStoresFeedResponseModel.fromJson(response.response?.data);

        final List<AllStoresFeedData> newData =
            allStoresFeedResponseModel.data ?? [];

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            allNearByStoresFeed.addAll(newData);
          } else {
            allNearByStoresFeed.assignAll(newData);
          }
          allStoreFeedPage++;
        }
      } else {
        allStoreFeedHasMore = false;
        getAllStoreFeedResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      // print("Error: $e");
      // print("stack trace: $s");
      getAllStoreFeedResponse.value = ApiResponse.error('error');
    } finally{
      isAllStoreFeedLoadingMore.value = false;
    }
  }

  ///GET FOOD SERVICES ONLY....
  Future<void> getAllFoodService({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFoodDataLoadingMore.value || !foodDataHasMore) return;
      isFoodDataLoadingMore.value = true;
    } else {
      isFoodDataFirstLoading.value = true;
      foodDataPage = 1;
      foodDataHasMore = true;
      foodDataList.clear();
    }

    try {
    Map<String, dynamic> params = {
      ApiKeys.page: foodDataPage,
      "all": true,
      "type": "food",
      "radius": kmRadius1000
    };
    ResponseModel responseModel =
        await FoodAiRepo().getFoodService(queryParam: params);
    if (responseModel.isSuccess) {
      getAllFoodServiceResponse.value = ApiResponse.complete(responseModel);

      final data = responseModel.response?.data;
      List<GetFoodDetailsModel> newItems = [];

      if (data is List) {
        // API returns raw array
        newItems = data.map((e) => GetFoodDetailsModel.fromJson(e)).toList();
      } else if (data is Map && data['data'] is List) {
        // API returns { "data": [...] }
        newItems = (data['data'] as List)
            .map((e) => GetFoodDetailsModel.fromJson(e))
            .toList();
      } else {
        print("Unexpected API response: $data");
      }

      if (newItems.isNotEmpty) {
        if (isLoadMore) {
          foodDataList.addAll(newItems);
        } else {
          foodDataList.assignAll(newItems);
        }

        foodDataPage++;
      } else {
        foodDataHasMore = false;
      }

      print("Loaded ${newItems.length} items | Total: ${foodDataList.length}");
    } else {
      getAllFoodServiceResponse.value = ApiResponse.error('error');
     }
    } catch (e) {
      getAllFoodServiceResponse.value = ApiResponse.error('error');
      log("ERROR===== $e");
    } finally{
      if (isLoadMore) {
        isFoodDataLoadingMore.value = false;
      } else {
        isFoodDataFirstLoading.value = false;
      }
    }
  }

  ///GET STORES ONLY....
  Future<void> getAllStoreNearBy({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isAllStoreLoadingMore.value || !allStoreHasMore) return;
      isAllStoreLoadingMore.value = true;
    } else {
      isAllStoreFirstLoading.value = true;
      allStorePage = 1;
      allStoreHasMore = true;
      allStore.clear();
    }

    try {

      final response = await StoreRepo().getStore(
          page: allStorePage,
          lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
          long: LocationService.lng != 0.0
              ? "${LocationService.lng}"
              : ""); // Make sure repo uses params
      if (response.isSuccess) {
        getAllStoreResponse.value = ApiResponse.complete(response);

        final responseData = response.response?.data;

        List<GetAllStoreResModel> newStores = [];

        // Handle both array or wrapped API formats
        if (responseData is List) {
          newStores = responseData
              .map((e) => GetAllStoreResModel.fromJson(e))
              .toList();
        } else if (responseData is Map && responseData['data'] is List) {
          newStores = (responseData['data'] as List)
              .map((e) => GetAllStoreResModel.fromJson(e))
              .toList();
        }

        if (newStores.isNotEmpty) {
          if (isLoadMore) {
            allStore.addAll(newStores);
          } else {
            allStore.assignAll(newStores);
          }

          allStorePage++;
        } else {
          allStoreHasMore = false;
        }

        print("Loaded ${newStores.length} stores | Total: ${allStore.length}");
      } else {

        getAllStoreResponse.value = ApiResponse.error('error');

        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      getAllStoreResponse.value = ApiResponse.error('error');
    }finally{
      if (isLoadMore) {
        isAllStoreLoadingMore.value = false;
      } else {
        isAllStoreFirstLoading.value = false;
      }
    }
  }

  ///GET STORE PRODUCT ONLY....
  Future<void> getAllStoreProductNearBy({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isStoreProductDataLoadingMore.value || !storeProductDataHasMore) return;
      isStoreProductDataLoadingMore.value = true;
    } else {
      isStoreProductDataFirstLoading.value = true;
      storeProductDataPage = 1;
      storeProductDataHasMore = true;
      storeProductDataList.clear();
    }

    try {

      final response = await StoreRepo().homePageProductRepo(
          page: storeProductDataPage,
          lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
          long: LocationService.lng != 0.0
              ? "${LocationService.lng}"
              : ""); // Make sure repo uses params
      if (response.isSuccess) {
        getAllStoreProductResponse.value = ApiResponse.complete(response);
        final getOwnProductModel =
        GetProductModel.fromJson(response.response?.data);

        final List<GetProductData> newData =
            getOwnProductModel.data;

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            storeProductDataList.addAll(newData);
          } else {
            storeProductDataList.assignAll(newData);
          }
          storeProductDataPage++;
        }
      } else {
        storeProductDataHasMore = false;
        getAllStoreProductResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      print("stack: $e");
      getAllStoreProductResponse.value = ApiResponse.error('error');
    } finally{
      if (isLoadMore) {
        isStoreProductDataLoadingMore.value = false;
      } else {
        isStoreProductDataFirstLoading.value = false;
      }
    }
  }

  ///GET ALL SERVICE....
  Future<void> getAllServiceNearBy({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isServiceDataLoadingMore.value || !serviceDataHasMore) return;
      isServiceDataLoadingMore.value = true;
    } else {
      isServiceDataFirstLoading.value = true;
      serviceDataPage = 1;
      serviceDataHasMore = true;
      serviceDataList.clear();
    }

    try {
      final response = await ServiceAiRepo().getServiceRepo(
        queryParams: {
          ApiKeys.page: serviceDataPage,
          "limit": 10, // adjust as per backend
          "radius": kmRadius1000,
          "type": "service",
        },
      );

      if (response.isSuccess) {
        final responseData = response.response?.data;
        List<GetServiceModel> newServices = [];

        // Handle both array or map API structures
        if (responseData is List) {
          newServices = responseData.map((e) => GetServiceModel.fromJson(e)).toList();
        } else if (responseData is Map && responseData['data'] is List) {
          newServices = (responseData['data'] as List)
              .map((e) => GetServiceModel.fromJson(e))
              .toList();
        } else {
          print(" Unexpected API structure: $responseData");
        }

        if (newServices.isNotEmpty) {
          if (isLoadMore) {
            serviceDataList.addAll(newServices);
          } else {
            serviceDataList.assignAll(newServices);
          }

          serviceDataPage++;
        } else {
          serviceDataHasMore = false;
        }

        getAllStoreServiceResponse.value = ApiResponse.complete(response);
        print("Loaded ${newServices.length} services | Total: ${serviceDataList.length}");
      } else {
        getAllStoreServiceResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("Stack: $s");
      getAllStoreServiceResponse.value = ApiResponse.error('error');
      serviceDataHasMore = false;
    } finally {
      if (isLoadMore) {
        isServiceDataLoadingMore.value = false;
      } else {
        isServiceDataFirstLoading.value = false;
      }
    }
  }

  // Scroll and Header Management
  final GlobalKey headerKey = GlobalKey();
  final ScrollController scrollController = ScrollController();
  Function(bool isVisible)? onHeaderVisibilityChanged;
  final RxDouble headerHeight = 0.0.obs;
  final RxBool isHeaderVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;
  RxInt selectedStoreIndex = 0.obs;
  final List<String> storeTab = [
    "All",
    "Product",
    "Service",
    "Food",
    "Store"
  ];

  // Search Management
  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;

  // Categories Data
  // final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;

  // Stores Data
  final RxList<Map<String, dynamic>> stores = <Map<String, dynamic>>[].obs;

  // @override
  // void onInit() {
  //   super.onInit();
  //   _setupListeners();
  //   _calculateHeaderHeight();
  // }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void onStoreTabChanged(int index) async {
    selectedStoreIndex.value = index;

    switch (index) {
      case 0: // All
        if (allNearByStoresFeed.isEmpty) {
          await getAllStoresFeedNearBy();
        }
        break;

      case 1: // Product
        if (storeProductDataList.isEmpty) {
          await getAllStoreProductNearBy();
        }
        break;

      case 2: // Service
        if (serviceDataList.isEmpty) {
          await getAllServiceNearBy();
        }
        break;

      case 3: // Food
        if (foodDataList.isEmpty) {
          await getAllFoodService();
        }
        break;

      case 4: // Store
        if (allStore.isEmpty) {
          await getAllStoreNearBy();
        }
        break;
    }
  }

}
