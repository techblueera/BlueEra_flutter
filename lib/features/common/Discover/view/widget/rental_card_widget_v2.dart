import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/all_stay_service_screen.dart';
import 'package:BlueEra/features/common/Discover/view/discover_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef _PropertyTile = ({String image, String label, bool isSale});

class RentalCardWidgetV2 extends StatelessWidget {
  const RentalCardWidgetV2({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = <_PropertyTile>[
      (
        image: AppImageAssets.propertyHouseSale,
        label: 'For Sale:\nHouses & Apartments',
        isSale: true,
      ),
      (
        image: AppImageAssets.propertyHouseRent,
        label: 'For Rent:\nHouses & Apartments',
        isSale: false,
      ),
      (
        image: AppImageAssets.propertyNewProjectSale,
        label: 'For Sale:\nNew Projects & Properties',
        isSale: true,
      ),
      (
        image: AppImageAssets.propertyLandPlotSale,
        label: 'Lands & Plots\nFor Sale',
        isSale: true,
      ),
      (
        image: AppImageAssets.propertyShopOfficeRent,
        label: 'For Rent:\nShops & Offices',
        isSale: false,
      ),
      (
        image: AppImageAssets.propertyShopOfficeSale,
        label: 'For Sale:\nShops & Offices',
        isSale: true,
      ),
    ];

    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.paddingXSL),
          titleWidget('Rent & Properties'),
          SizedBox(height: SizeConfig.paddingXSL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LayoutBuilder(builder: (context, constraints) {
              const double spacing = 8;
              const int columns = 3;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final double itemHeight = itemWidth / 0.72;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: tiles
                    .map((tile) => SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: _propertyCard(tile, _openRentals),
                        ))
                    .toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openRentals() {
    Get.to(() => AllStayServiceScreen(
          stayCategories: stayHomeItemsCategories,
          selectedStayCategory: stayHomeItemsCategories.first,
        ));
  }
}

Widget _propertyCard(_PropertyTile tile, VoidCallback onTap) {
  final radius = BorderRadius.circular(10);
  return InkWell(
    onTap: onTap,
    borderRadius: radius,
    splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
    highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFDDE2EE)),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: _tagChip(isSale: tile.isSale),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: LocalAssets(
                      imagePath: tile.image,
                      boxFix: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomText(
                  tile.label,
                  textAlign: TextAlign.center,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  maxLines: 3,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
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
      isSale ? 'FOR SALE' : 'FOR RENT',
      color: AppColors.primaryColor,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
  );
}
