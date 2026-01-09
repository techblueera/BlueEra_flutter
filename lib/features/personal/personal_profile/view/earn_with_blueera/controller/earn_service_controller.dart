import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_service_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/change_profession_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/repo/inventory_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/food_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/home_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/product_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/rental_service_guide_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/self_work_service_guide_bottom_sheet.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widget/service_item.dart';

class EarnServiceController extends GetxController{
  Rx<ApiResponse> ownProductsResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> serviceResponse =
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

  /// Self Profession Data
  Rx<ServiceData> professionData = ServiceData().obs;
  RxBool isProfessionDataLoading = false.obs;

  /// Earn Service Opt flag
  RxString isEarnServiceOpt = ''.obs;
  final List<EarnServiceOrdersStatus> earnServiceOrdersTabs = EarnServiceOrdersStatus.values;
  RxInt selectedEarnServiceOrderIndex = 0.obs;

  void handleServiceTap(BuildContext context, IndividualProfileCategory service) async {
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

      case CAR_DRIVER_TAXI:
        // ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
        //   context: context,
        //   designation: CAR_DRIVER_TAXI,
        // );
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
            serviceSubType: EarnServiceTypes.homeService,
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
            serviceSubType: EarnServiceTypes.homeService,
          );
        }
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

  Future<void> fetchSelfProfessionData() async {
    try {
      isProfessionDataLoading.value = true;

      final response = await EarnServiceRepo().fetchProfessionDataRepo(
        {
          ApiKeys.all: false,
        }
      );
      if (response.isSuccess) {
        serviceResponse.value = ApiResponse.complete(response);
        final serviceModelResponse = ServiceModelResponse.fromJson(response.response?.data);
        // professionData.value = serviceModelResponse.data;
        //
        // if (newData.isNotEmpty) {
        //   if (isLoadMore) {
        //     ownProductDataList.addAll(newData);
        //   } else {
        //     ownProductDataList.assignAll(newData);
        //   }
        //   ownProductDataPage++;
        // }
      } else {
        serviceResponse.value = ApiResponse.error('error');
      }
    } catch (e, s) {
      serviceResponse.value = ApiResponse.error('error');
      print("stack trace: $s");
    } finally {
      isProfessionDataLoading.value = false;
    }
  }

  ///UPDATE BUSINESS IMAGES....
  saveGalleryImages(String imagePath) async {
    dio.MultipartFile? imageByPart;

    String fileName = imagePath.split('/').last;
    imageByPart =
    await dio.MultipartFile.fromFile(imagePath, filename: fileName);

    Map<String, dynamic> params = {ApiKeys.category_image: imageByPart};
    uploadGalleryImage(params);
  }

  Future<void> uploadGalleryImage(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel = await EarnServiceRepo().uploadProfessionImages(params);
      if (responseModel.isSuccess) {
        fetchSelfProfessionData();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
    }
  }

  Future<void> deleteProfessionImage(String imagePath) async {
    try {
      Map<String, dynamic> params = {ApiKeys.image_url: imagePath};
      ResponseModel responseModel =
      await EarnServiceRepo().deleteProfessionImage(params);
      if (responseModel.isSuccess) {
        fetchSelfProfessionData();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
    }
  }


}