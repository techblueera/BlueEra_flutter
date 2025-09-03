import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CustomRadioOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final ValueChanged<String?> onChanged;

  const CustomRadioOption({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomText(
              title,
              fontSize: SizeConfig.large,
            ),
          ),
          Radio<String>(
            value: value,
            groupValue: groupValue,
            activeColor: AppColors.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
