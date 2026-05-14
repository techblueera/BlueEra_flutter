import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/circular_progress_painter.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

/// Compact "menu card" tile shared by every `me/*` feature (hospital, school,
/// medical, others, job seeker, automotive, etc). Renders a leading icon +
/// title, with an optional right-side affordance (progress badge or toggle)
/// and an optional expandable description underneath.
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
  final bool? isToggleOn;
  final ValueChanged<bool>? onToggleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        color: AppColors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildTitleRow()),
              if (showCount ?? false) _buildProgressBadge(),
              if (showToggleButton ?? false)
                CustomToggleSwitch(
                  isOn: isToggleOn ?? false,
                  onChanged: onToggleChanged,
                ),
            ],
          ),
          if (description != null) ...[
            SizedBox(height: SizeConfig.size6),
            ExpandableText(
              text: description!,
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
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        if (icon.isNotEmpty) ...[
          LocalAssets(imagePath: icon),
          SizedBox(width: SizeConfig.size8),
        ],
        Flexible(
          child: CustomText(
            title,
            fontSize: SizeConfig.size14,
            color: AppColors.mainTextColor,
          ),
        ),
      ],
    );
  }

  /// Hardcoded 50% indicator preserved verbatim from the original — callers
  /// currently treat this as a static visual badge, not a real metric.
  Widget _buildProgressBadge() {
    return SizedBox(
      width: 25,
      height: 25,
      child: CustomPaint(
        painter: CircleProgressPainter(0.50),
        child: Center(
          child: CustomText(
            "50%",
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
        ),
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
    final on = isOn ?? false;
    return GestureDetector(
      onTap: () => onChanged?.call(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: on ? Colors.green : Colors.grey.shade400,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
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
