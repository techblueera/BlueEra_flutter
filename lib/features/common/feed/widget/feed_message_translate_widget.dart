import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class TranslationButton extends StatelessWidget {
  final VoidCallback onTap;

  const TranslationButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: SizeConfig.size10,
      top: SizeConfig.size12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.blackCC,
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size15,
            vertical: SizeConfig.size5,
          ),
          child: LocalAssets(imagePath: AppIconAssets.languageIcon),
        ),
      ),
    );
  }
}
