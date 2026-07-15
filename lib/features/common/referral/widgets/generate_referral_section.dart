import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// "Generate Your Referral Code" card — the entire registration form
/// in the new single-step flow. The user types or picks a code, accepts
/// the terms, and submits. Submission calls
/// [ReferralController.submitRegistration], which POSTs to step-2
/// with the referral code and re-reads `/bdm/status`.
///
/// [isEditable] gates the field and submit button so the card can also
/// be rendered as a read-only preview (e.g. once the user is COMPLETED).
///
/// [isUpdate] switches the card into "Update Referral Code" mode: the
/// submit button calls [ReferralController.updateReferralCode]
/// (`PUT wallet/referral`) instead of the BDM registration step, the
/// terms row is hidden, and the screen pops on success. Used by the
/// referral dashboard's "Update Referral Code" flow.
class GenerateReferralSection extends StatefulWidget {
  final ReferralController controller;
  final bool isEditable;
  final bool isUpdate;

  const GenerateReferralSection({
    super.key,
    required this.controller,
    required this.isEditable,
    this.isUpdate = false,
  });

  @override
  State<GenerateReferralSection> createState() => _GenerateReferralSectionState();
}

class _GenerateReferralSectionState extends State<GenerateReferralSection> {
  final _formKey = GlobalKey<FormState>();
  late final TapGestureRecognizer _tncRecognizer;

  @override
  void initState() {
    super.initState();
    _tncRecognizer = TapGestureRecognizer()..onTap = _openTermsAndConditions;
    if (widget.isEditable) {
      widget.controller.fetchSuggestions();
    }
  }

  @override
  void dispose() {
    _tncRecognizer.dispose();
    super.dispose();
  }

  void _openTermsAndConditions() {
    Get.to(
      () => CommonWebView(
        urlLink: tncLink,
        urlTitle: AppStrings.termsConditions.tr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Form(
      key: _formKey,
      child: CustomFormCard(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.multiPersonsIcon,
                  imgColor: AppColors.secondaryTextColor,
                ),
                const SizedBox(width: 4),
                CustomText(
                  AppStrings.generateYourReferralCode.tr,
                  fontSize: SizeConfig.large,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                ),
              ],
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            CommonTextField(
              textEditController: c.referralCodeController,
              readOnly: !widget.isEditable,
              focusNode: c.referralFocusNode,
              isValidate: true,
              isCapitalize: true,
              hintText: AppStrings.enterYourReferralCode.tr,
              inputLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              validator: (value) {
                final trimmed = value?.trim();
                if (trimmed == null || trimmed.isEmpty) {
                  return 'Referral code cannot be empty';
                }
                if (trimmed.length < 4 || trimmed.length > 10) {
                  return 'Referral code must be between 4 to 10 characters';
                }
                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z0-9]+$').hasMatch(trimmed)) {
                  return 'Code must contain both letters and numbers';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            CustomText(
              AppStrings.referralTip.tr,
              fontSize: SizeConfig.small,
              color: Colors.grey.shade600,
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            if (widget.isEditable) _buildSuggestions(c),
            _buildTermsRow(c),
            SizedBox(height: SizeConfig.paddingXSL),
            Obx(() {
              final loading =
                  widget.isUpdate ? c.updateLoading.value : c.registerLoading.value;
              final enabled = widget.isEditable && c.termsAccepted.value;
              return Align(
                alignment: Alignment.center,
                child: CustomBtn(
                  height: 40,
                  radius: 8,
                  isLoading: loading,
                  isValidate: enabled,
                  onTap: enabled
                      ? () async {
                          if (_formKey.currentState!.validate()) {
                            c.referralFocusNode.unfocus();
                            final ok = await c.updateReferralCode(
                                c.referralCodeController.text);
                            if (ok) Get.back();
                          }
                        }
                      : null,
                  title: loading ? null : (widget.isUpdate ? 'Update' : 'Submit'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(ReferralController c) {
    return Obx(() {
      if (c.suggestionsResponse.value.status == Status.LOADING ||
          c.suggestionsResponse.value.status == Status.INITIAL) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (c.referralSuggestions.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.referralSuggestions.tr,
            fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: EdgeInsets.only(bottom: SizeConfig.paddingXSL),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            // Chip selection is derived from the live text-field value so:
            //   1. coming back to the screen with a pre-filled code still
            //      highlights the matching chip, and
            //   2. typing a code by hand highlights the chip too.
            // AnimatedBuilder rebuilds on every keystroke; the comparison
            // is case-insensitive because the field auto-capitalises.
            child: AnimatedBuilder(
              animation: c.referralCodeController,
              builder: (_, __) {
                final current = c.referralCodeController.text.trim().toUpperCase();
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: c.referralSuggestions.map((code) {
                    final selected = current.isNotEmpty && code.trim().toUpperCase() == current;
                    return InkWell(
                      onTap: () => c.selectSuggestion(code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryColor : AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomText(
                          code,
                          fontSize: SizeConfig.small,
                          color: selected ? AppColors.white : AppColors.secondaryTextColor,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTermsRow(ReferralController c) {
    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: c.termsAccepted.value,
              onChanged: widget.isEditable ? (v) => c.termsAccepted.value = v ?? false : null,
              activeColor: AppColors.primaryColor,
              checkColor: AppColors.white,
              side: const BorderSide(color: AppColors.greyLite),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
                children: [
                  TextSpan(text: '${AppStrings.iAcceptAll.tr} '),
                  TextSpan(
                    text: AppStrings.termsAndCondition.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.small,
                    ),
                    recognizer: _tncRecognizer,
                  ),
                  TextSpan(
                    text: ' ${AppStrings.authorizationMessage.tr}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
