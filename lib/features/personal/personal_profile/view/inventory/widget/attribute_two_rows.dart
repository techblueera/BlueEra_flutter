import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class AttributeRows extends StatelessWidget {
  final Map<String, List<dynamic>> attributeMap;

  const AttributeRows({Key? key, required this.attributeMap}) : super(key: key);

  Widget _buildRow(String key, List<dynamic> values) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.map((value) {
          if (key.toLowerCase() == 'color' && value is Map<String, dynamic>) {
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: hexToColor(value["color_code"]),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1),
              ),
            );
          } else {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CustomText(
                "$value",
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = attributeMap.keys.toList();

    if (keys.isEmpty) return const SizedBox.shrink();

    final firstKey = keys[0];
    final firstValues = attributeMap[firstKey]!;

    final secondKey = keys.length > 1 ? keys[1] : null;
    final secondValues = secondKey != null ? attributeMap[secondKey]! : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        _buildRow(firstKey, firstValues),
        if (secondKey != null) ...[
          const SizedBox(height: 6),
          _buildRow(secondKey, secondValues),
        ],
      ],
    );
  }
}
