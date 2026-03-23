import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CommonRatingRow extends StatelessWidget {
  final double rating;
  final int reviews;
  final String? distance; // Nullable to handle cases where distance isn't needed

  const CommonRatingRow({
    super.key,
    required this.rating,
    required this.reviews,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rating Star
        const Icon(Icons.star, size: 10, color: AppColors.yellow00),
        const SizedBox(width: 2),

        // Rating Text
        CustomText(
          rating != 0.0 ? "$rating " : 'N/A',
          fontSize: SizeConfig.small,
          color: AppColors.yellow00,
        ),
        const SizedBox(width: 4),

        // Reviews Count
        CustomText(
          // Assuming formatNumberLikePost is a global utility function
          "(${formatNumberLikePost(reviews)} reviews) ",
          fontSize: SizeConfig.small,
          color: AppColors.grey6D,
        ),

        // Optional Distance Section
        if (distance != null && distance!.isNotEmpty) ...[
          LocalAssets(imagePath: AppIconAssets.distanceLocation),
          const SizedBox(width: 2),
          CustomText(
            distance!,
            fontSize: SizeConfig.small,
            color: AppColors.black30,
          ),
        ],
      ],
    );
  }
}