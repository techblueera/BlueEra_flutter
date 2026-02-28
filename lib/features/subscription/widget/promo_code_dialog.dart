import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
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


  @override
  void dispose() {
    promoCodeController.dispose();
    super.dispose();
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
                bool hasText = value.text.isNotEmpty;

                return CustomBtn(
                  width: double.infinity,
                  textColor: AppColors.white,
                  bgColor: hasText ? AppColors.greenShade : AppColors.primaryColor,
                  title: hasText ? "Submit" : "No, I Don’t have",
                  onTap: () {

                    widget.onBtnPressed(promoCodeController.text.trim());
                    // if (hasText) {
                    //   // Logic for Submit
                    //   print("Promo Code: ${promoCodeController.text}");
                    //   widget.onBtnPressed(promoCodeController.text);
                    // } else {
                    //   // Logic for closing
                    //   Navigator.pop(context);
                    // }
                  },
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}