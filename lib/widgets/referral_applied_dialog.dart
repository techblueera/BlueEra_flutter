import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Acknowledgement shown after a referral code captured from the Play
/// Store install referrer (or a `?referralCode=` deeplink) is
/// auto-applied at signup. It surfaces the win to the user — "you were
/// referred, here's the code that's now on your account" — instead of
/// applying it silently. This is the success counterpart to
/// [PromoCodeDialog], which is the manual "type a code" path.
class ReferralAppliedDialog extends StatelessWidget {
  final String code;

  const ReferralAppliedDialog({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final upper = code.toUpperCase();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gift hero in a soft brand-tinted disc.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 32,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            // Eyebrow pill.
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size12,
                vertical: SizeConfig.size4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText(
                AppStrings.referralAppliedSubtitle.tr,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              AppStrings.referralAppliedTitle.tr,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              AppStrings.referralAppliedDesc.trParams({'code': upper}),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size14),
            // The applied code, set as the hero chip.
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: CustomText(
                upper,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            CustomBtn(
              width: double.infinity,
              textColor: AppColors.white,
              bgColor: AppColors.primaryColor,
              title: AppStrings.referralAppliedGotIt.tr,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
