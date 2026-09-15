import 'dart:io';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:permission_handler/permission_handler.dart';

class AppServices {

  // AGORA
  static const String agoraAppId = '381854d62adf4168afb825420f52539d'; // development
  // static const String agoraAppId = ''; // production (// todo : add)
  //App signature

  //One Signal app id
  static const String oneSignalAppId = '0f8a3218-2a6a-4811-b352-cb1c8c2b58d7';

  /// Requests the runtime permissions the app needs up front.
  ///
  /// Called from `main.dart`, CHAINED behind the location fetch and the
  /// notification request rather than fired alongside them: Android shows one
  /// system dialog at a time and silently drops any that arrive while another
  /// is up, so overlapping requests lose grants. Each request below is likewise
  /// awaited in turn for the same reason.
  ///
  /// Already-granted permissions are never re-requested, so this is a cheap
  /// no-op on every launch after the first.
  ///
  /// Deliberately NOT requested here:
  ///
  /// * `Permission.systemAlertWindow` — a special permission. Requesting it
  ///   does not show a dialog; it throws the user out of the app into the
  ///   "Display over other apps" Settings screen, which on first launch reads
  ///   as the app crashing. It is already requested in context, at the point
  ///   the feature needs it, by `OverlayService.requestPermission()` (call
  ///   overlay) and `GoLivePermissionService` (Go Live).
  ///
  /// * `Permission.audio` — maps to `READ_MEDIA_AUDIO` on Android 13+, which
  ///   AndroidManifest.xml deliberately does not declare (see the Play policy
  ///   note there). An undeclared permission resolves to permanently-denied
  ///   without ever prompting, so requesting it achieves nothing.
  static Future<void> permissionHandler() async {
    if (!Platform.isAndroid) return;
    await _requestIfNotGranted(Permission.notification);
    await _requestIfNotGranted(Permission.camera);
    await _requestIfNotGranted(Permission.microphone);
  }

  static Future<void> _requestIfNotGranted(Permission permission) async {
    try {
      final status = await permission.status;
      // Only `denied` is actionable. A permanently-denied permission re-prompts
      // into nothing on Android, and asking again on every launch is the
      // "settings nag on boot" the notification flow already avoids.
      if (status.isDenied) {
        await permission.request();
      }
    } catch (e) {
      // A failed permission request must never take startup down with it.
      logs('permission request failed for $permission: $e');
    }
  }

}
