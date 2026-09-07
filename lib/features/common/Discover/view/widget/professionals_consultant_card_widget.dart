import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/profession_consultant_discover_entry_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalsConsultantCardWidget extends StatelessWidget {
  const ProfessionalsConsultantCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories =
        Get.find<AuthController>().individualOnboardingConsultationList;

    // Shuffles a copy of the list so original order isn't mutated
    final randomizedCategories = (List.of(categories)..shuffle());

    return DiscoverGridSection(
      title: AppStrings.professionalsConsultant,
      items: DiscoverSheetScope.isActive(context)
          ? categories.take(8).toList()
          : randomizedCategories.take(8).toList(),
          // ? categories.toList()
          // : categories.take(8).toList(),
      getName: (item) => item.name ?? '',
      getIcon: (item) => item.imageUrl ?? getIndividualProfessionIcon(item.tagId),
      onViewAll: ()=> open(categories),
      onItemTap: (item)=> open(categories),
    );
  }

  void open(cate) => Get.to(() => ProfessionConsultantDiscoverEntryScreen(
    professionalConsultantCategories: cate,
  ));

}
