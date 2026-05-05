import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/onboarding/controller/business_onboarding_controller.dart';
import 'package:flutter/material.dart';

class BusinessOnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const BusinessOnboardingProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = BusinessOnboardingController.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (currentStep.clamp(0, totalSteps)) / totalSteps;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SizeConfig.size4),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 3,
          backgroundColor: AppColors.greyE5,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.mainTextColor),
        ),
      ),
    );
  }
}
