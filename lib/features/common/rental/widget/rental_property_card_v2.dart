import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/rental/view/rental_services_dashboard_screen_v2.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared overview-tab CTA for the rental flow — a header strip + a
/// 3×2 grid of "For Sale / For Rent" property tiles. Replaces the
/// legacy `_buildRentalCard` (homestay / flat-room / vehicle chips)
/// across every dashboard surface (self-employee, rider, cab/transport
/// partner, professionals consultant). Tapping the header or any
/// tile navigates to [RentalServicesDashboardScreenV2].
///
/// Lives under `common/rental/widget/` so both personal and business
/// dashboards can drop it in without duplicating the property catalog.
class RentalPropertyCardV2 extends StatelessWidget {
  /// Outer margin around the card. Defaults to the standard
  /// `EdgeInsets.symmetric(horizontal: 14)` used by all overview tabs.
  final EdgeInsetsGeometry margin;

  const RentalPropertyCardV2({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <({String image, String label, bool isSale})>[
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
      margin: margin,
      child: CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _openRentalDashboardV2(),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.holiday_village_outlined,
                        color: AppColors.primaryColor, size: 20),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.rentalServices.tr,
                          style: TextStyle(
                            fontFamily: AppConstants.OpenSans,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Browse properties for sale & rent',
                          style: TextStyle(
                            fontFamily: AppConstants.OpenSans,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.secondaryTextColor),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            LayoutBuilder(builder: (ctx, constraints) {
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
                          child:
                              _rentalPropertyTile(tile, _openRentalDashboardV2),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// V2 opener — navigates to the shared 6-section dashboard. Kept as
  /// a private function (not a method on a State) so this widget can
  /// stay `StatelessWidget`.
  void _openRentalDashboardV2() {
    Get.to(() => const RentalServicesDashboardScreenV2());
  }

  Widget _rentalPropertyTile(
    ({String image, String label, bool isSale}) tile,
    VoidCallback onTap,
  ) {
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
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: CustomText(
                  tile.isSale ? 'FOR SALE' : 'FOR RENT',
                  color: AppColors.primaryColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: LocalAssets(
                    imagePath: tile.image,
                    boxFix: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CustomText(
                tile.label,
                textAlign: TextAlign.center,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                maxLines: 3,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
