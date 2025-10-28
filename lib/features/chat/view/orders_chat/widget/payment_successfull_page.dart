import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/snackbar_helper.dart';
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
                colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
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
                    const SizedBox(height: 30),
                    const Text(
                      "Payment Successful!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your order has been placed successfully.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 35),

                    // Order details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
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
                    const SizedBox(height: 30),

                    // Track order button
                    ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(data.trackingUrl ?? '');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text("Track My Order"),
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
                    const SizedBox(height: 16),

                    // Done button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
          const Text(
            "Order ID",
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
          Row(
            children: [
              Text(
                orderId,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
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
          Text(title,
              style: const TextStyle(fontSize: 15, color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
        ],
      ),
    );
  }
}
