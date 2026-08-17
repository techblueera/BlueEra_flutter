import 'dart:async';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  /// Our own failure code for "the checkout sheet never opened", which the
  /// plugin has no code for: [Razorpay.open] is `async void`, so a platform
  /// failure inside it surfaces as an unhandled async error and NO payment
  /// event is ever emitted. Without this the caller is left spinning forever
  /// with nothing on screen — see [_handleOpenFailure].
  ///
  /// Deliberately outside the plugin's range (0-4, 100).
  static const int CHECKOUT_OPEN_FAILED = 900;

  // Custom callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onError;
  Function(ExternalWalletResponse)? onExternalWallet;

  /// True between [openCheckout] and the payment event that answers it.
  ///
  /// Two things depend on knowing a checkout is still outstanding: [dispose]
  /// must not tear the listeners down under it, and an async error arriving
  /// after the event has landed is a fault in OUR callback, not a failure to
  /// open.
  bool _checkoutOpen = false;
  bool get isCheckoutOpen => _checkoutOpen;

  /// Set when [dispose] was called mid-checkout; the teardown then happens as
  /// soon as the result arrives.
  bool _disposeRequested = false;

  RazorpayService() {
    _razorpay = Razorpay();
    _attachListeners();
  }

  /// Registers the three payment listeners.
  ///
  /// Called from the constructor — i.e. always before any [openCheckout], so a
  /// result can never arrive unlistened. Also re-used by [resync], because
  /// `Razorpay.on` is what triggers the plugin's internal `_resync()` that
  /// collects a result the native side had to park.
  void _attachListeners() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Re-collects a payment result that was delivered while the Flutter
  /// activity was away — call it when the app returns to the foreground with a
  /// checkout outstanding.
  ///
  /// Why it is needed: paying by UPI hands off to another app, and the
  /// Android activity behind checkout can be recreated meanwhile. The plugin
  /// then answers `onActivityResult` through a NEW delegate, so the
  /// `MethodChannel` future that `open()` is awaiting is never completed and
  /// no event fires. The native side parks that result in `pendingReply`, and
  /// re-registering a listener is the only way to ask for it. Parking is
  /// single-shot server-side (`resync` nulls it), so this cannot double-fire.
  void resync() {
    _razorpay.clear();
    _attachListeners();
  }

  /// Opens the Razorpay checkout sheet.
  ///
  /// [amount] is in **PAISE** — the same unit Razorpay's own `amount` option
  /// takes, and the unit every server order is denominated in. It is passed
  /// through untouched: nothing here re-computes a total. When [orderId] is
  /// given (every server-created order) Razorpay charges the ORDER's amount
  /// and this field is only a display/validation hint, so the two must agree.
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
    // Razorpay rejects empty prefill values outright (INVALID_OPTIONS, no
    // sheet), so an account with no email on file must send no email at all
    // rather than ''.
    final prefill = <String, dynamic>{
      if (contact.trim().isNotEmpty) 'contact': contact.trim(),
      if (email.trim().isNotEmpty) 'email': email.trim(),
    };
    // An EMPTY key is not the same as no key: the plugin only null-checks it,
    // so `''` sails past validation and dies in the native SDK with no sheet
    // and no event. Same for an empty order_id.
    final String key = (razorpayKeyId?.trim().isNotEmpty ?? false)
        ? razorpayKeyId!.trim()
        // The global is nullable and stays null until `projectKeys()` has run.
        : (razorpayKey ?? '');
    var options = {
      'key': key,
      // 'key': razorpayKey,
      'name': name,
      if (subscriptionId.isNotEmpty) ...{
        'subscription_id': subscriptionId,
      } else ...{
        // PAISE, as handed in. Razorpay's `amount` is paise, and the callers
        // pass the server's paise total — dividing here charged 1/100th of
        // it on every flow that has no order_id to override it.
        'amount': amount.toInt(),
        'currency': currency,
        if (orderId != null && orderId.trim().isNotEmpty)
          'order_id': orderId.trim(),
        // 'recurring': 1,
      },
      'description': description,
      'timeout': 180, // in seconds
      'retry': {'enabled': true, 'max_count': 3},
      if (prefill.isNotEmpty) 'prefill': prefill,
      if (note != null && note.isNotEmpty) 'notes': note,
    };

    _checkoutOpen = true;
    if (key.isEmpty) {
      // Nothing to open with — say so here rather than letting the native SDK
      // fail mutely a second later.
      _handleOpenFailure('missing razorpay key', options);
      return;
    }
    logs("Razorpay open: ${_redacted(options)}");
    // `Razorpay.open` is `async void` and awaits a MethodChannel call inside,
    // so a platform failure NEVER reaches a plain try/catch here — it lands as
    // an unhandled async error and the caller waits forever. The zone catches
    // exactly that; the try/catch stays for the synchronous path.
    final outerZone = Zone.current;
    try {
      runZonedGuarded(
        () => _razorpay.open(options),
        (error, stack) {
          // Anything raised once the result is in belongs to our own success
          // handler, not to the sheet — hand it back to the app's normal
          // uncaught-error path (Crashlytics) instead of eating it here.
          if (!_checkoutOpen) {
            logs("Razorpay post-result error (payment NOT affected): $error");
            outerZone.handleUncaughtError(error, stack);
            return;
          }
          _handleOpenFailure(error, options);
        },
      );
    } catch (e) {
      _handleOpenFailure(e, options);
    }
  }

  /// The checkout sheet did not open.
  ///
  /// Reported to the caller as a payment failure so the UI unwinds — a stuck
  /// spinner with nothing on screen is what made this indistinguishable from
  /// "the user closed the sheet". The log line carries the options, so the two
  /// are now told apart in a bug report as well.
  void _handleOpenFailure(Object error, Map<String, dynamic> options) {
    if (!_checkoutOpen) {
      logs("Razorpay post-result error (payment NOT affected): $error");
      return;
    }
    _settleCheckout();
    logs("Razorpay open FAILED: $error | options=${_redacted(options)}");
    final failure = PaymentFailureResponse(
      CHECKOUT_OPEN_FAILED,
      'checkout_open_failed: $error',
      null,
    );
    if (onError != null) {
      onError!(failure);
    } else {
      commonSnackBar(message: humanReadableError(failure));
    }
  }

  /// Options minus the buyer's contact details — these lines go to logcat and
  /// Crashlytics breadcrumbs, and the amount/order/key are what we actually
  /// need to read there.
  Map<String, dynamic> _redacted(Map<String, dynamic> options) {
    final copy = Map<String, dynamic>.from(options);
    if (copy.containsKey('prefill')) copy['prefill'] = '<redacted>';
    return copy;
  }

  /// Closes out one checkout, running any teardown [dispose] had to defer.
  void _settleCheckout() {
    _checkoutOpen = false;
    if (_disposeRequested) {
      _disposeRequested = false;
      _razorpay.clear();
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment Success: ${response.paymentId}");
    // Before the callback: an exception thrown inside it must not be mistaken
    // for a failure to open, and dispose must be free to run afterwards.
    _settleCheckout();
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
    _settleCheckout();
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
      case CHECKOUT_OPEN_FAILED:
        // Nothing was charged and no sheet was ever shown, so "couldn't be
        // completed" would be misleading — this failed before it started.
        return AppStrings.couldNotStartPayment.tr;
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
    _settleCheckout();
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    } else {
      commonSnackBar(message: 'Wallet selected: ${response.walletName}');
    }
  }

  /// Drops the payment listeners.
  ///
  /// Deferred while a checkout is outstanding: `clear()` removes the handlers
  /// the result is about to be delivered to, so disposing mid-payment (the
  /// controller being closed while the sheet is up, which GetX will do when
  /// the hosting route goes) silently loses a payment the user has already
  /// made. The teardown then runs from [_settleCheckout] instead.
  void dispose() {
    if (_checkoutOpen) {
      _disposeRequested = true;
      return;
    }
    _razorpay.clear();
  }
}
