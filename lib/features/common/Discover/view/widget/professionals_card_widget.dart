import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/profession_consultant_discover_entry_screen.dart';
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
      // v2 is location-first: both entry points open the entry screen (map +
      // "Where you Want?" + profession grid). The specific tile tapped just
      // enters the flow; the user picks location and category there. Mirrors
      // how [BookHomeServiceWidget] enters the self-profession flow.
      onViewAll: () {
        Get.to(() => ProfessionConsultantDiscoverEntryScreen(
              professionalConsultantCategories: categories,
            ));
      },
      onItemTap: (item) {
        Get.to(() => ProfessionConsultantDiscoverEntryScreen(
              professionalConsultantCategories: categories,
            ));
      },
      onFolderTap: () => Get.to(() => ProfessionConsultantDiscoverEntryScreen(
            professionalConsultantCategories: categories,
          )),
    );
  }
}
