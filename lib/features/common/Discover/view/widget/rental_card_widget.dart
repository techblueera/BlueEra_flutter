import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/rental/view/property_discover_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalCardWidget extends StatelessWidget {
  const RentalCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.rentAndProperties.tr,
      items: propertyDiscoverTiles,
      getName: (item) => item.label,
      getIcon: (item) => item.image,
      onItemTap: (item) {
        Get.to(() => PropertyDiscoverScreen(
              initialCategoryIndex: propertyDiscoverTiles.indexOf(item),
            ));
      },
      // Folder tap → the same screen on its first category; its own category
      // row is where the user switches.
      onFolderTap: () => Get.to(() => const PropertyDiscoverScreen()),
    );
  }
}
