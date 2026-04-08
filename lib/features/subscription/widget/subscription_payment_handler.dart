import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_trial_initiate.dart';
import 'package:BlueEra/features/subscription/widget/promo_code_dialog.dart';
import 'package:BlueEra/features/subscription/widget/subscription_success_dialog.dart';
import 'package:get/get.dart';

class SubscriptionPaymentHandler {
  final SubscriptionController controller;

  SubscriptionPaymentHandler(this.controller);

  final subscriptionController = getOrPut(()=> SubscriptionController());

  void showReferralCodeDialog() {
    Get.dialog(
      PromoCodeDialog(
        onBtnPressed: (refCode) async {
          if(refCode.isNotEmpty){
            await subscriptionController.checkReferralApi(refCode);
            if(subscriptionController.checkReferralResponse.value.status == Status.COMPLETE){
              Get.back();
              processSubscription(refCode);
            }
          }else{
            Get.back();
            processSubscription(refCode);
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  void showSuccess() {
    Get.dialog(
      SubscriptionSuccessDialog(
        title: "Congratulations",
        message: "Your subscription was successful. Enjoy your premium benefits!",
        onBtnPressed: () {
          // Closes the dialog
          Get.back();

          // Refresh the controller data
          Get.find<SubscriptionController>().userCurrentPlanApi();
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> processSubscription(String refCode) async {
    final subscriptionPlanData = controller
        .subscriptionPlanDetailsNewModel
        .value
        .data?[controller.selectedSubscriptionIndex.first];

    // 1. Initiate the subscription trial/payment via API
    await controller.subscriptionTrialInitiate(
      params: {
        ApiKeys.subscriptionPlanId: subscriptionPlanData?.id,
        if(refCode.isNotEmpty) ApiKeys.referralCode: refCode,
      },
    );

    final response = controller.createSubscriptionResponse.value;
    final trialData = controller.subscriptionTrialData.value;

    // 2. Validate API success before opening Razorpay
    if (response.status == Status.COMPLETE && (trialData.success ?? false)) {
      _launchRazorpay(trialData.data, subscriptionPlanData);
    } else {
      commonSnackBar(message: "Failed to initiate subscription. Please try again.");
    }
  }

  void _launchRazorpay(
      SubscriptionTrialInitiateData? data,
      SubscriptionPlanData? planData) {
    final razorpayService = RazorpayService();

    razorpayService.openCheckout(
      razorpayKeyId: data?.keyId,
      name: AppConstants.appName,
      subscriptionId: data?.subscriptionId ?? "",
      description: 'Subscription Payment',
      amount: data?.amount?.toDouble() ?? 0.0,
      contact: userMobileGlobal,
      email: '$userMobileGlobal@gmail.com',
      onPaymentSuccess: (response) => _handleSuccess(response, planData),
      onPaymentError: (response) {
        commonSnackBar(message: "Payment Failed: ${response.message}");
      },
    );
  }

  Future<void> _handleSuccess(dynamic response, dynamic planData) async {
    await controller.verifySubscriptionTrial(
      params: {
        ApiKeys.razorpay_payment_id: response.paymentId ?? "",
        ApiKeys.razorpay_signature: response.signature ?? "",
        ApiKeys.razorpay_subscription_id: response.data!['razorpay_subscription_id'],
        ApiKeys.planId: planData?.planId,
        ApiKeys.subscriptionPlanId: planData?.id,
      },
    );
    showSuccess();
  }


}



