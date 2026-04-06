import 'dart:developer';
import 'dart:io';

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
