import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/all_education_service_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_categories_data.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EducationServiceCardWidget extends StatelessWidget {
  const EducationServiceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Bundled categories, API artwork — see [apiCategoryIcon].
    //
    // NOTE the name collision: `businessOnboardingEducationTrainingCategories`
    // below is the top-level BUNDLED list in app_constant.dart, while the one
    // read for icons is the RxList of the same name on [AuthController]. Two
    // different things, one name — the unqualified reference resolves to the
    // bundled one, which is what the tap routing needs.
    final api = Get.find<AuthController>();
    return Obx(() {
      // Read the RxList in the builder body, not inside `getIcon` — that
      // callback runs outside Obx's reactive scope. See the note in
      // [HealthServiceCardWidget].
      final apiCategories = api.businessOnboardingEducationTrainingCategories.toList();
      return DiscoverGridSection(
        title: AppStrings.educationTrainingAndSectors.tr,
        items: businessOnboardingEducationTrainingCategories,
        getName: (item) => item.name.tr,
        getIcon: (item) =>
            apiCategoryIcon(apiCategories, item.slugId) ?? (item.icon ?? ''),
        onItemTap: (item) {
          Get.to(() => AllEducationServiceScreen(
              professionalConsultantCategories:
                  businessOnboardingEducationTrainingCategories,
              selectedProfessionConsultantData: item));
        },
        // Folder tap → the same listing on its first category; its category
        // header is where the user moves between them.
      );
    });
  }
}
