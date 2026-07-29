import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_v3_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A trim as the **buyer** sees it on discovery: the model, the cheapest live
/// listing behind it, and how many there are.
///
/// `priceFrom` and `listingCount` only exist on `/products/user/search` rows —
/// they are the rollup that endpoint computes from live inventory — so this
/// card is deliberately separate from [VehicleListingCardV3], which shows one
/// concrete listing.
class VehicleTrimCardV3 extends StatelessWidget {
  final VehicleTrimV3 trim;
  final VoidCallback? onTap;

  const VehicleTrimCardV3({super.key, required this.trim, this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = trim.firstImage;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 104,
                height: 84,
                child: image == null
                    ? Container(
                        color: AppColors.whiteF3,
                        alignment: Alignment.center,
                        child: Icon(Icons.directions_car_filled_outlined,
                            color: AppColors.secondaryTextColor),
                      )
                    : CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.whiteF3),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.whiteF3),
                      ),
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    trim.name,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_specLine.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      _specLine,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: SizeConfig.size6),
                  Row(
                    children: [
                      if (trim.priceFrom != null)
                        CustomText(
                          'From ${formatVehiclePriceV3(trim.priceFrom)}',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                        )
                      else if (trim.exShowroomPrice != null)
                        CustomText(
                          '${formatVehiclePriceV3(trim.exShowroomPrice)} ex-showroom',
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      const Spacer(),
                      if ((trim.listingCount ?? 0) > 0) _countChip(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countChip() {
    final count = trim.listingCount ?? 0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: CustomText(
        count == 1 ? '1 available' : '$count available',
        fontSize: SizeConfig.small11,
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  String get _specLine {
    final parts = <String>[
      if (trim.brand.isNotEmpty) trim.brand,
      if (trim.fuelType.isNotEmpty) trim.fuelType,
      if (trim.transmission.isNotEmpty) trim.transmission,
    ];
    return parts.join(' · ');
  }
}
