import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../core/services/razor_pay_services.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../common/bottomNavigationBar/auth/controller/bottom_bar_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/GetListOfMessageData.dart';

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
                message: "Payment window expired. Please try again.",
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Leave Payment?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    "If you leave this screen, your order will be cancelled.\nAre you sure you want to leave?",
                    style: TextStyle(fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx, false); // ❌ Stay
                      },
                      child: const CustomText("No, Stay"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx, true); // ✅ Leave
                      },
                      child: const CustomText("Yes, Leave",color: AppColors.white,),
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
              orderController.cancelOrderForce(orderId,{
                ApiKeys.status: "cancelled"
              });
              commonSnackBar(
                  message:
                      "Order cancelled because payment was not completed.");
            }
            return Future.value(false); // prevent default pop
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🚖 DRIVER DETAILS
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(driverImageUrl),
                        onBackgroundImageError: (_, __) =>
                            const Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              driverName,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                CustomText(driverPhone,
                                    fontSize: 14, color: Colors.grey[700]),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                CustomText(
                                  "${driverDistanceKm} away",
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: (){
                          launchDialPad(driverPhone);
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: AppColors.primaryColor),
                          child: Center(
                            child: CustomText(
                              "Call",
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

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
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    AppColors.primaryColor.withOpacity(0.1),
                                    AppColors.primaryColor,
                                    AppColors.primaryColor.withOpacity(0.1),
                                  ],
                                  stops: const [0.2, 0.5, 1],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.currency_rupee_rounded,
                          color: AppColors.primaryColor,
                          size: 36,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const CustomText(
                    "Payment Required",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 10),
                  const CustomText(
                    "Your rider is waiting for payment confirmation.\n"
                    "Please complete your payment to proceed with delivery.",
                    textAlign: TextAlign.center,
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),

                  const SizedBox(height: 16),
                  // ⏱ TIMER
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomText(
                      "Time remaining: ${formatTime(remainingSeconds)}",
                      fontSize: 15,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),
                  // 💳 BUTTON
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                          ),
                          onPressed: () {


                            timer?.cancel();
                            // Navigator.pop(context);
                            final razorpayService = RazorpayService();

                            razorpayService.openCheckout(note:  { ApiKeys.ride_order_id: '$orderId' },
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
                                orderController.createRiderPickupOrder(orderController.openedMessage?.id, orderController.openedMessage?.seller?.id, orderController.openedMessage?.conversationId,);
                                Get.back();
                                showOrderPlacedDialog(context);
                              },
                              onPaymentError: (response) {
                                orderController.cancelOrderForce(orderId,{
                                  ApiKeys.status: "cancelled"
                                });
                                debugPrint(
                                    "Payment Failed: ${response.message}");
                                commonSnackBar(
                                    message:
                                        "Payment Failed ${response.message}");
                              },
                            );
                          },
                          icon: const Icon(Icons.credit_card),
                          label: CustomText(
                            "Pay Now (₹${orderController.fare.value})",
                            fontSize: 16,
                            color: Colors.white,
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
  final orderController = Get.find<OrderNowController>();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withOpacity(0.1),
                Colors.white,
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
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryColor,
                  size: 70,
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Title
              CustomText(
                "Order Placed Successfully!",
                fontSize: 20,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ✅ Subtitle
              CustomText(
                "You can view your order details in the ‘Orders’ section below.",
                fontSize: 14,
                color: Colors.grey,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // ✅ Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: CustomText(
                        "Not Now",
                        fontSize: 15,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final chatViewController = Get.find<ChatViewController>();
                        final bottomBarController = Get.find<BottomBarController>();
                        chatViewController.emitEvent(
                            "ChatList", {ApiKeys.type: "order"}, true);
                        chatViewController.onSelectChatTab(3);
                        bottomBarController.onChangeIndex(4);
                        Navigator.popUntil(context, ModalRoute.withName(RouteHelper.getBottomNavigationBarScreenRoute()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: CustomText(
                        "Open Orders",
                        fontSize: 15,
                        color: Colors.white,
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
