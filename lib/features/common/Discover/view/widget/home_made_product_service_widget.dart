import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/v2/hmp_discover_screen_v2.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeProductAndServiceWidget extends StatelessWidget {
  const HomeMadeProductAndServiceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.homeMadeProducts.tr,
      items: discoverHomeMadeProductCategories,
      getName: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      onItemTap: (_) => Get.to(() => HmpDiscoverScreenV2()),
      onFolderTap: () => Get.to(() => HmpDiscoverScreenV2()),
    );
  }
}
