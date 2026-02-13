import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? actionCallback;
  final String? imagePath;
  final double? imageSize;
  final Color? textColor;
  final double? fontSize;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.actionText,
    this.actionCallback,
    this.imagePath,
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
            imagePath: imagePath ?? AppImageAssets.noMeContent,
            height: imageSize ?? SizeConfig.size80,
            width: imageSize ?? SizeConfig.size80,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          CustomText(
            message,
            fontSize: fontSize ?? SizeConfig.large,
            color: textColor ?? AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          if(actionText!=null && actionCallback!=null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: InkWell(
              onTap: ()=> actionCallback!(),
              child: CustomText(
                actionText,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
