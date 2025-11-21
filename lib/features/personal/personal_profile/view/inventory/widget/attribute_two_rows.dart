import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class AttributeRows extends StatelessWidget {
  final Map<String, List<dynamic>> attributeMap;

  const AttributeRows({Key? key, required this.attributeMap}) : super(key: key);

  void _showAllAttributesDialog(BuildContext context, String key, List<dynamic> values) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: CustomText(key, fontWeight: FontWeight.bold),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              if (key.toLowerCase() == 'color' && value is Map<String, dynamic>) {
                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: hexToColor(value["color_code"]),
                    borderRadius: BorderRadius.circular(2.0),
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: CustomText(
                    "$value",
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: SizeConfig.extraSmall,
                  ),
                );
              }
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.close),
          )
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String key, List<dynamic> values) {
    final displayCount = 4;
    final mainItems = values.take(displayCount).toList();
    final remainingCount = values.length - displayCount;

    return Row(
      children: [
        ...mainItems.map((value) {
          if (key.toLowerCase() == 'color' && value is Map<String, dynamic>) {
            return Container(
              width: SizeConfig.size16,
              height: SizeConfig.size16,
              margin: const EdgeInsets.only(right: 4.0),
              decoration: BoxDecoration(
                color: hexToColor(value["color_code"]),
                borderRadius: BorderRadius.circular(2.0),
                border: Border.all(color: Colors.grey, width: 1),
              ),
            );
          } else {
            return Container(
              height: SizeConfig.size16,
              margin: const EdgeInsets.only(right: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: CustomText(
                  "$value",
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: SizeConfig.extraSmall,
                ),
              ),
            );
          }
        }).toList(),
        if (remainingCount > 0)
          GestureDetector(
            onTap: () => _showAllAttributesDialog(context, key, values),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor..withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primaryColor, width: 0.5),
              ),
              child: CustomText(
                "+$remainingCount",
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = attributeMap.keys.toList();
    if (keys.isEmpty) return const SizedBox.shrink();

    final firstKey = keys[0];
    final firstValues = attributeMap[firstKey]!;

    // final secondKey = keys.length > 1 ? keys[1] : null;
    // final secondValues = secondKey != null ? attributeMap[secondKey]! : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size5),
        _buildRow(context, firstKey, firstValues),
        // if (secondKey != null) ...[
        //   const SizedBox(height: 6),
        //   _buildRow(context, secondKey, secondValues),
        // ],
      ],
    );
  }
}
