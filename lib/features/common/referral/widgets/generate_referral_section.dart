import 'package:BlueEra/core/api/apiService/api_response.dart';
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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class GenerateReferralSection extends StatefulWidget {
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
  State<GenerateReferralSection> createState() => _GenerateReferralSectionState();
}

class _GenerateReferralSectionState extends State<GenerateReferralSection> {

  @override
  initState() {
    super.initState();
    if(widget.isEligible){
      print('referral suggestions api call');
      widget.controller.referralSuggestionsApi();
    }
  }

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
              textEditController: widget.controller.mainReferralCode,
              readOnly: !widget.isEligible,
              focusNode: widget.controller.referralFocusNode,
              isValidate: true,
              isCapitalize: true,
              hintText: "Enter Your Referral Code",
              inputLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              validator: (String? value) {
                final trimmed = value?.trim();
                if (trimmed == null || trimmed.isEmpty) {
                  return "Referral code cannot be empty";
                }
                if (trimmed.length < 4 || trimmed.length > 10) {
                  return "Referral code must be between 4 to 10 characters";
                }
                // Optional: Prevent special characters
                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z0-9]+$').hasMatch(trimmed)) {
                  return "Code must contain both letters and numbers";
                }
                return null;
              },
            ),

            // 2. Add a tiny bit of spacing
            const SizedBox(height: 6),

            // 3. The Human-Readable Helper Text
            CustomText(
              "Tip: Use 4-10 characters, mixing letters and numbers (e.g., SAVE50).",
              fontSize: SizeConfig.small,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),

            SizedBox(height: SizeConfig.paddingXSL),

            if(widget.isEligible)
            Obx(() {
              if(widget.controller.referralSuggestionsResponse.value.status == Status.INITIAL){
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  CustomText(
                    'Referral Suggestions',
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600,
                  ),

                  SizedBox(height: SizeConfig.paddingXSL),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.0),
                    margin: EdgeInsets.only(bottom: SizeConfig.paddingXSL),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        width: 1.0,
                      ),
                    ),
                    child: Wrap(
                      spacing: 10.0,    // Horizontal space between the white pills
                      runSpacing: 10.0, // Vertical space if they wrap to the next line
                      children: widget.controller.referralSuggestions.map((code) {

                        bool isSelected = widget.controller.selectedSuggestion.value == code;

                        return InkWell(
                          onTap: (){
                            widget.controller.selectedSuggestion.value = code;
                            widget.controller.mainReferralCode.text = code;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryColor : AppColors.white,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: CustomText(
                              code,
                              fontSize: SizeConfig.small,
                              color: isSelected ? AppColors.white : AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }).toList(), // Convert the mapped items back to a list
                    ),
                  ),
                ],
              );

            }),

            // 3. Submit Button
            Obx(() => Align(
              alignment: Alignment.centerRight,
              child: CustomBtn(
                width: 100,
                height: 40,
                radius: 14,
                isLoading: widget.controller.bdmRegisterLoading.value,
                isValidate: widget.isEligible,
                onTap: widget.isEligible
                    ? () async {
                  if (_referralFormKey.currentState!.validate()) {
                    widget.controller.referralFocusNode.unfocus();
                    await widget.controller.bdmRegisterStepTwoApi();
                  }
                }
                    : null,
                title: widget.controller.bdmRegisterLoading.value ? null : "Submit",
              ),
            )),
          ],
        ),
      ),
    );
  }
}