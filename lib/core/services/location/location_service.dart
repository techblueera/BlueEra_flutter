import 'dart:async';
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

  /// Fallback coordinates pulled from the user's personal / business profile.
  /// Used when device GPS is off so location-based APIs still work instead of
  /// failing with 0,0. Set via [setProfileLocation] when a profile loads.
  static double? profileLat;
  static double? profileLng;

  /// Reactive flag: true only when a real device GPS position was obtained.
  /// Drives the app-wide "turn on location" banner. Profile-seeded coords do
  /// NOT flip this on — they're a silent fallback, not real device location.
  ///
  /// Seeded `true` (assume ON) so the banner stays hidden on launch and only
  /// appears once a check actually confirms location is OFF — rather than
  /// flashing before the first check runs.
  static final RxBool isDeviceLocationOn = true.obs;

  /// Bumps whenever usable coordinates first become available (a GPS fix or a
  /// profile seed). Lets screens that were built before location was ready
  /// wait for it — see [ensureUsableLocation].
  static final RxInt locationTick = 0.obs;

  /// True when we have usable coordinates from either device GPS or the
  /// profile fallback — i.e. location-based APIs can safely run.
  static bool get hasUsableLocation => lat != 0.0 || lng != 0.0;

  /// Resolves once usable coordinates exist — first trying a device GPS fetch,
  /// then (if GPS is off) waiting briefly for a profile load that may still be
  /// in flight to seed the fallback. Bounded by [timeout] so callers never
  /// hang if neither source ever produces coordinates.
  static Future<void> ensureUsableLocation({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (hasUsableLocation) return;

    await fetchLocation();
    if (hasUsableLocation) return;

    // Device GPS gave nothing and the profile hasn't seeded yet — wait for the
    // next location tick (e.g. profile finishes loading) or the timeout.
    final completer = Completer<void>();
    Worker? worker;
    Timer? timer;
    void finish() {
      if (!completer.isCompleted) completer.complete();
      worker?.dispose();
      timer?.cancel();
    }

    worker = ever<int>(locationTick, (_) {
      if (hasUsableLocation) finish();
    });
    timer = Timer(timeout, finish);
    return completer.future;
  }

  /// Record the profile's stored location as a fallback and seed [lat]/[lng]
  /// from it when device GPS hasn't provided coordinates yet.
  static void setProfileLocation(double? pLat, double? pLng) {
    if (pLat != null && pLat != 0.0) profileLat = pLat;
    if (pLng != null && pLng != 0.0) profileLng = pLng;
    seedFromProfileIfNeeded();
  }

  /// Fill [lat]/[lng] from the profile fallback only when device coords are
  /// still empty. Real GPS values (set in [fetchLocation]) always win.
  static void seedFromProfileIfNeeded() {
    if (lat != 0.0 || lng != 0.0) return;
    final pLat = profileLat ?? 0.0;
    final pLng = profileLng ?? 0.0;
    if (pLat != 0.0 && pLng != 0.0) {
      lat = pLat;
      lng = pLng;
      locationTick.value++;
      log('Location seeded from profile fallback: $lat, $lng');
    }
  }

  Future<bool> isLocationAvailable() async {
    final permission = await Permission.location.status;
    final gps = await Geolocator.isLocationServiceEnabled();
    return permission.isGranted && gps;
  }

  static Future<String> getAddressUsingLatLng({required double latitude,required double longitude}) async {
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
        isDeviceLocationOn.value = false;
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
          isDeviceLocationOn.value = false;
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
        if (!serviceEnabled) {
          isDeviceLocationOn.value = false;
          return null;
        }
      }

      // Step 3: Get location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      lat = position.latitude;
      lng = position.longitude;
      isDeviceLocationOn.value = true;
      locationTick.value++;
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
      isDeviceLocationOn.value = false;
      return null;
    } finally {
      isLoading = false;
      // Whenever device coords are unavailable, fall back to the profile
      // location so downstream APIs don't run with 0,0.
      seedFromProfileIfNeeded();
    }
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
