import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/subscription/auth/controller/subscription_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PromoCodeDialog extends StatefulWidget {
  final Function(String) onBtnPressed;

  const PromoCodeDialog({
    super.key,
    required this.onBtnPressed,
  });

  @override
  State<PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends State<PromoCodeDialog> {
  final TextEditingController promoCodeController = TextEditingController();
  final SubscriptionController _subscriptionController =
      getOrPut(() => SubscriptionController());
  bool _isChecking = false;

  @override
  void dispose() {
    promoCodeController.dispose();
    super.dispose();
  }

  /// Validates the typed code via `subscription/check-referral` before
  /// invoking the host's callback. Centralised here so every screen that
  /// uses this dialog (subscription, individual onboarding, business
  /// onboarding) gets the same gate without duplicating the check.
  ///
  /// On invalid response we keep the dialog open so the user can correct
  /// the code — the controller's own snackbar/error state surfaces the
  /// reason. Empty code is the "No, I Don't have" path and skips the
  /// validation entirely.
  Future<void> _onSubmit(String rawCode) async {
    final code = rawCode.trim();
    if (_isChecking) return;

    if (code.isEmpty) {
      widget.onBtnPressed('');
      return;
    }

    setState(() => _isChecking = true);
    await _subscriptionController.checkReferralApi(code);
    if (!mounted) return;
    final response = _subscriptionController.checkReferralResponse.value;
    setState(() => _isChecking = false);

    // Transport-level failure (network, 5xx, etc.) — checkReferralApi
    // surfaces those itself, so just stay on the dialog.
    if (response.status != Status.COMPLETE) return;

    // 200 OK does NOT imply the code is valid: the server returns
    // `{success:true, isValid:false, message:"Referral code is invalid"}`
    // for unknown codes. Block forward progress and show the server's
    // message so the user can correct the code.
    final data = response.data;
    final isValid = data is Map ? data['isValid'] == true : false;
    if (!isValid) {
      final message = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'Referral code is invalid';
      commonSnackBar(message: message);
      return;
    }

    widget.onBtnPressed(code);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.greenShade,
              width: 0.5
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Success Icon with Circle
            LocalAssets(imagePath: AppIconAssets.questionMarkIcon),

            SizedBox(height: SizeConfig.paddingM),

            // 2. Title
            CustomText(
                'Do You Have\nPromo Code ?',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor
            ),

            SizedBox(height: SizeConfig.paddingM),

            CommonTextField(
              textEditController: promoCodeController,
              keyBoardType: TextInputType.text,
              title: 'Enter Promo Code',
              hintText: 'E.g. SAVE20',
              isValidate: false,
              isCapitalize: true,
              inputLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              validator: (value){
                final trimmedValue = value?.trim();

                // If it's empty, it's valid (optional)
                if (trimmedValue == null || trimmedValue.isEmpty) {
                  return null;
                }

                // If they typed something, enforce the rules
                if (trimmedValue.length < 4 || trimmedValue.length > 10) {
                  return "Referral code must be between 4 to 10 characters";
                }

                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z0-9]+$').hasMatch(trimmedValue)) {
                  return "Code must contain both letters and numbers";
                }

                return null;
              },
              onChange: (val) => setState(() {}),
            ),

            SizedBox(height: SizeConfig.paddingM),

            // 4. Action Button
            // --- Dynamic Button Logic ---
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: promoCodeController,
              builder: (context, value, child) {
                bool hasText = value.text.trim().isNotEmpty;
                final title = _isChecking
                    ? 'Checking…'
                    : (hasText ? 'Submit' : "No, I Don’t have");

                return CustomBtn(
                  width: double.infinity,
                  textColor: AppColors.white,
                  bgColor: hasText ? AppColors.greenShade : AppColors.primaryColor,
                  title: title,
                  onTap: _isChecking
                      ? () {}
                      : () => _onSubmit(promoCodeController.text),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}