import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static double lat = 0.0;
  static double lng = 0.0;
  static List<String> userCurrentAddress = [];
  static bool isLoading = false;

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   if (state == AppLifecycleState.resumed) {
  //     if (await Permission.location.isGranted) {
  //       await fetchLocation(NavigatorService.context);
  //     }
  //   }
  //   super.didChangeAppLifecycleState(state);
  // }

  /// 🌍 Fetches current location and address
  static Future<Map<String, dynamic>?> fetchLocation({
    bool isPermissionRequired = false,
  }) async {
    try {
      isLoading = true;

      // Step 1: Check location permission
      PermissionStatus permission = await Permission.location.status;

      if (permission.isPermanentlyDenied) {
        await _showPermissionDialog(
          title: 'Location Permission Denied',
          message:
          'Location access is permanently denied. Please enable it manually from settings.',
          openAppSettingsOnConfirm: true,
          isPermissionRequired: isPermissionRequired,
        );
        return null;
      }

      if (permission.isDenied || permission.isRestricted) {
        final result = await Permission.location.request();
        if (result.isDenied || result.isRestricted || result.isPermanentlyDenied) {
          await _showPermissionDialog(
            title: 'Location Access Needed',
            message:
            'This app requires location access to function properly. Please grant permission.',
            isPermissionRequired: isPermissionRequired,
          );
          return null;
        }
      }

      // Step 2: Check GPS / location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show dialog with only OK button
        await _showPermissionDialog(
          title: 'Enable Location Services',
          message:
          'Your device\'s location services are turned off. Please enable GPS to continue.',
          openLocationSettingsOnConfirm: true,
          isPermissionRequired: isPermissionRequired,
        );

        // Wait until user turns on location
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null; // User still did not enable
      }

      // Step 3: Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      lat = position.latitude;
      lng = position.longitude;

      // Step 4: Get address
      final placeMarks = await placemarkFromCoordinates(lat, lng);
      if (placeMarks.isNotEmpty) {
        final place = placeMarks.first;
        userCurrentAddress = _composeAddress(
          thoroughfare: place.thoroughfare,
          subLocality: place.subLocality,
          locality: place.locality,
          administrativeArea: place.administrativeArea,
          country: place.country,
          postalCode: place.postalCode,
        );

        if (userCurrentAddress.isEmpty) {
          userCurrentAddress = [
            place.subLocality ?? '',
            place.locality ?? '',
            place.administrativeArea ?? '',
            place.country ?? '',
          ];
        }
      } else {
        userCurrentAddress = [];
      }

      log("userCurrentAddress=== $userCurrentAddress");

      return {
        "position": position,
        "address": userCurrentAddress,
      };
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    } finally {
      isLoading = false;
    }
  }

  /// 📌 Get formatted address parts as a list
  static List<String> _composeAddress(
      {String? thoroughfare,
      String? subLocality,
      String? locality,
      String? administrativeArea,
      String? country,
      String? postalCode}) {
    final List<String> parts = [];

    if (thoroughfare?.isNotEmpty ?? false) {
      parts.add(thoroughfare!);
    }
    if (subLocality?.isNotEmpty ?? false) {
      parts.add(subLocality!);
    }
    if (locality?.isNotEmpty ?? false) {
      parts.add(locality!);
    }
    if (administrativeArea?.isNotEmpty ?? false) {
      parts.add(administrativeArea!);
    }
    if (country?.isNotEmpty ?? false) {
      parts.add(country!);
    }
    if (postalCode?.isNotEmpty ?? false) {
      parts.add(postalCode!);
    }

    return parts;
  }

  /// Helper: Show a permission alert dialog with optional settings redirection
  static Future<void> _showPermissionDialog({
    required String title,
    required String message,
    required bool isPermissionRequired,
    bool openAppSettingsOnConfirm = false,
    bool openLocationSettingsOnConfirm = false,
    String confirmText = "OK",
  }) async {
    return Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        title: CustomText(
          title,
          color: AppColors.black28,
          fontWeight: FontWeight.w700,
        ),
        content: CustomText(
          message,
          color: AppColors.black28,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Get.back(); // close the dialog first
              // Perform the required action after closing dialog
              if (openAppSettingsOnConfirm) {
                await openAppSettings();
              } else if (openLocationSettingsOnConfirm) {
                await Geolocator.openLocationSettings();
              }
            },
            child: CustomText(
              confirmText,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Only show cancel button if permission is NOT mandatory
          if (!isPermissionRequired)
            TextButton(
              onPressed: () => Get.back(),
              child: CustomText(
                "Cancel",
                color: AppColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Position? _lastPosition;

  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    Position current = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Check if location has changed
    if (_lastPosition == null /*||
        _hasLocationChanged(_lastPosition!, current)*/) {
      _lastPosition = current;
      return current;
    }
    return null; // same location → no need to update
  }

  static bool _hasLocationChanged(Position oldPos, Position newPos) {
    logs("oldPos= ${oldPos.latitude},${oldPos.longitude} NEW === ${newPos.latitude},${newPos.longitude}");
    const double threshold = 0.0001; // ~10m difference
    return (oldPos.latitude - newPos.latitude).abs() > threshold ||
        (oldPos.longitude - newPos.longitude).abs() > threshold;
  }

}
