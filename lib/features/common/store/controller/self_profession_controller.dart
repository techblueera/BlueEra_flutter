import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/common/map/model/service_model_response.dart';
import 'package:BlueEra/features/common/map/repo/map_service_repo.dart';
import 'package:BlueEra/features/common/store/repo/discover_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:get/get.dart';

import '../../../personal/personal_profile/view/widget/service_item.dart';

enum CategoryFilter {
  nearest('Nearest'),
  experienced('Experienced'),
  priceLowToHigh('Price (Low-High)');

  final String label;

  const CategoryFilter(this.label);
}


class SelfProfessionController extends GetxController{
  var selfProfessionServiceResponse =
      ApiResponse.initial('Initial').obs;

  Rx<ServiceItem?> selectedSelfProfessionData = Rx<ServiceItem?>(null);
  RxInt selectedTabIndex = 0.obs;
  final List<CategoryFilter> filters = CategoryFilter.values;
  Rx<CategoryFilter> selectedFilter = CategoryFilter.nearest.obs;

  /// Self Profession Services
  RxList<ServiceData> selfProfessionServiceList = <ServiceData>[].obs;
  RxBool isSelfProfessionLoading = false.obs;
  int selfProfessionPage = 1;
  final int selfProfessionLimit = 20;
  var isSelfProfessionLoadingMore = false.obs;
  bool hasMoreSelfProfessionData = true;

  /// fetch home service
  Future<void> fetchSelfWorkServices({bool isLoadMore = false}) async {

    if (isLoadMore) {
      if (isSelfProfessionLoadingMore.value || !hasMoreSelfProfessionData) {
        return;
      }
      isSelfProfessionLoadingMore.value = true;
    } else {
      selfProfessionServiceList.clear();
      isSelfProfessionLoading.value = true;
      selfProfessionPage = 1;
      hasMoreSelfProfessionData = true;
    }

    double lat = LocationService.lat;
    double lng = LocationService.lng;

    final Map<String, dynamic> queryParams = {
      ApiKeys.type: AppConstants.service,
      ApiKeys.subType: EarnWithBlueEraServiceTypes.selfWork.label,
      // ApiKeys.lat: lat,
      // ApiKeys.lng: lng,
      ApiKeys.page: selfProfessionPage,
      ApiKeys.limit: selfProfessionLimit,
    };
    if(selectedSelfProfessionData.value!=null){
      queryParams[ApiKeys.category] = selectedSelfProfessionData.value?.slugId;
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

        if (tempNewItems.length < selfProfessionLimit) {
          hasMoreSelfProfessionData = false;
        }

        if (isLoadMore) {
          selfProfessionServiceList.addAll(tempNewItems);
        } else {
          selfProfessionServiceList.assignAll(tempNewItems);
        }

        if (tempNewItems.isNotEmpty) {
          selfProfessionPage++;
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
        isSelfProfessionLoadingMore.value = false;
      } else{
        isSelfProfessionLoading.value = false;
      }
    }
  }

}