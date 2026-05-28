import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/contribution/controller/contribution_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Body of the "Statistics" tab on every Me-screen dashboard. Mirrors the
/// old SubscriptionStatusView — when the user has an active recharge it
/// shows a simple confirmation card, otherwise it shows the same locked
/// hint + arrow pointing at the contribution peek sheet at the bottom of
/// the screen. CTA-less by design — the peek already carries the action.
class ContributionStatusView extends StatelessWidget {
  const ContributionStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => ContributionController());
    return Container(
      width: double.infinity,
      alignment: Alignment.topCenter,
      child: Obx(() {
        if (controller.hasActiveRecharge.value) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size20,
            ),
            child: _ActiveContributionCard(),
          );
        }
        return const _StatisticsLockedHint();
      }),
    );
  }
}

class _ActiveContributionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded,
              size: 28, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.contributionActiveTitle.tr,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  AppStrings.thanksForContributing.tr,
                  fontSize: SizeConfig.medium,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsLockedHint extends StatelessWidget {
  const _StatisticsLockedHint();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 28),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size24,
          vertical: SizeConfig.size32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(SizeConfig.size24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.20),
                    AppColors.primaryColor.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.28),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.insights_rounded,
                size: 56,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              AppStrings.statisticsLocked.tr,
              fontSize: SizeConfig.extraLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              AppStrings.contributeToUnlockAnalytics.tr,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
            SizedBox(height: SizeConfig.size20),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    AppStrings.seePlansAtBottom.tr,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
