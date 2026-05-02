import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable referral / promo code entry dialog. Validates the typed code
/// via `wallet-service/wallet/check-referral` (UserRepo) before invoking
/// the host's callback. Empty code is the "No, I Don't have" path and
/// skips validation.
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
  bool _isChecking = false;

  @override
  void dispose() {
    promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(String rawCode) async {
    final code = rawCode.trim();
    if (_isChecking) return;

    if (code.isEmpty) {
      widget.onBtnPressed('');
      return;
    }

    setState(() => _isChecking = true);
    final res = await UserRepo().checkReferralRepo(code);
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (!res.isSuccess) return;

    // 200 OK does NOT imply the code is valid: server returns
    // `{success:true, isValid:false, message:"Referral code is invalid"}`
    // for unknown codes. Block forward progress and show the server's
    // message so the user can correct the code.
    final data = res.response?.data;
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
          border: Border.all(color: AppColors.greenShade, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(imagePath: AppIconAssets.questionMarkIcon),
            SizedBox(height: SizeConfig.paddingM),
            CustomText(
              'Do You Have\nPromo Code ?',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.mainTextColor,
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
              validator: (value) {
                final trimmedValue = value?.trim();
                if (trimmedValue == null || trimmedValue.isEmpty) return null;
                if (trimmedValue.length < 4 || trimmedValue.length > 10) {
                  return "Referral code must be between 4 to 10 characters";
                }
                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z0-9]+$')
                    .hasMatch(trimmedValue)) {
                  return "Code must contain both letters and numbers";
                }
                return null;
              },
              onChange: (val) => setState(() {}),
            ),
            SizedBox(height: SizeConfig.paddingM),
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
                  bgColor:
                      hasText ? AppColors.greenShade : AppColors.primaryColor,
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
