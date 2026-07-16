import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/controller/aadhaar_manual_kyc_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Manual Aadhaar verification — the fallback when OKYC (OTP) can't complete.
///
/// The user enters their Aadhaar number and uploads the front and back of the
/// card; the AI document verifier confirms the images are an Aadhaar card and
/// that the number on them matches. Reached from [AadhaarKycView] via its
/// `onVerifyManually` callback.
///
/// Pass an [AadhaarManualKycController] whose `onManualVerified` records the
/// result in the host flow. See
/// docs/backend/aadhaar-verification-ui-integration.md.
class AadhaarManualKycScreen extends StatefulWidget {
  const AadhaarManualKycScreen({super.key, required this.controller});

  final AadhaarManualKycController controller;

  @override
  State<AadhaarManualKycScreen> createState() => _AadhaarManualKycScreenState();
}

class _AadhaarManualKycScreenState extends State<AadhaarManualKycScreen> {
  AadhaarManualKycController get controller => widget.controller;

  @override
  void dispose() {
    controller.disposeFlow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Verify Aadhaar Manually',
        isLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size8, vertical: SizeConfig.size15),
          child: Obx(
            () => AbsorbPointer(
              absorbing: controller.isSubmitting.value,
              child: CustomFormCard(
                child: controller.stage.value == AadhaarManualStage.verified
                    ? _buildVerifiedState()
                    : _buildEntryStage(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Enter number + card images + consent ───────────────────────────
  Widget _buildEntryStage(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            "Couldn't verify with OTP? Upload your Aadhaar card instead and "
            "we'll verify the details on it.",
            fontSize: SizeConfig.small,
            color: AppColors.coloGreyText,
            maxLines: 3,
          ),
          SizedBox(height: SizeConfig.paddingM),

          CommonTextField(
            textEditController: controller.aadharController,
            title: 'Aadhaar Number',
            hintText: 'E.g. 5678 1234 6679 9012',
            keyBoardType: TextInputType.number,
            validator: ValidationMethod.validateAadhaar,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 12,
          ),
          SizedBox(height: SizeConfig.paddingM),

          CustomText(
            'Upload Aadhaar card (both sides)',
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w400,
          ),
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              Expanded(
                child: _uploadTile(
                  context: context,
                  title: 'Front',
                  target: controller.frontImage,
                ),
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: _uploadTile(
                  context: context,
                  title: 'Back',
                  target: controller.backImage,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            'Make sure the Aadhaar number is fully visible and readable.',
            fontSize: SizeConfig.small,
            color: AppColors.coloGreyText,
            maxLines: 2,
          ),
          SizedBox(height: SizeConfig.paddingM),

          /// Consent — mandatory, never pre-ticked (compliance requirement).
          Obx(
            () => InkWell(
              onTap: () => controller.consentGiven.toggle(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: controller.consentGiven.value,
                      onChanged: (v) =>
                          controller.consentGiven.value = v ?? false,
                      activeColor: AppColors.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  Expanded(
                    child: CustomText(
                      'I voluntarily share my Aadhaar details and consent to their use for identity verification.',
                      fontSize: SizeConfig.small,
                      color: AppColors.coloGreyText,
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: SizeConfig.paddingL),

          CustomBtn(
            title: controller.isSubmitting.value ? null : 'Submit',
            onTap: controller.isSubmitting.value
                ? null
                : () => controller.submit(),
            radius: 10.0,
            bgColor: AppColors.primaryColor,
            isLoading: controller.isSubmitting.value,
          ),
        ],
      ),
    );
  }

  Widget _uploadTile({
    required BuildContext context,
    required String title,
    required Rxn<File> target,
  }) {
    return CommonImageUploadTile(
      title: title,
      imageFile: target,
      context: context,
      onImageSelected: () async {
        final selectedPath = await CommonImageUploadTile.pickImage(
          context: context,
          cropAspectRatio: CommonImageUploadTile.documentCropAspectRatio,
        );
        if (selectedPath != null) {
          target.value = File(selectedPath);
        }
      },
    );
  }

  // ── Submitted ──────────────────────────────────────────────────────
  Widget _buildVerifiedState() {
    return Obx(() {
      final masked = controller.maskedNumber.value;
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
            'Aadhaar Verified',
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.green00,
          ),
          SizedBox(height: SizeConfig.size12),
          if (masked != null && masked.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    'Aadhaar: ',
                    fontSize: SizeConfig.small,
                    color: AppColors.coloGreyText,
                  ),
                  Flexible(
                    child: CustomText(
                      masked,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            'Your Aadhaar card has been submitted and is pending review.',
            fontSize: SizeConfig.small,
            color: AppColors.coloGreyText,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          SizedBox(height: SizeConfig.paddingM),
          CustomBtn(
            title: 'Done',
            onTap: () => Get.back(),
            radius: 10.0,
            bgColor: AppColors.primaryColor,
          ),
        ],
      );
    });
  }
}
