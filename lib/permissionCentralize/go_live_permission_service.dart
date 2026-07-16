import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Identifies the discrete permissions required to start a "Go Live" session.
enum GoLivePermissionType {
  backgroundLocation,
  batteryOptimization,
  displayOverOtherApps,
}

/// Service that checks & requests the permissions required for the
/// Discover screen "Go Live" feature (Rapido captain style).
class GoLivePermissionService {
  /// Returns the live grant status of every Go Live permission.
  static Future<Map<GoLivePermissionType, bool>> checkAll() async {
    final results = <GoLivePermissionType, bool>{};
    results[GoLivePermissionType.backgroundLocation] =
        await isBackgroundLocationGranted();
    results[GoLivePermissionType.batteryOptimization] =
        await isBatteryOptimizationDisabled();
    results[GoLivePermissionType.displayOverOtherApps] =
        await isDisplayOverOtherAppsGranted();
    return results;
  }

  /// Convenience: returns true only when ALL Go Live permissions are granted.
  static Future<bool> areAllGranted() async {
    final map = await checkAll();
    return map.values.every((granted) => granted);
  }

  /// The permissions that MUST be granted before going live.
  ///
  /// Battery optimization is intentionally EXCLUDED. Its check relies on
  /// [Permission.ignoreBatteryOptimizations] → `isIgnoringBatteryOptimizations()`,
  /// which only reflects the Doze whitelist. On Android 13+/16 the toggle users
  /// actually reach (App info → Battery → "Unrestricted") is a different setting
  /// and does NOT flip that flag, so gating on it leaves the go-live permission
  /// screen re-appearing forever even after the user "granted" everything.
  /// It stays visible in the UI as an optional nudge, just not a hard blocker.
  static Future<bool> areRequiredGranted() async {
    final bgLocation = await isBackgroundLocationGranted();
    final overlay = await isDisplayOverOtherAppsGranted();
    return bgLocation && overlay;
  }

  // ---------------- BACKGROUND LOCATION ----------------
  static Future<bool> isBackgroundLocationGranted() async {
    try {
      final whileInUse = await Permission.location.status;
      if (!whileInUse.isGranted) return false;
      if (Platform.isIOS) return whileInUse.isGranted;
      final always = await Permission.locationAlways.status;
      return always.isGranted;
    } catch (e) {
      log('isBackgroundLocationGranted error: $e');
      return false;
    }
  }

  static Future<bool> requestBackgroundLocation() async {
    try {
      // Foreground location is a prerequisite for background/always.
      var foreground = await Permission.location.status;
      if (!foreground.isGranted) {
        foreground = await Permission.location.request();
      }
      if (!foreground.isGranted) {
        if (foreground.isPermanentlyDenied) await openAppSettings();
        return false;
      }

      // Make sure GPS itself is enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        if (!await Geolocator.isLocationServiceEnabled()) return false;
      }

      if (Platform.isIOS) return foreground.isGranted;

      var always = await Permission.locationAlways.status;
      if (!always.isGranted) {
        always = await Permission.locationAlways.request();
      }
      if (!always.isGranted && always.isPermanentlyDenied) {
        await openAppSettings();
      }
      return always.isGranted;
    } catch (e) {
      log('requestBackgroundLocation error: $e');
      return false;
    }
  }

  // ---------------- BATTERY OPTIMIZATION ----------------

  /// Android API level at (and above) which the battery-optimization card is
  /// HIDDEN. On Android 13+ (API 33) the user-facing "Unrestricted" toggle
  /// (App info → Battery) does NOT flip the `isIgnoringBatteryOptimizations`
  /// flag we can read, so the card could never show as granted and only
  /// confuses the user — so we don't display or ask for it there.
  static const int _batteryOptHiddenFromSdk = 33;

  static int? _cachedSdkInt;
  static Future<int> _androidSdkInt() async {
    if (_cachedSdkInt != null) return _cachedSdkInt!;
    final info = await DeviceInfoPlugin().androidInfo;
    return _cachedSdkInt = info.version.sdkInt;
  }

  /// Whether the battery-optimization permission should be shown / asked for on
  /// THIS device. False on iOS (no such concept) and on Android 13+ (API 33+),
  /// where its status can't be reliably reflected. Only Android ≤ 32 gets it.
  static Future<bool> isBatteryOptimizationRelevant() async {
    if (!Platform.isAndroid) return false;
    try {
      return (await _androidSdkInt()) < _batteryOptHiddenFromSdk;
    } catch (e) {
      log('isBatteryOptimizationRelevant error: $e');
      return false;
    }
  }

  static Future<bool> isBatteryOptimizationDisabled() async {
    try {
      // iOS does not expose this; treat as granted.
      if (!Platform.isAndroid) return true;
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      log('isBatteryOptimizationDisabled error: $e');
      return false;
    }
  }

  static Future<bool> requestBatteryOptimization() async {
    try {
      if (!Platform.isAndroid) return true;
      var status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        status = await Permission.ignoreBatteryOptimizations.request();
      }
      if (!status.isGranted && status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return status.isGranted;
    } catch (e) {
      log('requestBatteryOptimization error: $e');
      return false;
    }
  }

  // ---------------- DISPLAY OVER OTHER APPS ----------------
  static Future<bool> isDisplayOverOtherAppsGranted() async {
    try {
      // iOS has no equivalent; treat as granted so the flow can complete.
      if (!Platform.isAndroid) return true;
      final status = await Permission.systemAlertWindow.status;
      return status.isGranted;
    } catch (e) {
      log('isDisplayOverOtherAppsGranted error: $e');
      return false;
    }
  }

  static Future<bool> requestDisplayOverOtherApps() async {
    try {
      if (!Platform.isAndroid) return true;
      var status = await Permission.systemAlertWindow.status;
      if (!status.isGranted) {
        status = await Permission.systemAlertWindow.request();
      }
      return status.isGranted;
    } catch (e) {
      log('requestDisplayOverOtherApps error: $e');
      return false;
    }
  }
}
