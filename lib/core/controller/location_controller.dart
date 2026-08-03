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

  Future<LocationDataModel?> checkPermissionAndSetData() async {
    isFetchingAddress.value = true;
    HapticFeedback.lightImpact();

    final locationResult = await LocationPermissionHandler().getCurrentLocation();

    if (locationResult.isSuccess && locationResult.position != null) {
      final pos = locationResult.position!;
      log("📍 lat: ${pos.latitude}, lng: ${pos.longitude}");
      LocationDataModel? locationDataModel = await getAddressDetails(position: pos);
      return locationDataModel;
    } else {
      log("❌ Location error: ${locationResult.message}");
      fetchAddressFromGeo.value = false;
      isFetchingAddress.value = false;
      return null;
    }
  }

  /// Coordinates → address, using the **device's own geocoder first**.
  ///
  /// This is the app's only caller of Google's Geocoding API, and it reads
  /// exactly three things: the formatted address, the city and the pincode.
  /// All three come out of `placemarkFromCoordinates` (the `geocoding`
  /// package), which is **free, on-device, and works with no network** —
  /// whereas every Google call here bills a Geocoding request.
  ///
  /// Google is kept only as a fallback for the case the OS geocoder genuinely
  /// cannot answer (no Play Services geocoder backend, or a coordinate it has
  /// no data for). In practice that is rare, so Geocoding spend should now sit
  /// at or near zero — if the Cloud Console shows meaningful Geocoding volume
  /// after this, it is not coming from this app.
  Future<LocationDataModel?> getAddressDetails({required Position position}) async {
    // ── Free path: the OS geocoder ──
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final city = p.locality?.trim() ?? '';
        final pinCode = p.postalCode?.trim() ?? '';

        // Composed widest-last the way an Indian address reads, de-duplicated
        // because the OS repeats values across fields often enough that
        // "Dehradun, Dehradun, Uttarakhand" is the common case, not the edge.
        final seen = <String>{};
        final address = [
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ]
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && seen.add(s.toLowerCase()))
            .join(', ');

        // Only accept it if it actually answered. An empty address means the
        // geocoder had nothing for this point, and Google may still.
        if (address.isNotEmpty) {
          log("✅ (device geocoder) full address: $address, "
              "city: $city, PinCode: $pinCode");

          fetchAddressFromGeo.value = true;
          isFetchingAddress.value = false;

          return LocationDataModel(
            fullAddress: address,
            city: city,
            pinCode: pinCode,
            lat: position.latitude.toString(),
            long: position.longitude.toString(),
          );
        }
      }
    } catch (e) {
      // Geocoder unavailable on this device/emulator — fall through to Google.
      log("device geocoder unavailable, falling back to Google: $e");
    }

    // ── Paid fallback: Google Geocoding ──
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
}
