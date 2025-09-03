import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String? title;
  final Color? color;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final double? fontSize;
  final TextAlign? textAlign;
  final double? height;
  final FontStyle? fontStyle;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextDecoration? decoration;
  final double? letterSpacing;
  final Color? decorationColor;
  final TextDecorationStyle? decorationStyle;

  const CustomText(
    this.title, {
    Key? key,
    this.color,
    this.fontWeight,
    this.fontFamily,
    this.fontSize,
    this.textAlign,
    this.height,
    this.fontStyle,
    this.maxLines,
    this.overflow,
    this.decoration = TextDecoration.none,
    this.letterSpacing,
    this.decorationColor,
    this.decorationStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title ?? "",
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: true,
      style: TextStyle(
        color: color ?? AppColors.black,
        fontFamily: fontFamily ?? AppConstants.OpenSans,
        fontWeight: fontWeight ?? FontWeight.w400,
        fontSize: fontSize ?? SizeConfig.medium,
        height: height,
        fontStyle: fontStyle,
        overflow: overflow,
        decoration: decoration,
        letterSpacing: letterSpacing,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
      ),
    );
  }
}
