import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class PostMetaInfo extends StatelessWidget {
  final String timeAgoText;
  final double? fontSize;
  final Color? color;

  const PostMetaInfo({
    super.key,
    required this.timeAgoText,
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomText(
      timeAgoText,
      color: color ?? AppColors.secondaryTextColor,
      fontWeight: FontWeight.w400,
      fontSize: fontSize ?? SizeConfig.small11,
    );
  }
}
