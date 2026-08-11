import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/aadhaar_capture_frame.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Aadhaar card capture: title + hint → front/back frames → submit.
///
/// Lifted out of the delivery-partner Aadhaar sheet so onboarding presents the
/// identical thing rather than a second design for the same job. It renders
/// only; every piece of state and every action belongs to the host, which is
/// what lets different controllers drive the same UI.
///
/// The "OTP isn't working?" note and OR divider that wrap this block in the
/// rider sheet are NOT here — there they introduce a fallback, and onboarding
/// has no OTP path for it to fall back from. A host that wants them supplies
/// them above this widget.
class AadhaarPhotoSection extends StatelessWidget {
  const AadhaarPhotoSection({
    super.key,
    required this.frontImage,
    required this.backImage,
    required this.isSubmitting,
    required this.hasBothImages,
    required this.onPickFront,
    required this.onPickBack,
    required this.onViewFront,
    required this.onViewBack,
    required this.onSubmit,
  });

  final Rxn<File> frontImage;
  final Rxn<File> backImage;

  /// True while the AI check / upload is running.
  final RxBool isSubmitting;

  /// Read inside the button's `Obx`, so it must touch observables to restyle
  /// when the second photo lands.
  final bool Function() hasBothImages;

  final VoidCallback onPickFront;
  final VoidCallback onPickBack;
  final VoidCallback onViewFront;
  final VoidCallback onViewBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          AppStrings.verifyUsingAadhaarPhoto.tr,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: SizeConfig.size4),
        CustomText(
          AppStrings.uploadAadhaarPhotoHint.tr,
          fontSize: SizeConfig.small,
          color: AppColors.coloGreyText,
          maxLines: 2,
        ),
        SizedBox(height: SizeConfig.paddingS),

        // Both sides side by side, each shaped like the face it wants — the
        // pair reads as one card turned over, and which slot is still empty is
        // obvious without reading either label.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AadhaarCaptureFrame(
                side: AadhaarSide.front,
                imageFile: frontImage,
                label: AppStrings.aadharFront.tr,
                onPick: onPickFront,
                onView: onViewFront,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: AadhaarCaptureFrame(
                side: AadhaarSide.back,
                imageFile: backImage,
                label: AppStrings.aadharBack.tr,
                onPick: onPickBack,
                onView: onViewBack,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.paddingM),

        // Greyed out until BOTH images are picked, so the requirement is
        // visible before the tap rather than only in the snackbar after it.
        // The host still re-checks — this is the affordance, not the guard.
        Obx(
          () => CustomBtn(
            title: isSubmitting.value
                ? null
                : AppStrings.submitAadhaarImages.tr,
            bgColor: hasBothImages()
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.5),
            onTap: isSubmitting.value ? null : onSubmit,
            radius: 10.0,
            isLoading: isSubmitting.value,
          ),
        ),
      ],
    );
  }

}
