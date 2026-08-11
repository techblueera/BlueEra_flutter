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
  const AadhaarKycView({
    super.key,
    required this.controller,
    this.onVerifyManually,
    this.onDone,
    this.doneLabel,
  });

  final AadhaarKycController controller;

  /// What the verified stage's button does. Defaults to closing the host —
  /// right for the bottom sheets, wrong for a full-page step in a wizard,
  /// where the button has to carry the user FORWARD rather than back to the
  /// screen they came from.
  final VoidCallback? onDone;

  /// Label for that button. Defaults to "Done".
  final String? doneLabel;


  /// Opens the host's manual (image-based) verification fallback, receiving
  /// whatever Aadhaar number is currently typed so it can be prefilled.
  ///
  /// A "Verify manually" link appears once OTP verification has failed. Leave
  /// null on hosts with no manual fallback — the link is then never shown.
  final void Function(String enteredAadhaarNumber)? onVerifyManually;

  @override
  State<AadhaarKycView> createState() => _AadhaarKycViewState();
}

class _AadhaarKycViewState extends State<AadhaarKycView> {
  AadhaarKycController get controller => widget.controller;

  /// Held here so a rejected code can hand focus straight back to the pins —
  /// see [_submitOtp].
  final FocusNode _otpFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Reset the flow and fetch current verification status on open.
    controller.init();
  }

  @override
  void dispose() {
    _otpFocus.dispose();
    controller.disposeFlow();
    super.dispose();
  }

  /// Verify as soon as the sixth digit lands — there is nothing left to decide
  /// once the code is complete, so a Verify button was only ever an extra tap
  /// between the user and the answer.
  ///
  /// A wrong code clears the pins and takes focus back, because auto-submit
  /// otherwise strands them: the field stays full, so no further completion
  /// event fires and they would have to delete six digits by hand to retry.
  Future<void> _submitOtp() async {
    if (controller.isOtpVerifying.value) return;
    FocusScope.of(context).unfocus();
    await controller.verifyOtp();
    if (!mounted) return;
    if (controller.stage.value == AadhaarStage.otp) {
      controller.otpController.clear();
      _otpFocus.requestFocus();
    }
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
          _buildManualFallback(),
        ],
      ),
    );
  }

  /// Link-style escape hatch to manual (image-based) verification, for hosts
  /// that push it as a separate screen.
  ///
  /// Offered only once OTP verification has actually failed, so the OTP path
  /// stays the default and the fallback appears exactly when it's useful.
  Widget _buildManualFallback() {
    final onVerifyManually = widget.onVerifyManually;
    if (onVerifyManually == null) return const SizedBox.shrink();

    return Obx(() {
      if (!controller.otpFailed.value) return const SizedBox.shrink();
      return Column(
        children: [
          SizedBox(height: SizeConfig.paddingM),
          Divider(color: AppColors.greyE5, height: 1),
          SizedBox(height: SizeConfig.paddingM),
          CustomText(
            "Can't verify with OTP?",
            fontSize: SizeConfig.small,
            color: AppColors.coloGreyText,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size6),
          InkWell(
            onTap: () => onVerifyManually(controller.aadharController.text),
            child: CustomText(
              'Verify by uploading Aadhaar card',
              fontSize: SizeConfig.small,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      );
    });
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
        Obx(
          () => Pinput(
            controller: controller.otpController,
            focusNode: _otpFocus,
            length: 6,
            autofocus: true,
            // Locked while the code is in flight so a stray tap can't edit the
            // digits being checked.
            enabled: !controller.isOtpVerifying.value,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            // No Verify button: the sixth digit submits. Nothing is left to
            // decide once the code is complete.
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
            child: controller.isOtpVerifying.value
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
              // Sending — the request is in flight. Inert text with a spinner
              // rather than a live link: the tap has already been accepted, and
              // a second one is refused by the controller anyway.
              else if (controller.isOtpSending.value)
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
                      'Sending OTP…',
                      fontSize: SizeConfig.small,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
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
        SizedBox(height: SizeConfig.size10),
        // Kept, unlike the delivery-partner sheet this mirrors: that one moved
        // "edit number" to a back arrow in its sheet header, and neither host
        // of this view has one — without this there is no way back to the
        // number after a typo.
        InkWell(
          onTap: () => controller.editNumber(),
          child: CustomText(
            '✎ Edit Aadhaar number',
            fontSize: SizeConfig.small,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        _buildManualFallback(),
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
            title: widget.doneLabel ?? 'Done',
            onTap: widget.onDone ?? () => Get.back(),
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
