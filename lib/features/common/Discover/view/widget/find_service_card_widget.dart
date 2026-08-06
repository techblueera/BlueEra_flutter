import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/services_near_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FindServiceCardWidget extends StatelessWidget {
  const FindServiceCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories =
        Get.find<AuthController>().businessOnboardingServicesCategories;

    return DiscoverGridSection(
      title: AppStrings.findServices,
      // Eight on the landing card to keep it to a strip; every category inside
      // the opened folder, where the whole point is to choose one — and each
      // tile here carries its own `tagId` into the listing, so a category left
      // out is a category the user cannot filter by.
      items: DiscoverSheetScope.isActive(context)
          ? categories.toList()
          : categories.take(8).toList(),
      getName: (item) => item.name ?? '',
      getIcon: (item) => item.imageUrl ?? '',
      // Folder tap → the same listing unfiltered. Its category params are
      // nullable and only applied when present, so this opens on every service
      // near the user instead of one category chosen for them — and it also
      // reaches the categories past the eight this card shows.
      onItemTap: (item) {
        Get.to(() => ServicesNearMeScreen(
              serviceCategory: item.tagId,
              serviceCategoryName: item.name,
            ));
      },
    );
  }
}
