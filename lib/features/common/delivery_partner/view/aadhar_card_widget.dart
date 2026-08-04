import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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

  @override
  void initState() {
    super.initState();
    // Reset the flow and fetch current verification status on open.
    controller.initAadhaarFlow();
  }

  @override
  void dispose() {
    controller.disposeAadhaarFlow();
    super.dispose();
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
        CommonImageUploadTile(
          title: AppStrings.uploadAadhaarFront.tr,
          imageFile: controller.aadharFrontImage,
          context: context,
          onImageSelected: () => _pickAadhaarImage(
              controller.aadharFrontImage, AppStrings.aadharFront.tr),
        ),
        SizedBox(height: SizeConfig.paddingS),
        CommonImageUploadTile(
          title: AppStrings.uploadAadhaarBackOptional.tr,
          imageFile: controller.aadharBackImage,
          context: context,
          onImageSelected: () => _pickAadhaarImage(
              controller.aadharBackImage, AppStrings.aadharBack.tr),
        ),
        SizedBox(height: SizeConfig.paddingM),
        Obx(
          () => CustomBtn(
            title: controller.isAadhaarImageSubmitting.value
                ? null
                : AppStrings.submitAadhaarImages.tr,
            onTap: controller.isAadhaarImageSubmitting.value
                ? null
                : () => controller.submitAadhaarImages(),
            radius: 10.0,
            bgColor: AppColors.primaryColor,
            isLoading: controller.isAadhaarImageSubmitting.value,
          ),
        ),
        ],
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
        Pinput(
          controller: controller.aadhaarOtpController,
          length: 6,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          defaultPinTheme: defaultPinTheme,
        ),
        SizedBox(height: SizeConfig.size15),

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
        SizedBox(height: SizeConfig.paddingM),
        Obx(
          () => CustomBtn(
            title: controller.isAadhaarOtpVerifying.value
                ? null
                : AppStrings.verifyOtp.tr,
            onTap: controller.isAadhaarOtpVerifying.value
                ? null
                : () => controller.verifyAadhaarOtp(),
            radius: 10.0,
            bgColor: AppColors.primaryColor,
            isLoading: controller.isAadhaarOtpVerifying.value,
          ),
        ),
        SizedBox(height: SizeConfig.size10),
        InkWell(
          onTap: () => controller.editAadhaarNumber(),
          child: CustomText(
            '✎ ${AppStrings.editAadhaarNumber.tr}',
            fontSize: SizeConfig.small,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: SizeConfig.paddingM),
        // Fallback — OTP delivery fails for some Aadhaar-linked numbers, so
        // offer the "verify by image" option right here on the OTP screen.
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
