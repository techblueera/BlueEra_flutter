import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/finance/finance_listing_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FinancialSectors extends StatelessWidget {
  final bool isShowInGrid;

  const FinancialSectors({super.key, required this.isShowInGrid});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      color: AppColors.whiteFC,
      borderRadius: BorderRadius.circular(0),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
            EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            child: titleWidget(AppStrings.financialSectors.tr),
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: isShowInGrid ?
            LayoutBuilder(
                builder: (context, constraints) {
              const double spacing = 10;
              const int columns = 3;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: financeCategories.map((categoryItem) {
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: () {
                        Get.to(() => FinanceListingScreen(
                              selectedCategory: categoryItem,
                            ));
                      },
                      child: Container(
                        padding: EdgeInsets.all(SizeConfig.size10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xffE7F3FF),
                              AppColors.white,
                            ],
                            stops: [0.0, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          // boxShadow: [AppShadows.textFieldShadow],
                          border:
                              Border.all(color: Color(0xffDDE2EE), width: 1.0),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            LocalAssets(
                              imagePath: categoryItem.icon ?? '',
                              height: SizeConfig.size60,
                              width: SizeConfig.size80,
                            ),
                            SizedBox(height: SizeConfig.paddingXSL),
                            Container(
                              height: SizeConfig.size30,
                              alignment: Alignment.center,
                              child: CustomText(
                                categoryItem.name,
                                fontSize: SizeConfig.small11,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w600,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            })
            : Builder(builder: (context) {
              // Show ~2 cards plus a half-card peek so users see the list is
              // horizontally scrollable. Subtract the outer horizontal padding
              // (18*2 from the parent + 10*2 from the scroll view) and the
              // 6px right margin per card from the available width.
              const double cardMargin = 6;
              final double horizontalChrome =
                  (18 * 2) + (SizeConfig.size10 * 2);
              final double cardWidth =
                  ((MediaQuery.of(context).size.width - horizontalChrome) /
                          2.5) -
                      cardMargin;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                physics: const AlwaysScrollableScrollPhysics(),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: financeCategories.map((categoryItem) {
                      return InkWell(
                        onTap: () {
                          Get.to(() => FinanceListingScreen(
                                selectedCategory: categoryItem,
                              ));
                        },
                        child: Container(
                          width: cardWidth,
                          padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.size10,
                            horizontal: SizeConfig.size12,
                          ),
                          margin: EdgeInsets.only(right: cardMargin),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xffE7F3FF),
                                AppColors.white,
                              ],
                              stops: [0.0, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [AppShadows.textFieldShadow],
                            border: Border.all(
                                color: Color(0xffDDE2EE), width: 1.0),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              LocalAssets(
                                imagePath: categoryItem.icon ?? '',
                                height: SizeConfig.size80,
                                width: SizeConfig.size80,
                              ),
                              SizedBox(height: SizeConfig.paddingXSL),
                              CustomText(
                                categoryItem.name,
                                fontSize: SizeConfig.large,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w600,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: SizeConfig.paddingXSL),
                              CustomText(
                                categoryItem.subtitle,
                                fontSize: SizeConfig.small,
                                color: AppColors.secondaryTextColor,
                                fontWeight: FontWeight.w500,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}
