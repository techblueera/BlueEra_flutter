import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class ProfileSummaryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double rating;
  final int reviews;
  final String distance;
  final double? imageSize;
  final double? imageBorderRadius;

  const ProfileSummaryCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.distance,
    this.imageSize,
    this.imageBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.red02,
            borderRadius: BorderRadius.circular(imageBorderRadius ?? SizeConfig.size15),
          ),
          child: CachedAvatarWidget(
            size: imageSize ?? SizeConfig.size30,
            borderRadius: imageBorderRadius ?? SizeConfig.size15,
            imageUrl: imageUrl,
          ),
        ),
        SizedBox(width: SizeConfig.size7),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  name,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black30,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size1),
                Row(
                  children: [
                    Icon(Icons.star, size: 10, color: AppColors.yellow00),
                    SizedBox(width: 2),
                    CustomText(
                      rating != 0.0 ? "$rating " : 'N/A',
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.yellow00,
                    ),
                    SizedBox(width: 4),
                    CustomText(
                      "($reviews reviews) ",
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.grey6D,
                    ),
                    LocalAssets(imagePath: AppIconAssets.distanceLocation),
                    CustomText(
                      distance,
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.black30,
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
