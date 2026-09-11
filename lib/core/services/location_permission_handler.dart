import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Resolves the device position, reporting WHY it could not when it fails.
///
/// Deliberately UI-free. It used to throw a non-dismissible dialog of its own
/// and to fling the user at the system Location settings unannounced, which is
/// how people ended up stuck on a screen with no way back and no idea what was
/// being asked of them. Explaining the failure is the caller's job now — see
/// `showLocationHelpSheet` / `resolveLocationWithGuidance` in
/// `lib/widgets/location_help_sheet.dart` — and this only reports facts.
class LocationPermissionHandler {
  /// Check if location services are enabled (call this only when getting location)
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      log("Error checking location service: $e");
      return false;
    }
  }

  Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. The device-level master switch. Nothing below can succeed while it
      //    is off, and the app permission prompt does NOT turn it on — so it
      //    has to be reported as its own thing, with its own instructions.
      if (!await isLocationServiceEnabled()) {
        return LocationResult(
          position: null,
          isSuccess: false,
          message: 'Location services are turned off on this device.',
          shouldOpenSettings: true,
          errorType: LocationErrorType.serviceDisabled,
        );
      }

      // 2. The app permission.
      //
      //    The status AFTER the request is the one that decides. Reading the
      //    one from BEFORE it — what this used to do — meant a user who had
      //    just tapped Allow was still treated as denied and shown the "no
      //    location" dialog, which was un-dismissible and had a single button
      //    into the settings screen. That is the "I granted it and got stuck"
      //    report this rewrite is for.
      //
      //    `request()` is also a no-op once the OS has recorded a permanent
      //    denial (two refusals on Android, one on iOS): it returns straight
      //    back as permanentlyDenied with no prompt shown, and only the app's
      //    settings page can undo it.
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        return LocationResult(
          position: null,
          isSuccess: false,
          message: 'Location permission is blocked for this app.',
          shouldOpenSettings: true,
          errorType: LocationErrorType.permissionPermanentlyDenied,
        );
      }

      // `limited` is iOS's "approximate location", which is plenty for a
      // pincode and an address line, so it counts as granted here.
      if (!status.isGranted && !status.isLimited) {
        return LocationResult(
          position: null,
          isSuccess: false,
          message: 'Location permission was not granted.',
          errorType: LocationErrorType.permissionDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(
        position: position,
        isSuccess: true,
        message: 'Location retrieved successfully',
        errorType: LocationErrorType.none,
      );
    } on LocationServiceDisabledException {
      // Switched off between the check above and the fix itself.
      return LocationResult(
        position: null,
        isSuccess: false,
        message: 'Location services are turned off on this device.',
        shouldOpenSettings: true,
        errorType: LocationErrorType.serviceDisabled,
      );
    } on TimeoutException {
      // Permission and GPS are both fine — the radio just couldn't get a fix
      // inside the limit. Indoors, a tunnel, a cold start on a weak signal.
      return LocationResult(
        position: null,
        isSuccess: false,
        message: 'Timed out waiting for a location fix.',
        errorType: LocationErrorType.timeout,
      );
    } catch (e) {
      log("Error getting current location: $e");
      return LocationResult(
        position: null,
        isSuccess: false,
        message: 'Failed to get location: $e',
        errorType: LocationErrorType.unknown,
      );
    }
  }

  /// Check if we have permission to access location
  static Future<bool> hasLocationPermission() async {
    try {
      PermissionStatus permission = await Permission.location.status;
      return permission == PermissionStatus.granted;
    } catch (e) {
      log("Error checking location permission: $e");
      return false;
    }
  }
}

/// Result class for location permission operations
class LocationPermissionResult {
  final bool isGranted;
  final String message;
  final bool shouldOpenSettings;

  LocationPermissionResult({
    required this.isGranted,
    required this.message,
    this.shouldOpenSettings = false,
  });
}

/// Enhanced result class for location operations
class LocationResult {
  final Position? position;
  final bool isSuccess;
  final String message;
  final bool shouldOpenSettings;
  final LocationErrorType errorType;

  LocationResult({
    this.position,
    required this.isSuccess,
    required this.message,
    this.shouldOpenSettings = false,
    required this.errorType,
  });
}

/// Different types of location errors.
///
/// The three permission/service cases are kept apart because the fix for each
/// is somewhere different: a system prompt, the app's own settings page, or
/// the device Location toggle. Telling a user to "enable location permission"
/// when what's actually off is the GPS master switch sends them hunting in the
/// wrong screen.
enum LocationErrorType {
  none,

  /// Refused this time, but the OS will still show the prompt again.
  permissionDenied,

  /// Refused for good — only the app's settings page can turn it back on.
  permissionPermanentlyDenied,

  /// Device-level location services are off.
  serviceDisabled,

  /// Position obtained, but it could not be turned into an address.
  addressLookupFailed,

  timeout,
  unknown,
}
