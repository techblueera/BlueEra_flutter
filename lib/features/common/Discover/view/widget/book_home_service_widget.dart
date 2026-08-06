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
    final showMoreButton = categories.length > 10;
    // Full list inside the opened folder — see the note in [ShoppingCardWidget].
    // The cap and its toggle are a landing-card concern; the sheet renders no
    // toggle, so a cap there would just hide options.
    final displayCategories =
        (_showAll || DiscoverSheetScope.isActive(context))
            ? categories.toList()
            : categories.take(10).toList();

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
      // Profession artwork comes from the API (`image_url`), not the bundled
      // tagId map — a profession added or renamed server-side then arrives
      // with its icon. `getIndividualProfessionIcon` still backs the
      // profession ENTRY screens, which aren't part of the Discover grid.
      getIcon: (item) => item.imageUrl ?? '',
      onViewAll: showMoreButton
          ? () => setState(() => _showAll = !_showAll)
          : null,
      viewAllLabel: _showAll ? AppStrings.showLess.tr : AppStrings.showMore.tr,
      // Folder tap → the same entry screen every tile opens. `categories`, not
      // `displayCategories`: the entry screen shows the full profession grid,
      // and the 10-item cap here is only this card's Show more/less state.
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
