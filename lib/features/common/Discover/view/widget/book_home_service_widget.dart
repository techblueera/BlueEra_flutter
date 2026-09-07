import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/Discover/view/self_profession_discover_entry_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
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

    // Shuffles a copy of the list so original order isn't mutated
    final randomizedCategories = (List.of(categories)..shuffle());

    final showMoreButton = categories.length > 8;
    debugPrint('show more button-- $showMoreButton');

    // Full list inside the opened folder — see the note in [ShoppingCardWidget].
    // The cap and its toggle are a landing-card concern; the sheet renders no
    // toggle, so a cap there would just hide options.
    final displayCategories =
        (_showAll || DiscoverSheetScope.isActive(context))
            ? categories.take(8).toList()
            : randomizedCategories.take(8).toList();

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
      getIcon: (item) => item.imageUrl ?? getIndividualProfessionIcon(item.tagId),
      onViewAll: showMoreButton
          ? () => setState(() => _showAll = !_showAll)
          : null,
      viewAllLabel: _showAll ? AppStrings.showLess.tr : AppStrings.showMore.tr,
      onItemTap: (item)=> open(categories),
    );
  }

  void open(cate) => Get.to(() => SelfProfessionDiscoverEntryScreen(
    selfEmployedCategories: cate,
  ));

}
