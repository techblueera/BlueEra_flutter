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
  final double? actionTextFontSize;
  final bool actionHighlight;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.actionText,
    this.actionCallback,
    this.imagePath,
    this.imageSize,
    this.textColor,
    this.fontSize,
    this.actionTextFontSize,
    this.actionHighlight = false,
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
          if (actionText != null && actionCallback != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: () => actionCallback!(),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: actionHighlight
                      ? EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16,
                          vertical: SizeConfig.size8,
                        )
                      : EdgeInsets.zero,
                  decoration: actionHighlight
                      ? BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.35),
                          ),
                        )
                      : null,
                  child: CustomText(
                    actionText,
                    fontSize: actionTextFontSize ?? SizeConfig.medium,
                    fontWeight:
                        actionHighlight ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.primaryColor,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
