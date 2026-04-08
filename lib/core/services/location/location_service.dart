import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/location/user_address.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService extends GetxService {
  static double lat = 0.0;
  static double lng = 0.0;
  static Rx<UserAddress> userCurrentAddress = UserAddress().obs;
  // static RxList<String> userCurrentAddress = <String>[].obs;
  static bool isLoading = false;

  Future<bool> isLocationAvailable() async {
    final permission = await Permission.location.status;
    final gps = await Geolocator.isLocationServiceEnabled();
    return permission.isGranted && gps;
  }

  static Future<String> getAddressUsingLatLng({required double latitude,required double longitude})async{
    final placeMarks = await placemarkFromCoordinates(latitude, longitude);

    if (placeMarks.isNotEmpty) {
      final place = placeMarks.first;
      // log('place -- $place');

      userCurrentAddress.value = UserAddress(
        street: place.thoroughfare ?? '',
        subLocality: place.subLocality ?? '',
        city: place.locality ?? '',
        state: place.administrativeArea ?? '',
        country: place.country ?? '',
        postalCode: place.postalCode ?? '',
      );
      return "${place.thoroughfare ?? ''}${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''} ,${place.postalCode}";
    } else {
      return AppStrings.addressNotFound.tr;
    }

  }

  /// 🌍 Fetches current location and address
  static Future<Map<String, dynamic>?> fetchLocation({
    bool openSettingsOnDeny = false,
  }) async {
    try {
      isLoading = true;

      // Step 1: Check location permission
      PermissionStatus permission = await Permission.location.status;

      // Permanently denied
      if (permission.isPermanentlyDenied) {
        if (openSettingsOnDeny) {
          await openAppSettings();

          log('called check');
        }
        return null;
      }

      // Permission denied or restricted
      if (permission.isDenied || permission.isRestricted) {
        final result = await Permission.location.request();

        if (result.isDenied || result.isRestricted || result.isPermanentlyDenied) {
          if (openSettingsOnDeny) {
            await openAppSettings();
          }
          return null;
        }
      }

      // Step 2: GPS disabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (openSettingsOnDeny) {
          await Geolocator.openLocationSettings();
        }

        // re-check
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null;
      }

      // Step 3: Get location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      lat = position.latitude;
      lng = position.longitude;
      log('lat--> $lat, lng--> $lng');

      // Step 4: Get address
      final placeMarks = await placemarkFromCoordinates(lat, lng);

      if (placeMarks.isNotEmpty) {
        final place = placeMarks.first;
        // log('place--> $place');

        userCurrentAddress.value = UserAddress(
          street: place.thoroughfare ?? '',
          subLocality: place.subLocality ?? '',
          city: place.locality ?? '',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
          postalCode: place.postalCode ?? '',
        );
      } else {
        // Reset to empty if not found
        userCurrentAddress.value = UserAddress();
      }

      return {
        "position": position,
        "address": userCurrentAddress.value,
      };
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    } finally {
      isLoading = false;
    }
  }


  /// 📌 Get formatted address parts as a list
  // static List<String> _composeAddress(
  //     {String? thoroughfare,
  //     String? subLocality,
  //     String? locality,
  //     String? administrativeArea,
  //     String? country,
  //     String? postalCode}) {
  //   final List<String> parts = [];
  //
  //   if (thoroughfare?.isNotEmpty ?? false) {
  //     parts.add(thoroughfare!);
  //   }
  //   if (subLocality?.isNotEmpty ?? false) {
  //     parts.add(subLocality!);
  //   }
  //   if (locality?.isNotEmpty ?? false) {
  //     parts.add(locality!);
  //   }
  //   if (administrativeArea?.isNotEmpty ?? false) {
  //     parts.add(administrativeArea!);
  //   }
  //   if (country?.isNotEmpty ?? false) {
  //     parts.add(country!);
  //   }
  //   if (postalCode?.isNotEmpty ?? false) {
  //     parts.add(postalCode!);
  //   }
  //
  //   return parts;
  // }

  /// Helper: Show a permission alert dialog with optional settings redirection
  // static Future<void> _showPermissionDialog({
  //   required String title,
  //   required String message,
  //   bool openAppSettingsOnConfirm = false,
  //   bool openLocationSettingsOnConfirm = false,
  //   String confirmText = "OK",
  // }) async {
  //   return Get.dialog(
  //     AlertDialog(
  //       backgroundColor: AppColors.white,
  //       title: CustomText(
  //         title,
  //         color: AppColors.black28,
  //         fontWeight: FontWeight.w700,
  //       ),
  //       content: CustomText(
  //         message,
  //         color: AppColors.black28,
  //       ),
  //       actions: [
  //           TextButton(
  //             onPressed: () => Get.back(),
  //             child: CustomText(
  //               "Cancel",
  //               color: AppColors.red,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //           TextButton(
  //           onPressed: () async {
  //             Get.back(); // close the dialog first
  //             // Perform the required action after closing dialog
  //             if (openAppSettingsOnConfirm) {
  //               await openAppSettings();
  //             } else if (openLocationSettingsOnConfirm) {
  //               await Geolocator.openLocationSettings();
  //             }
  //           },
  //           child: CustomText(
  //             confirmText,
  //             color: AppColors.primaryColor,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //       ],
  //     ),
  //     barrierDismissible: false,
  //   );
  // }

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
        locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // Check if location has changed
    if (_lastPosition == null /*||
        _hasLocationChanged(_lastPosition!, current)*/) {
      _lastPosition = current;
      return current;
    }
    return null; // same location → no need to update
  }



  static Future<void> askLocationPermission() async {
    Get.dialog<bool>(
      PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: CustomText(
            AppStrings.locationPermissionRequired.tr,
            fontSize: 16,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w600,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                AppStrings.locationPermissionStoreMessage.tr,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              CustomBtn(
                onTap: () async {
                  // First close the dialog
                  Get.back();

                  // Request permission and fetch location
                  await fetchLocation(openSettingsOnDeny: true);
                },
                title: AppStrings.grantPermission.tr,
                borderColor: AppColors.primaryColor,
                bgColor: AppColors.primaryColor,
              ),

              const SizedBox(height: 10),

              InkWell(
                onTap: () {
                  Get.back(result: false);  // Skip returns false
                },
                child: CustomText(
                  AppStrings.skip.tr,
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.w600,
                  decorationColor: AppColors.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

  }

}


String getLocalityAddress(String? address) {
  if (address == null || address.isEmpty) return 'N/A';
  final parts = address
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts[parts.length - 2]}, ${parts[parts.length - 1]}';
  }
  return address;
}
