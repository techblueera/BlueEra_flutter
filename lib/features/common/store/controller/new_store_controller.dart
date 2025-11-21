import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/store/repo/store_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewStoreController extends GetxController{
  Rx<ApiResponse> getAllStoreResponse =
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

  @override
  void onClose() {
    debounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// All Stores data
  RxList<GetAllStoreResModel> allStore = <GetAllStoreResModel>[].obs;
  RxBool isAllStoreLoadingMore = false.obs;
  RxBool isAllStoreFirstLoading = false.obs;
  int allStorePage = 1;
  bool allStoreHasMore = true;

  ///GET STORES ONLY....
  Future<void> getAllStoreNearBy({bool isLoadMore = false}) async {
    if(typeOfBusiness == null || businessCategoryId == null){
      commonSnackBar(message: 'Business Category id not found');
      return;
    }

    if (isLoadMore) {
      if (isAllStoreLoadingMore.value || !allStoreHasMore) return;
      isAllStoreLoadingMore.value = true;
    } else {
      isAllStoreFirstLoading.value = true;
      // final cachedFood = await HiveServices().getAllStore(userId);
      // if (cachedFood != null && cachedFood.isNotEmpty) {
      //   allStore.assignAll(cachedFood);
      //   isAllStoreFirstLoading.value = false; // show instantly
      // } else {
      //   allStore.clear();
      // }
      allStorePage = 1;
      allStoreHasMore = true;
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
            // await HiveServices().saveAllStore(allStore, userId);
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

}