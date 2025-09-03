import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationModel {
  final double? latitude;
  final double? longitude;
  final String? address;

  LocationModel(
      {required this.latitude, required this.longitude, required this.address});
}

Future<void> openGoogleMaps({LocationModel? locationModel}) async {
  final lat = locationModel?.latitude;
  final lng = locationModel?.longitude;
  final address = locationModel?.address ?? '';

  Get.dialog(
    const Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );

  try {
    if (lat != null && lng != null) {
      final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (address.isNotEmpty) {
      final addressUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
      if (await canLaunchUrl(addressUrl)) {
        await launchUrl(addressUrl, mode: LaunchMode.externalApplication);
        return;
      }
    }
    commonSnackBar(message: "No valid location or address found for this job.");
  } catch (e) {
    print('Error opening Google Maps: $e');
    commonSnackBar(message: 'Could not open Google Maps: $e');
  } finally {
    Get.back(); // Always close loading dialog
  }
}
