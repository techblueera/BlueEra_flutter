import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/string_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_service_model_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_service_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/change_profession_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/change_profession_warning_dialog.dart';
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
  Rx<EarnServiceModelResponse> professionData = EarnServiceModelResponse().obs;
  RxBool isProfessionDataLoading = false.obs;

  /// Earn Service Opt flag
  RxString isEarnServiceOpt = ''.obs;
  final List<EarnServiceOrdersStatus> earnServiceOrdersTabs = EarnServiceOrdersStatus.values;
  RxInt selectedEarnServiceOrderIndex = 0.obs;

  void handleServiceTap(BuildContext context, IndividualProfileCategory service) async {
    switch (service.slugId) {
      case SELF_EMPLOYED:
        // if(earnServiceCreatedStatusGlobal == 'true'){
        //   commonSnackBar(message: AppStrings.youCanOptOnlyOneService.tr);
        // }else{
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => SelfWorkServiceGuideBottomSheet(),
          );
        // }

        break;

      case DELIVERY_RIDER:

        // _handleDeliveryPartner();

        ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
          context: context,
          designation: DELIVERY_RIDER,
        );

        break;

      case CAR_TAXI:
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
        // if(earnServiceCreatedStatusGlobal == 'true'){
        //   commonSnackBar(message: AppStrings.youCanOptOnlyOneService.tr);
        // }else {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => HomeServiceGuideBottomSheet(),
          );
        // }
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

        if(isEarnServiceOpt.value=='true' && userWorkTypeGlobal == CONSULTANT){
          commonSnackBar(message: 'You are already ${userWorkTypeGlobal.withArticle}');
          return;
        }

        ChangeProfessionWarningDialog.show(
          context,
          onConfirm: ()=> Get.toNamed(
            RouteHelper.getAddSelfServiceRoute(),
            arguments: {
              ApiKeys.designation: CONSULTANT,
              ApiKeys.serviceSubType: EarnServiceTypes.homeService,
            },
          ),
        );

        // if(earnServiceCreatedStatusGlobal == 'true'){
        //   commonSnackBar(message: AppStrings.youCanOptOnlyOneService.tr);
        // }else {
        //   ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
        //     context: context,
        //     designation: CONSULTANT,
        //     serviceSubType: EarnServiceTypes.homeService,
        //   );
        // }
        break;

      case TUTOR:

        if(isEarnServiceOpt.value=='true' && userWorkTypeGlobal == TUTOR){
          commonSnackBar(message: 'You are already ${userWorkTypeGlobal.withArticle}');
          return;
        }

        ChangeProfessionWarningDialog.show(
          context,
          onConfirm: ()=> Get.toNamed(
            RouteHelper.getAddSelfServiceRoute(),
            arguments: {
              ApiKeys.designation: TUTOR,
              ApiKeys.serviceSubType: EarnServiceTypes.homeService,
            },
          ),
        );

        // if(earnServiceCreatedStatusGlobal == 'true'){
        //   commonSnackBar(message: AppStrings.youCanOptOnlyOneService.tr);
        // }else {
        //   ProfessionChangeDialogHelper().shouldShowUpdateDesignationDialog(
        //     context: context,
        //     designation: TUTOR,
        //     serviceSubType: EarnServiceTypes.homeService,
        //   );
        // }
        break;

      default:
        break;
    }
  }

  void _handleDeliveryPartner() {
    final controller = getOrPut(() => DeliveryPartnerController());

    final stepStatus = controller.stepStatus;

    if (stepStatus.isEmpty) {
      Get.toNamed(RouteHelper.getPersonalInformationRidingScreenRoute());
      return;
    }

    // Check if all completed
    final allCompleted = stepStatus.values.every((status) => status == true);

    if (allCompleted) {
      commonSnackBar(message: AppStrings.allStepsSubmitted.tr);
      return;
    }

    // Find first incomplete step
    final firstIncompleteEntry =
    stepStatus.entries.firstWhere((entry) => entry.value == false);


    if (firstIncompleteEntry.key == RiderProfileStep.personalInfo) {
      Get.toNamed(RouteHelper.getPersonalInformationRidingScreenRoute());
    } else if (firstIncompleteEntry.key == RiderProfileStep.addressInfo) {
      Get.toNamed(RouteHelper.getAddressLocationRidingScreenRoute());
    } else {
      Get.to(RiderProfileStatusScreen(
        screeName: '',
      ));
      // Get.toNamed(RouteHelper.getRiderProfileStatusScreenRoute());
    }

    // switch (firstIncompleteEntry.key) {
    //   case RiderProfileStep.personalInfo:
    //     Get.toNamed(RouteHelper.getPersonalInformationRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.addressInfo:
    //     Get.toNamed(RouteHelper.getAddressLocationRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.personalIdentificationInfo:
    //     Get.toNamed(RouteHelper.getPersonalIdentificationRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.drivingInfo:
    //     Get.toNamed(RouteHelper.getDrivingVerificationRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.vehicleImagesInfo:
    //     Get.toNamed(RouteHelper.getVehicleImagesRidingScreenRoute());
    //     break;
    //   case RiderProfileStep.vehicleInfo:
    //     Get.toNamed(RouteHelper.getVehicleInformationRidingScreenRoute());
    //     break;
    // }
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
        final earnServiceModelResponse = EarnServiceModelResponse.fromJson(response.response?.data);
        professionData.value = earnServiceModelResponse;
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
  saveGalleryImages(String serviceId, String imagePath) async {
    dio.MultipartFile? imageByPart;

    String fileName = imagePath.split('/').last;
    imageByPart =
    await dio.MultipartFile.fromFile(imagePath, filename: fileName);

    Map<String, dynamic> params = {ApiKeys.category_image: imageByPart};
    uploadGalleryImage(serviceId, params);
  }

  Future<void> uploadGalleryImage(String serviceId, Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel = await EarnServiceRepo().uploadProfessionImages(serviceId: serviceId, params: params);
      if (responseModel.isSuccess) {
        fetchSelfProfessionData();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
    }
  }

  Future<void> deleteProfessionImage(String serviceId, String imagePath) async {
    try {
      Map<String, dynamic> params = {ApiKeys.image_url: imagePath};
      ResponseModel responseModel =
      await EarnServiceRepo().deleteProfessionImage(serviceId: serviceId, params: params);
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