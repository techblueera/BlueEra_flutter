import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class SubCategoryTabBar<T> extends StatelessWidget {
  final List<T> tabs;
  final int selectedIndex;
  final Function(int, T) onSelected;
  final TextStyle? textStyle;
  final double underlineHeight;
  final double horizontalPadding;
  final bool isFilterIconShow;
  final VoidCallback? onFitterTab;
  final String Function(T) labelBuilder;

  const SubCategoryTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.labelBuilder,
    this.textStyle,
    this.underlineHeight = 3.0,
    this.horizontalPadding = 6.0,
    this.isFilterIconShow = false,
    this.onFitterTab,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (isFilterIconShow) ...[
            _buildFilterButton(
              context,
              child: LocalAssets(imagePath: AppIconAssets.filterIcon, imgColor: AppColors.black),
            ),
            SizedBox(width: SizeConfig.size7),
            ],
          ...List.generate(tabs.length, (index) {
            final isSelected = index == selectedIndex;
            final label = labelBuilder(tabs[index]);

            return GestureDetector(
              onTap: () => onSelected(index, tabs[index]),
              child: Padding(
                padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: SizeConfig.size10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      label,
                      fontSize: SizeConfig.medium,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size7),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: underlineHeight,
                      width: (label.length * 7.5).toDouble() + 12,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
        ]
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
