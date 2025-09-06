import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer';

class LocationPermissionHandler {

  /// Request location permission first (GPS service check happens later)
  static Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      // Step 1: Check current permission status FIRST
      PermissionStatus permission = await Permission.location.status;
      log("Current location permission status: $permission");

      // Step 2: Handle different permission states
      switch (permission) {
        case PermissionStatus.granted:
          return LocationPermissionResult(
              isGranted: true,
              message: 'Location permission granted'
          );

        case PermissionStatus.denied:
        // Request permission
          permission = await Permission.location.request();
          return _handlePermissionResult(permission);

        case PermissionStatus.permanentlyDenied:
          return LocationPermissionResult(
            isGranted: false,
            message: 'Location permission permanently denied. Please grant it in app settings.',
            shouldOpenSettings: true,
          );

        case PermissionStatus.restricted:
          return LocationPermissionResult(
            isGranted: false,
            message: 'Location permission is restricted on this device.',
          );

        default:
          return LocationPermissionResult(
            isGranted: false,
            message: 'Unknown permission status.',
          );
      }
    } catch (e) {
      log("Error requesting location permission: $e");
      return LocationPermissionResult(
        isGranted: false,
        message: 'Error requesting location permission: $e',
      );
    }
  }

  /// Handle the result of permission request
  static LocationPermissionResult _handlePermissionResult(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return LocationPermissionResult(
            isGranted: true,
            message: 'Location permission granted'
        );
      case PermissionStatus.denied:
        return LocationPermissionResult(
          isGranted: false,
          message: 'Location permission denied',
        );
      case PermissionStatus.permanentlyDenied:
        return LocationPermissionResult(
          isGranted: false,
          message: 'Location permission permanently denied. Please grant it in app settings.',
          shouldOpenSettings: true,
        );
      default:
        return LocationPermissionResult(
          isGranted: false,
          message: 'Permission request failed',
        );
    }
  }

  /// Check if location services are enabled (call this only when getting location)
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      log("Error checking location service: $e");
      return false;
    }
  }

  /// Get current location with proper error handling
  /// This method checks both permission AND GPS service
  // static Future<LocationResult> getCurrentLocation() async {
  //   try {
  //     // 1. permission ----------------------------------------------------------
  //     final permissionResult = await requestLocationPermission();
  //     if (!permissionResult.isGranted) {
  //       return LocationResult(
  //         position: null,
  //         isSuccess: false,
  //         message: permissionResult.message,
  //         shouldOpenSettings: permissionResult.shouldOpenSettings,
  //         errorType: LocationErrorType.permissionDenied,
  //       );
  //     }
  //
  //     // 2. let the Fused Provider ask for GPS if it is off ----------------------
  //     try {
  //       final position = await Geolocator.getCurrentPosition(
  //         locationSettings: const LocationSettings(
  //           accuracy: LocationAccuracy.high,
  //           timeLimit: Duration(seconds: 10),
  //         ),
  //       );
  //
  //       return LocationResult(
  //         position: position,
  //         isSuccess: true,
  //         message: 'Location retrieved successfully',
  //         errorType: LocationErrorType.none,
  //       );
  //     } on LocationServiceDisabledException {
  //       // user pressed “No thanks” in the system dialog
  //       return LocationResult(
  //         position: null,
  //         isSuccess: false,
  //         message: 'Location services are disabled. Please enable GPS in device settings.',
  //         shouldOpenSettings: true,
  //         errorType: LocationErrorType.serviceDisabled,
  //       );
  //     }
  //   } catch (e) {
  //     log("Error getting current location: $e");
  //     return LocationResult(
  //       position: null,
  //       isSuccess: false,
  //       message: 'Failed to get location: $e',
  //       errorType: LocationErrorType.unknown,
  //     );
  //   }
  // }

  static Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Permission check
      final permissionResult = await requestLocationPermission();
      if (!permissionResult.isGranted) {
        return LocationResult(
          position: null,
          isSuccess: false,
          message: permissionResult.message,
          shouldOpenSettings: permissionResult.shouldOpenSettings,
          errorType: LocationErrorType.permissionDenied,
        );
      }

      // 2. Try to get location (triggers system dialog if GPS off)
      try {
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
        // User pressed "No thanks" in system dialog → open settings manually
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(milliseconds: 800)); // Wait for user

        // 3. Retry once after user comes back
        final serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          return LocationResult(
            position: null,
            isSuccess: false,
            message: 'Location services still disabled. Please enable GPS.',
            shouldOpenSettings: true,
            errorType: LocationErrorType.serviceDisabled,
          );
        }

        // Retry location fetch
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
      }
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

  /// Open app settings for manual permission grant
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      log("Error opening app settings: $e");
    }
  }

  /// Open device location settings
  static Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      log("Error opening location settings: $e");
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

/// Different types of location errors
enum LocationErrorType {
  none,
  permissionDenied,
  serviceDisabled,
  timeout,
  unknown,
}
