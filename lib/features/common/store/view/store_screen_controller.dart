import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/hive_services.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/repo/service_ai_repo.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/all_stores_feed_response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../food/model/get_food_details_model.dart';
import '../../food/repo/food_ai_repo.dart';

class StoreScreenController extends GetxController {
  Rx<ApiResponse> getAllStoreFeedResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreProductResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllStoreServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getAllFoodServiceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> followResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> unFollowResponse =
      ApiResponse.initial('Initial').obs;


  // Scroll and Header Management
  final ScrollController scrollController = ScrollController();
  final GlobalKey headerKey = GlobalKey();
  Function(bool isVisible)? onHeaderVisibilityChanged;
  final RxBool isHeaderVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;
  double headerHeight = 0;

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
  Timer? debounce;

  /// All Stores feed data(Product, stores, food, services)
  RxList<AllStoresFeedData> allNearByStoresFeed = <AllStoresFeedData>[].obs;
  final RxList<List<AllStoresFeedData>> groupedStoreFeed = <List<AllStoresFeedData>>[].obs;
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

      // Try to load cached feed first
      final cachedFeed = await HiveServices().getAllStoresFeeds(userId);
      if (cachedFeed != null && cachedFeed.isNotEmpty) {
        isAllStoreFeedFirstLoading.value = false;
        allNearByStoresFeed.assignAll(cachedFeed);
        await Future(() {
          final newBlocks = _groupStoreFeed(allNearByStoresFeed);
          groupedStoreFeed.assignAll(newBlocks);
        });
      }else{
        allNearByStoresFeed.clear();
        groupedStoreFeed.clear();
      }

      // final locationData = await LocationService.fetchLocation(
      //   isPermissionRequired: false,
      // );
      //
      // if (locationData == null) {
      //   print("Location not granted or GPS not enabled");
      //   Get.find<BottomBarController>().currentIndex.value = 0;
      //   return;
      // }

       // Then fetch latest in background
       await getAllStoresFeedNearBy();
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
      allStoreFeedPage = 1;
      allStoreFeedHasMore = true;
    }

    try {
      log('lat--> ${LocationService.lat}, lng--> ${LocationService.lng}');
      final response = await StoreRepo().getAllStoresFeed(
        page: allStoreFeedPage,
        lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "0.0",
        long: LocationService.lng != 0.0 ? "${LocationService.lng}" : "0.0",
      );

      if (!response.isSuccess) {
        allStoreFeedHasMore = false;
        getAllStoreFeedResponse.value = ApiResponse.error('error');
        return;
      }

      // Parse API response
      final model = AllStoresFeedResponseModel.fromJson(response.response?.data);
      final List<AllStoresFeedData> newData = model.data ?? [];

      if (newData.isEmpty) {
        allStoreFeedHasMore = false;
        return;
      }

      if (isLoadMore) {
        allNearByStoresFeed.addAll(newData);
      } else {
        allNearByStoresFeed
          ..clear()
          ..addAll(newData);

        Future.microtask(() => HiveServices().saveAllStoresFeeds(newData, userId));
      }

      // Update grouped list in background (non-blocking)
      Future.microtask(() async {
        final newBlocks = _groupStoreFeed(newData);
        if (isLoadMore) {
          groupedStoreFeed.addAll(newBlocks);
        } else {
          groupedStoreFeed
            ..clear()
            ..addAll(newBlocks);
        }
      });

      //  Move to next page for pagination
      allStoreFeedPage++;

      getAllStoreFeedResponse.value = ApiResponse.complete(response);
    } catch (e, s) {
      log('Error in getAllStoresFeedNearBy → $e\nStacktrace → $s');
      getAllStoreFeedResponse.value = ApiResponse.error('error');
    } finally {
      isAllStoreFeedLoadingMore.value = false;
    }
  }

  List<List<AllStoresFeedData>> _groupStoreFeed(List<AllStoresFeedData> items) {
    final List<List<AllStoresFeedData>> grouped = [];
    final List<AllStoresFeedData> tempFood = [];

    for (var item in items) {
      final type = StoreTypeExtension.fromString(item.type);

      if (type == StoreType.food) {
        tempFood.add(item);
        if (tempFood.length == 2) {
          grouped.add(List.from(tempFood));
          tempFood.clear();
        }
      } else {
        if (tempFood.isNotEmpty) {
          grouped.add(List.from(tempFood));
          tempFood.clear();
        }
        grouped.add([item]);
      }
    }

    if (tempFood.isNotEmpty) {
      grouped.add(List.from(tempFood));
    }

    return grouped;
  }

  ///GET STORES ONLY....
  Future<void> getAllStoreNearBy({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isAllStoreLoadingMore.value || !allStoreHasMore) return;
      isAllStoreLoadingMore.value = true;
    } else {
      isAllStoreFirstLoading.value = true;
      final cachedFood = await HiveServices().getAllStore(userId);
      if (cachedFood != null && cachedFood.isNotEmpty) {
        allStore.assignAll(cachedFood);
        isAllStoreFirstLoading.value = false; // show instantly
      } else {
        allStore.clear();
      }
      allStorePage = 1;
      allStoreHasMore = true;
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
            await HiveServices().saveAllStore(allStore, userId);
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
        GetProductModel.fromJson(response.response?.businessCategory);

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
    } catch (e, s) {
      print("stack: $s");
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
  Future<void> getAllFoodService({bool isLoadMore = false}) async {
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
        "type": "food",
        "radius": kmRadius1000,
        'limit': 20
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
            await HiveServices().saveAllStoreFoodServices(newItems, userId);
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

  ///GET ALL SERVICE....
  Future<void> getAllServiceNearBy({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isServiceDataLoadingMore.value || !serviceDataHasMore) return;
      isServiceDataLoadingMore.value = true;
    } else {
      isServiceDataFirstLoading.value = true;
      final cachedFood = await HiveServices().getAllStoreServices(userId);
      if (cachedFood != null && cachedFood.isNotEmpty) {
        serviceDataList.assignAll(cachedFood);
        isServiceDataFirstLoading.value = false;
      } else {
        serviceDataList.clear();
      }

      serviceDataPage = 1;
      serviceDataHasMore = true;
    }

    try {
      final response = await ServiceAiRepo().getServiceRepo(
        queryParams: {
          ApiKeys.page: serviceDataPage,
          ApiKeys.all: true,
          "limit": 20,
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
            await HiveServices().saveAllStoreServices(serviceDataList, userId);
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

  /// FOLLOW BUSINESS USER
  Future<void> followBusinessUser({
    required String? businessId,
    required GetAllStoreResModel store,
  }) async {
    try {
      followResponse.value = ApiResponse.initial('Initial');

      final responseModel =
      await UserRepo().followUser(followUserId: businessId);

      if (responseModel.isSuccess) {
        followResponse.value = ApiResponse.complete(responseModel);

        /// Update store locally
        final updatedStore = store.copyWith(
          isFollowed: true,
          followerCount:
          ((int.tryParse(store.followerCount ?? '0') ?? 0) + 1).toString(),
        );

        /// Update both lists
        _updateStoreInLists(updatedStore);
      } else {
        followResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      followResponse.value = ApiResponse.error('error');
    }
  }

  /// UNFOLLOW BUSINESS USER
  Future<void> unFollowBusinessUser({
    required String? businessId,
    required GetAllStoreResModel store,
  }) async {
    try {
      unFollowResponse.value = ApiResponse.initial('Initial');

      final responseModel =
      await UserRepo().unfollowUser(followUserId: businessId);

      if (responseModel.isSuccess) {
        unFollowResponse.value = ApiResponse.complete(responseModel);

        /// Update store locally
        final updatedStore = store.copyWith(
          isFollowed: false,
          followerCount:
          ((int.tryParse(store.followerCount ?? '0') ?? 0) - 1).toString(),
        );

        /// Update both lists
        _updateStoreInLists(updatedStore);
      } else {
        unFollowResponse.value = ApiResponse.error('error');
        commonSnackBar(
          message: responseModel.message ?? AppStrings.somethingWentWrong,
        );
      }
    } catch (e) {
      unFollowResponse.value = ApiResponse.error('error');
    }
  }

  void _updateStoreInLists(GetAllStoreResModel updatedStore) {
    /// 1️⃣ Update in allStore list
    final index1 = allStore.indexWhere((s) => s.id == updatedStore.id);
    if (index1 != -1) {
      allStore[index1] = updatedStore;
    }

    /// 2️⃣ Update inside allNearByStoresFeed list
    final updatedFeed = allNearByStoresFeed.map((feedItem) {
      log('updated store id--> ${updatedStore.id}');
      log('feedItem.businessData?.id--> ${feedItem.businessData?.id}');
      if (feedItem.type == StoreType.business.name.toLowerCase() &&
          feedItem.businessData?.id == updatedStore.id) {
        log('do update');
        return feedItem.copyWith(businessData: updatedStore);
      }
      return feedItem;
    }).toList();

    allNearByStoresFeed.assignAll(updatedFeed);

    allStore.refresh();
    allNearByStoresFeed.refresh();

  }

  void updateStoreRatings(String businessId) {
    ///  Update inside allStore list
    final index1 = allStore.indexWhere((s) => s.id == businessId);
    if (index1 != -1) {
      final store = allStore[index1];
      allStore[index1] = store.copyWith(
        totalRatings: (int.parse(store.totalRatings ?? "0") + 1).toString(),
      );
    }

    /// Update inside allNearByStoresFeed list
    final updatedFeed = allNearByStoresFeed.map((feedItem) {
      if (feedItem.type == StoreType.business.name.toLowerCase() &&
          feedItem.businessData?.id == businessId) {
        final businessData = feedItem.businessData!;
        return feedItem.copyWith(
          businessData: businessData.copyWith(
            totalRatings: (int.parse(businessData.totalRatings ?? "0") + 1).toString(),
          ),
        );
      }
      return feedItem;
    }).toList();

    allNearByStoresFeed.assignAll(updatedFeed);

    /// Refresh reactive lists
    allStore.refresh();
    allNearByStoresFeed.refresh();

    log('Store rating count updated for businessId: $businessId');
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScrollEnd);
  }

  void _onScrollEnd() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      switch (selectedStoreIndex.value) {
        case 0:
          getAllStoresFeedNearBy(isLoadMore: true);
          break;
        case 1:
          getAllStoreProductNearBy(isLoadMore: true);
          break;
        case 2:
          getAllServiceNearBy(isLoadMore: true);
          break;
        case 3:
          getAllFoodService(isLoadMore: true);
          break;
        case 4:
          getAllStoreNearBy(isLoadMore: true);
          break;
      }
    }
  }


  @override
  void onClose() {
    debounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void onStoreTabChanged(int index) async {
    selectedStoreIndex.value = index;

    switch (index) {
      case 0: // All
        // if (allNearByStoresFeed.isEmpty) {
          await getAllStoresFeedNearBy();
        // }
        break;

      case 1: // Product
        // if (storeProductDataList.isEmpty) {
          await getAllStoreProductNearBy();
        // }
        break;

      case 2: // Service
        // if (serviceDataList.isEmpty) {
          await getAllServiceNearBy();
        // }
        break;

      case 3: // Food
        // if (foodDataList.isEmpty) {
          await getAllFoodService();
        // }
        break;

      case 4: // Store
        // if (allStore.isEmpty) {
          await getAllStoreNearBy();
        // }
        break;
    }
  }

}
