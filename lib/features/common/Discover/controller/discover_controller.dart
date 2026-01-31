import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/food/model/collapsible_grid_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/model/rental_service_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum CategoryFilter {
  nearest('Nearest'),
  experienced('Experienced'),
  priceLowToHigh('Price (Low-High)');

  final String label;

  const CategoryFilter(this.label);
}

enum DiscoverFilter {
  home('Home'),
  deals('Deals'),
  events('Events'),
  careerJobs('Career / Jobs');

  final String label;

  const DiscoverFilter(this.label);
}


class DiscoverController extends GetxController{
  var selfProfessionServiceResponse =
      ApiResponse.initial('Initial').obs;
  var rentalServiceResponse =
      ApiResponse.initial('Initial').obs;

  final ScrollController scrollController = ScrollController();
  final GlobalKey headerKey = GlobalKey();
  Function(bool isVisible)? onHeaderVisibilityChanged;
  final RxBool isHeaderVisible = true.obs;
  final RxDouble headerOffset = 0.0.obs;
  double headerHeight = 0;

  final List<DiscoverFilter> discoverFilters = DiscoverFilter.values;
  Rx<DiscoverFilter> selectedDiscoverFilter = DiscoverFilter.home.obs;

  Rx<OnboardingCategoryModel?> selectedEarnServiceData = Rx<OnboardingCategoryModel?>(null);
  RxInt selectedTabIndex = 0.obs;
  final List<CategoryFilter> filters = CategoryFilter.values;
  Rx<CategoryFilter> selectedFilter = CategoryFilter.nearest.obs;
  final int limit = 20;

  /// Self Profession Services
  RxList<ServiceData> earnServiceList = <ServiceData>[].obs;
  RxBool isEarnServiceLoading = false.obs;
  int earnServicePage = 1;
  var isEarnServiceLoadingMore = false.obs;
  bool hasMoreEarnServiceData = true;

  /// Rental Services
  RxList<RentalServiceData> rentalServices = <RentalServiceData>[].obs;
  RxBool isRentalServiceLoading = false.obs;
  int rentalServicePage = 1;
  var isRentalServiceLoadingMore = false.obs;
  bool hasMoreRentalServiceData = true;

  /// fetch Earn service
  Future<void> fetchEarnServices({
    required String earnServiceType,
    required String subType,
    bool isLoadMore = false}) async {

    if (isLoadMore) {
      if (isEarnServiceLoadingMore.value || !hasMoreEarnServiceData) {
        return;
      }
      isEarnServiceLoadingMore.value = true;
    } else {
      earnServiceList.clear();
      isEarnServiceLoading.value = true;
      earnServicePage = 1;
      hasMoreEarnServiceData = true;
    }

    // double lat = LocationService.lat;
    // double lng = LocationService.lng;

    final Map<String, dynamic> queryParams = {
      ApiKeys.type: earnServiceType,
      ApiKeys.subType: subType,
      // ApiKeys.lat: lat,
      // ApiKeys.lng: lng,
      // ApiKeys.radius: kmRadius1500,
      ApiKeys.page: earnServicePage,
      ApiKeys.limit: limit,
    };
    if(selectedEarnServiceData.value!=null){
      queryParams[ApiKeys.category] = selectedEarnServiceData.value?.slugId;
    }

    ResponseModel response =
    await DiscoverRepo().fetchSelfWorkServices(queryParams: queryParams);

    try {
      if (response.isSuccess) {
        selfProfessionServiceResponse.value = ApiResponse.complete(response);

        final responseModel = ServiceModelResponse.fromJson(response.response?.data);

        List<ServiceData> tempNewItems = [];

        for (var service in responseModel.services ?? []) {
          if (service.data != null && service.data!.isNotEmpty) {
            for (ServiceData item in service.data!) {

              // Distance Calculation Logic
              double itemLat = double.tryParse(item.userLocation?.lat.toString() ?? "0") ?? 0.0;
              double itemLng = double.tryParse(item.userLocation?.lon.toString() ?? "0") ?? 0.0;

              double? tempDistance;
              if (itemLat != 0 && itemLng != 0) {
                tempDistance = await getDistanceInKm(itemLat, itemLng);
              } else {
                tempDistance = 0.0;
              }
              item.distance = tempDistance?.toInt();

              tempNewItems.add(item);
            }
          }
        }

        if (tempNewItems.length < limit) {
          hasMoreEarnServiceData = false;
        }

        if (isLoadMore) {
          earnServiceList.addAll(tempNewItems);
        } else {
          earnServiceList.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          earnServicePage++;
        }

      } else {
        if (!isLoadMore) {
          selfProfessionServiceResponse.value = ApiResponse.error('error');
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e, s) {
      print('stack trace --> $s');
      selfProfessionServiceResponse.value = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      if(isLoadMore){
        isEarnServiceLoadingMore.value = false;
      } else{
        isEarnServiceLoading.value = false;
      }
    }
  }

  Future<void> fetchRentalServices({
    required RentalServiceType rentalServiceType,
    bool isLoadMore = false
  }) async {
    try {
      if (isLoadMore) {
        log('more rental data -- $hasMoreRentalServiceData');
        if (isRentalServiceLoadingMore.value || !hasMoreRentalServiceData) {
          return;
        }
        isRentalServiceLoadingMore.value = true;
      } else {
        rentalServices.clear();
        isRentalServiceLoading.value = true;
        rentalServicePage = 1;
        hasMoreRentalServiceData = true;
      }

      double lat = LocationService.lat;
      double lng = LocationService.lng;

      Map<String, dynamic> queryParams = {
        ApiKeys.type: rentalServiceType.apiValue,
        ApiKeys.lat: lat,
        ApiKeys.lng: lng,
        ApiKeys.radius: kmRadius1500,
        ApiKeys.page: rentalServicePage,
        ApiKeys.limit: limit,
      };

      final response = await DiscoverRepo().getRentalService(
        queryParams: queryParams,
      );

      if (response.isSuccess) {
        rentalServiceResponse.value = ApiResponse.complete(response);

        final responseModel =
        RentalServiceResponse.fromJson(response.response!.data);

        final List<RentalServiceData> tempNewItems = responseModel.data ?? [];

        if (tempNewItems.length < limit) {
          hasMoreRentalServiceData = false;
        }

        if (isLoadMore) {
          rentalServices.addAll(tempNewItems);
        } else {
          rentalServices.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          rentalServicePage++;
        }

      }  else {
        if (!isLoadMore) {
          rentalServiceResponse.value = ApiResponse.error('error');
          commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
        }
      }
    } catch (e) {
      rentalServiceResponse.value = ApiResponse.error(AppStrings.somethingWentWrong);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      if(isLoadMore){
        isRentalServiceLoadingMore.value = false;
      } else{
        isRentalServiceLoading.value = false;
      }
    }
  }


}