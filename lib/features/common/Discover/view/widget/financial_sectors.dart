import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FinancialSectors extends StatelessWidget {
  const FinancialSectors({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.financialSectors.tr,
      items: financeCategories,
      getName: (item) => item.name,
      getIcon: (item) => item.icon ?? '',
      onItemTap: (item) {
        Get.to(() => FinanceListingScreen(
              selectedCategory: item,
            ));
      },
      // Folder tap → the same listing with no category picked, which it opens
      // on `financeCategories.first` itself; its category header takes over
      // from there.
    );
  }
}
