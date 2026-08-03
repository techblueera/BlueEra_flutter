import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/api/model/geo_coding_response.dart';
import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../services/location_permission_handler.dart';

class LocationController extends GetxController {
  final isFetchingAddress = false.obs;
  final fetchAddressFromGeo = false.obs;

  /// [preferNativeGeocoding] resolves lat/lng → address through the OS
  /// geocoder (the `geocoding` package: Android Geocoder / iOS CLGeocoder)
  /// instead of the billed Google Geocoding API. Callers on the new-account
  /// creation path pass true — that flow runs once per signup for every user
  /// installing the app, so it was the single biggest consumer of the
  /// Geocoding SKU. The Google call is still used as a fallback when the OS
  /// geocoder returns nothing (see [getAddressDetails]), so behaviour is
  /// unchanged for the user either way.
  Future<LocationDataModel?> checkPermissionAndSetData({
    bool preferNativeGeocoding = false,
  }) async {
    isFetchingAddress.value = true;
    HapticFeedback.lightImpact();

    final locationResult = await LocationPermissionHandler().getCurrentLocation();

    if (locationResult.isSuccess && locationResult.position != null) {
      final pos = locationResult.position!;
      log("📍 lat: ${pos.latitude}, lng: ${pos.longitude}");
      LocationDataModel? locationDataModel = await getAddressDetails(
        position: pos,
        preferNativeGeocoding: preferNativeGeocoding,
      );
      return locationDataModel;
    } else {
      log("❌ Location error: ${locationResult.message}");
      fetchAddressFromGeo.value = false;
      isFetchingAddress.value = false;
      return null;
    }
  }

  Future<LocationDataModel?> getAddressDetails({
    required Position position,
    bool preferNativeGeocoding = false,
  }) async {
    if (preferNativeGeocoding) {
      final native = await _addressFromDeviceGeocoder(position);
      if (native != null) {
        fetchAddressFromGeo.value = true;
        isFetchingAddress.value = false;
        return native;
      }
      // OS geocoder unavailable (no Play Services / CLGeocoder throttled /
      // offline). Fall through to the billed Google call rather than failing
      // the signup — this is the rare path, not the common one.
      log("ℹ️ Device geocoder gave nothing, falling back to Google Geocoding");
    }

    try {
      final responseModel = await PlaceRepo().getGeoCode(position: position);

      if (responseModel.isSuccess) {
        final data = GeocodingResponse.fromJson(responseModel.response?.data);
        final result = data.results.first;

        String address = result.formattedAddress;

        // City
        String city = result.addressComponents
            .firstWhere(
              (c) => c.types.contains('locality'),
          orElse: () => AddressComponent(
            longName: '',
            shortName: '',
            types: [],
          ),
        )
            .longName;

        // Pincode
        String pinCode = result.addressComponents
            .firstWhere(
              (c) => c.types.contains('postal_code'),
          orElse: () => AddressComponent(
            longName: '',
            shortName: '',
            types: [],
          ),
        )
            .longName;

        log("✅ full address: $address, "
            "city: $city, "
            "PinCode: $pinCode");

        fetchAddressFromGeo.value = true;
        isFetchingAddress.value = false;

        return LocationDataModel(
          fullAddress: address,
          city: city,
          pinCode: pinCode, lat: position.latitude.toString(), long: position.longitude.toString(),
        );
      } else {
        fetchAddressFromGeo.value = false;
        isFetchingAddress.value = false;
        return null;
      }
    } catch (e) {
      fetchAddressFromGeo.value = false;
      isFetchingAddress.value = false;
      log("⚠️ Error fetching address: $e");
      return null;
    }
  }

  /// Reverse-geocode through the OS (Android `Geocoder` / iOS `CLGeocoder`)
  /// via the `geocoding` package. Free and quota-free, unlike the Geocoding
  /// API SKU.
  ///
  /// Returns null — never throws — when the platform gives us nothing usable,
  /// so the caller can decide whether to fall back to the paid lookup.
  static bool _localeApplied = false;

  Future<LocationDataModel?> _addressFromDeviceGeocoder(Position position) async {
    try {
      // en_IN keeps the strings in English regardless of device locale; the
      // Google path we're replacing was implicitly English too, and the
      // address is sent to the backend as-is. In geocoding 4.x the locale is
      // process-wide state rather than a per-call argument, so set it once.
      if (!_localeApplied) {
        await setLocaleIdentifier('en_IN');
        _localeApplied = true;
      }

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isEmpty) return null;
      final place = placemarks.first;

      final address = _formatPlacemark(place);
      // An empty line is worse than no result — let the caller fall back.
      if (address.isEmpty) return null;

      // Matches the Google path, which read `locality` for city. Android often
      // leaves locality empty outside metros, so mirror the fallback chain
      // already used for motel creation in AuthController.
      final city = _firstNonEmpty([
        place.locality,
        place.subAdministrativeArea,
        place.subLocality,
      ]);

      log("✅ full address (device): $address, "
          "city: $city, "
          "PinCode: ${place.postalCode ?? ''}");

      return LocationDataModel(
        fullAddress: address,
        city: city,
        pinCode: place.postalCode?.trim() ?? '',
        lat: position.latitude.toString(),
        long: position.longitude.toString(),
      );
    } on TimeoutException {
      log("⚠️ Device geocoder timed out");
      return null;
    } catch (e) {
      log("⚠️ Device geocoder failed: $e");
      return null;
    }
  }

  /// Builds a single readable line that stands in for Google's
  /// `formatted_address`, e.g. "12, Ring Road, Athwa, Surat, Gujarat, 395007,
  /// India".
  static String _formatPlacemark(Placemark place) {
    final parts = <String>[];
    for (final raw in [
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
      place.postalCode,
      place.country,
    ]) {
      final value = raw?.trim() ?? '';
      if (value.isEmpty) continue;
      final lower = value.toLowerCase();
      // The platform repeats itself a lot — Android's `street` usually already
      // contains `name`, and `locality` frequently equals
      // `subAdministrativeArea`. Skip anything a part we already kept covers,
      // and drop earlier parts this longer one subsumes, so the line never
      // reads "Surat, Surat, Gujarat".
      if (parts.any((existing) => existing.toLowerCase().contains(lower))) {
        continue;
      }
      parts.removeWhere((existing) => lower.contains(existing.toLowerCase()));
      parts.add(value);
    }
    return parts.join(', ');
  }

  static String _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}
