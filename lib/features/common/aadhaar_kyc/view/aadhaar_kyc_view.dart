import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/controller/aadhaar_kyc_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

/// Reusable Aadhaar OKYC (OTP) verification widget.
///
/// Drives the generic per-user Aadhaar identity verification flow:
///   status → enter Aadhaar + consent → generate OTP → verify OTP → verified.
/// Pass an [AadhaarKycController] whose `onVerified` bridges the result into
/// the host flow. See docs/backend/aadhaar-verification-ui-integration.md.
class AadhaarKycView extends StatefulWidget {
  const AadhaarKycView({super.key, required this.controller});

  final AadhaarKycController controller;

  @override
  State<AadhaarKycView> createState() => _AadhaarKycViewState();
}

class _AadhaarKycViewState extends State<AadhaarKycView> {
  AadhaarKycController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Reset the flow and fetch current verification status on open.
    controller.init();
  }

  @override
  void dispose() {
    controller.disposeFlow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Obx(() {
        if (controller.isStatusLoading.value) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        switch (controller.stage.value) {
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
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonTextField(
            textEditController: controller.aadharController,
            title: AppStrings.aadharNumber,
            hintText: 'E.g. 5678 1234 6679 9012',
            keyBoardType: TextInputType.number,
            validator: ValidationMethod.validateAadhaar,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 12,
          ),
          SizedBox(height: SizeConfig.paddingS),

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
                      'I voluntarily share my Aadhaar number and consent to its use for identity verification.',
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
              title: controller.isOtpSending.value ? null : 'Send OTP',
              onTap: controller.isOtpSending.value
                  ? null
                  : () => controller.generateOtp(),
              radius: 10.0,
              bgColor: AppColors.primaryColor,
              isLoading: controller.isOtpSending.value,
            ),
          ),
        ],
      ),
    );
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
          'Enter the 6-digit OTP',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(
          'Sent to your Aadhaar-linked mobile number',
          fontSize: SizeConfig.small,
          color: AppColors.coloGreyText,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: SizeConfig.paddingM),
        Pinput(
          controller: controller.otpController,
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
                "Didn't get the OTP?",
                fontSize: SizeConfig.small,
                color: AppColors.coloGreyText,
              ),
              if (controller.resendSeconds.value > 0)
                CustomText(
                  'Resend in ${controller.resendSeconds.value}s',
                  fontSize: SizeConfig.small,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                )
              else
                InkWell(
                  onTap: () => controller.generateOtp(),
                  child: CustomText(
                    'Resend OTP',
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
            title: controller.isOtpVerifying.value ? null : 'Verify OTP',
            onTap: controller.isOtpVerifying.value
                ? null
                : () => controller.verifyOtp(),
            radius: 10.0,
            bgColor: AppColors.primaryColor,
            isLoading: controller.isOtpVerifying.value,
          ),
        ),
        SizedBox(height: SizeConfig.size10),
        InkWell(
          onTap: () => controller.editNumber(),
          child: CustomText(
            '✎ Edit Aadhaar number',
            fontSize: SizeConfig.small,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Stage 3: verified ──────────────────────────────────────────────
  Widget _buildVerifiedState() {
    return Obx(() {
      final name = controller.verifiedName.value;
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
          if (name != null && name.isNotEmpty) _infoRow('Name', name),
          if (masked != null && masked.isNotEmpty) _infoRow('Aadhaar', masked),
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
