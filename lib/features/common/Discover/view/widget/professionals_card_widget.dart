import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/professional_consultant_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalsCardWidget extends StatelessWidget {
  const ProfessionalsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories =
        Get.find<AuthController>().individualOnboardingConsultationList;

    return DiscoverGridSection(
      title: AppStrings.professionalsConsultant,
      items: categories.take(10).toList(),
      getName: (item) => item.name ?? '',
      getIcon: (item) => getIndividualProfessionIcon(item.tagId),
      onViewAll: () {
        Get.to(() => ProfessionConsultantDiscoverScreen(
              professionalConsultantCategories: categories,
            ));
      },
      onItemTap: (item) {
        Get.to(() => ProfessionConsultantDiscoverScreen(
            professionalConsultantCategories: categories,
            selectedProfessionConsultantData: item));
      },
    );
  }
}
