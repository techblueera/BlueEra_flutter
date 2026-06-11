import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// UPI apps we can deep-link into. [anyUpi] uses the generic `upi://` scheme,
/// which makes Android show its *system chooser* listing every installed UPI
/// app (Google Pay, PhonePe, Paytm, BHIM, …).
enum UpiApp { phonePe, googlePay, paytm, bhim, anyUpi }

/// Outcome of *launching* a UPI app.
///
/// IMPORTANT: `url_launcher` can only tell us whether the app opened — it does
/// NOT report the transaction result. UPI apps return success/failure/cancel
/// via Android's `onActivityResult`, which this plugin discards. So after a
/// [launched] result you should ask the user to confirm the payment (see
/// [UpiPaymentService.payWithPhonePeOrChooser] usage), or switch to a
/// native-result package (`upi_pay` / `upi_india`, both Android-only) if you
/// need the real status programmatically.
enum UpiLaunchResult {
  /// The app (or chooser) was opened successfully.
  launched,

  /// The requested app is not installed on the device.
  appNotInstalled,

  /// Something went wrong while trying to launch.
  failed,
}

/// Reusable, UI-free service to start a UPI payment by deep-linking into a
/// specific app or the system UPI chooser.
///
/// Example:
/// ```dart
/// final result = await UpiPaymentService.instance.payWithPhonePeOrChooser(
///   payeeVpa: 'merchant@upi',
///   payeeName: 'My Business',
///   amount: '100.00',
///   transactionNote: 'Payment',
/// );
/// ```
class UpiPaymentService {
  UpiPaymentService._();

  static final UpiPaymentService instance = UpiPaymentService._();

  /// Base deep-link for each supported app. These schemes must also be
  /// declared so the OS lets us see/open them:
  ///  - Android 11+: `<queries>` in AndroidManifest.xml
  ///  - iOS: `LSApplicationQueriesSchemes` in Info.plist
  static const Map<UpiApp, String> _deepLinks = {
    UpiApp.phonePe: 'phonepe://pay',
    UpiApp.googlePay: 'tez://upi/pay',
    UpiApp.paytm: 'paytmmp://pay',
    UpiApp.bhim: 'upi://pay',
    UpiApp.anyUpi: 'upi://pay',
  };

  /// Builds a spec-compliant UPI intent URI with the standard query params.
  /// See https://developers.google.com/pay/india/api/web/create-payment-links
  Uri _buildUri({
    required String base,
    required String payeeVpa,
    required String payeeName,
    String? amount,
    required String transactionNote,
    String currency = 'INR',
    String? transactionRef,
  }) {
    return Uri.parse(base).replace(queryParameters: {
      'pa': payeeVpa, // payee address (UPI ID)
      'pn': payeeName, // payee name
      // Omit `am` entirely when no amount is given so the UPI app lands on its
      // amount-entry screen instead of prefilling 0.
      if (amount != null && amount.isNotEmpty) 'am': amount,
      'cu': currency, // currency, always INR for UPI
      'tn': transactionNote, // transaction note
      if (transactionRef != null && transactionRef.isNotEmpty)
        'tr': transactionRef, // optional merchant transaction reference
    });
  }

  /// Whether [app] appears to be installed (its scheme can be launched).
  /// Requires the scheme to be declared (see [_deepLinks]) or this always
  /// returns false on Android 11+/iOS.
  Future<bool> isInstalled(UpiApp app) async {
    try {
      return await canLaunchUrl(Uri.parse(_deepLinks[app]!));
    } catch (_) {
      return false;
    }
  }

  /// Opens [app] (or the chooser for [UpiApp.anyUpi]) prefilled with the
  /// payment details. Returns how the launch went.
  Future<UpiLaunchResult> pay({
    required UpiApp app,
    required String payeeVpa,
    required String payeeName,
    String? amount,
    String transactionNote = 'Payment',
    String currency = 'INR',
    String? transactionRef,
  }) async {
    final uri = _buildUri(
      base: _deepLinks[app]!,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
      currency: currency,
      transactionRef: transactionRef,
    );

    try {
      // For a *specific* app, bail out early when it isn't installed so the
      // caller can fall back. For the generic chooser we always try to launch.
      if (app != UpiApp.anyUpi && !await canLaunchUrl(uri)) {
        return UpiLaunchResult.appNotInstalled;
      }
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      return launched
          ? UpiLaunchResult.launched
          : UpiLaunchResult.appNotInstalled;
    } catch (e) {
      debugPrint('UpiPaymentService.pay($app) error: $e');
      return UpiLaunchResult.failed;
    }
  }

  /// Opens PhonePe directly when it is installed, otherwise falls back to the
  /// system UPI chooser (Google Pay, Paytm, BHIM, …) via the generic `upi://`
  /// intent.
  Future<UpiLaunchResult> payWithPhonePeOrChooser({
    required String payeeVpa,
    required String payeeName,
    String? amount,
    String transactionNote = 'Payment',
    String currency = 'INR',
    String? transactionRef,
  }) async {
    final phonePe = await pay(
      app: UpiApp.phonePe,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
      currency: currency,
      transactionRef: transactionRef,
    );
    if (phonePe != UpiLaunchResult.appNotInstalled) return phonePe;

    // PhonePe missing → show every installed UPI app via the chooser.
    return pay(
      app: UpiApp.anyUpi,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
      currency: currency,
      transactionRef: transactionRef,
    );
  }
}
