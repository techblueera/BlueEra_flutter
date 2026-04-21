import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/subscription_offer_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/string_utils.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_trial_initiate.dart';
import 'package:BlueEra/features/subscription/auth/repo/subscription_repo.dart';
import 'package:flutter/foundation.dart';
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
  Rx<ApiResponse> checkReferralResponse =
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

  static String? resolveEntityType() {
    // if(isIndividualUser()){
    //   debugPrint('user profile type -- $userProfileTypeGlobal');
    // }else{
    //   debugPrint('business type -- $businessTypeGlobal');
    // }

    // ─── Individual profile types ─────────────────────────────────
    if (userProfileTypeGlobal == SELF_EMPLOYED) return 'SELF_EMPLOYED';

    // Gig worker is allowlisted only for the three rider professions —
    // other gig roles (delivery helpers, etc.) deliberately fall through.
    if (userProfileTypeGlobal == GIG_WORKER) {
      if (userProfessionGlobal == BIKE_RIDER) return 'BIKE_RIDER';
      if (userProfessionGlobal == AUTO_TAXI) return 'AUTO_TAXI';
      if (userProfessionGlobal == CAR_TAXI_DRIVER) return 'CAR_DRIVER_TAXI';
      return null;
    }

    // ─── Business types ───────────────────────────────────────────
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Food.name)) {
      return 'FOOD';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Grocery.name)) {
      return 'GROCERY';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Product.name)) {
      return 'PRODUCT';
    }
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Service.name)) {
      return 'SERVICE';
    }

    // Automotive sub-sectors fold into PRODUCT (sales/parts) or SERVICE
    // (rental / service / support / transport-logistic) so the dealership
    // and the workshop both still get a subscription, just under the
    // closest matching umbrella entity.
    if (businessTypeGlobal.equalsIgnoreCase(BusinessType.Automotive.name)) {
      final isProductLike = [
        AppConstants.SALES_SECTOR,
        AppConstants.PARTS_SECTOR,
      ].any((s) => s.equalsIgnoreCase(businessCategoryGlobal));
      return isProductLike ? 'PRODUCT' : 'SERVICE';
    }

    return null;
  }

  // In-flight dedupe flags. Multiple UI surfaces (bottom nav, peek sheet,
  // statistics tab, single-plan page) can each call these endpoints in
  // their initState; without this guard a single Me-screen entry can
  // trigger 2-3 concurrent hits to the same endpoint. The flags coalesce
  // overlapping callers into one HTTP request — sequential calls (after
  // the previous one completes) still go through, so screen entries get
  // fresh data.
  bool _planFetchInFlight = false;
  bool _userPlanFetchInFlight = false;

  Future<void> subscriptionPlansGetApi() async {
    if (_planFetchInFlight) return;

    final entityType = resolveEntityType();
    if (entityType == null) {
      // Profile/business not on the subscription allowlist — no plans
      // to fetch. Park the response in a non-loading state so any UI
      // listening to it doesn't sit on a perpetual spinner.
      getSubscriptionPlanResponse.value = ApiResponse.initial('Initial');
      return;
    }

    _planFetchInFlight = true;
    try {
      final Map<String, String> queryParams = {'entity_type': entityType};

      getSubscriptionPlanResponse.value = ApiResponse.initial('Initial');

      ResponseModel response = await SubscriptionRepo()
          .subscriptionPlansGetApi(queryParams: queryParams);
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
    } finally {
      _planFetchInFlight = false;
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
    if (_userPlanFetchInFlight) return;
    _userPlanFetchInFlight = true;
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
    } finally {
      _userPlanFetchInFlight = false;
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

  /// Fetches the backend's view of the user's pending-referral state.
  ///
  /// The returned record mirrors the `GET /wallet/pending-referral` body:
  ///   • `hasPending`        — a code was captured at onboarding and the
  ///     server will auto-apply it on trial/subscription, so we do NOT
  ///     need to send it back in our payload.
  ///   • `alreadyProcessed`  — the user already has a completed referral;
  ///     never prompt them again.
  ///   • `code`              — display-only; useful if the UI wants to
  ///     show "Applying your code XYZ" but not something we forward.
  ///
  /// Returns `null` on transport errors so the caller can fall back to
  /// the manual prompt safely.
  Future<({bool hasPending, bool alreadyProcessed, String? code})?>
      fetchPendingReferralStatus() async {
    try {
      final res = await SubscriptionRepo().pendingReferralRepo();
      if (!res.isSuccess) return null;
      final data = res.response?.data?['data'];
      if (data is! Map) return null;
      return (
        hasPending: data['hasPending'] == true,
        alreadyProcessed: data['alreadyProcessed'] == true,
        code: data['referralCode']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> checkReferralApi(String refCode) async {
    try {

      checkReferralResponse.value =
          ApiResponse.initial('Initial');

      final res = await UserRepo().checkReferralRepo(refCode);

      if (res.isSuccess) {
        // referralSuggestions.value = res.response?.data['data'];
        checkReferralResponse.value =
            ApiResponse.complete(res.response?.data);

      } else {
        commonSnackBar(
          message: res.message ?? AppStrings.somethingWentWrong.tr,
        );
        checkReferralResponse.value =
            ApiResponse.error("${res.message ?? AppStrings.somethingWentWrong.tr}");
      }
    } catch (e) {
      checkReferralResponse.value =
          ApiResponse.error(e.toString());
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
