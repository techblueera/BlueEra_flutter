import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/all_self_profession_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/book_home_service_card.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
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
    final showMoreButton = categories.length > 8;
    final displayCategories =
        _showAll ? categories : categories.take(8).toList();

    return CustomFormCard(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget(AppStrings.bookHomeServices),
              if (showMoreButton)
                ViewAllButton(
                  onTap: () => setState(() => _showAll = !_showAll),
                  label: _showAll
                      ? AppStrings.showLess.tr
                      : AppStrings.showMore.tr,
                ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(builder: (context, constraints) {
              const double spacing = 8;
              const int columns = 4;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: displayCategories.map((categoryItem) {
                  return SizedBox(
                    width: itemWidth,
                    child: BookHomeServiceCard(
                      service: categoryItem,
                      getName: (item) {
                        final raw = item.name ?? '';
                        if (raw.toLowerCase().startsWith('home ')) {
                          return raw.substring(5).trim();
                        }
                        return raw;
                      },
                      getIcon: (item) => getIndividualProfessionIcon(item.tagId),
                      onTap: (item) {
                        Get.to(() => AllSelfProfessionScreen(
                            selfEmployedCategories: categories,
                            selectedSelfProfessionData: item));
                      },
                    ),
                  );
                }).toList(),
              );
            }),
          )
        ],
      ),
    );
  }
}
