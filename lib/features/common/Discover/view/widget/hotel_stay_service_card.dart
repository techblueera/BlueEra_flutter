import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelStayServiceCard extends StatelessWidget {
  const HotelStayServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Bundled categories, API artwork — see [apiCategoryIcon]. This section is
    // the one where the two vocabularies are known to disagree
    // (`HOTELS_RESORTS` vs `HOTELS_RESORT`), so the bundled icon is doing real
    // work as the fallback rather than sitting there for form's sake.
    final api = Get.find<AuthController>();
    return Obx(() {
      // Read the RxList in the builder body, not inside `getIcon` — that
      // callback runs outside Obx's reactive scope. See the note in
      // [HealthServiceCardWidget].
      final apiCategories = api.businessOnboardingHospitalityStayCategories.toList();
      return DiscoverGridSection(
        title: AppStrings.bookYourStay,
        items: stayItemsCategories,
        getName: (item) => item.name,
        getIcon: (item) =>
            apiCategoryIcon(apiCategories, item.slugId) ?? (item.icon ?? ''),
        onItemTap: (item) {
          Get.to(() => AllStayServiceScreen(
              stayCategories: stayItemsCategories, selectedStayCategory: item));
        },
        // Folder tap → the same listing, opened on the first category. The screen
        // carries a header of every stay category, so nothing is lost by not
        // picking one here — and it must be given ONE: `AllStayServiceScreen`
        // dereferences `selectedStayCategory` in its initState.
      );
    });
  }
}
