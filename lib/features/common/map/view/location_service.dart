
import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
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
  static Future<Map<String, dynamic>?> fetchLocation(BuildContext context, {bool isPermissionRequired = false}) async {
    try {
      isLoading = true;

      // Step 1: Check if location permission is granted
      PermissionStatus permission = await Permission.location.status;
      log("Initial location permission: $permission");

      if (permission.isPermanentlyDenied) {
        _showPermissionDialog(
          title: 'Location Permission Denied',
          message: 'Location access is permanently denied. Please enable it manually from the app settings.',
          openAppSettingsOnConfirm: true,
          isPermissionRequired: isPermissionRequired
        );
        return null;
      }

      if (permission.isDenied || permission.isRestricted) {
        final result = await Permission.location.request();
        log("Requested location permission result: $result");

        if (result.isPermanentlyDenied) {
          _showPermissionDialog(
            title: 'Location Permission Denied',
            message: 'Location access is permanently denied. Please enable it manually from the app settings.',
            openAppSettingsOnConfirm: true,
            isPermissionRequired: isPermissionRequired
          );
          return null;
        }

        if (result.isDenied || result.isRestricted) {
          _showPermissionDialog(
            title: 'Location Access Needed',
            message: 'This app requires location access to function properly. Please grant permission.',
            isPermissionRequired: isPermissionRequired
          );
          return null;
        }
      }

      // Step 2: Check if GPS/location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      log("Is location service enabled: $serviceEnabled");

      if (!serviceEnabled) {
        _showPermissionDialog(
          title: 'Enable Location Services',
          message: 'Your device\'s location services are turned off. Please enable GPS to continue.',
          openLocationSettingsOnConfirm: true,
          isPermissionRequired: isPermissionRequired
        );
        return null;
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
        log("place: $place");

        userCurrentAddress = _composeAddress(
          subLocality: place.subLocality,
          locality: place.locality,
          administrativeArea: place.administrativeArea,
          country: place.country
        );

        if (userCurrentAddress.isEmpty) {
          userCurrentAddress = [
            place.subLocality??'',
            place.locality??'',
            place.administrativeArea??'',
            place.country??'',
          ];;
        }
      } else {
        userCurrentAddress = [];
      }

      return {
        "position": position,
        "address": userCurrentAddress,
      };
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      isLoading = false;
    }
    return null;
  }

  /// 📌 Get formatted address parts as a list
  static List<String> _composeAddress({
    String? subLocality,
    String? locality,
    String? administrativeArea,
    String? country
  }) {
    final List<String> parts = [];

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

    return parts;
  }


  /// Helper: Show a permission alert dialog with optional settings redirection
  static Future<void> _showPermissionDialog({
    required String title,
    required String message,
    required bool isPermissionRequired,
    bool openAppSettingsOnConfirm = false,
    bool openLocationSettingsOnConfirm = false,
    String confirmText = "Open Settings",
    String cancelText = "Cancel",
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
              Future.microtask(() async {
                if (openAppSettingsOnConfirm) {
                  await openAppSettings();
                } else if (openLocationSettingsOnConfirm) {
                  await Geolocator.openLocationSettings();
                }
              });
            },
            child: CustomText(
              confirmText,
              color: AppColors.primaryColor,
            ),
          ),

          if(!isPermissionRequired)
          TextButton(
            onPressed: () => Get.back(), // cancel closes the popup
            child: CustomText(
              cancelText,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }


}
