import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/automotive_other_services_screen.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_category_discover_screen.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AutomotiveServiceCardWidget extends StatelessWidget {
  const AutomotiveServiceCardWidget({super.key});

  /// Maps an automotive category slug to the add-vehicle condition so the
  /// add flow can skip the NEW/USED chooser: `Vehicle_Sales` lists/adds a
  /// brand-new vehicle, `Vehicle_Rental` (re-labelled "Old Vehicle Sales")
  /// a used one. Any other category has no implied condition.
  String? _conditionForSlug(String? slugId) {
    switch (slugId) {
      case 'Vehicle_Sales':
        return VehicleCondition.isNew;
      case 'Vehicle_Rental':
        return VehicleCondition.used;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.automotiveShowroom,
      items: automotiveServiceItemsCategories,
      getName: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      onItemTap: (item) =>
          _onCategoryTap(item, automotiveServiceItemsCategories),
    );
  }

  /// Card-tap routing:
  ///   * Vehicle Parts → automotive products discover screen.
  ///   * Vehicle Service / Support / Transport Logistics → the
  ///     `/other-service/business-profile/search` listing.
  ///   * Everything else → the public vehicle listing.
  void _onCategoryTap(
      CollapsibleGridModel item, List<CollapsibleGridModel> categories) {
    final tag = (item.slugId ?? '').toLowerCase();
    final name = (item.name ?? '').toLowerCase();
    final isParts = tag.contains('part') || name.contains('part');

    if (isParts) {
      Get.to(() => const AutomotiveCategoryDiscoverScreen());
      return;
    }

    final otherServiceWire = _otherServiceWireForSlug(item.slugId);
    if (otherServiceWire != null) {
      Get.to(() => AutomotiveOtherServicesScreen(
            initialCategoryWire: otherServiceWire,
          ));
      return;
    }

    // AllVehicleServiceScreen is typed against CollapsibleGridModel and keys
    // its category filter off `slugId`, so map the API categories
    // (tag_id → slugId) before handing off.

    Get.to(() => VehicleListingScreen(
          initialCondition: _conditionForSlug(item.slugId),
        ));
  }

  /// Maps the home-tile slug for the three "Other Service" automotive
  /// categories to the `categoryOfBusiness` wire value expected by
  /// `/other-service/business-profile/search`. Returns null for slugs
  /// that don't belong on that listing.
  String? _otherServiceWireForSlug(String? slugId) {
    switch (slugId) {
      case 'VEHICLE_SERVICE':
        return 'VEHICLE_SERVICE';
      case 'VehicleSupport':
        return 'VEHICLE_SUPPORT';
      case 'Transport_Logistic':
        return 'TRANSPORT_LOGISTICS_PARKING';
      default:
        return null;
    }
  }
}
