import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/subscription_create_model.dart';
import 'package:BlueEra/core/api/model/subscription_offer_model.dart';
import 'package:BlueEra/core/api/model/subscription_plan_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/string_utils.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_trial_initiate.dart';
import 'package:BlueEra/features/subscription/auth/repo/subscription_repo.dart';
import 'package:get/get.dart';
import '../model/subscription_list_details_model.dart';
import '../model/user_subscription_model.dart';

class SubscriptionController extends GetxController {
  Rx<ApiResponse> createSubscriptionResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> verificationSubscriptionResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> cancelSubscriptionResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSubscriptionPlanResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> userSubscriptionResponse =
      ApiResponse.initial('Initial').obs;
  // Rx<ApiResponse> getSubscriptionOfferResponse =
  //     ApiResponse.initial('Initial').obs;

  RxList<UserSubscription> currentPlansList=<UserSubscription>[].obs;
  RxList<int> selectedSubscriptionIndex = <int>[].obs;

  // RxInt myPlanSelectedTab=0.obs;
  // RxBool mySubscriptionAvailable=false.obs;
  // var selectedMethod = PaymentMethod.upi.obs;
  // void selectMethod(PaymentMethod? method) {
  //   selectedMethod.value = method ?? selectedMethod.value;
  // }
  //
  // var selectedOffer = Rxn<OfferData>();
  //
  // void selectOffer(OfferData? offer) {
  //   selectedOffer.value = offer;
  // }
  //
  // var isRedeemEnabled = false.obs;
  //
  // void toggleRedeem(bool value) {
  //   isRedeemEnabled.value = value;
  // }
  //
  // var isAutoPayEnabled = false.obs;
  //
  // void toggleAutoPay(bool value) {
  //   isAutoPayEnabled.value = value;
  // }
  //
  // RxnInt selectedIndex = RxnInt(null);
  // RxnInt finalPayAmount = RxnInt(null);
  //
  // ///SUBSCRIPTION PLAN...
  // Rx<SubscriptionPlanModel> subscriptionDetailModel =
  //     SubscriptionPlanModel().obs;
  //
  // calculateAmount() {
  //   finalPayAmount.value = (subscriptionDetailModel
  //               .value.data?[selectedIndex.value ?? -1].amount!
  //               .toInt() ??
  //           0) -
  //       (selectedOffer.value?.offerAmount?.toInt() ?? 0);
  // }

  int get finalAmount {
    final index = selectedSubscriptionIndex.first;

    if (index < 0 ||
        index >= (subscriptionPlanDetailsNewModel.value.data?.length ?? 0)) {
      return 0;
    }

    final amount = subscriptionPlanDetailsNewModel
        .value.data?[index].amount
        ?.toInt() ??
        0;

    // 🔎 Logs
    print("💰 api amount: ${subscriptionPlanDetailsNewModel
        .value.data?[index].amount
        ?.toInt()}");
    print("💰 Original Amount: $amount");

    return amount;

    // final offerAmount = selectedOffer.value?.offerAmount?.toInt() ?? 0;
    //
    // return amount - offerAmount;
  }


  ///GET SUBSCRIPTION PLAN ..
  Rx<SubscriptionOfferModel> subscriptionOfferModel =
      SubscriptionOfferModel().obs;
  String? bannerVideoUrl;
  Rx<SubscriptionPlanDetailsNewModel> subscriptionPlanDetailsNewModel = SubscriptionPlanDetailsNewModel().obs;

  Future<void> subscriptionPlansGetApi() async {
    try {


      // Gig Worker
      // Skill Worker
      // Grocery
      // Food
      // Product
      // Other

      String entityType;
      if(userProfileTypeGlobal == GIG_WORKER){
        entityType = 'Gig Worker';
      }else if(userProfileTypeGlobal == SKILL_WORKER ||
          userProfileTypeGlobal == PROFESSIONAL){
        entityType = 'Skill Worker';
      }
      else if(
      businessTypeGlobal.equalsIgnoreCase(BusinessType.Grocery.name)
      ){
        entityType = 'Grocery';
      }else if(businessTypeGlobal.equalsIgnoreCase(BusinessType.Food.name) ||
          (businessTypeGlobal.equalsIgnoreCase(BusinessType.Healthcare.name) &&
              businessCategoryGlobal.equalsIgnoreCase(AppConstants.INSTRUMENTS_PHARMACY)
          )){
        entityType = 'Food';
      }else if(businessTypeGlobal.equalsIgnoreCase(BusinessType.Product.name) ||
          businessTypeGlobal.equalsIgnoreCase(BusinessType.Automotive.name) &&
              [AppConstants.SALES_SECTOR, AppConstants.PARTS_SECTOR]
                  .any((s) => s.equalsIgnoreCase(businessCategoryGlobal))
      ){
        entityType = 'Product';
      }else{
        entityType = 'Other';
      }

      Map<String, String> _queryParams = {
          'entity_type': entityType
        };


      getSubscriptionPlanResponse.value = ApiResponse.initial('Initial');

      ResponseModel response = await SubscriptionRepo().subscriptionPlansGetApi(queryParams: _queryParams);
      if (response.isSuccess) {
        subscriptionPlanDetailsNewModel.value =
            SubscriptionPlanDetailsNewModel.fromJson(response.response?.data);
        getSubscriptionPlanResponse.value = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getSubscriptionPlanResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      getSubscriptionPlanResponse.value = ApiResponse.error('error');
    }
  }

  ///CANCEL SUBSCRIPTION...
  Future<void> cancelSubscriptionController({required Map<String, dynamic> params}) async {
    try {
      ResponseModel responseModel =
          await SubscriptionRepo().cancelSubscriptionRepo(params);
      if (responseModel.isSuccess) {
        cancelSubscriptionResponse.value = ApiResponse.complete(responseModel);
        userCurrentPlanApi();
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      cancelSubscriptionResponse.value = ApiResponse.error('error');
    }
  }
  Future<void> userCurrentPlanApi({Map<String, dynamic>? params}) async {
    try {
      ResponseModel responseModel =
          await SubscriptionRepo().userCurrentPlanApi(params);
      if (responseModel.isSuccess) {
        userSubscriptionResponse.value = ApiResponse.complete(responseModel);

        List details = responseModel.data;
        currentPlansList.value = details.map((e)=>UserSubscription.fromJson(e)).toList();

      } else {
        userSubscriptionResponse.value = ApiResponse.error(responseModel.message ?? AppStrings.somethingWentWrong);
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      userSubscriptionResponse.value = ApiResponse.error('error');
    }
  }

  ///SUBSCRIPTION TRIAL INITIATE...

  Rx<SubscriptionTrialInitiate> subscriptionTrialData = SubscriptionTrialInitiate().obs;

  Future<void> subscriptionTrialInitiate(
      {required Map<String, dynamic>? params}) async {
    try {
      createSubscriptionResponse.value = ApiResponse.initial('Initial');

      ResponseModel responseModel =
      await SubscriptionRepo().subscriptionTrialInitiateRepo(params: params ?? {});
      if (responseModel.isSuccess) {
        subscriptionTrialData.value =
            SubscriptionTrialInitiate.fromJson(responseModel.response?.data);
        // commonSnackBar(
        //     message: subscriptionData.value.message ?? AppStrings.success);
        createSubscriptionResponse.value = ApiResponse.complete(responseModel);
      } else {
        createSubscriptionResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      createSubscriptionResponse.value = ApiResponse.error('error');
    }
  }

  ///VERIFY SUBSCRIPTION Trial...
  Future<void> verifySubscriptionTrial(
      {required Map<String, dynamic> params}) async {
    try {
      ResponseModel responseModel =
      await SubscriptionRepo().verifyTrialSubscriptionRepo(params: params);
      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? AppStrings.success);
        verificationSubscriptionResponse.value =
            ApiResponse.complete(responseModel);

        // Payment success Popup


      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      verificationSubscriptionResponse.value = ApiResponse.error('error');
    }
  }


  // Future getSubscriptionPlan() async {
  //   try {
  //     getSubscriptionPlanResponse.value = ApiResponse.initial('Initial');
  //
  //     ResponseModel response = await SubscriptionRepo().subscriptionPlan();
  //     if (response.isSuccess) {
  //       subscriptionDetailModel.value =
  //           SubscriptionPlanModel.fromJson(response.response?.data);
  //       getSubscriptionPlanResponse.value = ApiResponse.complete(response);
  //     } else {
  //       commonSnackBar(message: AppStrings.somethingWentWrong);
  //       getSubscriptionPlanResponse.value = ApiResponse.error('error');
  //     }
  //   } catch (e) {
  //     getSubscriptionPlanResponse.value = ApiResponse.error('error');
  //   }
  // }
  //
  // ///GET PLAN OFFER..
  // Future getSubscriptionOffer() async {
  //   try {
  //     getSubscriptionOfferResponse.value = ApiResponse.initial('Initial');
  //
  //     ResponseModel response = await SubscriptionRepo().subscriptionOffer();
  //     if (response.isSuccess) {
  //       subscriptionOfferModel.value =
  //           SubscriptionOfferModel.fromJson(response.response?.data);
  //       getSubscriptionOfferResponse.value = ApiResponse.complete(response);
  //     } else {
  //       commonSnackBar(message: AppStrings.somethingWentWrong);
  //       getSubscriptionOfferResponse.value = ApiResponse.error('error');
  //     }
  //   } catch (e) {
  //     getSubscriptionOfferResponse.value = ApiResponse.error('error');
  //   }
  // }

  // ///CREATE SUBSCRIPTION...
  //
  // Rx<SubscriptionCreateModel> subscriptionData = SubscriptionCreateModel().obs;
  //
  // Future<void> createSubscriptionController(
  //     {required Map<String, dynamic>? params}) async {
  //   try {
  //     createSubscriptionResponse.value = ApiResponse.initial('Initial');
  //
  //     ResponseModel responseModel =
  //     await SubscriptionRepo().createSubscriptionRepo(params: params ?? {});
  //     if (responseModel.isSuccess) {
  //       subscriptionData.value =
  //           SubscriptionCreateModel.fromJson(responseModel.response?.data);
  //       // commonSnackBar(
  //       //     message: subscriptionData.value.message ?? AppStrings.success);
  //       createSubscriptionResponse.value = ApiResponse.complete(responseModel);
  //     } else {
  //       createSubscriptionResponse.value = ApiResponse.error('error');
  //
  //       commonSnackBar(
  //           message: responseModel.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     createSubscriptionResponse.value = ApiResponse.error('error');
  //   }
  // }
  //
  // ///VERIFY SUBSCRIPTION...
  // Future<void> verifySubscriptionController(
  //     {required Map<String, dynamic> params}) async {
  //   try {
  //     ResponseModel responseModel =
  //     await SubscriptionRepo().verifySubscriptionRepo(params: params);
  //     if (responseModel.isSuccess) {
  //       commonSnackBar(message: responseModel.message ?? AppStrings.success);
  //       Get.back();
  //       verificationSubscriptionResponse.value =
  //           ApiResponse.complete(responseModel);
  //     } else {
  //       commonSnackBar(
  //           message: responseModel.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     verificationSubscriptionResponse.value = ApiResponse.error('error');
  //   }
  // }



}
