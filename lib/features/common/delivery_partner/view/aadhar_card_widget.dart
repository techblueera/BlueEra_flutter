import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/aadhaar_capture_frame.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

/// Aadhaar OKYC (OTP) verification bottom sheet.
///
/// Drives the generic per-user Aadhaar identity verification flow:
///   status → enter Aadhaar + consent → generate OTP → verify OTP → verified.
/// See docs/backend/aadhaar-verification-ui-integration.md.
class AadharCardWidget extends StatefulWidget {
  const AadharCardWidget({super.key});

  @override
  State<AadharCardWidget> createState() => _AadharCardWidgetState();
}

class _AadharCardWidgetState extends State<AadharCardWidget> {
  final controller = Get.find<DeliveryPartnerController>();

  /// Held here so a rejected code can hand focus straight back to the pins —
  /// see [_submitOtp].
  final FocusNode _otpFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Reset the flow and fetch current verification status on open.
    controller.initAadhaarFlow();
  }

  @override
  void dispose() {
    _otpFocus.dispose();
    controller.disposeAadhaarFlow();
    super.dispose();
  }

  /// Verify as soon as the sixth digit lands — there is nothing left to decide
  /// once the code is complete, so a Verify button was only ever an extra tap
  /// between the rider and the answer.
  ///
  /// A wrong code clears the pins and takes focus back, because auto-submit
  /// otherwise strands them: the field stays full, so no further completion
  /// event fires and they have to delete six digits by hand before they can
  /// try again.
  Future<void> _submitOtp() async {
    if (controller.isAadhaarOtpVerifying.value) return;
    FocusScope.of(context).unfocus();
    await controller.verifyAadhaarOtp();
    if (!mounted) return;
    if (controller.aadhaarStage.value == AadhaarStage.otp) {
      controller.aadhaarOtpController.clear();
      _otpFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Obx(() {
        if (controller.isAadhaarStatusLoading.value) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        switch (controller.aadhaarStage.value) {
          case AadhaarStage.verified:
            return _buildVerifiedState();
          case AadhaarStage.otp:
            return _buildOtpStage();
          case AadhaarStage.entry:
            return _buildEntryStage();
        }
      }),
    );
  }

  // ── Stage 1: enter Aadhaar + consent ───────────────────────────────
  Widget _buildEntryStage() {
    return Form(
      key: controller.aadharFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonTextField(
            textEditController: controller.aadharController,
            // `title`/`hintText` are rendered verbatim — the key has to be
            // resolved here, or the raw identifier shows up on screen.
            title: AppStrings.aadharNumber.tr,
            hintText: AppStrings.egAadharNo.tr,
            keyBoardType: TextInputType.number,
            validator: ValidationMethod.validateAadhaar,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 12,
          ),
          SizedBox(height: SizeConfig.paddingS),

          /// Consent — mandatory, never pre-ticked (compliance requirement).
          Obx(
            () => InkWell(
              onTap: () => controller.aadhaarConsentGiven.toggle(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: controller.aadhaarConsentGiven.value,
                      onChanged: (v) =>
                          controller.aadhaarConsentGiven.value = v ?? false,
                      activeColor: AppColors.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      checkColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CustomText(
                      AppStrings.aadhaarConsentDeclaration.tr,
                      fontSize: SizeConfig.small,
                      color: AppColors.coloGreyText,
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SizeConfig.paddingM),

          Obx(
            () => CustomBtn(
              title: controller.isAadhaarOtpSending.value
                  ? null
                  : AppStrings.sendOtp.tr,
              onTap: controller.isAadhaarOtpSending.value
                  ? null
                  : () => controller.generateAadhaarOtp(),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              isLoading: controller.isAadhaarOtpSending.value,
            ),
          ),
        ],
      ),
    );
  }

  /// Red note on the OTP screen pointing riders to the image option when the
  /// OTP isn't being delivered.
  Widget _buildOtpFallbackNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
        SizedBox(width: SizeConfig.size6),
        Expanded(
          child: CustomText(
            AppStrings.aadhaarOtpFallbackNote.tr,
            fontSize: SizeConfig.small,
            color: AppColors.red,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  /// "— OR —" separator between the OTP path and the image path.
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.greyE5, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: CustomText(
            AppStrings.orLabel.tr,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.coloGreyText,
          ),
        ),
        Expanded(child: Divider(color: AppColors.greyE5, thickness: 1)),
      ],
    );
  }

  /// Second verification option: upload the Aadhaar front & back images and
  /// submit them (with the number entered above) via [submitAadhaarImages].
  Widget _buildAadhaarImageSection() {
    // Full-width regardless of the parent's cross-axis alignment (the OTP
    // stage centers its children), so the tiles and button span the sheet.
    return SizedBox(
      width: double.infinity,
      child: Column(
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
        // obvious without reading either label. Both are mandatory;
        // [submitAadhaarImages] rejects a missing back.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AadhaarCaptureFrame(
                side: AadhaarSide.front,
                imageFile: controller.aadharFrontImage,
                label: AppStrings.aadharFront.tr,
                onPick: () => _pickAadhaarImage(
                    controller.aadharFrontImage, AppStrings.aadharFront.tr),
                onView: () => _viewAadhaarImage(
                    controller.aadharFrontImage, AppStrings.aadharFront.tr),
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: AadhaarCaptureFrame(
                side: AadhaarSide.back,
                imageFile: controller.aadharBackImage,
                label: AppStrings.aadharBack.tr,
                onPick: () => _pickAadhaarImage(
                    controller.aadharBackImage, AppStrings.aadharBack.tr),
                onView: () => _viewAadhaarImage(
                    controller.aadharBackImage, AppStrings.aadharBack.tr),
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.paddingM),
        // Greyed out until BOTH images are picked, so the requirement is
        // visible before the tap rather than only in the snackbar after it.
        // The controller still re-checks — this is the affordance, not the
        // guard.
        Obx(
          () => CustomBtn(
            title: controller.isAadhaarImageSubmitting.value
                ? null
                : AppStrings.submitAadhaarImages.tr,
            bgColor: controller.hasBothAadhaarImages
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.5),
            onTap: controller.isAadhaarImageSubmitting.value
                ? null
                : () => controller.submitAadhaarImages(),
            radius: 10.0,
            isLoading: controller.isAadhaarImageSubmitting.value,
          ),
        ),
        ],
      ),
    );
  }

  /// Opens the picked side full screen, so the rider can check the photo is
  /// readable before submitting it.
  void _viewAadhaarImage(Rxn<File> target, String title) {
    final file = target.value;
    if (file == null) return;
    Get.to(
      () => ImageViewScreen(
        appBarTitle: title,
        imageUrls: [file.path],
        initialIndex: 0,
      ),
    );
  }

  /// Picks a document photo (ID-card crop ratio) and stores it in [target].
  Future<void> _pickAadhaarImage(Rxn<File> target, String title) async {
    final path = await CommonImageUploadTile.pickImage(
      context: context,
      title: title,
      cropAspectRatio: CommonImageUploadTile.documentCropAspectRatio,
    );
    if (path != null && path.isNotEmpty) {
      target.value = File(path);
    }
  }

  // ── Stage 2: enter OTP ─────────────────────────────────────────────
  Widget _buildOtpStage() {
    final defaultPinTheme = PinTheme(
      width: 46,
      height: 50,
      textStyle: TextStyle(
        fontSize: SizeConfig.medium,
        color: AppColors.black,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.white,
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
    );

    // Focused cell is the only thing that moves while typing, so it carries
    // the primary colour; the rest stay quiet.
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryColor, width: 1.4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomText(
          AppStrings.enterSixDigitOtp.tr,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          AppStrings.sentToAadhaarLinkedMobile.tr,
          fontSize: SizeConfig.small,
          color: AppColors.coloGreyText,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SizeConfig.paddingM),
        Obx(
          () => Pinput(
            controller: controller.aadhaarOtpController,
            focusNode: _otpFocus,
            length: 6,
            autofocus: true,
            // Locked while the code is in flight so a stray tap can't edit the
            // digits being checked.
            enabled: !controller.isAadhaarOtpVerifying.value,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            // The whole point: no Verify button, the sixth digit submits.
            onCompleted: (_) => _submitOtp(),
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        /// Takes the place of the old Verify button. Present only while the
        /// request is in flight — an idle row here would just be a button that
        /// does nothing.
        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: controller.isAadhaarOtpVerifying.value
                ? Row(
                    key: const ValueKey('verifying'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      CustomText(
                        AppStrings.verifyingDots.tr,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  )
                : const SizedBox(key: ValueKey('idle'), height: 14),
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        /// Resend (disabled during the cooldown per UIDAI's 30 s gap).
        Obx(
          () => Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CustomText(
                AppStrings.didntGetOtpCode.tr,
                fontSize: SizeConfig.small,
                color: AppColors.coloGreyText,
              ),
              if (controller.aadhaarResendSeconds.value > 0)
                CustomText(
                  // Placeholder rather than concatenation — the countdown sits
                  // in a different position across languages.
                  AppStrings.resendInFmt.trParams(
                      {'seconds': '${controller.aadhaarResendSeconds.value}s'}),
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                )
              // Sending — the request is in flight. Shown as inert text with a
              // spinner rather than a live link: the tap has already been
              // accepted, and a second one is refused by the controller anyway.
              else if (controller.isAadhaarOtpSending.value)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      AppStrings.sendingOtp.tr,
                      fontSize: SizeConfig.small,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: () => controller.generateAadhaarOtp(),
                  child: CustomText(
                    AppStrings.resendOtp.tr,
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
            ],
          ),
        ),
        // The "✎ Edit Aadhaar number" link used to sit here. It moved to the
        // sheet header as a back arrow — the conventional place to step back
        // a stage, and one control for the job instead of two.

        SizedBox(height: SizeConfig.paddingM),
        // Fallback — OTP delivery fails for some Aadhaar-linked numbers, so
        // offer the "verify by image" option right here on the OTP screen.
        // Stays visible while the code is being typed: the rider may still be
        // deciding between the two paths, and hiding it mid-entry was the
        // more disorienting of the two options.
        _buildOtpFallbackNote(),
        SizedBox(height: SizeConfig.paddingM),
        _buildOrDivider(),
        SizedBox(height: SizeConfig.paddingM),
        _buildAadhaarImageSection(),
      ],
    );
  }

  // ── Stage 3: verified ──────────────────────────────────────────────
  Widget _buildVerifiedState() {
    return Obx(() {
      final name = controller.aadhaarVerifiedName.value;
      final masked = controller.aadhaarMaskedNumber.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_rounded,
            color: AppColors.green00,
            size: SizeConfig.size48,
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            AppStrings.aadhaarVerified.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.green00,
          ),
          SizedBox(height: SizeConfig.size12),
          if (name != null && name.isNotEmpty)
            _infoRow(AppStrings.nameLabel.tr, name),
          if (masked != null && masked.isNotEmpty)
            _infoRow(AppStrings.aadharNumber.tr, masked),
          SizedBox(height: SizeConfig.paddingM),
          CustomBtn(
            title: AppStrings.done.tr,
            onTap: () => Get.back(),
            radius: 10.0,
            bgColor: AppColors.primaryColor,
          ),
        ],
      );
    });
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            '$label: ',
            fontSize: SizeConfig.small,
            color: AppColors.coloGreyText,
          ),
          Flexible(
            child: CustomText(
              value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
