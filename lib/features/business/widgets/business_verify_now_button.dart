import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_verfication.dart';
import 'package:BlueEra/features/business/widgets/blinking_verify_button.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reusable "Verify Now" status button.
///
/// Shows either a "Verified Profile" badge (when the business is already
/// verified) or a blinking "Verify Now" button that navigates to
/// [BusinessVerification].
///
/// Extracted from [BusinessProfileHeader] so the same control can be reused
/// on other screens (e.g. the grocery store screen).
class BusinessVerifyNowButton extends StatelessWidget {
  final BusinessProfileDetails? details;

  const BusinessVerifyNowButton({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = details?.businessIsVerified ?? false;

    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xffC5FFC9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomText(
          AppStrings.verifiedProfile,
          color: AppColors.secondaryTextColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return BlinkingVerifyButton(
      onTap: () {
        Get.to(()=> BusinessVerification());
      },
    );
  }
}
