import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/all_education_service_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EducationServiceCardWidget extends StatelessWidget {
  const EducationServiceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoverGridSection(
      title: AppStrings.educationTrainingAndSectors.tr,
      items: businessOnboardingEducationTrainingCategories,
      getName: (item) => item.name.tr,
      getIcon: (item) => item.icon ?? '',
      onItemTap: (item) {
        Get.to(() => AllEducationServiceScreen(
            professionalConsultantCategories:
                businessOnboardingEducationTrainingCategories,
            selectedProfessionConsultantData: item));
      },
      // Folder tap → the same listing on its first category; its category
      // header is where the user moves between them.
      onFolderTap: () => Get.to(() => AllEducationServiceScreen(
          professionalConsultantCategories:
              businessOnboardingEducationTrainingCategories,
          selectedProfessionConsultantData:
              businessOnboardingEducationTrainingCategories.first)),
    );
  }
}
