import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  // Custom callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onError;
  Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay(

    );
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    String? razorpayKeyId,
    required String name,
    required String description,
    required double amount,
    required String contact,
    required String email,
    required String subscriptionId,
    String currency = "INR",
    String? orderId,
    Map<String,dynamic>? note,
    Function(PaymentSuccessResponse)? onPaymentSuccess,
    Function(PaymentFailureResponse)? onPaymentError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    this.onSuccess = onPaymentSuccess;
    this.onError = onPaymentError;

    this.onExternalWallet = onExternalWallet;
    var options = {
      'key': razorpayKeyId ?? razorpayKey,
      // 'key': razorpayKey,
      'name': name,
      if (subscriptionId.isNotEmpty) ...{
        'subscription_id': subscriptionId,
      } else ...{
        'amount': (amount/100).toInt(),
        'currency': currency,
        if (orderId != null) 'order_id': orderId,
        // 'recurring': 1,
      },
      'description': description,
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
    debugPrint("Payment Error: ${response.error}");
    debugPrint("Payment Error Message: ${response.message}");
    debugPrint("Payment Error Code: ${response.code}");
    if (onError != null) {
      onError!(response);
    } else {
      commonSnackBar(message: humanReadableError(response));
    }
  }

  /// Maps a Razorpay [PaymentFailureResponse] to a short, human-readable
  /// message safe to show in a snackbar/dialog.
  ///
  /// Razorpay's own [PaymentFailureResponse.message] is frequently the
  /// literal string `"undefined"` (e.g. when the user back-presses out of
  /// the checkout sheet) or a raw error description, so we key off the
  /// stable integer [PaymentFailureResponse.code] first
  /// (`Razorpay.PAYMENT_CANCELLED`, `NETWORK_ERROR`, …) and only fall back
  /// to the server description when it actually reads like a sentence.
  static String humanReadableError(PaymentFailureResponse response) {
    switch (response.code) {
      case Razorpay.PAYMENT_CANCELLED:
        return AppStrings.paymentCancelled.tr;
      case Razorpay.NETWORK_ERROR:
      case Razorpay.TLS_ERROR:
        return AppStrings.paymentNetworkError.tr;
      case Razorpay.INVALID_OPTIONS:
      case Razorpay.INCOMPATIBLE_PLUGIN:
      case Razorpay.UNKNOWN_ERROR:
        return AppStrings.paymentGenericError.tr;
    }

    // Unknown / null code — use the server description only when it's a
    // real message, not Razorpay's "undefined", an empty string, or a raw
    // JSON error blob.
    final desc = response.message?.trim() ?? '';
    if (desc.isNotEmpty &&
        desc.toLowerCase() != 'undefined' &&
        !desc.startsWith('{')) {
      return desc;
    }
    return AppStrings.paymentGenericError.tr;
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
