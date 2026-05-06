import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/vehicle/vehicle_listing_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AutomotiveServiceCardWidget extends StatelessWidget {
  const AutomotiveServiceCardWidget({super.key});

  // Maps the legacy `slugId`s carried by `automotiveServiceItemsCategories`
  // to the CATEGORY constants the be_vehicle_service expects on
  // `GET /vehicles?category=…`. Anything not in this map falls through
  // to the unfiltered listing — which still surfaces every vehicle and
  // lets the user category-chip-filter on the listing screen itself.
  static const _slugToCategory = <String, String>{
    'Vehicle_Sales': 'CAR',
    'Vehicle_Rental': 'CAR',
    'Transport_Logistic': 'TRUCK',
    // The remaining slugs (`Vehicle_parts`, `VEHICLE_SERVICE`,
    // `VehicleSupport`) don't map cleanly to a vehicle category — open
    // the unfiltered listing for those.
  };

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
            child: LayoutBuilder(
                builder: (context, constraints) {
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
                      onTap: (i) => Get.to(() => VehicleListingScreen(
                            initialCategory: _slugToCategory[i.slugId],
                          )),
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
}
