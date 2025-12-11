import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/common/food/repo/food_ai_repo.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewStoreController extends GetxController{
  Rx<ApiResponse> getAllStoreResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreProductResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllFoodServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getListOfAiMessageResponse =
      ApiResponse.initial('Initial').obs;


  final ScrollController scrollController = ScrollController();
  final GlobalKey headerKey = GlobalKey();
  Function(bool isVisible)? onHeaderVisibilityChanged;
  final RxBool isHeaderVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;
  double headerHeight = 0;

  // Search Management
  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;
  Timer? debounce;

  String? typeOfBusiness;
  String? businessCategoryId;

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

  /// All Food service data
  RxList<GetFoodDetailsModel> foodDataList = <GetFoodDetailsModel>[].obs;
  RxBool isFoodDataLoadingMore = false.obs;
  RxBool isFoodDataFirstLoading = false.obs;
  int foodDataPage = 1;
  bool foodDataHasMore = true;

  /// Store Ai Variables
  TextEditingController sendMessageController = TextEditingController();
  RxBool isTextFieldEmpty = false.obs;
  final ScrollController aiChatScrollController = ScrollController();
  RxBool chatBotReading = false.obs;


  RxBool isBannerVisible = false.obs;
  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(() {
      if (scrollController.offset > 300) {
        isBannerVisible.value = true;
      } else {
        isBannerVisible.value = false;
      }
    });
  }

  @override
  void onClose() {
    debounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  ///GET STORES ONLY....
  Future<void>  getAllStoreNearBy({bool isLoadMore = false}) async {
    // if(typeOfBusiness == null || businessCategoryId == null){
    //   commonSnackBar(message: 'Business Category id not found');
    //   return;
    // }

    if (isLoadMore) {
      if (isAllStoreLoadingMore.value || !allStoreHasMore) return;
      isAllStoreLoadingMore.value = true;
    } else {
      isAllStoreFirstLoading.value = true;
      allStore.clear();
      allStorePage = 1;
      allStoreHasMore = true;

      if(typeOfBusiness == null && businessCategoryId == null){
        final cachedFood = await HiveServices().getAllStore(userId);
        if (cachedFood != null && cachedFood.isNotEmpty) {
          allStore.assignAll(cachedFood);
          isAllStoreFirstLoading.value = false; // show instantly
        }
      }
    }

    try {

      Map<String, dynamic> queryParams = {
        ApiKeys.page: allStorePage,
        ApiKeys.limit: 20,
        ApiKeys.lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "0.0",
        ApiKeys.lng: LocationService.lng != 0.0 ? "${LocationService.lng}" : "0.0",
        ApiKeys.categoryId: businessCategoryId,
        ApiKeys.type: typeOfBusiness,
        ApiKeys.radius: kmRadius1500
      };

      final response = await StoreRepo().getSpecificStores(
        queryParams: queryParams
      ); // Make sure repo uses params
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

        log("Loaded ${newStores.length} stores");

        newStores = newStores
            .where((store) =>
        (store.livePhotos != null &&
            store.livePhotos!.isNotEmpty &&
            store.livePhotos!.any((p) => p.trim().isNotEmpty)))
            .toList();

        if (newStores.isNotEmpty) {
          if (isLoadMore) {
            allStore.addAll(newStores);
          } else {
            allStore.assignAll(newStores);
            if(typeOfBusiness == null && businessCategoryId == null){
              await HiveServices().saveAllStore(allStore, userId);
            }
          }

          allStorePage++;
        } else {
          allStoreHasMore = false;
        }

        log("Total: ${allStore.length}");
      } else {

        getAllStoreResponse.value = ApiResponse.error('error');

        log("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      log("Error: $e");
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
  Future<void> getAllStoreProductNearBy({
    bool isLoadMore = false,
    String? query}
      ) async {
    if (isLoadMore) {
      if (isStoreProductDataLoadingMore.value || !storeProductDataHasMore) return;
      isStoreProductDataLoadingMore.value = true;
    } else {
      isStoreProductDataFirstLoading.value = true;
      storeProductDataPage = 1;
      storeProductDataHasMore = true;
      storeProductDataList.clear();

      /// fetch local data not for search
      if(query == null){
        final cachedProduct = await HiveServices().getAllStoreProduct(userId);
        if (cachedProduct != null && cachedProduct.isNotEmpty) {
          storeProductDataList.assignAll(cachedProduct);
          isStoreProductDataFirstLoading.value = false;
        }
      }

    }

    try {
      log('lat--> ${LocationService.lat}, lng--> ${LocationService.lng}');
      final response;
      if(query != null){
        response = await StoreRepo().productSearchFilterRepo(
            page: storeProductDataPage,
            lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
            long: LocationService.lng != 0.0
                ? "${LocationService.lng}"
                : "",
            query: query
        );
      }else{
        response = await StoreRepo().homePageProductRepo(
            page: storeProductDataPage,
            lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
            long: LocationService.lng != 0.0
                ? "${LocationService.lng}"
                : ""
        );
      }

      if (response.isSuccess) {
        getAllStoreProductResponse.value = ApiResponse.complete(response);
        final getOwnProductModel =
        GetProductModel.fromJson(response.response?.data);

        final List<GetProductData> newData = getOwnProductModel.data;

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            storeProductDataList.addAll(newData);
          } else {
            storeProductDataList.assignAll(newData);
            log('product data length--> ${storeProductDataList.length}');
            log('loggggg 1--> ${storeProductDataList[0].product.business_name}');

            if(query == null) {
              await HiveServices().saveAllStoreProduct(
                  storeProductDataList, userId);
            }
          }
          storeProductDataPage++;
        }
      } else {
        storeProductDataHasMore = false;
        getAllStoreProductResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      getAllStoreProductResponse.value = ApiResponse.error('error');
    } finally{
      if (isLoadMore) {
        isStoreProductDataLoadingMore.value = false;
      } else {
        isStoreProductDataFirstLoading.value = false;
      }
    }
  }

  ///GET FOOD SERVICES ONLY....
  Future<void> getAllFoodServiceNearBy({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFoodDataLoadingMore.value || !foodDataHasMore) return;
      isFoodDataLoadingMore.value = true;
    } else {
      isFoodDataFirstLoading.value = true;
      final cachedFood = await HiveServices().getAllStoreFoodServices(userId);
      if (cachedFood != null && cachedFood.isNotEmpty) {
        foodDataList.assignAll(cachedFood);
        isFoodDataFirstLoading.value = false;
      } else {
        foodDataList.clear();
      }
      foodDataPage = 1;
      foodDataHasMore = true;
    }

    try {
      Map<String, dynamic> params = {
        ApiKeys.page: foodDataPage,
        ApiKeys.all: true,
        ApiKeys.type: AppConstants.food,
        ApiKeys.radius: kmRadius1000,
        ApiKeys.limit: 20
      };
      ResponseModel responseModel = await FoodAiRepo().getFoodService(queryParam: params);
      if (responseModel.isSuccess) {
        getAllFoodServiceResponse.value = ApiResponse.complete(responseModel);

        final data = responseModel.response?.data;
        List<GetFoodDetailsModel> newItems = [];

        if (data is List) {
          // API returns raw array
          newItems = data.map((e) => GetFoodDetailsModel.fromJson(e)).toList();
        } else if (data is Map && data['data'] is List) {
          newItems = (data['data'] as List)
              .map((e) => GetFoodDetailsModel.fromJson(e))
              .toList();
        } else {
          log("Unexpected API response: $data");
        }

        if (newItems.isNotEmpty) {
          if (isLoadMore) {
            foodDataList.addAll(newItems);
          } else {
            foodDataList.assignAll(newItems);
            await HiveServices().saveAllStoreFoodServices(newItems, userId);
          }

          foodDataPage++;
        } else {
          foodDataHasMore = false;
        }

        log("Loaded ${newItems.length} items | Total: ${foodDataList.length}");
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

  RxBool aiInventoryLoading = false.obs;

  /// Ask Ai Inventory
  Future<void> askAiInventory({required String message}) async {

    try {
      aiInventoryLoading.value = true;
      final response = await StoreRepo().askAiInventoryRepo(
        params: {
          ApiKeys.query: message
        },
      );

      if (response.isSuccess) {
        getListOfAiMessageResponse.value = ApiResponse.complete(response);
        // final getOwnProductModel =
        // GetProductModel.fromJson(response.response?.data);
        //
        // final List<GetProductData> newData = getOwnProductModel.data;
        //
        // if (newData.isNotEmpty) {
        //   if (isLoadMore) {
        //     storeProductDataList.addAll(newData);
        //   } else {
        //     storeProductDataList.assignAll(newData);
        //     log('product data length--> ${storeProductDataList.length}');
        //     log('loggggg 1--> ${storeProductDataList[0].product.business_name}');
        //
        //     if(query == null) {
        //       await HiveServices().saveAllStoreProduct(
        //           storeProductDataList, userId);
        //     }
        //   }
        //   storeProductDataPage++;
        // }
      } else {
        storeProductDataHasMore = false;
        getListOfAiMessageResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      getListOfAiMessageResponse.value = ApiResponse.error('error');
    } finally{
      aiInventoryLoading.value = false;
    }
  }



}