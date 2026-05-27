import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/features/common/rental/view/property_discover_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalCardWidgetV2 extends StatefulWidget {
  const RentalCardWidgetV2({super.key});

  @override
  State<RentalCardWidgetV2> createState() => _RentalCardWidgetV2State();
}

class _RentalCardWidgetV2State extends State<RentalCardWidgetV2> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayTiles = _showAll
        ? propertyDiscoverTiles
        : propertyDiscoverTiles.take(6).toList();

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleWidget('Rent & Properties'),
              ViewAllButton(
                onTap: () => setState(() => _showAll = !_showAll),
                label:
                    _showAll ? AppStrings.showLess.tr : AppStrings.showMore.tr,
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(builder: (context, constraints) {
              const double spacing = 8;
              const int columns = 3;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: displayTiles.asMap().entries.map((entry) {
                  return SizedBox(
                    width: itemWidth,
                    child: _propertyCard(
                      entry.value,
                      () => _openDiscover(entry.key),
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openDiscover(int categoryIndex) {
    Get.to(() => PropertyDiscoverScreen(
          initialCategoryIndex: categoryIndex,
        ));
  }
}

Widget _propertyCard(PropertyTileData tile, VoidCallback onTap) {
  final radius = BorderRadius.circular(10);
  return InkWell(
    onTap: onTap,
    borderRadius: radius,
    splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
    highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
    child: AspectRatio(
      aspectRatio: 0.9,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: radius,
              border: Border.all(color: const Color(0xFFDDE2EE)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: LocalAssets(
                      imagePath: tile.image,
                      height: SizeConfig.size80,
                      boxFix: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size10),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: CustomText(
                      tile.label,
                      textAlign: TextAlign.center,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: _tagChip(isSale: tile.isSale),
          ),
        ],
      ),
    ),
  );
}

Widget _tagChip({required bool isSale}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(8),
      ),
    ),
    child: CustomText(
      isSale ? 'FOR SELL' : 'FOR RENT',
      color: AppColors.primaryColor,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
  );
}
