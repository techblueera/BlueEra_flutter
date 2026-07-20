import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../core/services/razor_pay_services.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/controller/order_controllar.dart';

class WaitingForPaymentDialog extends StatelessWidget {
  const WaitingForPaymentDialog({
    super.key,
    required this.driverDistanceKm,
    required this.orderId,
    required this.driverPhone,
    required this.driverName,
    required this.driverImageUrl,
    required this.context,
  });

  final String orderId;
  final String driverPhone;
  final String driverName;
  final String driverImageUrl;
  final String driverDistanceKm;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final orderController = Get.find<OrderNowController>();

    int remainingSeconds = 180; // 3 minutes
    Timer? timer;

    void launchDialPad(String phoneNumber) async {
      final Uri url = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch dialer';
      }
    }

    return StatefulBuilder(
      builder: (context, setState) {
        // ✅ Start timer only once
        if (timer == null) {
          timer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (remainingSeconds > 0) {
              setState(() => remainingSeconds--);
            } else {
              t.cancel();
              // Navigator.pop(context);
              commonSnackBar(
                message: AppStrings.paymentWindowExpired,
              );
            }
          });
        }

        String formatTime(int seconds) {
          int minutes = seconds ~/ 60;
          int secs = seconds % 60;
          return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        }

        /// ⚠️ Warning dialog shown when user tries to leave
        Future<bool> _showLeaveWarningDialog(BuildContext ctx) async {
          return await showDialog<bool>(
                context: ctx,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeConfig.size16),
                  ),
                  title: const CustomText(AppStrings.leavePayment,
                      fontWeight: FontWeight.bold),
                  content: CustomText(AppStrings.leavePaymentWarning,
                      fontSize: SizeConfig.size15),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx, false); // ❌ Stay
                        },
                        child: CustomText(
                          AppStrings.noStay,
                        )),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx, true); // ✅ Leave
                      },
                      child: const CustomText(AppStrings.yesLeave,
                          color: AppColors.white),
                    ),
                  ],
                ),
              ) ??
              false;
        }

        return WillPopScope(
          onWillPop: () async {
            // 👇 intercept system back press
            bool shouldLeave = await _showLeaveWarningDialog(context);
            if (shouldLeave) {
              timer?.cancel();
              Navigator.pop(context);
              orderController
                  .cancelOrderForce(orderId, {ApiKeys.status: "cancelled"});
              commonSnackBar(message: AppStrings.orderCanceledPayment);
            }
            return Future.value(false); // prevent default pop
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SizeConfig.size20),
            ),
            insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
            child: Container(
              padding: EdgeInsets.all(SizeConfig.size20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SizeConfig.size20),
                color: AppColors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🚖 DRIVER DETAILS
                  Row(
                    children: [
                      CircleAvatar(
                        radius: SizeConfig.size28,
                        backgroundImage: NetworkImage(driverImageUrl),
                        onBackgroundImageError: (_, __) =>
                            Icon(Icons.person, size: SizeConfig.size30),
                      ),
                      SizedBox(width: SizeConfig.size12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              driverName,
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: SizeConfig.size4),
                            Row(
                              children: [
                                Icon(Icons.phone,
                                    size: SizeConfig.size16,
                                    color: AppColors.grey9B),
                                SizedBox(width: SizeConfig.size4),
                                CustomText(driverPhone,
                                    fontSize: SizeConfig.small,
                                    color: AppColors.grey9B),
                              ],
                            ),
                            SizedBox(height: SizeConfig.size4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: SizeConfig.size16,
                                    color: AppColors.grey9B),
                                SizedBox(width: SizeConfig.size4),
                                CustomText(
                                  "${driverDistanceKm} ${AppStrings.away.tr}",
                                  fontSize: SizeConfig.small,
                                  color: AppColors.grey9B,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          launchDialPad(driverPhone);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size14,
                              vertical: SizeConfig.size5),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.size6),
                              color: AppColors.primaryColor),
                          child: Center(
                            child: CustomText(
                              AppStrings.call,
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size24),

                  // 🎨 PAYMENT DESIGN (Animated Circle)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 6.28,
                            child: Container(
                              width: SizeConfig.size90,
                              height: SizeConfig.size90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    AppColors.primaryColor.withValues(alpha: 0.1),
                                    AppColors.primaryColor,
                                    AppColors.primaryColor.withValues(alpha: 0.1),
                                  ],
                                  stops: const [0.2, 0.5, 1],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: SizeConfig.size65,
                        height: SizeConfig.size65,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.currency_rupee_rounded,
                          color: AppColors.primaryColor,
                          size: SizeConfig.size36,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size18),
                  CustomText(
                    AppStrings.paymentRequired,
                    fontSize: SizeConfig.extraLarge,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: SizeConfig.size10),
                  CustomText(
                    AppStrings.waitingPaymentMsg,
                    textAlign: TextAlign.center,
                    fontSize: SizeConfig.medium15,
                    color: AppColors.black65,
                    height: 1.4,
                  ),

                  SizedBox(height: SizeConfig.size16),
                  // ⏱ TIMER
                  Container(
                    padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size8,
                        horizontal: SizeConfig.size16),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(SizeConfig.size12),
                    ),
                    child: CustomText(
                      "${AppStrings.timeRemaining.tr}: ${formatTime(remainingSeconds)}",
                      fontSize: SizeConfig.medium15,
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: SizeConfig.size20),
                  // 💳 BUTTON
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.size12),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.size10,
                              horizontal: SizeConfig.size20,
                            ),
                          ),
                          onPressed: () {
                            timer?.cancel();
                            // Navigator.pop(context);
                            final razorpayService = RazorpayService();

                            razorpayService.openCheckout(
                              note: {ApiKeys.ride_order_id: '$orderId'},
                              name:
                                  "${orderController.openedMessage?.buyer?.name}",
                              subscriptionId: "",
                              description: '',
                              amount: double.parse(
                                  orderController.fare.value.toString()),
                              contact:
                                  "${orderController.openedMessage?.buyer?.contact}",
                              email: 'admin@bluecs.in',
                              onPaymentSuccess: (response) async {
                                await orderController
                                    .updatePaymentStausByUser(orderId);
                                orderController.createRiderPickupOrder(
                                  orderController.openedMessage?.id,
                                  orderController.openedMessage?.seller?.id,
                                  orderController.openedMessage?.conversationId,
                                );
                                Get.back();
                                showOrderPlacedDialog(context);
                              },
                              onPaymentError: (response) {
                                orderController.cancelOrderForce(
                                    orderId, {ApiKeys.status: "cancelled"});
                                debugPrint(
                                    "Payment Failed: ${response.message}");
                                // Shared mapping — a back-press / cancel reads
                                // as "payment cancelled", not raw "Payment Error".
                                commonSnackBar(
                                    message: RazorpayService
                                        .humanReadableError(response));
                              },
                            );
                          },
                          icon:
                              Icon(Icons.credit_card, size: SizeConfig.size18),
                          label: CustomText(
                            "${AppStrings.payNow.tr} (₹${orderController.fare.value})",
                            fontSize: SizeConfig.large,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showOrderPlacedDialog(BuildContext context) async {
  Get.find<OrderNowController>();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.size24),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size24),
        child: Container(
          padding: EdgeInsets.all(SizeConfig.size24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SizeConfig.size24),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.1),
                AppColors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Success icon
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(SizeConfig.size16),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryColor,
                  size: SizeConfig.size70,
                ),
              ),
              SizedBox(height: SizeConfig.size20),

              // ✅ Title
              CustomText(
                AppStrings.orderPlacedSuccess,
                fontSize: SizeConfig.extraLarge,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SizeConfig.size12),

              // ✅ Subtitle
              CustomText(
                AppStrings.viewOrderBelow,
                fontSize: SizeConfig.small,
                color: AppColors.grey9B,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SizeConfig.size28),

              // ✅ Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: SizeConfig.size14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12),
                        ),
                      ),
                      child: CustomText(
                        AppStrings.notNow,
                        fontSize: SizeConfig.medium15,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final chatViewController =
                            Get.find<ChatViewController>();
                        final bottomBarController =
                            Get.find<BottomBarController>();
                        chatViewController.emitEvent(ChatEmitEvents.ChatList,
                            {ApiKeys.type: "order"}, );
                        bottomBarController.onChangeIndex(2);
                        chatViewController.onSelectChatTab(0);

                        Navigator.popUntil(
                            context,
                            ModalRoute.withName(RouteHelper
                                .getBottomNavigationBarScreenRoute()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding:
                            EdgeInsets.symmetric(vertical: SizeConfig.size14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12),
                        ),
                      ),
                      child: CustomText(
                        AppStrings.openOrders,
                        fontSize: SizeConfig.medium15,
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
