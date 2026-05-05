import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/onboarding/controller/business_onboarding_controller.dart';
import 'package:BlueEra/features/business/onboarding/widget/business_onboarding_progress_bar.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class BusinessOnboardingDescriptionScreen extends StatelessWidget {
  BusinessOnboardingDescriptionScreen({super.key});

  final controller = getOrPut(() => BusinessOnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CommonBackAppBar(isLeading: true, isShadowShow: false),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            const BusinessOnboardingProgressBar(currentStep: 6),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              'Add a business\ndescription',
              fontSize: SizeConfig.size26,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
              child: CustomText(
                'Tell potential customers what you do and why they should choose you.',
                fontSize: SizeConfig.medium,
                textAlign: TextAlign.center,
                color: AppColors.secondaryTextColor,
              ),
            ),
            SizedBox(height: SizeConfig.size20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size12,
                  vertical: SizeConfig.size12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.greyE5),
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                ),
                child: TextField(
                  controller: controller.descriptionController,
                  maxLines: 6,
                  maxLength:
                      BusinessOnboardingController.maxDescriptionChars,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      BusinessOnboardingController.maxDescriptionChars,
                    ),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    hintText: 'Description',
                  ),
                  onChanged: controller.setDescription,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                right: SizeConfig.size20,
                top: SizeConfig.size4,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(() => CustomText(
                      '${controller.descriptionLength.value} / ${BusinessOnboardingController.maxDescriptionChars}',
                      fontSize: SizeConfig.medium,
                      color: AppColors.grey9B,
                    )),
              ),
            ),
            const Spacer(),
            _bottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton() {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size12,
          ),
          child: Obx(() {
            final loading = controller.isSubmitting.value;
            final canProceed =
                controller.descriptionController.text.trim().isNotEmpty;
            return CustomBtn(
              radius: SizeConfig.size30,
              isValidate: canProceed,
              isLoading: loading,
              bgColor: canProceed
                  ? AppColors.mainTextColor
                  : AppColors.whiteF3,
              textColor:
                  canProceed ? AppColors.white : AppColors.grey9B,
              title: 'Next',
              onTap: (canProceed && !loading) ? controller.submit : null,
            );
          }),
        ),
      ),
    );
  }
}
