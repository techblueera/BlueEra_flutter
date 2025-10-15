import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Checks and requests location permission.
  static Future<bool> checkLocationPermissionAndGPS() async {
    try {
      // Step 1: Check location permission
      var status = await Permission.location.status;

      if (status.isGranted) {
        // Permission already granted
      } else if (status.isDenied || status.isRestricted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            await openAppSettings();
          }
          return false;
        }
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      // Step 2: Ensure GPS/location services are enabled and get position
      try {
        // This will automatically throw if GPS is off or permissions denied
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        // Location fetched successfully
        // lat = position.latitude;
        // lng = position.longitude;
        return true;
      } catch (e) {
        // Handle cases where GPS is off or permission denied
        log("Failed to get location: $e");
        return false;
      }

      // bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      // if (!serviceEnabled) {
      //   await Geolocator.openLocationSettings();
      //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
      //   if (!serviceEnabled) return false;
      // }

      return true;
    } catch (e) {
      log('checkLocationPermissionAndGPS error: $e');
      return false;
    }
  }


}
