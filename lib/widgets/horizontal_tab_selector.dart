import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/glass_surface.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HorizontalTabSelector<T> extends StatelessWidget {
  final List<T> tabs;
  final int selectedIndex;
  final Function(int, String) onTabSelected;
  final double horizontalPadding;
  final double verticalPadding;
  final String Function(T) labelBuilder;
  final bool isFilterIconShow;
  final bool isIconShow;
  final double? horizontalMargin;
  final double? verticalMargin;
  final VoidCallback? onFitterTab;
  final Color? unSelectedBackgroundColor;
  final Color? selectedBackgroundColor;
  final Color? unSelectedBorderColor;
  final List<BoxShadow>? boxShadow;
  final double tabBorderRadius;

  const HorizontalTabSelector({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.labelBuilder,
    this.horizontalPadding = 8,
    this.verticalPadding = 4,
    this.isFilterIconShow = false,
    this.isIconShow = false,
    this.horizontalMargin,
    this.verticalMargin,
    this.onFitterTab,
    this.unSelectedBackgroundColor,
    this.selectedBackgroundColor,
    this.unSelectedBorderColor,
    this.boxShadow,
    this.tabBorderRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    // Under a [GlassScope] these chips sit on the frosted header rather than on
    // a solid page (the Connect tab — docs/chat_new.jpeg), so an unselected chip
    // gets a translucent white fill and a white rim to lift it off the banner.
    // The LABEL stays dark: the fill is what it reads against, so it needs no
    // restyling. Explicit colour overrides from the caller still win, leaving
    // the 27 other placements untouched.
    final bool glass = GlassScope.isActive(context);
    final Color unselectedBorder = unSelectedBorderColor ??
        (glass
            ? Colors.white.withValues(alpha: 0.75)
            : AppColors.secondaryTextColor);
    final Color unselectedFill = unSelectedBackgroundColor ??
        (glass ? Colors.white.withValues(alpha: 0.30) : Colors.transparent);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: horizontalMargin ?? SizeConfig.paddingXSL,
          vertical: verticalMargin ?? SizeConfig.size2
      ),
      physics: BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Filter Icon
          if (isFilterIconShow) ...[
            _buildFilterButton(
              context,
              child: LocalAssets(
                  imagePath: AppIconAssets.filterIcon,
                  imgColor: AppColors.black),
            ),
            SizedBox(width: SizeConfig.size7),
          ],

          ...List.generate(tabs.length, (index) {
            final isSelected = selectedIndex == index;
            final label = labelBuilder(tabs[index]);
            final isLast = index == tabs.length - 1;

            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0.0 : SizeConfig.size8),
              child: InkWell(
                onTap: () => onTabSelected(index, label),
                borderRadius: BorderRadius.circular(tabBorderRadius),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: verticalPadding),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (selectedBackgroundColor ?? AppColors.primaryColor)
                        : unselectedFill,
                    borderRadius: BorderRadius.circular(tabBorderRadius),

                    border: isSelected
                        ? null
                        : Border.all(color: unselectedBorder),
                    boxShadow: boxShadow ?? null
                  ),
                  child: Row(
                    children: [
                      CustomText(
                        label,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.secondaryTextColor,
                      ),
                      if (isIconShow) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.expand_more,
                          color: AppColors.black33,
                          size: 16,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, {required Widget child}) {
    return InkWell(
      onTap: onFitterTab,
      child: child,
    );
  }
}
