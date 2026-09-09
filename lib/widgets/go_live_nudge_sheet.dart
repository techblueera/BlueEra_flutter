import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "You're offline" nudge, shown on arrival at the Me section when an account
/// that CAN be live isn't.
///
/// This started as the rider dashboard's sheet and is now shared by every "Me"
/// screen — business (Food / Grocery / School / Hospital / Hotel / Product /
/// Manufacturing / Automotive / …) and individual alike. Only the copy differs
/// per account type; the shape, the dismiss behaviour and the single-CTA rule
/// are the same everywhere, which is the point of having one of these.
///
/// It is an INVITATION, not an interruption: it comes up from the bottom near
/// the thumb, and a swipe or a tap outside dismisses it. Compare
/// `showRiderRideInProgressDialog`, which is a refusal and therefore a dialog.
///
/// **It deliberately does not diagnose why the account can't go live.** Hours
/// not set, plan unpaid, documents in review, permissions missing — every one
/// of those is already handled by the go-live action this button routes
/// through (`toggleLiveNow` for business/individual, `handleGoLiveTap` for
/// riders), and each says the right thing for its own case. Two places
/// deciding what blocks an account is two places to get out of step.
Future<void> showGoLiveNudgeSheet({
  required String title,
  required String message,
  required String ctaLabel,
  required VoidCallback onGoLive,
}) {
  return Get.bottomSheet(
    Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + (Get.mediaQuery.padding.bottom),
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab handle — says "this is draggable" before anyone tries.
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyE5,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: SizeConfig.size20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green1A.withValues(alpha: 0.10),
              border: Border.all(
                color: AppColors.green1A.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Icon(Icons.bolt_rounded, size: 30, color: AppColors.green1A),
          ),
          SizedBox(height: SizeConfig.size14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: SizeConfig.size8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              height: 1.5,
            ),
          ),
          SizedBox(height: SizeConfig.size20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Close FIRST, then act. `onGoLive` can push the permission
                // screen, the hours editor or the plan page, and pushing over a
                // live sheet leaves it underneath — backing out would land the
                // user right back on this prompt.
                Get.back();
                onGoLive();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green1A,
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                ctaLabel,
                style: TextStyle(
                  fontFamily: AppConstants.OpenSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: Get.back,
            child: CustomText(
              'Not now',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
    // Swipe-down and tap-outside both dismiss: nothing here is mandatory, and
    // someone who has decided not to go live yet should not have to hunt for
    // the way out.
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
  );
}

/// Shared re-ask policy for the nudge.
///
/// One timestamp for the whole app, static so it survives the Me screens being
/// rebuilt or swapped when the profile type resolves. Dismissing buys quiet for
/// a while; arriving again later asks again, because the thing it is asking
/// about — you are offline and earning nothing — has not changed.
///
/// Acting on it needs no cooldown of its own: the caller's "already live" check
/// stays silent for as long as the account remains online.
class GoLiveNudgeCooldown {
  const GoLiveNudgeCooldown._();

  static const Duration window = Duration(minutes: 15);
  static DateTime? _shownAt;

  /// True when enough time has passed to ask again.
  static bool get isDue {
    final at = _shownAt;
    return at == null || DateTime.now().difference(at) >= window;
  }

  static void markShown() => _shownAt = DateTime.now();
}
