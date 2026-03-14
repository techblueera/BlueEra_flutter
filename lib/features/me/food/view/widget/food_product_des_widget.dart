import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';

class ProductDescriptionWidget extends StatelessWidget {
  final String? description;
  final int trimLines;
  final Color? textColor;

  const ProductDescriptionWidget({
    super.key,
    this.description,
    this.trimLines = 2,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableText(
      text: (description == null || description!.isEmpty)
          ? AppStrings.na
          : description!,
      trimLines: trimLines,
      isReadMoreNewLine: false,
      expandMode: ExpandMode.dialog,
      style: TextStyle(
        color: textColor ?? AppColors.secondaryTextColor,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w400,
        fontFamily: AppConstants.OpenSans,
      ),
    );
  }
}