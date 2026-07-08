import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// On-device AdMob diagnostics.
///
/// [openInspector] launches Google's **Ad Inspector** — a full-screen overlay
/// that shows, per ad request, exactly why a slot did/didn't fill (e.g.
/// "app-ads.txt not found", "No fill", "app not approved", per-adapter status).
/// Use it to stop guessing at 403 / error-3 problems.
///
/// Ad Inspector is only available on **registered test devices**. Add your
/// device's hash to [testDeviceIds] (printed in logcat on the first ad request:
/// `Use RequestConfiguration.Builder.setTestDeviceIds(Arrays.asList("XXXX"))`)
/// so [applyTestDevices] registers it at SDK init.
class AdDebug {
  AdDebug._();

  /// Device hashes registered as AdMob test devices. Paste yours from the
  /// logcat "setTestDeviceIds" line so Ad Inspector will open on this device.
  static const List<String> testDeviceIds = <String>[
    '37FF1C2B20D994B2FEA90EE28F577FC6',
  ];

  /// Register [testDeviceIds] with the Mobile Ads SDK. Safe to call after
  /// `MobileAds.instance.initialize()`; a no-op when the list is empty.
  static void applyTestDevices() {
    if (testDeviceIds.isEmpty) return;
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: testDeviceIds),
    );
  }

  /// Launch the Ad Inspector overlay. Surfaces any launch error (e.g. "device
  /// not registered as a test device") as a snackbar. [openAdInspector] returns
  /// void (the result comes via the callback), so it's called, not awaited.
  static void openInspector() {
    try {
      MobileAds.instance.openAdInspector((error) {
        if (error != null) {
          commonSnackBar(
              message: 'Ad Inspector: ${error.message} '
                  '(register this device as a test device — see AdDebug)');
        }
      });
    } catch (e) {
      commonSnackBar(message: 'Ad Inspector failed: $e');
    }
  }
}
