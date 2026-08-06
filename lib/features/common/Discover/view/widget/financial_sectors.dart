import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_listing_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FinancialSectors extends StatelessWidget {
  const FinancialSectors({super.key});

  @override
  Widget build(BuildContext context) {
    // Bundled categories, API artwork — see [apiCategoryIcon].
    final api = Get.find<AuthController>();
    return Obx(() {
      // Read the RxList in the builder body, not inside `getIcon` — that
      // callback runs outside Obx's reactive scope. See the note in
      // [HealthServiceCardWidget].
      final apiCategories = api.businessOnboardingFinancialSectorsCategories.toList();
      return DiscoverGridSection(
        title: AppStrings.financialSectors.tr,
        items: financeCategories,
        getName: (item) => item.name,
        getIcon: (item) =>
            apiCategoryIcon(apiCategories, item.slugId) ?? (item.icon ?? ''),
        onItemTap: (item) {
          Get.to(() => FinanceListingScreen(
                selectedCategory: item,
              ));
        },
        // Folder tap → the same listing with no category picked, which it opens
        // on `financeCategories.first` itself; its category header takes over
        // from there.
      );
    });
  }
}
