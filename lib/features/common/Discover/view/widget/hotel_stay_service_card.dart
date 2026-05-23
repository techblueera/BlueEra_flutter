import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class HotelStayServiceCard extends StatelessWidget {
  final bool isShowInGrid;

  const HotelStayServiceCard({super.key, required this.isShowInGrid});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget(AppStrings.bookYourStay),
              SizedBox(
                width: SizeConfig.size8,
              ),
              // _viewAll(),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          isShowInGrid
              ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(builder: (context, constraints) {
              const double spacing = 8;
              const int columns = 2;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: stayItemsCategories.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: () {
                        Get.to(() => AllStayServiceScreen(
                            stayCategories: stayItemsCategories,
                            selectedStayCategory: item));
                      },
                      splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
                      highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xffDDE2EE), width: 1.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    width: double.infinity,
                                    color: item.colorCode,
                                    child: LocalAssets(imagePath: item.icon ?? ""),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  color: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomText(
                                        item.name,
                                        textAlign: TextAlign.center,
                                        fontSize: SizeConfig.large,
                                        color: AppColors.secondaryTextColor,
                                        fontWeight: FontWeight.w500,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.subtitle != null) ...[
                                        const SizedBox(height: 6),
                                        CustomText(
                                          item.subtitle ?? "N/A",
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.secondaryTextColor,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: stayItemsCategories.map((item) {
                        return InkWell(
                          onTap: () {
                            Get.to(() => AllStayServiceScreen(
                                stayCategories: stayItemsCategories,
                                selectedStayCategory: item));
                          },
                          splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
                          highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
                          child: Container(
                            width: SizeConfig.size150,
                            margin: EdgeInsets.only(right: SizeConfig.size8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xffDDE2EE), width: 1.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                children: [
                                  // Square-ish image area sized off the card width
                                  // so the height of every card stays in sync via
                                  // IntrinsicHeight.
                                  Container(
                                    width: double.infinity,
                                    height: SizeConfig.size120,
                                    color: item.colorCode,
                                    child:
                                        LocalAssets(imagePath: item.icon ?? ""),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    color: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CustomText(
                                          item.name,
                                          textAlign: TextAlign.center,
                                          fontSize: SizeConfig.large,
                                          color: AppColors.secondaryTextColor,
                                          fontWeight: FontWeight.w600,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.subtitle != null) ...[
                                          const SizedBox(height: 6),
                                          CustomText(
                                            item.subtitle ?? "N/A",
                                            fontSize: SizeConfig.small,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.secondaryTextColor,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
