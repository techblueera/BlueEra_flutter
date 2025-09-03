import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/subscription_create_model.dart';
import 'package:BlueEra/core/api/model/subscription_offer_model.dart';
import 'package:BlueEra/core/api/model/subscription_plan_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/subscription/subscription_repo.dart';
import 'package:get/get.dart';

class SubscriptionController extends GetxController {
  Rx<ApiResponse> createSubscriptionResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> verificationSubscriptionResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> cancelSubscriptionResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSubscriptionPlanResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSubscriptionOfferResponse =
      ApiResponse.initial('Initial').obs;

  var selectedMethod = PaymentMethod.upi.obs;

  void selectMethod(PaymentMethod? method) {
    selectedMethod.value = method ?? selectedMethod.value;
  }

  var selectedOffer = Rxn<OfferData>();

  void selectOffer(OfferData? offer) {
    selectedOffer.value = offer;
  }

  var isRedeemEnabled = false.obs;

  void toggleRedeem(bool value) {
    isRedeemEnabled.value = value;
  }

  var isAutoPayEnabled = false.obs;

  void toggleAutoPay(bool value) {
    isAutoPayEnabled.value = value;
  }

  RxnInt selectedIndex = RxnInt(null);
  RxnInt finalPayAmount = RxnInt(null);

  ///SUBSCRIPTION PLAN...
  Rx<SubscriptionPlanModel> subscriptionDetailModel =
      SubscriptionPlanModel().obs;

  calculateAmount() {
    finalPayAmount.value = (subscriptionDetailModel
                .value.data?[selectedIndex.value ?? -1].amount!
                .toInt() ??
            0) -
        (selectedOffer.value?.offerAmount?.toInt() ?? 0);
  }

  Future getSubscriptionPlan() async {
    try {
      getSubscriptionPlanResponse.value = ApiResponse.initial('Initial');

      ResponseModel response = await SubscriptionRepo().subscriptionPlan();
      if (response.isSuccess) {
        subscriptionDetailModel.value =
            SubscriptionPlanModel.fromJson(response.response?.data);
        getSubscriptionPlanResponse.value = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getSubscriptionPlanResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      getSubscriptionPlanResponse.value = ApiResponse.error('error');
    }
  }

  ///GET PLAN OFFER..
  Rx<SubscriptionOfferModel> subscriptionOfferModel =
      SubscriptionOfferModel().obs;

  Future getSubscriptionOffer() async {
    try {
      getSubscriptionOfferResponse.value = ApiResponse.initial('Initial');

      ResponseModel response = await SubscriptionRepo().subscriptionOffer();
      if (response.isSuccess) {
        subscriptionOfferModel.value =
            SubscriptionOfferModel.fromJson(response.response?.data);
        getSubscriptionOfferResponse.value = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getSubscriptionOfferResponse.value = ApiResponse.error('error');
      }
    } catch (e) {
      getSubscriptionOfferResponse.value = ApiResponse.error('error');
    }
  }

  ///CREATE SUBSCRIPTION...

  Rx<SubscriptionCreateModel> subscriptionData = SubscriptionCreateModel().obs;

  Future<void> createSubscriptionController(
      {required Map<String, dynamic>? params}) async {
    try {
      createSubscriptionResponse.value = ApiResponse.initial('Initial');

      ResponseModel responseModel =
          await SubscriptionRepo().createSubscriptionRepo(params: params ?? {});
      if (responseModel.isSuccess) {
        subscriptionData.value =
            SubscriptionCreateModel.fromJson(responseModel.response?.data);
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

  ///VERIFY SUBSCRIPTION...
  Future<void> verifySubscriptionController(
      {required Map<String, dynamic> params}) async {
    try {
      ResponseModel responseModel =
          await SubscriptionRepo().verifySubscriptionRepo(params: params);
      if (responseModel.isSuccess) {
        commonSnackBar(message: responseModel.message ?? AppStrings.success);
        Get.back();
        verificationSubscriptionResponse.value =
            ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      verificationSubscriptionResponse.value = ApiResponse.error('error');
    }
  }

  ///CANCEL SUBSCRIPTION...
  Future<void> cancelSubscriptionController(Map<String, dynamic> params) async {
    try {
      ResponseModel responseModel =
          await SubscriptionRepo().cancelSubscriptionRepo(params);
      if (responseModel.isSuccess) {
        cancelSubscriptionResponse.value = ApiResponse.complete(responseModel);
      } else {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      cancelSubscriptionResponse.value = ApiResponse.error('error');
    }
  }
}
