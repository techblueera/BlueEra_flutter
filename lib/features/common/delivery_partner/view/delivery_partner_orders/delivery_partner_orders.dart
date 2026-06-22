import 'dart:developer';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/pickup_order_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeliveryPartnerOrders extends StatefulWidget {
  /// When true, this widget is being embedded inside a parent
  /// [CustomScrollView] (e.g. the rider service screen tab body) and
  /// should NOT introduce its own [Scaffold]/[Expanded] chrome — the
  /// inner [PickupOrderScreen] will run in shrink-wrap mode so the
  /// parent owns the scroll. Defaults to `false` for standalone use.
  final bool isInParentScroll;

  const DeliveryPartnerOrders({super.key, this.isInParentScroll = false});

  @override
  State<DeliveryPartnerOrders> createState() => _DeliveryPartnerOrdersState();
}

class _DeliveryPartnerOrdersState extends State<DeliveryPartnerOrders> {
  final controller = getOrPut(() => DeliverPartnerOrdersController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());

  @override
  void initState() {
    super.initState();
    // When embedded in a parent scroll (e.g. RiderServiceScreen), the
    // PARENT owns the single SSE stream lifecycle — it needs the stream
    // running even while this widget is hidden behind the preference
    // card. So we only self-manage the stream in standalone use.
    if (!widget.isInParentScroll &&
        deliveryPartnerController.riderVerificationState ==
            RiderVerificationState.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchStream();
      });
    }
  }

  @override
  void dispose() {
    // Mirror initState: only tear the stream down when we started it.
    // For embedded use the parent owns (and disposes) the stream.
    if (!widget.isInParentScroll &&
        deliveryPartnerController.riderVerificationState ==
            RiderVerificationState.completed) {
      controller.stopStream();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final body = (userProfessionGlobal == BIKE_RIDER||userProfessionGlobal == CAR_TAXI_DRIVER)
            ? Obx(() => deliveryPartnerController.isRiderStatusLoading.value
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Builder(builder: (context) {
                    final state =
                        deliveryPartnerController.riderVerificationState;
                    final allCompleted = deliveryPartnerController
                        .stepStatus.values
                        .every((s) => s == true);
                    log('all steps Completed-- $allCompleted state ==== $state');

                    // ---- Rejected ----
                    if (allCompleted &&
                        state == RiderVerificationState.rejected) {
                      // showStatusDialog(
                      //   context,
                      //   "Verification Rejected",
                      //   "Your rider verification was rejected. Please contact support or update your details.",
                      // );

                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: CustomText(
                            AppStrings.verificationRejected,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // ---- Pending ----
                    if (allCompleted &&
                        state == RiderVerificationState.pending) {
                      // showStatusDialog(
                      //   context,
                      //   "Verification Pending",
                      //   "Your rider verification is under review. Please wait for approval.",
                      // );

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CustomText(
                            AppStrings.verificationPending,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // ---- Completed ----
                    if (state == RiderVerificationState.completed) {
                      // Verified driver — go straight to the pickup
                      // orders screen. (The L3 category filter has
                      // been retired; the only live body is pickup,
                      // and pickup's own per-status filters now sit
                      // in a bottom-sheet picker inside that screen.)
                      return PickupOrderScreen(
                        isInParentScroll: widget.isInParentScroll,
                      );
                    }

                    // ================================
                    final firstIncomplete = deliveryPartnerController
                        .stepStatus.entries
                        .firstWhere((e) => e.value == false);

                    log('firstIncomplete -- $firstIncomplete');

                    String message = "";

                    switch (firstIncomplete.key) {
                      case RiderProfileStep.personalInfo:
                        message = AppStrings.personalInfoMsg;
                        break;
                      case RiderProfileStep.addressInfo:
                        message = AppStrings.addressInfoMsg;
                        break;
                      case RiderProfileStep.personalIdentificationInfo:
                        message = AppStrings.idVerificationMsg;
                        break;
                      case RiderProfileStep.drivingInfo:
                        message = AppStrings.drivingVerificationMsg;
                        break;
                      case RiderProfileStep.vehicleImagesInfo:
                        message = AppStrings.vehicleImagesMsg;
                        break;
                      case RiderProfileStep.vehicleInfo:
                        message = AppStrings.vehicleInfoMsg;
                        break;
                      case RiderProfileStep.aadharInfo:
                        // TODO: Handle this case.
                        message = AppStrings.aadharNumber;
                      case RiderProfileStep.rcInfo:
                        // TODO: Handle this case.
                        message = AppStrings.rcNumber;
                      case RiderProfileStep.panInfo:
                        // TODO: Handle this case.
                        message = AppStrings.panNumber;
                    }

                    // showStatusDialog(context, title, message);

                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: CustomText(
                          message,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }))
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: CustomText(
                    AppStrings.ridersOnlyMsg,
                    textAlign: TextAlign.center,
                  ),
                ),
              );

    return widget.isInParentScroll ? body : Scaffold(body: body);
  }

  void showStatusDialog(BuildContext context, String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: CustomText(title),
          content: CustomText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomText(AppStrings.ok),
            ),
          ],
        ),
      );
    });
  }
}
