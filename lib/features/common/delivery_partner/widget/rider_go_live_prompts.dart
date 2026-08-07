import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Prompts for the rider dashboard's go-live state.
///
/// Two, and deliberately different shapes:
///
///   * [showRiderGoLiveSheet] — a BOTTOM SHEET shown on arrival at the Me
///     section when the rider is set up but not live. It is an invitation, not
///     an interruption, so it comes up from the bottom, near the thumb, and
///     goes away with a swipe.
///   * [showRiderRideInProgressDialog] — a DIALOG, because it is a refusal of
///     something the rider just tried to do. A refusal has to land in the
///     middle of the screen and be acknowledged.
///
/// The sheet deliberately does NOT diagnose why go-live is off. Deposit unpaid,
/// permissions missing, onboarding still in review — all of it is already
/// handled by `handleGoLiveTap`, which says the right thing for each case. Two
/// places deciding what blocks a rider is two places to get out of step, so
/// this one just offers the button and lets that be the single authority.
Future<void> showRiderGoLiveSheet({required VoidCallback onGoLive}) {
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
            "You're offline",
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
            'You will not receive any ride requests while you are offline. '
            'Turn on Go Live to start earning.',
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
                // screen or the deposit page, and pushing over a live sheet
                // leaves it underneath — backing out would land the rider right
                // back on this prompt.
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
                'Turn on Go Live',
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
    // Swipe-down and tap-outside both dismiss: nothing here is mandatory, and a
    // rider who has decided not to go live yet should not have to hunt for the
    // way out.
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
  );
}

/// The rider tried to go offline with a ride still running.
///
/// A refusal, so it explains itself: the customer is mid-trip and has no other
/// rider. There is no "go offline anyway" — that is the whole point — but the
/// rider does get told exactly what unblocks it.
Future<void> showRiderRideInProgressDialog() {
  return Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.redLite.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.redLite.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: Icon(Icons.motorcycle_rounded,
                  size: 30, color: AppColors.redLite),
            ),
            SizedBox(height: SizeConfig.size14),
            Text(
              'Finish your ride first',
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
              'You have a ride in progress. You can go offline once it is '
              'completed or cancelled — your customer is waiting on you.',
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
                onPressed: Get.back,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.redLite,
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue ride',
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
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}
