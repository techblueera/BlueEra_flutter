import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_listing_screen.dart';
import 'package:BlueEra/features/me/automotive_products/view/customer/automotive_category_discover_screen.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
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
    return CustomFormCard(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget(AppStrings.automotiveShowroom),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(builder: (context, constraints) {
              const double spacing = 8;
              const int columns = 3;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: automotiveServiceItemsCategories.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    child: CommonServiceCard(
                      service: item,
                      getName: (i) => i.name,
                      getIcon: (i) => i.icon ?? "",
                      onTap: (data) => _onCategoryTap(data, automotiveServiceItemsCategories),
                      // Get.to(()=> VehicleListingScreen(
                      //   addCondition: _conditionForSlug(item.slug Id),
                      // )),
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// "Vehicle Parts" opens the products category-discover screen; every
  /// other automotive category keeps the existing AllVehicleServiceScreen
  /// listing.
  void _onCategoryTap(CollapsibleGridModel item, List<CollapsibleGridModel> categories) {
    final tag = (item.slugId ?? '').toLowerCase();
    final name = (item.name ?? '').toLowerCase();
    final isParts = tag.contains('part') || name.contains('part');

    if (isParts) {
      Get.to(() => const AutomotiveCategoryDiscoverScreen());
      return;
    }

    // AllVehicleServiceScreen is typed against CollapsibleGridModel and keys
    // its category filter off `slugId`, so map the API categories
    // (tag_id → slugId) before handing off.

    Get.to(()=> VehicleListingScreen(
      addCondition: _conditionForSlug(item.slugId),
    ));

  }

}
