import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:get/get.dart';


class EarnWithBlueEraController extends GetxController{
  Rx<ApiResponse> ownProductsResponse =
      ApiResponse.initial('Initial').obs;

  RxInt selectedProductsServicesTabIndex = 0.obs;
  final List<String> productsServicesTab = [
    "Product",
    "Food",
    "Home Services",
    "Rental Services",
  ];
  RxBool showGoLiveEnabled = false.obs;

  /// Product data
  RxList<GetProductData> ownProductDataList = <GetProductData>[].obs;
  RxBool isOwnProductDataLoadingMore = false.obs;
  RxBool isOwnProductDataFirstLoading = false.obs;
  int ownProductDataPage = 1;
  bool ownProductDataHasMore = true;

  /// Food Service Data
  RxList<GetProductData> ownFoodDataList = <GetProductData>[].obs;
  RxBool isOwnFoodDataLoadingMore = false.obs;
  RxBool isOwnFoodDataFirstLoading = false.obs;
  int ownFoodDataPage = 1;
  bool ownFoodDataHasMore = true;

  /// Services data
  RxList<GetProductData> ownServiceDataList = <GetProductData>[].obs;
  RxBool isOwnServiceDataLoadingMore = false.obs;
  RxBool isOwnServiceDataFirstLoading = false.obs;
  int ownServiceDataPage = 1;
  bool ownServiceDataHasMore = true;

  Future<void> fetchOwnProducts({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isOwnProductDataLoadingMore.value || !ownProductDataHasMore) return;
      isOwnProductDataLoadingMore.value = true;
    } else {
      isOwnProductDataFirstLoading.value = true;
      ownProductDataPage = 1;
      ownProductDataHasMore = true;
      ownProductDataList.clear();
    }

    try {

      Map<String, dynamic> queryParams = {
        'DRAFT': false,
        'ownerId': userId,
        'ownerType': ProductServiceProviderType.user.title,
      };


      final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsApi(queryParams: queryParams);
      if (response.isSuccess) {
        ownProductsResponse.value = ApiResponse.complete(response);
        final getProductModel =
        GetProductModel.fromJson(response.response?.data);

        final List<GetProductData> newData =
            getProductModel.data;

        if (newData.isNotEmpty) {
          if (isLoadMore) {
            ownProductDataList.addAll(newData);
          } else {
            ownProductDataList.assignAll(newData);
          }
          ownProductDataPage++;
        }
      } else {
        ownProductDataHasMore = false;
        ownProductsResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      print("stack trace: $s");
    } finally {
      if (isLoadMore) {
        isOwnProductDataLoadingMore.value = false;
      } else {
        isOwnProductDataFirstLoading.value = false;
      }
    }
  }



  // ///GET FOOD SERVICES ONLY....
  // Future<void> getAllFoodService({bool isLoadMore = false}) async {
  //   if (isLoadMore) {
  //     if (isFoodDataLoadingMore.value || !foodDataHasMore) return;
  //     isFoodDataLoadingMore.value = true;
  //   } else {
  //     isFoodDataFirstLoading.value = true;
  //     foodDataPage = 1;
  //     foodDataHasMore = true;
  //     foodDataList.clear();
  //   }
  //
  //   try {
  //     Map<String, dynamic> params = {
  //       ApiKeys.page: foodDataPage,
  //       "all": true,
  //       "type": "food",
  //       "radius": kmRadius1000
  //     };
  //     ResponseModel responseModel =
  //     await FoodAiRepo().getFoodService(queryParam: params);
  //     if (responseModel.isSuccess) {
  //       getAllFoodServiceResponse.value = ApiResponse.complete(responseModel);
  //
  //       final data = responseModel.response?.data;
  //       List<GetFoodDetailsModel> newItems = [];
  //
  //       if (data is List) {
  //         // API returns raw array
  //         newItems = data.map((e) => GetFoodDetailsModel.fromJson(e)).toList();
  //       } else if (data is Map && data['data'] is List) {
  //         // API returns { "data": [...] }
  //         newItems = (data['data'] as List)
  //             .map((e) => GetFoodDetailsModel.fromJson(e))
  //             .toList();
  //       } else {
  //         print("Unexpected API response: $data");
  //       }
  //
  //       if (newItems.isNotEmpty) {
  //         if (isLoadMore) {
  //           foodDataList.addAll(newItems);
  //         } else {
  //           foodDataList.assignAll(newItems);
  //         }
  //
  //         foodDataPage++;
  //       } else {
  //         foodDataHasMore = false;
  //       }
  //
  //       print("Loaded ${newItems.length} items | Total: ${foodDataList.length}");
  //     } else {
  //       getAllFoodServiceResponse.value = ApiResponse.error('error');
  //     }
  //   } catch (e) {
  //     getAllFoodServiceResponse.value = ApiResponse.error('error');
  //     log("ERROR===== $e");
  //   } finally{
  //     if (isLoadMore) {
  //       isFoodDataLoadingMore.value = false;
  //     } else {
  //       isFoodDataFirstLoading.value = false;
  //     }
  //   }
  // }
  //
  // ///GET STORES ONLY....
  // Future<void> getAllStoreNearBy({bool isLoadMore = false}) async {
  //   if (isLoadMore) {
  //     if (isAllStoreLoadingMore.value || !allStoreHasMore) return;
  //     isAllStoreLoadingMore.value = true;
  //   } else {
  //     isAllStoreFirstLoading.value = true;
  //     allStorePage = 1;
  //     allStoreHasMore = true;
  //     allStore.clear();
  //   }
  //
  //   try {
  //
  //     final response = await StoreRepo().getStore(
  //         page: allStorePage,
  //         lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
  //         long: LocationService.lng != 0.0
  //             ? "${LocationService.lng}"
  //             : ""); // Make sure repo uses params
  //     if (response.isSuccess) {
  //       getAllStoreResponse.value = ApiResponse.complete(response);
  //
  //       final responseData = response.response?.data;
  //
  //       List<GetAllStoreResModel> newStores = [];
  //
  //       // Handle both array or wrapped API formats
  //       if (responseData is List) {
  //         newStores = responseData
  //             .map((e) => GetAllStoreResModel.fromJson(e))
  //             .toList();
  //       } else if (responseData is Map && responseData['data'] is List) {
  //         newStores = (responseData['data'] as List)
  //             .map((e) => GetAllStoreResModel.fromJson(e))
  //             .toList();
  //       }
  //
  //       if (newStores.isNotEmpty) {
  //         if (isLoadMore) {
  //           allStore.addAll(newStores);
  //         } else {
  //           allStore.assignAll(newStores);
  //         }
  //
  //         allStorePage++;
  //       } else {
  //         allStoreHasMore = false;
  //       }
  //
  //       print("Loaded ${newStores.length} stores | Total: ${allStore.length}");
  //     } else {
  //
  //       getAllStoreResponse.value = ApiResponse.error('error');
  //
  //       print("API failed with status: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("Error: $e");
  //     getAllStoreResponse.value = ApiResponse.error('error');
  //   }finally{
  //     if (isLoadMore) {
  //       isAllStoreLoadingMore.value = false;
  //     } else {
  //       isAllStoreFirstLoading.value = false;
  //     }
  //   }
  // }
  //
  // ///GET STORE PRODUCT ONLY....
  // Future<void> getAllStoreProductNearBy({bool isLoadMore = false}) async {
  //   if (isLoadMore) {
  //     if (isStoreProductDataLoadingMore.value || !storeProductDataHasMore) return;
  //     isStoreProductDataLoadingMore.value = true;
  //   } else {
  //     isStoreProductDataFirstLoading.value = true;
  //     storeProductDataPage = 1;
  //     storeProductDataHasMore = true;
  //     storeProductDataList.clear();
  //   }
  //
  //   try {
  //
  //     final response = await StoreRepo().homePageProductRepo(
  //         page: storeProductDataPage,
  //         lat: LocationService.lat != 0.0 ? "${LocationService.lat}" : "",
  //         long: LocationService.lng != 0.0
  //             ? "${LocationService.lng}"
  //             : ""); // Make sure repo uses params
  //     if (response.isSuccess) {
  //       getAllStoreProductResponse.value = ApiResponse.complete(response);
  //       final getOwnProductModel =
  //       GetProductModel.fromJson(response.response?.data);
  //
  //       final List<GetProductData> newData =
  //           getOwnProductModel.data;
  //
  //       if (newData.isNotEmpty) {
  //         if (isLoadMore) {
  //           storeProductDataList.addAll(newData);
  //         } else {
  //           storeProductDataList.assignAll(newData);
  //         }
  //         storeProductDataPage++;
  //       }
  //     } else {
  //       storeProductDataHasMore = false;
  //       getAllStoreProductResponse.value = ApiResponse.error('error');
  //     }
  //   } catch (e) {
  //     print("stack: $e");
  //     getAllStoreProductResponse.value = ApiResponse.error('error');
  //   } finally{
  //     if (isLoadMore) {
  //       isStoreProductDataLoadingMore.value = false;
  //     } else {
  //       isStoreProductDataFirstLoading.value = false;
  //     }
  //   }
  // }
  //
  // ///GET ALL SERVICE....
  // Future<void> getAllServiceNearBy({bool isLoadMore = false}) async {
  //   if (isLoadMore) {
  //     if (isServiceDataLoadingMore.value || !serviceDataHasMore) return;
  //     isServiceDataLoadingMore.value = true;
  //   } else {
  //     isServiceDataFirstLoading.value = true;
  //     serviceDataPage = 1;
  //     serviceDataHasMore = true;
  //     serviceDataList.clear();
  //   }
  //
  //   try {
  //     final response = await ServiceAiRepo().getServiceRepo(
  //       queryParams: {
  //         ApiKeys.page: serviceDataPage,
  //         "limit": 10, // adjust as per backend
  //         "radius": kmRadius1000,
  //         "type": "service",
  //       },
  //     );
  //
  //     if (response.isSuccess) {
  //       final responseData = response.response?.data;
  //       List<GetServiceModel> newServices = [];
  //
  //       // Handle both array or map API structures
  //       if (responseData is List) {
  //         newServices = responseData.map((e) => GetServiceModel.fromJson(e)).toList();
  //       } else if (responseData is Map && responseData['data'] is List) {
  //         newServices = (responseData['data'] as List)
  //             .map((e) => GetServiceModel.fromJson(e))
  //             .toList();
  //       } else {
  //         print(" Unexpected API structure: $responseData");
  //       }
  //
  //       if (newServices.isNotEmpty) {
  //         if (isLoadMore) {
  //           serviceDataList.addAll(newServices);
  //         } else {
  //           serviceDataList.assignAll(newServices);
  //         }
  //
  //         serviceDataPage++;
  //       } else {
  //         serviceDataHasMore = false;
  //       }
  //
  //       getAllStoreServiceResponse.value = ApiResponse.complete(response);
  //       print("Loaded ${newServices.length} services | Total: ${serviceDataList.length}");
  //     } else {
  //       getAllStoreServiceResponse.value = ApiResponse.error('error');
  //     }
  //   } catch (e, s) {
  //     print("Stack: $s");
  //     getAllStoreServiceResponse.value = ApiResponse.error('error');
  //     serviceDataHasMore = false;
  //   } finally {
  //     if (isLoadMore) {
  //       isServiceDataLoadingMore.value = false;
  //     } else {
  //       isServiceDataFirstLoading.value = false;
  //     }
  //   }
  // }
  //

}