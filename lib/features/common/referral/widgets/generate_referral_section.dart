import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GenerateReferralSection extends StatelessWidget {
  final ReferralController controller;
  final bool isEligible;
  final String initialText;

  const GenerateReferralSection({
    super.key,
    required this.controller,
    required this.isEligible,
    required this.initialText,
  });

  @override
  Widget build(BuildContext context) {
    final _referralFormKey = GlobalKey<FormState>();


    return Form(
      key: _referralFormKey,
      child: CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Row(
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.multiPersonsIcon,
                  imgColor: AppColors.secondaryTextColor,
                ),
                const SizedBox(width: 4),
                CustomText(
                  "Generate Your Referral Code",
                  fontSize: SizeConfig.large,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                )
              ],
            ),
        
            SizedBox(height: SizeConfig.paddingXSL),
        
            // 2. TextField
            CommonTextField(
              textEditController: controller.mainReferralCode,
              readOnly: !isEligible,
              focusNode: controller.referralFocusNode,
              isValidate: true,
              hintText: "Enter Your Referral Code",
              inputLength: 8,
              validator: (String? value) {
                final trimmed = value?.trim();
                if (trimmed == null || trimmed.isEmpty) {
                  return "Referral code cannot be empty";
                }
                if (trimmed.length < 4 || trimmed.length > 8) {
                  return "Referral code must be between 4 to 8 characters";
                }
                // Optional: Prevent special characters
                if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(trimmed)) {
                  return "Only letters and numbers allowed";
                }
                return null;
              },
            ),
        
            SizedBox(height: SizeConfig.paddingXSL),
        
            // 3. Submit Button
            Obx(() => Align(
              alignment: Alignment.centerRight,
              child: CustomBtn(
                width: 100,
                height: 40,
                radius: 14,
                isLoading: controller.bdmRegisterLoading.value,
                isValidate: isEligible,
                onTap: isEligible
                    ? () async {
                  if (_referralFormKey.currentState!.validate()) {
                    controller.referralFocusNode.unfocus();
                    await controller.bdmRegisterStepTwoApi();
                  }
                }
                    : null,
                title: controller.bdmRegisterLoading.value ? null : "Submit",
              ),
            )),
          ],
        ),
      ),
    );
  }
}