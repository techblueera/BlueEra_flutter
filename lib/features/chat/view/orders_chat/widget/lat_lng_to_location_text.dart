import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../../widgets/custom_text_cm.dart';

class LocationTextWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double fontSize;
  final Color color;

  const LocationTextWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.fontSize = 14,
    this.color = Colors.black,
  }) : super(key: key);

  @override
  State<LocationTextWidget> createState() => _LocationTextWidgetState();
}

class _LocationTextWidgetState extends State<LocationTextWidget> {
  String _addressText = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _getAddressFromLatLng();
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.latitude,
        widget.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Build clean string (area, city, pincode)

        String locationString =
        "${place.name ?? ''}, ${place.subLocality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.locality ?? ''} - ${place.postalCode ?? ''}".trim();
        setState(() {
          _addressText = locationString;
        });
      } else {
        setState(() {
          _addressText = "Unknown location";
        });
      }
    } catch (e) {
      setState(() {
        _addressText = "Location not found";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomText(
      _addressText,
      fontSize: widget.fontSize,
      color: widget.color,
    );
  }
}
