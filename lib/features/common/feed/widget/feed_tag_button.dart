import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class FeedTagButton extends StatelessWidget {
  final VoidCallback onTap;

  const FeedTagButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: SizeConfig.size15,
      bottom: SizeConfig.size7,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.mainTextColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size9,
            vertical: SizeConfig.size6,
          ),
          child: LocalAssets(imagePath: AppIconAssets.profileFillIcon),
        ),
      ),
    );
  }
}
