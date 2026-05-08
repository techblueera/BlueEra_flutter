import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/repo/inventory_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/consulting_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_food_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_made_product_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_service_profile_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/gig_work_service_bottom_sheet.dart';
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
    AppStrings.homeMadeFoodItems,
    AppStrings.homeMadeProducts,
  ];
  RxBool showGoLiveEnabled = false.obs;

  String earnProfileLabel(String type) {
    switch (type) {
      case 'homeMadeFood':
        return 'Home Made Food';
      case 'homeMadeProduct':
        return 'Home Made Product';
      case 'homeService':
        return 'Home Services';
      case 'Channel':
        return 'Channel';
      default:
        return type;
    }
  }

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

      // case SELF_EMPLOYED:
      //     showModalBottomSheet(
      //       context: context,
      //       backgroundColor: Colors.transparent,
      //       isScrollControlled: true,
      //       builder: (_) => SelfWorkServiceGuideBottomSheet(),
      //     );
      //   break;

      // case GIG_WORKER:
      //   showModalBottomSheet(
      //     context: context,
      //     backgroundColor: Colors.transparent,
      //     isScrollControlled: true,
      //     builder: (_) => GigWorkServiceGuideBottomSheet(),
      //   );
      //
      //   break;

      case HOME_MADE_PRODUCTS:
        Get.to(() => const HomeProfileScreen());
        break;

      case HOME_MADE_FOOD:
        Get.to(() => const HomeMadeFoodProfileScreen());
        break;

      case HOME_SERVICES:
        Get.to(()=> const HomeServiceProfileScreen());
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

      // case CONTENT_CREATOR:
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
        // break;

        // case TUTOR:
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
        // break;

      default:
        break;
    }
  }

  /// PATCH /inventory-service/products/inventory/{inventoryId}/variants/{variantId}
  /// Body: `{ updateFields: { sellingPrice, mrp, varientIsActive }, owner: { id, type } }`.
  Future<bool> updateProductVariantPrice({
    required String inventoryId,
    required String variantId,
    required num sellingPrice,
    required num mrp,
    required bool varientIsActive,
  }) async {
    try {
      final res = await InventoryRepo().updateInventoryVariantRepo(
        inventoryId: inventoryId,
        variantId: variantId,
        params: {
          'updateFields': {
            'sellingPrice': sellingPrice,
            'mrp': mrp,
            'varientIsActive': varientIsActive,
          },
          ApiKeys.owner: {
            ApiKeys.id: userId,
            ApiKeys.type: ProviderType.user.title,
          },
        },
      );
      if (!res.isSuccess) return false;
      await fetchOwnProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  static const int ownProductPageSize = 20;

  Future<void> fetchOwnProducts({
    bool isLoadMore = false,
    int limit = ownProductPageSize,
  }) async {
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
      final Map<String, dynamic> queryParams = {
        'DRAFT': false,
        'ownerId': userId,
        'ownerType': ProviderType.user.title,
        'page': ownProductDataPage,
        'limit': limit,
      };

      final response = await InventoryRepo()
          .fetchOwnDraftedAndPublicProductsRepo(queryParams: queryParams);
      if (response.isSuccess) {
        ownProductsResponse.value = ApiResponse.complete(response);
        final getProductModel =
            GetProductModel.fromJson(response.response?.data);

        final List<GetProductData> newData = getProductModel.data;

        if (newData.isEmpty || newData.length < limit) {
          ownProductDataHasMore = false;
        }

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