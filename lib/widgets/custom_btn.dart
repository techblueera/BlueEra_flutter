import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CustomBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final String? title;
  final double? radius;
  final double? height;
  final double? width;
  final Color? bgColor;
  final Color? textColor;
  final Color? borderColor;
  final double? fontSize;
  final bool? isDownloadFile;
  final IconData? leading;
  final bool? withIcon;
  final bool? toLowerCase;
  final String? iconPath;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final TextAlign? textAlign;
  final Alignment? align;
  final bool? isValidate;

  const CustomBtn(
      {super.key,
      this.isValidate,
      required this.onTap,
      required this.title,
      this.radius,
      this.toLowerCase = false,
      this.fontWeight,
      this.align,
      this.borderColor,
      this.height,
      this.width,
      this.fontSize,
      this.bgColor,
      this.textColor,
      this.leading,
      this.withIcon = false,
      this.iconPath,
      this.isDownloadFile = false,
      this.textAlign,
      this.padding});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:  onTap ,
        borderRadius: BorderRadius.circular(radius ?? 10),
        child: Ink(
          height: height ?? SizeConfig.buttonXL,
          width: width ?? SizeConfig.screenWidth,
          padding: padding ?? const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: bgColor == null
                ? (isValidate ?? false)
                    ? AppColors.primaryColor
                    : AppColors.grey9B
                : bgColor,
            border: Border.all(color: borderColor ?? Colors.transparent),
            borderRadius: BorderRadius.circular(radius ?? 5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
              child: Align(
                alignment: align ?? Alignment.center,
                child: CustomText(
                  (title ?? ""),
                  fontWeight: fontWeight ?? FontWeight.bold,
                  color: textColor ?? AppColors.white,
                  fontSize: fontSize ?? SizeConfig.medium,
                  textAlign: textAlign ?? TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PositiveCustomBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final String? title;
  final double? radius;
  final double? height;
  final double? width;
  final Color? bgColor;
  final Color? textColor;
  final Color? borderColor;
  final double? fontSize;
  final bool? isDownloadFile;
  final IconData? leading;
  final bool? withIcon;
  final bool? toLowerCase;
  final String? iconPath;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final TextAlign? textAlign;
  final Alignment? align;

  const PositiveCustomBtn(
      {super.key,
      required this.onTap,
      required this.title,
      this.radius,
      this.toLowerCase = false,
      this.fontWeight,
      this.align,
      this.borderColor,
      this.height,
      this.width,
      this.fontSize,
      this.bgColor,
      this.textColor,
      this.leading,
      this.withIcon = false,
      this.iconPath,
      this.isDownloadFile = false,
      this.textAlign,
      this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius ?? 3),
        child: Ink(
          height: height ?? SizeConfig.buttonXL,
          width: width ?? SizeConfig.screenWidth,
          padding: padding ?? const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: bgColor ?? theme.colorScheme.primary,
            border: Border.all(color: borderColor ?? theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(radius ?? 5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Align(
              alignment: align ?? Alignment.center,
              child: Row(
                children: [
                  CustomText(
                    (title ?? ""),
                    // toLowerCase == true ?( title ?? ""):( title?.toUpperCase() ?? ""),
                    fontWeight: fontWeight ?? FontWeight.w600,
                    color: textColor ?? AppColors.white,
                    fontSize: fontSize ?? SizeConfig.medium,
                    textAlign: textAlign ?? TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if(iconPath!=null) Padding(
                    padding: const EdgeInsets.only(left: 3.0),
                    child: LocalAssets(imagePath: iconPath!),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
