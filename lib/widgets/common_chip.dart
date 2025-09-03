import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CommonChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;

  const CommonChip({
    Key? key,
    required this.label,
    this.onDeleted,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.skyBlueFF,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: CustomText(
              label,
              fontSize: SizeConfig.medium,
              color: textColor ?? AppColors.black33,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          if (onDeleted != null)
            GestureDetector(
              onTap: onDeleted,
              child: Icon(
                Icons.close,
                size: SizeConfig.size20,
                color: iconColor ?? AppColors.black33,
              ),
            ),
        ],
      ),
    );
  }
}
