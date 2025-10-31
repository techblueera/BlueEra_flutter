import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

import '../../view/orders_chat/widget/payment_successfull_page.dart';

class RazorpayController extends GetxController {
  late Razorpay _razorpay;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required double amount,
    required String customerName,
    required String contact,
    required String email,
  }) {
    var options = {
      'key': 'rzp_live_RYv0tzupV710iQ', // 🔑 Replace with your Razorpay key
      // 'key': 'rzp_test_ohzYMNmUvD1Vxg', // 🔑 Replace with your Razorpay key
      'amount': (amount + (amount * 0.10)).toInt(), // Razorpay takes amount in paise
      'name': customerName,
      'description': 'Porter Vehicle Booking',
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.snackbar(
      "Payment Successful",
      "Payment ID: ${response.paymentId}",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    Get.off(()=>PaymentSuccessScreen(

    ));
    // TODO: Call your order confirm API here
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar(
      "Payment Failed",
      "Code: ${response.code}\nMessage: ${response.message}",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      "External Wallet Selected",
      response.walletName ?? '',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
