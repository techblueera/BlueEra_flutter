import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/inactivity/controller/inactivity_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shown once, right after login, to a user whose content the backend has
/// already erased for 90 days of inactivity.
///
/// Without it a purged user lands on a real, valid, completely empty account —
/// no posts, no orders, no chats — which is indistinguishable from "the app is
/// broken" or "I'm in someone else's account". The backend cannot solve that
/// on its own: the account is deliberately valid, so there is nothing for
/// login to reject.
///
/// The tone is deliberately warm rather than apologetic. Nothing has gone
/// wrong, their account and phone number are untouched, and the only thing
/// being asked of them is to fill their profile back in — so this reads as a
/// welcome back, not an incident report.
///
/// See docs/backend/FLUTTER_INACTIVE_USER_DATA_PURGE_GUIDE.md §5.1.
class DataPurgedScreen extends StatelessWidget {
  const DataPurgedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = InactivityController.to;
    return PopScope(
      // This is the only route on the stack — the controller reaches it with
      // `Get.offAll`, because the screens behind it were all showing the
      // previous life's data. So there is nothing to pop TO; `canPop: false`
      // is here to stop the Android back button backgrounding the app before
      // the button has run `/acknowledge` and re-created the session's
      // controllers, which is the whole reason this screen exists.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _badge(),
                    SizedBox(height: SizeConfig.size24),
                    CustomText(
                      AppStrings.inactivityPurgedTitle.tr,
                      textAlign: TextAlign.center,
                      fontSize: SizeConfig.large18,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: SizeConfig.size12),
                    CustomText(
                      // The copy names the retention period only in words
                      // ("for a long time"), never a hardcoded 90: the
                      // threshold is server-side config and can change without
                      // an app release.
                      AppStrings.inactivityPurgedBody.tr,
                      textAlign: TextAlign.center,
                      fontSize: SizeConfig.medium,
                      color: AppColors.grey72,
                    ),
                    SizedBox(height: SizeConfig.size16),
                    _reassurance(),
                    SizedBox(height: SizeConfig.size30),
                    Obx(
                      () => CustomBtn(
                        isLoading: controller.isAcknowledging.value,
                        onTap: controller.acknowledgeAndContinue,
                        title: AppStrings.inactivityPurgedCta.tr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: SizeConfig.size80,
        height: SizeConfig.size80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryColor.withValues(alpha: 0.10),
        ),
        child: Icon(
          Icons.waving_hand_rounded,
          color: AppColors.primaryColor,
          size: SizeConfig.size36,
        ),
      ),
    );
  }

  /// The single most important line on the screen: the account itself is fine.
  /// Boxed so it reads as a fact rather than as more of the apology above it.
  Widget _reassurance() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(SizeConfig.size12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.primaryColor,
            size: SizeConfig.size18,
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: CustomText(
              AppStrings.inactivityPurgedNote.tr,
              fontSize: SizeConfig.small,
              color: AppColors.grey72,
            ),
          ),
        ],
      ),
    );
  }
}
