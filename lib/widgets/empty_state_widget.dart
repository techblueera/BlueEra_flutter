import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String imagePath;
  final double? imageSize;
  final Color? textColor;
  final double? fontSize;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.imagePath = AppIconAssets.emptyIcon,
    this.imageSize,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: imagePath,
            height: imageSize ?? SizeConfig.size80,
            width: imageSize ?? SizeConfig.size80,
          ),
          SizedBox(height: SizeConfig.size20),
          CustomText(
            message,
            fontSize: fontSize ?? SizeConfig.extraLarge,
            color: textColor ?? AppColors.grey9A,
          ),
        ],
      ),
    );
  }
}
