import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../core/services/location/location_service.dart';

class StoreKmAwayTextWidget extends StatelessWidget {
  final double lat;
  final double long;
  final bool isUnderlineShow;
  final double isPadding; // padding inside the container

  const StoreKmAwayTextWidget({
    super.key,
    required this.lat,
    required this.long,
    this.isUnderlineShow = true,
    this.isPadding = 8.0,
  });


  @override
  Widget build(BuildContext context) {
    final distance = calculateDistanceKm(
        LocationService.lat,
        LocationService.lng,
        lat,
        long
    );

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isPadding,
          vertical: isPadding / 2
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        // color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: AppColors.greyE5,
          // color: AppColors.primaryColor,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(
              imagePath: AppIconAssets.location_outline,
              height: 14,
              width: 14,
              imgColor: AppColors.secondaryTextColor,
          ),
          SizedBox(
            width: SizeConfig.size6,
          ),
          CustomText(
            "${distance.toInt()} Km Away",
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
            decoration: isUnderlineShow ? TextDecoration.underline : TextDecoration.none,
          ),
        ],
      ),
    );
  }
}
