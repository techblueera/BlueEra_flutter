import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/location/user_address.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/services/location/geocoding_compat.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService extends GetxService {
  static double lat = 0.0;
  static double lng = 0.0;
  static Rx<UserAddress> userCurrentAddress = UserAddress().obs;

  /// Straight-line metres between [fromLat]/[fromLng] and the device's current
  /// cached location ([lat]/[lng]).
  ///
  /// Returns [double.infinity] when either point is unset (0,0) so callers
  /// treat "unknown location" as "moved far" — i.e. a cache built at an
  /// unknown location is never reused for a different unknown location.
  static double metersFromCurrent(double fromLat, double fromLng) {
    if (lat == 0.0 && lng == 0.0) return double.infinity;
    if (fromLat == 0.0 && fromLng == 0.0) return double.infinity;
    return Geolocator.distanceBetween(fromLat, fromLng, lat, lng);
  }
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

  /// Whether the app both holds location permission and has the device's
  /// location services switched on.
  ///
  /// Answers false rather than throwing. Both checks cross a platform channel
  /// and either can fail — and `Geolocator.isLocationServiceEnabled()` is the
  /// bare `.then((value) => value ?? false)` form in
  /// geolocator_platform_interface, with none of the
  /// PlatformException-to-typed-exception mapping the position calls get. A
  /// platform-side failure therefore arrives as a raw
  /// `PlatformException(LOCATION_SERVICES_DISABLED)` rather than a
  /// `LocationServiceDisabledException`.
  ///
  /// That matters because the caller is AppLifecycleHandler, which awaits this
  /// on every resume without a guard: anything thrown here was a fatal every
  /// time the app came back to the foreground. "Cannot determine" and "not
  /// available" lead to the same behaviour, so returning false loses nothing.
  Future<bool> isLocationAvailable() async {
    try {
      final permission = await Permission.location.status;
      final gps = await Geolocator.isLocationServiceEnabled();
      return permission.isGranted && gps;
    } catch (e) {
      debugPrint('isLocationAvailable check failed: $e');
      return false;
    }
  }

  /// Reverse-geocodes [latitude]/[longitude], or [AppStrings.addressNotFound]
  /// when there is no address to give.
  ///
  /// Never throws. Reverse geocoding needs a geocoder backend and a network,
  /// so `placemarkFromCoordinates` fails routinely in the field: offline, on a
  /// device without Play services, or when the platform geocoder is
  /// rate-limited. Its callers are inconsistent about catching that — three of
  /// the six do — and the method already has an answer for "no address", so it
  /// returns that rather than throwing past them.
  static Future<String> getAddressUsingLatLng({required double latitude,required double longitude}) async {
    try {
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
      }
    } catch (e) {
      debugPrint('Reverse geocode failed for $latitude,$longitude: $e');
    }

    return AppStrings.addressNotFound.tr;
  }

  /// In-flight [fetchLocation] call, used to coalesce concurrent callers.
  /// Cold start fires a fetch from main()'s deferred init while the home
  /// screen (and others) may fire their own — two overlapping runs mean two
  /// `Permission.location.request()` calls racing (permission_handler throws
  /// "A request for permissions is already running") plus duplicate GPS
  /// fixes. All concurrent callers now share one run.
  static Future<Map<String, dynamic>?>? _inFlightFetch;

  /// 🌍 Fetches current location and address
  static Future<Map<String, dynamic>?> fetchLocation({
    bool openSettingsOnDeny = false,
  }) {
    // Only the passive path coalesces — an explicit openSettingsOnDeny call
    // is a user-driven retry and must run its own interactive flow.
    if (!openSettingsOnDeny) {
      final existing = _inFlightFetch;
      if (existing != null) return existing;
      final run = _fetchLocationImpl(openSettingsOnDeny: false);
      _inFlightFetch = run;
      run.whenComplete(() {
        if (identical(_inFlightFetch, run)) _inFlightFetch = null;
      });
      return run;
    }
    return _fetchLocationImpl(openSettingsOnDeny: true);
  }

  static Future<Map<String, dynamic>?> _fetchLocationImpl({
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
    // The pre-checks are guarded too, not just the fix below. All three cross
    // a platform channel and all three can throw:
    // `isLocationServiceEnabled()` is the unmapped `.then((v) => v ?? false)`
    // form in geolocator_platform_interface, so a platform-side failure
    // arrives as a raw PlatformException — that is what crashed
    // [isLocationAvailable] — and `requestPermission()` throws outright when
    // another permission request is already in flight, which this file
    // already knows happens (see the _inFlightFetch note above).
    final LocationPermission permission;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        status = await Geolocator.requestPermission();
      }
      permission = status;
    } catch (e) {
      debugPrint('Location availability check failed: $e');
      return null;
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // The isLocationServiceEnabled() check above is a snapshot, not a lock:
    // location can be switched off between it and the fix, and on older
    // Android (Xiaomi/MIUI in particular) the service can report enabled while
    // the provider it would use is not — either way geolocator answers with a
    // LocationServiceDisabledException rather than a Position. That is the
    // same answer as the guards above, just delivered by throwing, and every
    // other "no fix" path here returns null. Callers rely on that.
    final Position current;
    try {
      current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }

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
