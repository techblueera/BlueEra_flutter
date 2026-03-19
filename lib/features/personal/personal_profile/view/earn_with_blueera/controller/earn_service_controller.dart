import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/consulting_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/food_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/gig_work_service_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/home_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/product_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/rental_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/self_work_service_guide_bottom_sheet.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarnServiceController extends GetxController{
  Rx<ApiResponse> ownProductsResponse =
      ApiResponse.initial('Initial').obs;

  RxInt selectedProductsServicesTabIndex = 0.obs;
  final List<String> productsServicesTab = [
    AppStrings.tiffin,
    AppStrings.homeMadeProducts,
    AppStrings.homeMadeFoodItems
  ];
  RxBool showGoLiveEnabled = false.obs;

  /// Product data
  RxList<GetProductData> ownProductDataList = <GetProductData>[].obs;
  RxBool isOwnProductDataLoadingMore = false.obs;
  RxBool isOwnProductDataFirstLoading = false.obs;
  int ownProductDataPage = 1;
  bool ownProductDataHasMore = true;

  final List<EarnServiceOrdersStatus> earnServiceOrdersTabs = EarnServiceOrdersStatus.values;
  RxInt selectedEarnServiceOrderIndex = 0.obs;

  void handleServiceTap(BuildContext context, CollapsibleGridModel service) async {
    switch (service.slugId) {
      case SELF_EMPLOYED:
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => SelfWorkServiceGuideBottomSheet(),
          );
        break;

      case GIG_WORKER:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => GigWorkServiceGuideBottomSheet(),
        );

        break;

      case HOME_MADE_PRODUCTS:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => ProductServiceGuideBottomSheet(),
        );
        break;

      case HOME_MADE_FOOD:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => FoodServiceGuideBottomSheet(),
        );
        break;

      case HOME_SERVICES:
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => HomeServiceGuideBottomSheet(),
          );
        break;

      case RENTAL_SERVICES:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => RentalServiceGuideBottomSheet(),
        );
        break;
      case PROFESSIONAL:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => ConsultingServiceGuideBottomSheet(),
        );

      case CONTENT_CREATOR:
        // if(isEarnServiceOpt.value=='true' && userDesignationGlobal == CONSULTANT){
        //   commonSnackBar(message: 'You are already ${userDesignationGlobal.withArticle}');
        //   return;
        // }
        //
        // ChangeProfessionWarningDialog.show(
        //   context,
        //   onConfirm: ()=> Get.toNamed(
        //     RouteHelper.getAddSelfServiceRoute(),
        //     arguments: {
        //       ApiKeys.designation: CONSULTANT,
        //       ApiKeys.serviceSubType: EarnServiceTypes.homeService,
        //     },
        //   ),
        // );
        break;

      case TUTOR:
        // if(isEarnServiceOpt.value=='true' && userProfessionGlobal == TUTOR){
        //   commonSnackBar(message: 'You are already ${userProfessionGlobal.withArticle}');
        //   return;
        // }
        //
        // ChangeProfessionWarningDialog.show(
        //   context,
        //   onConfirm: ()=> Get.toNamed(
        //     RouteHelper.getAddSelfServiceRoute(),
        //     arguments: {
        //       ApiKeys.designation: TUTOR,
        //       ApiKeys.serviceSubType: EarnServiceTypes.homeService,
        //     },
        //   ),
        // );
        break;

      default:
        break;
    }
  }



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
        'ownerType': ProviderType.user.title,
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




}