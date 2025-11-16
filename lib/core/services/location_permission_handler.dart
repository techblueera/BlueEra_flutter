import 'dart:developer';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

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

  noLocationPermissionDialogBox() async {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent closing with back button
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // 👈 Border radius here
          ),
          backgroundColor: Colors.white,
          title: CustomText(
            "Current Location Unavailable",
            fontSize: 16,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w600,
          ),
          content: SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  "Blue Era needs your location while using the app to provide accurate nearby services and improve your experience.",
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 10,
                ),
                PositiveCustomBtn(
                  onTap: () async {
                    await openAppSettings();
                    Get.back(); // Close dialog after navigating to settings
                  },
                  title: "Change Location Settings",
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<LocationResult> getCurrentLocation() async {
    try {
      try {
        var location = await Permission.location.status;
        logs("location==== 1 ${location}");
        if ((location == PermissionStatus.permanentlyDenied) ||
            (location == PermissionStatus.denied)) {
          var locationStatus = await Permission.location.request();
          logs("location==== 2 ${locationStatus}");

          if ((location == PermissionStatus.permanentlyDenied) ||
              (location == PermissionStatus.denied)) {
            await noLocationPermissionDialogBox();
          }
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
        // User pressed "No thanks" in system dialog → open settings manually
        // await Geolocator.openLocationSettings();
        await openAppSettings();

        await Future.delayed(
            const Duration(milliseconds: 800)); // Wait for user

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
