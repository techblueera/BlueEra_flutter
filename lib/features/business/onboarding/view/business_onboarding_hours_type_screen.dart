import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/onboarding/controller/business_onboarding_controller.dart';
import 'package:BlueEra/features/business/onboarding/widget/business_onboarding_progress_bar.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessOnboardingHoursTypeScreen extends StatelessWidget {
  BusinessOnboardingHoursTypeScreen({super.key});

  final controller = getOrPut(() => BusinessOnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CommonBackAppBar(isLeading: true, isShadowShow: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BusinessOnboardingProgressBar(currentStep: 2),
          SizedBox(height: SizeConfig.size30),
          CustomText(
            'Add your\nbusiness hours',
            fontSize: SizeConfig.size26,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
            child: CustomText(
              'Let customers know when you open and close each day.',
              fontSize: SizeConfig.medium,
              textAlign: TextAlign.center,
              color: AppColors.secondaryTextColor,
            ),
          ),
          SizedBox(height: SizeConfig.size30),
          _option(
            label: 'Open for selected hours',
            mode: BusinessHoursMode.selectedHours,
          ),
          _option(label: 'Always open', mode: BusinessHoursMode.alwaysOpen),
          _option(
            label: 'Appointments only',
            mode: BusinessHoursMode.appointmentsOnly,
          ),
          const Spacer(),
          _bottomButton(),
        ],
      ),
    );
  }

  Widget _option({
    required String label,
    required BusinessHoursMode mode,
  }) {
    return Obx(() {
      final selected = controller.hoursMode.value == mode;
      return InkWell(
        onTap: () => controller.setHoursMode(mode),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size12,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? AppColors.mainTextColor
                    : AppColors.grey9B,
                size: SizeConfig.size24,
              ),
              SizedBox(width: SizeConfig.size16),
              CustomText(
                label,
                fontSize: SizeConfig.large,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w400,
              ),
            ],
          ),
        ),
      );
    });
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
            final canProceed = controller.canProceedFromHoursMode;
            return CustomBtn(
              radius: SizeConfig.size30,
              isValidate: canProceed,
              bgColor: canProceed
                  ? AppColors.mainTextColor
                  : AppColors.whiteF3,
              textColor:
                  canProceed ? AppColors.white : AppColors.grey9B,
              title: 'Next',
              onTap: canProceed
                  ? () {
                      if (controller.hoursMode.value ==
                          BusinessHoursMode.selectedHours) {
                        Get.toNamed(
                          RouteHelper
                              .getBusinessOnboardingSelectHoursScreenRoute(),
                        );
                      } else {
                        Get.toNamed(
                          RouteHelper
                              .getBusinessOnboardingPhotoScreenRoute(),
                        );
                      }
                    }
                  : null,
            );
          }),
        ),
      ),
    );
  }
}
