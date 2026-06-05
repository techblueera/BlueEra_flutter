import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Compact "Use current location" action. Fetches the device location,
/// reverse-geocodes it to an address, and hands the coordinates + address
/// string back via [onResolved] so the caller can fill its address field.
class UseCurrentLocationButton extends StatefulWidget {
  final void Function(double lat, double lng, String address) onResolved;

  const UseCurrentLocationButton({super.key, required this.onResolved});

  @override
  State<UseCurrentLocationButton> createState() =>
      _UseCurrentLocationButtonState();
}

class _UseCurrentLocationButtonState extends State<UseCurrentLocationButton> {
  bool _loading = false;

  Future<void> _onTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final result =
          await LocationService.fetchLocation(openSettingsOnDeny: true);
      if (result == null) {
        commonSnackBar(
            message:
                'Could not get current location. Please enable location and try again.');
        return;
      }
      final lat = LocationService.lat;
      final lng = LocationService.lng;

      var address = LocationService.userCurrentAddress.value.formattedAddress;
      if (address.trim().isEmpty) {
        try {
          address = await LocationService.getAddressUsingLatLng(
              latitude: lat, longitude: lng);
        } catch (_) {}
      }
      if (!mounted) return;
      widget.onResolved(lat, lng, address);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _loading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  )
                : Icon(Icons.my_location_rounded,
                    size: 15, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              _loading ? 'Getting location…' : 'Use current location',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
