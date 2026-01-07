import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/circular_progress_painter.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

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
  });

  final String title;
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // LocalAssets(imagePath: icon),
              SizedBox(width: SizeConfig.size12),
              CustomText(
                title,
                fontSize: SizeConfig.size18,
                color: AppColors.secondaryTextColor,
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
          color: (isOn??false) ? Colors.green : Colors.grey.shade400,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: (isOn??false) ? Alignment.centerRight : Alignment.centerLeft,
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