import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class VideoPostMetaInfo extends StatelessWidget {
  final String totalLikes;
  final String totalVideoDuration;
  const VideoPostMetaInfo({super.key, required this.totalLikes, required this.totalVideoDuration});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: SizeConfig.size30,
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size6, horizontal: SizeConfig.size8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.blackCC,
              borderRadius: BorderRadius.circular(8.0)
          ),
          child:
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: SizeConfig.size2),
                child: LocalAssets(imagePath: AppIconAssets.unlikeIcon),
              ),
              CustomText(
                "$totalLikes",
                color: AppColors.white,
                fontSize: SizeConfig.extraSmall,
              ),
            ],
          ),

        ),

        Container(
          height: SizeConfig.size30,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size6, horizontal: SizeConfig.size8),
          decoration: BoxDecoration(
              color: AppColors.blackCC,
              borderRadius: BorderRadius.circular(8.0)
          ),
          child: CustomText(
            "$totalVideoDuration",
            color: AppColors.white,
            fontSize: SizeConfig.extraSmall,
          ),
        )

      ],
    );
  }
}
