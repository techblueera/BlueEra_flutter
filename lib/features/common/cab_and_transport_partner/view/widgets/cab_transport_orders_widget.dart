
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/pickup_order_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CabsAndTransportPartnerOrders extends StatefulWidget {
  /// When true, this widget is being embedded inside a parent
  /// [CustomScrollView] (e.g. the cab/transport partner tab body) and
  /// should NOT introduce its own [Scaffold]/[Expanded] chrome — the
  /// inner [PickupOrderScreen] will run in shrink-wrap mode so the
  /// parent owns the scroll. Defaults to `false` for standalone use.
  final bool isInParentScroll;

  const CabsAndTransportPartnerOrders({super.key, this.isInParentScroll = false});

  @override
  State<CabsAndTransportPartnerOrders> createState() => _CabsAndTransportPartnerOrdersState();
}

class _CabsAndTransportPartnerOrdersState extends State<CabsAndTransportPartnerOrders> {
  final controller = getOrPut(() => DeliverPartnerOrdersController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());

  @override
  void initState() {
    // if (deliveryPartnerController.riderVerificationState ==
    //     RiderVerificationState.completed) {
      controller.fetchStream();
    // }
    super.initState();
  }

  @override
  void dispose() {
    // if (deliveryPartnerController.riderVerificationState ==
    //     RiderVerificationState.completed) {
      controller.subscription?.cancel();
    // }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBody = Builder(
      builder: (context) {
        switch (controller.selectedDeliveryPartnerOrderIndex.value) {
          case 0:
            return PickupOrderScreen(
              isInParentScroll: widget.isInParentScroll,
            );
          case 1:
            return CustomText(AppStrings.comingSoon);
          // return GroceryOrderScreen();
          case 2:
            return CustomText(AppStrings.comingSoon);
          // return ParcelOrderScreen();
          case 3:
            return CustomText(AppStrings.comingSoon);
          // return IncomeScreen();
          default:
            return SizedBox.shrink(); // fallback
        }
      },
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.isInParentScroll
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: [
        // In embedded mode the parent owns the scroll, so we cannot use
        // `Expanded` (it requires a bounded vertical constraint).
        widget.isInParentScroll ? tabBody : Expanded(child: tabBody),
      ],
    );

    return widget.isInParentScroll
        ? body
        : Scaffold(
            body: body

        // (userProfessionGlobal == BIKE_RIDER)
        //     ? Obx(() => deliveryPartnerController.isRiderStatusLoading.value
        //     ? Center(
        //   child: CircularProgressIndicator(),
        // )
        //     : Builder(builder: (context) {
        //   final state =
        //       deliveryPartnerController.riderVerificationState;
        //   final allCompleted = deliveryPartnerController
        //       .stepStatus.values
        //       .every((s) => s == true);
        //   log('all steps Completed-- $allCompleted state ==== $state');
        //
        //   // ---- Rejected ----
        //   if (allCompleted &&
        //       state == RiderVerificationState.rejected) {
        //     // showStatusDialog(
        //     //   context,
        //     //   "Verification Rejected",
        //     //   "Your rider verification was rejected. Please contact support or update your details.",
        //     // );
        //
        //     return Padding(
        //       padding: const EdgeInsets.all(20.0),
        //       child: Center(
        //         child: CustomText(
        //           AppStrings.verificationRejected,
        //           textAlign: TextAlign.center,
        //         ),
        //       ),
        //     );
        //   }
        //
        //   // ---- Pending ----
        //   if (allCompleted &&
        //       state == RiderVerificationState.pending) {
        //     // showStatusDialog(
        //     //   context,
        //     //   "Verification Pending",
        //     //   "Your rider verification is under review. Please wait for approval.",
        //     // );
        //
        //     return Center(
        //       child: Padding(
        //         padding: const EdgeInsets.all(20.0),
        //         child: CustomText(
        //           AppStrings.verificationPending,
        //           textAlign: TextAlign.center,
        //         ),
        //       ),
        //     );
        //   }
        //
        //   // ---- Completed ----
        //   if (state == RiderVerificationState.completed) {
        //     return Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         // Padding(
        //         //   padding: EdgeInsets.all(SizeConfig.size15),
        //         //   child: HorizontalTabSelector(
        //         //     tabs: controller.deliveryPartnerOrdersTabs,
        //         //     selectedIndex: controller
        //         //         .selectedDeliveryPartnerOrderIndex.value,
        //         //     onTabSelected: (index, value) {
        //         //       if (mounted) {
        //         //         controller.selectedDeliveryPartnerOrderIndex
        //         //             .value = index;
        //         //       }
        //         //     },
        //         //     labelBuilder: (value) => value.label,
        //         //   ),
        //         // ),
        //         Expanded(
        //           child: Builder(
        //             builder: (context) {
        //               switch (controller
        //                   .selectedDeliveryPartnerOrderIndex.value) {
        //                 case 0:
        //                   return PickupOrderScreen();
        //                 case 1:
        //                   return CustomText(AppStrings.comingSoon);
        //               // return GroceryOrderScreen();
        //                 case 2:
        //                   return CustomText(AppStrings.comingSoon);
        //               // return ParcelOrderScreen();
        //                 case 3:
        //                   return CustomText(AppStrings.comingSoon);
        //               // return IncomeScreen();
        //                 default:
        //                   return SizedBox.shrink(); // fallback
        //               }
        //             },
        //           ),
        //         ),
        //       ],
        //     );
        //   }
        //
        //   // ================================
        //   final firstIncomplete = deliveryPartnerController
        //       .stepStatus.entries
        //       .firstWhere((e) => e.value == false);
        //
        //   log('firstIncomplete -- $firstIncomplete');
        //
        //   String title = AppStrings.stepIncompleteTitle;
        //   String message = "";
        //
        //   switch (firstIncomplete.key) {
        //     case RiderProfileStep.personalInfo:
        //       message = AppStrings.personalInfoMsg;
        //       break;
        //     case RiderProfileStep.addressInfo:
        //       message = AppStrings.addressInfoMsg;
        //       break;
        //     case RiderProfileStep.personalIdentificationInfo:
        //       message = AppStrings.idVerificationMsg;
        //       break;
        //     case RiderProfileStep.drivingInfo:
        //       message = AppStrings.drivingVerificationMsg;
        //       break;
        //     case RiderProfileStep.vehicleImagesInfo:
        //       message = AppStrings.vehicleImagesMsg;
        //       break;
        //     case RiderProfileStep.vehicleInfo:
        //       message = AppStrings.vehicleInfoMsg;
        //       break;
        //     case RiderProfileStep.aadharInfo:
        //     // TODO: Handle this case.
        //       message = AppStrings.aadharNumber;
        //     case RiderProfileStep.rcInfo:
        //     // TODO: Handle this case.
        //       message = AppStrings.rcNumber;
        //     case RiderProfileStep.panInfo:
        //     // TODO: Handle this case.
        //       message = AppStrings.panNumber;
        //   }
        //
        //   // showStatusDialog(context, title, message);
        //
        //   return Padding(
        //     padding: const EdgeInsets.all(20.0),
        //     child: Center(
        //       child: CustomText(
        //         message,
        //         textAlign: TextAlign.center,
        //       ),
        //     ),
        //   );
        // }))
        //     : Padding(
        //   padding: const EdgeInsets.all(20.0),
        //   child: Center(
        //     child: CustomText(
        //       AppStrings.ridersOnlyMsg,
        //       textAlign: TextAlign.center,
        //     ),
        //   ),
        // )
    );
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
