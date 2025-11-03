import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../common/bottomNavigationBar/auth/controller/bottom_bar_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/payment_success_model.dart';
import '../../../../../core/api/apiService/api_response.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  final orderController = Get.find<OrderNowController>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final chatViewController = Get.find<ChatViewController>();
  final bottomBarController = Get.find<BottomBarController>();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero,(){orderController.createOrder();});
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Obx(() {
        if (orderController.paymentResponse.value.status == Status.COMPLETE) {
          PaymentResponseModel data = orderController.paymentResponseModel.value;

          final timestamp = data.estimatedPickupTime;

// safely handle nulls & seconds-based timestamps
          final pickupDateTime = DateTime.fromMillisecondsSinceEpoch(
            (timestamp ?? 0) < 1000000000000 // if timestamp looks like seconds
                ? (timestamp ?? 0) * 1000
                : (timestamp ?? 0),
          );

          final formattedPickupTime =
          DateFormat('dd MMM yyyy • hh:mm a').format(pickupDateTime);
          final amount =((data.estimatedFareDetails?.minorAmount ?? 0) / 100);
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.blueLight,AppColors.blueDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.green,
                          size: 80,
                        ),
                      ),
                    ),
                     SizedBox(height: SizeConfig.size30),
                    const CustomText(
                      "Payment Successful!",
                        color: AppColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                    ),
                     SizedBox(height: SizeConfig.size10),
                    const CustomText(
                      "Your order has been placed successfully.",
                        color: AppColors.white99,
                        fontSize: 16,
                      textAlign: TextAlign.center,
                    ),
                     SizedBox(height: SizeConfig.size35),

                    // Order details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          AppShadows.bottomShadow
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildOrderIdRow(data.orderId ?? '-'),
                          const Divider(),
                          _buildDetailRow(
                              "Amount",
                              "₹ ${(amount+(amount * 0.10)).toStringAsFixed(2)}"),
                          const Divider(),
                          _buildDetailRow("Pickup At", formattedPickupTime),
                        ],
                      ),
                    ),
                     SizedBox(height: SizeConfig.size30),

                    // Track order button
                    ElevatedButton.icon(
                      onPressed: () async {
                        chatViewController.emitEvent(
                            "ChatList", {ApiKeys.type: "order"}, true);
                        chatViewController.onSelectChatTab(3);
                        bottomBarController.onChangeIndex(4);
                        Navigator.popUntil(context, ModalRoute.withName(RouteHelper.getBottomNavigationBarScreenRoute()));

                      },
                      // icon: const Icon(Icons.location_on_outlined),
                      label: const CustomText("View My Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2F80ED),
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                     SizedBox(height: SizeConfig.size16),

                    // Done button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const CustomText(
                        "Done",
                       color:  AppColors.white,
                          fontSize: 16
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      }),
    );
  }

  /// 🔹 Row with COPY icon for Order ID
  Widget _buildOrderIdRow(String orderId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CustomText(
            "Order ID",
           fontSize: 15,
              color:  AppColors.grayText
          ),
          Row(
            children: [
              CustomText(
                orderId,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:AppColors.black,
              ),
               SizedBox(width: SizeConfig.size8),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: orderId));
                  if (mounted) {
                    commonSnackBar(message: "Order ID copied to clipboard");
                  }
                },
                child: const Icon(
                  Icons.copy,
                  size: 18,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔹 Reusable detail row widget
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(title,
                  fontSize: 15, color: AppColors.blackA3
          ),
          CustomText(value,

                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black
          )
        ],
      ),
    );
  }
}
