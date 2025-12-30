import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/widget/change_profession_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/food_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/home_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/product_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/rental_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/self_work_service_guide_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widget/service_item.dart';


class EarnWithBlueEraController extends GetxController{
  Rx<ApiResponse> ownProductsResponse =
      ApiResponse.initial('Initial').obs;

  RxInt selectedProductsServicesTabIndex = 0.obs;
  final List<String> productsServicesTab = [
    // AppStrings.selfWork,
    // AppStrings.deliveryPartner,
    AppStrings.tiffin,
    AppStrings.homeMadeProducts,
    AppStrings.homeMadeFoodItems,
    // AppStrings.homeServices,
    // AppStrings.rentalServices,
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

  /// Earn Service Opt flag

  RxString isEarnServiceOpt = ''.obs;

  final List<EarnServiceOrdersStatus> earnServiceOrdersTabs =
      EarnServiceOrdersStatus.values;
  RxInt selectedEarnServiceOrderIndex = 0.obs;

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


      final response = await InventoryRepo().fetchOwnDraftedAndPublicProductsRepo(queryParams: queryParams);
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

  void handleServiceTap(BuildContext context, ServiceItem service) async {
    switch (service.slugId) {
      case SELF_EMPLOYED:
        if(earnServiceCreatedStatusGlobal == 'true'){
          commonSnackBar(message: AppStrings.youCanOptOnlyOneService.tr);
        }else{
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => SelfWorkServiceGuideBottomSheet(),
          );
        }

        break;

      case DELIVERY_RIDER:
        ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
          context: context,
          designation: DELIVERY_RIDER,
        );
        break;

      case HOME_MADE_PRODUCTS_OPTION:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => ProductServiceGuideBottomSheet(),
        );
        break;

      case HOME_MADE_FOOD_ITEMS_OPTION:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => FoodServiceGuideBottomSheet(),
        );
        break;

      case HOME_SERVICES_OPTION:
        if(earnServiceCreatedStatusGlobal == 'true'){
          commonSnackBar(message: AppStrings.youCanOptOnlyOneService.tr);
        }else {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => HomeServiceGuideBottomSheet(),
          );
        }
        break;

      case RENTAL_SERVICES_OPTION:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => RentalServiceGuideBottomSheet(),
        );
        break;

      case CONSULTANT:
        if(earnServiceCreatedStatusGlobal == 'true'){
          commonSnackBar(message: AppStrings.youCanOptOnlyOneService.tr);
        }else {
          ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
            context: context,
            designation: CONSULTANT,
            serviceSubType: EarnWithBlueEraServiceTypes.homeService,
          );
        }
        break;

      case TUTOR:
        if(earnServiceCreatedStatusGlobal == 'true'){
          commonSnackBar(message: AppStrings.youCanOptOnlyOneService.tr);
        }else {
          ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
            context: context,
            designation: TUTOR,
            serviceSubType: EarnWithBlueEraServiceTypes.homeService,
          );
        }
        break;

      default:
        break;
    }
  }

}