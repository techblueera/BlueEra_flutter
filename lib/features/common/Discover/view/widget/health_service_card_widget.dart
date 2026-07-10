import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/health_care_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthServiceCardWidget extends StatelessWidget {
  const HealthServiceCardWidget({super.key});

  void _open(dynamic categoryItem) {
    Get.to(() => HealthCareListingScreen(
          selectedProfessionConsultantData: categoryItem,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.healthcareServices.tr,
      items: healthCareList,
      getName: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      onViewAll: () => _open(healthCareList[0]),
      onItemTap: (item) => _open(item),
    );
  }
}
