import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

Widget commonButtonWithIcon({
  required String title,
  required String icon,
  required bool isPrefix,
  required VoidCallback onTap,
  Color? iconColor,
  double? height,
  double? width,
  double? radius,
  double? fontSize,
  Color? bgColor,
  Color? textColor,
  Color? borderColor,
  FontWeight? fontWeight,
  TextAlign? textAlign,
  Alignment? align,
  EdgeInsets? padding,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius ?? 5),
      child: Ink(
        height: height ?? SizeConfig.buttonXL,
        width: width ?? SizeConfig.screenWidth,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.transparent,
          border: Border.all(color: borderColor ?? Colors.transparent),
          borderRadius: BorderRadius.circular(radius ?? 5),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPrefix)
                  Padding(
                    padding: EdgeInsets.only(right: SizeConfig.size8),
                    child: LocalAssets(imagePath: icon, imgColor: iconColor),
                  ),
                CustomText(
                  title,
                  fontSize: fontSize ?? SizeConfig.medium,
                  fontWeight: fontWeight ?? FontWeight.w600,
                  color: textColor ?? AppColors.white,
                  textAlign: textAlign ?? TextAlign.center,
                ),
                if (!isPrefix)
                  Padding(
                    padding: EdgeInsets.only(left: SizeConfig.size8),
                    child: LocalAssets(imagePath: icon),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
