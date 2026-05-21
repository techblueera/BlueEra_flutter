import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/onboarding/controller/business_onboarding_controller.dart';
import 'package:BlueEra/features/business/onboarding/widget/business_onboarding_progress_bar.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessOnboardingPhotoScreen extends StatelessWidget {
  BusinessOnboardingPhotoScreen({super.key});

  final controller = getOrPut(() => BusinessOnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        isLeading: true,
        isShadowShow: false,
        showRightTextButton: true,
        rightTextButtonText: 'Skip',
        rightTextButtonColor: AppColors.mainTextColor,
        onRightTextButtonTap: _next,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BusinessOnboardingProgressBar(currentStep: 4),
          SizedBox(height: SizeConfig.size20),
          CustomText(
            'Add a profile\nphoto',
            fontSize: SizeConfig.size26,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
            child: CustomText(
              'A clear image can help you attract potential customers.',
              fontSize: SizeConfig.medium,
              textAlign: TextAlign.center,
              color: AppColors.secondaryTextColor,
            ),
          ),
          SizedBox(height: SizeConfig.size40),
          Center(child: _photoPicker(context)),
          const Spacer(),
          _bottomButton(),
        ],
      ),
    );
  }

  Widget _photoPicker(BuildContext context) {
    return Obx(() {
      final path = controller.logoPath.value;
      return SizedBox(
        height: SizeConfig.size180,
        width: SizeConfig.size180,
        child: Stack(
          children: [
            ClipOval(
              child: Container(
                color: AppColors.whiteF3,
                width: SizeConfig.size180,
                height: SizeConfig.size180,
                child: path.isNotEmpty
                    ? Image.file(File(path)..existsSync(),
                        fit: BoxFit.cover)
                    : const Icon(
                        Icons.business,
                        color: AppColors.grey9B,
                        size: 60,
                      ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: InkWell(
                borderRadius: BorderRadius.circular(SizeConfig.size20),
                onTap: () => _pickPhoto(context),
                child: Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mainTextColor,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final selected = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.uploadProfilePicture,
    );
    if (selected is String && selected.isNotEmpty) {
      controller.logoPath.value = selected;
    }
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
          child: CustomBtn(
            radius: SizeConfig.size30,
            isValidate: true,
            bgColor: AppColors.mainTextColor,
            textColor: AppColors.white,
            title: 'Next',
            onTap: _next,
          ),
        ),
      ),
    );
  }

  void _next() => Get.toNamed(
      RouteHelper.getBusinessOnboardingAddressScreenRoute());
}
