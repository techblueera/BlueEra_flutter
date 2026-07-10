import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelStayServiceCard extends StatelessWidget {
  const HotelStayServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.bookYourStay,
      items: stayItemsCategories,
      getName: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      onItemTap: (item) {
        Get.to(() => AllStayServiceScreen(
            stayCategories: stayItemsCategories, selectedStayCategory: item));
      },
    );
  }
}
