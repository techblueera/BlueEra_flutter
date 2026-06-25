import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Shared frosted-glass "Go live" toggle pill used across every "Me"
/// business/profile home top bar.
///
/// The visual is identical everywhere — frosted white pill, hairline
/// `#C9CDD5` border, a 30×18 toggle track (ON = primary, OFF = white) with a
/// 14×14 thumb. Only the *state source* and *tap handler* differ per screen,
/// so those are injected. A couple of screens omit the soft outer drop shadow
/// ([showShadow]) and one or two use a different [label]; the reactive screens
/// flip [isUpdating] to show a spinner while the status call is in flight.
class GoLivePill extends StatelessWidget {
  const GoLivePill({
    super.key,
    required this.value,
    required this.onTap,
    this.isUpdating = false,
    this.label,
    this.showShadow = true,
  });

  /// Whether the shop is currently live (toggle ON). The screen owns this.
  final bool value;

  /// Tap handler — flips the live state. Disabled while [isUpdating].
  final VoidCallback onTap;

  /// Shows a spinner in place of the toggle while a status update is pending.
  final bool isUpdating;

  /// Pill label. Defaults to `AppStrings.goLive.tr`.
  final String? label;

  /// Whether to paint the soft outer drop shadow behind the pill.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final pill = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10,
            vertical: SizeConfig.size6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFC9CDD5), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                label ?? AppStrings.goLive.tr,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(width: SizeConfig.size6),
              if (isUpdating)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                )
              else
                Container(
                  width: 30,
                  height: 18,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: value ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          AppColors.secondaryTextColor.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    alignment:
                        value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: value
                            ? Colors.white
                            : AppColors.secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: isUpdating ? null : onTap,
      child: showShadow
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 3,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: pill,
            )
          : pill,
    );
  }
}
