import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Minimal empty state for "My Videos" — a small tinted icon, a short
/// heading and one line of helper copy pointing at the "Add Your
/// Links" CTA sitting just above it.
class PostEmptyState extends StatelessWidget {
  const PostEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Stretch full width so the inner Column's center-aligned
      // children sit on the screen midline regardless of any
      // start-aligned parent column.
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.paddingM,
          horizontal: SizeConfig.size12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: AppColors.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            CustomText(
              AppStrings.noVideosYetTitle,
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            CustomText(
              AppStrings.addYourLinksHint,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
