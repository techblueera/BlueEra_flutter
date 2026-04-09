import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/features/subscription/widget/subscription_live_plan_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Body of the "Statistics" tab on every Me-screen dashboard.
///
/// Renders the live plan card when the user is on a live plan
/// (`status == 'active'` or `status == 'authenticated'`). For every other
/// lifecycle state (no plan / paused / halted / cancelled) renders an
/// instructional empty state pointing at the bottom [SubscriptionDraggableSheet]
/// peek — deliberately CTA-less because the peek already has the
/// subscribe / recharge button. Two competing CTAs on the same screen
/// would split the user's attention.
///
/// No initState fetch lives here. The shared [SubscriptionController] is
/// populated by the bottom-nav `Me` tab tap (the canonical refresh point)
/// and the peek sheet's mount-time fetch, so by the time the user swipes
/// to the statistics tab `currentPlansList` is already up to date. The
/// [Obx] makes the body flip automatically when payments / cancels change
/// the status.
class SubscriptionStatusView extends StatelessWidget {
  const SubscriptionStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => SubscriptionController());
    return Container(
      color: AppColors.whiteFC,
      width: double.infinity,
      alignment: Alignment.topCenter,
      child: Obx(() {
        final plans = controller.currentPlansList;
        final userSub = plans.isNotEmpty ? plans.first : null;
        final isLive = userSub != null &&
            (userSub.status == 'active' ||
                userSub.status == 'authenticated');

        if (isLive) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size12,
            ),
            child: SubscriptionLivePlanCard(userSub: userSub),
          );
        }

        return const _StatisticsLockedHint();
      }),
    );
  }
}

/// Empty-state placeholder shown when the user has no live plan. Soft
/// gradient halo around a stats icon, a short pitch, and a subtle pill
/// pointing the user to the peek sheet at the bottom of the screen.
/// Auto-plays a fade + slide entry the first time it mounts.
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
            // Gradient halo + insights icon — visual anchor for the empty state.
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
              'Statistics locked',
              fontSize: SizeConfig.extraLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              'Subscribe to a plan to unlock detailed analytics, '
              'leads, and performance insights for your business.',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
            SizedBox(height: SizeConfig.size20),
            // Pill pointing the user at the peek sheet at the bottom of
            // the screen. Deliberately not a button — just a hint.
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
                    'See plans at the bottom',
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
