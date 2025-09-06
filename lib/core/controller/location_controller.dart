import 'dart:developer';
import 'package:BlueEra/core/api/model/geo_coding_response.dart';
import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import '../services/location_permission_handler.dart';

class LocationController extends GetxController {
  final isFetchingAddress = false.obs;
  final fetchAddressFromGeo = false.obs;

  Future<LocationDataModel?> checkPermissionAndSetData() async {
    isFetchingAddress.value = true; // show loader immediately
    HapticFeedback.lightImpact();   // ✅ instant haptic feedback

    final locationResult = await LocationPermissionHandler.getCurrentLocation();

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

  Future<LocationDataModel?> getAddressDetails({required Position position}) async {
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
