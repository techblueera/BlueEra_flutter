import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  // Custom callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onError;
  Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required String name,
    required String description,
    required double amount,
    required String contact,
    required String email,
    required String subscriptionId,
    String currency = "INR",
    String? orderId,
    Function(PaymentSuccessResponse)? onPaymentSuccess,
    Function(PaymentFailureResponse)? onPaymentError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    this.onSuccess = onPaymentSuccess;
    this.onError = onPaymentError;
    this.onExternalWallet = onExternalWallet;
logs("amount====$amount");
    var options = {
      'key': razorpayKey,
      'amount': amount,
      'name': name,
      if (subscriptionId.isNotEmpty) 'subscription_id': subscriptionId,
      'description': description,
      'currency': currency,
      'timeout': 180, // in seconds
      'retry': {'enabled': true, 'max_count': 3},
      'prefill': {'contact': contact, 'email': email},
    };

    try {
      logs("options =======$options");
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment Success: ${response.paymentId}");
    if (onSuccess != null) {
      onSuccess!(response);
    } else {
      commonSnackBar(message: 'Payment successful: ${response.paymentId}');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment Error: ${response.message}");
    if (onError != null) {
      onError!(response);
    } else {
      commonSnackBar(message: 'Payment failed: ${response.message}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    } else {
      commonSnackBar(message: 'Wallet selected: ${response.walletName}');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
