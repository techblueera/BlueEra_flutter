import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_discover_entry_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookHomeServiceWidget extends StatefulWidget {
  const BookHomeServiceWidget({super.key});

  @override
  State<BookHomeServiceWidget> createState() => _BookHomeServiceWidgetState();
}

class _BookHomeServiceWidgetState extends State<BookHomeServiceWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final categories =
        Get.find<AuthController>().individualOnboardingSkillWorkList;
    final showMoreButton = categories.length > 10;
    final displayCategories =
        _showAll ? categories.toList() : categories.take(10).toList();

    return DiscoverGridSection(
      title: AppStrings.bookHomeServices,
      items: displayCategories,
      getName: (item) {
        final raw = item.name ?? '';
        if (raw.toLowerCase().startsWith('home ')) {
          return raw.substring(5).trim();
        }
        return raw;
      },
      getIcon: (item) => getIndividualProfessionIcon(item.tagId),
      onViewAll: showMoreButton
          ? () => setState(() => _showAll = !_showAll)
          : null,
      viewAllLabel: _showAll ? AppStrings.showLess.tr : AppStrings.showMore.tr,
      // Folder tap → the same entry screen every tile opens. `categories`, not
      // `displayCategories`: the entry screen shows the full profession grid,
      // and the 10-item cap here is only this card's Show more/less state.
      onFolderTap: () => Get.to(() => SelfProfessionDiscoverEntryScreen(
            selfEmployedCategories: categories,
          )),
      onItemTap: (item) {
        // v2 is location-first: open the entry screen (map + "Where you Want?"
        // + profession grid). The specific tile tapped just enters the flow;
        // the user picks location and category there.
        Get.to(() => SelfProfessionDiscoverEntryScreen(
              selfEmployedCategories: categories,
            ));
      },
    );
  }
}
