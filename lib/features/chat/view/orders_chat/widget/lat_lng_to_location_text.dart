
import 'package:flutter/material.dart';
import 'package:BlueEra/core/services/location/geocoding_compat.dart';

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

  /// Resolves the coordinates to a label, then publishes it in ONE guarded
  /// `setState` at the end.
  ///
  /// This is started from `initState` and awaits a network geocode, so the
  /// widget can be gone by the time it returns — an order-chat row scrolled
  /// out of the list, or the screen popped. `setState` on a disposed State
  /// dereferences a null `_element` and throws `Null check operator used on a
  /// null value`, which reaches Crashlytics as a fatal even though nothing was
  /// actually broken: the answer simply arrived after nobody was listening.
  ///
  /// The `mounted` check has to sit AFTER the await — checking before it
  /// proves nothing, since disposal happens during the gap.
  Future<void> _getAddressFromLatLng() async {
    String resolved;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.latitude,
        widget.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Build clean string (area, city, pincode)

        resolved =
        "${place.name ?? ''}, ${place.subLocality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.locality ?? ''} - ${place.postalCode ?? ''}".trim();
      } else {
        resolved = "Unknown location";
      }
    } catch (e) {
      // Offline, no result, or a platform-channel failure — all ordinary, and
      // all already represented by the fallback label.
      resolved = "Location not found";
    }

    if (!mounted) return;
    setState(() {
      _addressText = resolved;
    });
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
