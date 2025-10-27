import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  void init() {
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
    // Razorpay amount is in paise, so multiply by 100
    var options = {
      'key': 'rzp_test_xxxxxxxx', // <-- Replace with your Razorpay Key ID
      'amount': (amount * 100).toInt(),
      'name': 'BlueEra Logistics',
      'description': 'Vehicle Booking Payment',
      'prefill': {
        'contact': contact,
        'email': email,
        'name': customerName,
      },
      'timeout': 120, // seconds
      'theme': {'color': '#0D47A1'}, // Blue color theme
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("⚠️ Razorpay open error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("✅ Payment Successful: ${response.paymentId}");
    // TODO: handle success callback (call API to confirm booking etc.)
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("❌ Payment Failed: ${response.message}");
    // TODO: handle failure callback (show dialog/snackbar)
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("⚡ External Wallet Selected: ${response.walletName}");
  }

  void dispose() {
    _razorpay.clear();
  }
}
