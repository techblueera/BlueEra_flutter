import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/circular_progress_painter.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constant.dart';
import '../../../../../widgets/expandable_text.dart';

class MeMenuCardDesign extends StatelessWidget {
  const MeMenuCardDesign({
    super.key,
    required this.title,
    required this.icon,
    this.showCount,
    this.count,
    this.showToggleButton,
    this.isToggleOn,
    this.onToggleChanged,
    this.description,
  });

  final String title;
  final String? description;
  final String icon;
  final bool? showCount;
  final bool? showToggleButton;
  final String? count;

  /// 🔥 NEW
  final bool? isToggleOn;
  final ValueChanged<bool>? onToggleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        color: AppColors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon.isNotEmpty)...[
                    LocalAssets(imagePath: icon),
                    SizedBox(width: SizeConfig.size8),
                  ] ,
                  CustomText(
                    title,
                    fontSize: SizeConfig.size18,
                    color: AppColors.black,
                  ),
                ],
              ),

              if (showCount ?? false)
                SizedBox(
                  width: 25,
                  height: 25,
                  child: CustomPaint(
                    painter: CircleProgressPainter(0.50),
                    child: Center(
                      child: CustomText(
                        "${(0.50 * 100).toInt()}%",
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ),
                ),
              if (showToggleButton ?? false)
                CustomToggleSwitch(
                  isOn: isToggleOn ?? false,
                  onChanged: onToggleChanged,
                ),
            ],
          ),
          if(description!=null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height:
                SizeConfig.size6,),
                ExpandableText(
                  text:"${description}",
                  trimLines: 3,
                  isReadMoreNewLine: false,
                  expandMode: ExpandMode.dialog,
                  style: TextStyle(
                    color: AppColors.grayText,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppConstants.OpenSans,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class CustomToggleSwitch extends StatelessWidget {
  const CustomToggleSwitch({
    super.key,
    this.isOn,
    this.onChanged,
  });

  final bool? isOn;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged?.call(!isOn!); // 🔥 return updated value
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: (isOn ?? false) ? Colors.green : Colors.grey.shade400,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment:
              (isOn ?? false) ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
