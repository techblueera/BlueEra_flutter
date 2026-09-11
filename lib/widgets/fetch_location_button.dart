import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/widgets/location_help_sheet.dart';
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

  /// One line on why THIS screen wants the location, shown at the top of the
  /// guidance sheet when the fetch fails. Null falls back to the generic line.
  final String? purpose;

  const CommonLocationFetcher({
    super.key,
    required this.locationController,
    required this.onLocationFetched,
    required this.childBuilder,
    this.preferNativeGeocoding = false,
    this.purpose,
  });

  /// Every route into here is a deliberate tap — the button the host screen
  /// builds, or the red "location not found" line below — so a failure is
  /// explained rather than swallowed: the sheet names what went wrong, walks
  /// the user through the fix, and retries without them having to find this
  /// button again.
  Future<void> _fetchLocation(BuildContext context) async {
    final locationData = await resolveLocationWithGuidance(
      context: context,
      controller: locationController,
      preferNativeGeocoding: preferNativeGeocoding,
      purpose: purpose,
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
            onTap: () => _fetchLocation(context),
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

      return childBuilder(() => _fetchLocation(context));
    });
  }
}