import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/view/aadhaar_photo_section.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Aadhaar verification for the rider onboarding step.
///
/// **One step, one screen**: the 12-digit number, consent, and both card photos
/// are asked for together and submitted once —
/// [DeliveryPartnerController.submitAadhaarImages] runs the AI document check,
/// uploads the images, and records the rider onboarding step.
///
/// The OTP (UIDAI OKYC) path was removed: it was two stages deep, delivery to
/// the Aadhaar-linked mobile failed often enough that the photo upload existed
/// as a fallback on the OTP screen anyway, and every rider who hit that
/// fallback had already been walked through a dead end to reach it. The photo
/// path is now the only path, matching the Gig Work onboarding step.
///
/// Stages left: [AadhaarStage.entry] and [AadhaarStage.verified].
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
          case AadhaarStage.pending:
            return _buildPendingState();
          case AadhaarStage.rejected:
            return _buildRejectedState();
          case AadhaarStage.entry:
            return _buildEntryStage();
        }
      }),
    );
  }

  // ── Stage 1: number + consent + both photos, submitted together ────
  Widget _buildEntryStage() {
    return Form(
      key: controller.aadharFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          /// It used to gate the OTP send; with that gone it gates the submit,
          /// because handing Aadhaar photographs to a verifier is precisely
          /// when the declaration needs to have been made.
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

          _buildAadhaarImageSection(),
        ],
      ),
    );
  }

  /// The card photos and the single submit button.
  ///
  /// The shared [AadhaarPhotoSection] — the same widget the Gig Work onboarding
  /// step renders — rather than the copy this sheet used to carry inline. It
  /// was extracted FROM this sheet for onboarding to reuse; with the OTP path
  /// and its "OTP isn't working?" wrapper gone, there is nothing left for the
  /// local copy to do differently.
  Widget _buildAadhaarImageSection() {
    return AadhaarPhotoSection(
      frontImage: controller.aadharFrontImage,
      backImage: controller.aadharBackImage,
      isSubmitting: controller.isAadhaarImageSubmitting,
      hasBothImages: () => controller.hasBothAadhaarImages,
      onPickFront: () => _pickAadhaarImage(
          controller.aadharFrontImage, AppStrings.aadharFront.tr),
      onPickBack: () => _pickAadhaarImage(
          controller.aadharBackImage, AppStrings.aadharBack.tr),
      onViewFront: () => _viewAadhaarImage(
          controller.aadharFrontImage, AppStrings.aadharFront.tr),
      onViewBack: () => _viewAadhaarImage(
          controller.aadharBackImage, AppStrings.aadharBack.tr),
      onSubmit: () => controller.submitAadhaarImages(),
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

  // ── Stage 2a: submitted, awaiting review ───────────────────────────
  //
  // The state that was missing entirely. It is also the most common failure to
  // land in, so it says WHAT is missing rather than just "pending": the
  // document route needs the number AND both card sides, and a number-only or
  // one-sided submission stays pending forever with nothing telling the rider
  // why. The re-submit button drops back to the entry form so they can finish.
  Widget _buildPendingState() {
    return Obx(() {
      final masked = controller.aadhaarMaskedNumber.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.primaryColor,
            size: SizeConfig.size48,
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            AppStrings.aadhaarPendingTitle.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: CustomText(
              AppStrings.aadhaarPendingHint.tr,
              fontSize: SizeConfig.small,
              color: AppColors.coloGreyText,
              textAlign: TextAlign.center,
              maxLines: 4,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          if (masked != null && masked.isNotEmpty)
            _infoRow(AppStrings.aadharNumber.tr, masked),
          SizedBox(height: SizeConfig.paddingM),
          CustomBtn(
            title: AppStrings.aadhaarResubmit.tr,
            onTap: () =>
                controller.aadhaarStage.value = AadhaarStage.entry,
            radius: 10.0,
            bgColor: AppColors.primaryColor,
          ),
        ],
      );
    });
  }

  // ── Stage 2b: rejected ─────────────────────────────────────────────
  Widget _buildRejectedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: AppColors.red,
          size: SizeConfig.size48,
        ),
        SizedBox(height: SizeConfig.size10),
        CustomText(
          AppStrings.aadhaarRejectedTitle.tr,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.red,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SizeConfig.size8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
          child: CustomText(
            AppStrings.aadhaarRejectedHint.tr,
            fontSize: SizeConfig.small,
            color: AppColors.coloGreyText,
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
        ),
        SizedBox(height: SizeConfig.paddingM),
        CustomBtn(
          title: AppStrings.aadhaarResubmit.tr,
          onTap: () => controller.aadhaarStage.value = AadhaarStage.entry,
          radius: 10.0,
          bgColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  // ── Stage 3: verified ──────────────────────────────────────────────
  Widget _buildVerifiedState() {
    return Obx(() {
      // No name row: the photo path produces no verified identity name — the
      // saved number is the whole record. (The OKYC name went with the OTP
      // path.)
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
