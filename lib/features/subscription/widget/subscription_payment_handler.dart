import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/razor_pay_services.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';
import 'package:BlueEra/features/subscription/auth/model/subscription_trial_initiate.dart';
import 'package:BlueEra/features/subscription/widget/promo_code_dialog.dart';
import 'package:BlueEra/features/subscription/widget/subscription_loading_dialog.dart';
import 'package:BlueEra/features/subscription/widget/subscription_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionPaymentHandler {
  final SubscriptionController controller;

  SubscriptionPaymentHandler(this.controller);

  final subscriptionController = getOrPut(()=> SubscriptionController());

  /// Entry point for the subscription flow.
  ///
  /// Before showing the PromoCodeDialog, we ask the backend (via
  /// `GET /wallet/pending-referral`) for the user's referral state:
  ///
  ///   • `hasPending: true`         — a code was captured earlier (e.g.
  ///     an invite deep link) and the server will auto-apply it on
  ///     trial/subscription. Skip the dialog AND do NOT forward the
  ///     code in our payload (it's display-only).
  ///   • `alreadyProcessed: true`   — the user already has a completed
  ///     referral row; never prompt them again. Skip the dialog.
  ///   • both false                 — show the manual PromoCodeDialog so
  ///     the user can type a code if they have one.
  ///
  /// On transport errors we fall through to the manual dialog so a
  /// backend hiccup doesn't silently block the flow.
  Future<void> showReferralCodeDialog() async {
    final status = await subscriptionController.fetchPendingReferralStatus();
    if (status != null && (status.hasPending || status.alreadyProcessed)) {
      processSubscription('');
      return;
    }

    Get.dialog(
      PromoCodeDialog(
        onBtnPressed: (refCode) async {
          if (refCode.isNotEmpty) {
            await subscriptionController.checkReferralApi(refCode);
            if (subscriptionController.checkReferralResponse.value.status != Status.COMPLETE) return;
          }
          Get.back();
          processSubscription(refCode);
        },
      ),
      barrierDismissible: false,
    );
  }

  void showSuccess() {
    // Track which path closed the dialog so the .then callback below
    // doesn't double-fire the refresh when the user already used the
    // button (which closes the dialog itself).
    bool handledByButton = false;

    Get.dialog(
      SubscriptionSuccessDialog(
        // title: "You're All Set!",
        message:
            "Your plan is now active. Let's take you to your statistics so you can track everything in one place.",
        buttonTitle: "View My Statistics",
        onBtnPressed: () async {
          handledByButton = true;
          // Close the success dialog first so the route stack is clean
          // before we touch the underlying Me-screen TabController.
          if (Get.isDialogOpen ?? false) Get.back();
          await _refreshAfterSuccess(navigateToStats: true);
        },
      ),
      // Tap-outside / back-gesture path is now allowed — the .then
      // callback below catches it and runs the same refresh as the
      // button so the user always lands on fresh data.
      barrierDismissible: true,
    ).then((_) async {
      if (!handledByButton) {
        await _refreshAfterSuccess(navigateToStats: false);
      }
    });
  }

  /// Re-pulls both subscription endpoints after a successful purchase so
  /// the live plan card and the plan-list UI both reflect the new state,
  /// then optionally jumps to the Statistics tab. Wrapped in the branded
  /// loader so the user always sees deliberate feedback during the
  /// post-payment refresh — no blank screen between the success dialog
  /// closing and the Me-screen tab content updating.
  Future<void> _refreshAfterSuccess({required bool navigateToStats}) async {
    _showLoader(
      message: 'Updating your account',
      subtitle: 'Just a sec — pulling your latest plan…',
    );
    // Concurrent fetches; the controller's per-endpoint in-flight flags
    // make the calls independent so this is one round-trip wall-clock.
    await Future.wait([
      controller.userCurrentPlanApi(),
      controller.subscriptionPlansGetApi(),
    ]);
    _hideLoader();
    if (navigateToStats) {
      // Jump whichever Me screen is currently mounted to its Statistics
      // tab. The peek subscription sheet is already hidden because the
      // refresh above flipped the user to 'active' status reactively.
      MeTabRegistry.goToStatisticsTab();
    }
  }

  Future<void> processSubscription(String refCode) async {
    final subscriptionPlanData = controller
        .subscriptionPlanDetailsNewModel
        .value
        .data?[controller.selectedSubscriptionIndex.first];

    // 1. Initiate the subscription trial/payment via API. Show the
    // branded loader for the entire round-trip so the user has visible
    // feedback while we wait on /subscription/trial/initiate.
    _showLoader(
      message: 'Setting up your subscription',
      subtitle: "Hang tight — we're preparing your plan.",
    );
    await controller.subscriptionTrialInitiate(
      params: {
        ApiKeys.subscriptionPlanId: subscriptionPlanData?.id,
        if(refCode.isNotEmpty) ApiKeys.referralCode: refCode,
      },
    );
    _hideLoader();

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
    // Razorpay sheet has just closed — show the loader for the entire
    // verify + refresh chain so the user isn't staring at a blank screen
    // while the two backend calls finish.
    _showLoader(
      message: 'Verifying your payment',
      subtitle: 'Activating your premium access…',
    );
    await controller.verifySubscriptionTrial(
      params: {
        ApiKeys.razorpay_payment_id: response.paymentId ?? "",
        ApiKeys.razorpay_signature: response.signature ?? "",
        ApiKeys.razorpay_subscription_id: response.data!['razorpay_subscription_id'],
        ApiKeys.planId: planData?.planId,
        ApiKeys.subscriptionPlanId: planData?.id,
      },
    );
    // Refresh the user's current plan up-front (don't wait for the
    // dialog button) so the SubscriptionDraggableSheet's reactive
    // visibility check sees the new "active" status and collapses
    // immediately. By the time the user taps "View My Statistics" the
    // peek is already gone and the underlying Me screen is unobstructed.
    await controller.userCurrentPlanApi();
    _hideLoader();
    showSuccess();
  }

  /// Mounts [SubscriptionLoadingDialog] as a non-dismissible Get dialog.
  /// The barrier blocks taps so the user can't accidentally trigger the
  /// flow twice while a request is in flight.
  void _showLoader({required String message, String? subtitle}) {
    Get.dialog(
      SubscriptionLoadingDialog(message: message, subtitle: subtitle),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
    );
  }

  /// Closes the loader dialog if it's currently on top of the route stack.
  /// Guarded so it's safe to call when no loader is open (e.g., after a
  /// failure path that already dismissed it).
  void _hideLoader() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}



