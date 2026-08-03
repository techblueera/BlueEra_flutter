import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/custom_text_cm.dart';

class CommonLocationFetcher extends StatelessWidget {
  final LocationController locationController;
  final Function(LocationDataModel locationData) onLocationFetched; // Replace 'dynamic' with LocationData type
  final Widget Function(VoidCallback triggerFetch) childBuilder;

  /// Resolve the address with the free OS geocoder instead of the billed
  /// Google Geocoding API. Set on the account-creation screens.
  final bool preferNativeGeocoding;

  const CommonLocationFetcher({
    super.key,
    required this.locationController,
    required this.onLocationFetched,
    required this.childBuilder,
    this.preferNativeGeocoding = false,
  });

  Future<void> _fetchLocation() async {
    final locationData = await locationController.checkPermissionAndSetData(
      preferNativeGeocoding: preferNativeGeocoding,
    );
    if (locationData != null) {
      onLocationFetched(locationData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 1. Loading State
      if (locationController.isFetchingAddress.value) {
        return const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      // 2. Error State
      if (!locationController.fetchAddressFromGeo.value) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: GestureDetector(
            onTap: _fetchLocation,
            child: CustomText(
              AppStrings.gpsLocationNotFound,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.red,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.red,
            ),
          ),
        );
      }

      return childBuilder(_fetchLocation);
    });
  }
}