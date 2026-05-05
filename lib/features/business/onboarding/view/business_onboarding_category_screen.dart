import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/onboarding/controller/business_onboarding_controller.dart';
import 'package:BlueEra/features/business/onboarding/widget/business_onboarding_progress_bar.dart';
import 'package:BlueEra/features/common/auth/model/business_category_response_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessOnboardingCategoryScreen extends StatefulWidget {
  const BusinessOnboardingCategoryScreen({super.key});

  @override
  State<BusinessOnboardingCategoryScreen> createState() =>
      _BusinessOnboardingCategoryScreenState();
}

class _BusinessOnboardingCategoryScreenState
    extends State<BusinessOnboardingCategoryScreen> {
  final controller =
      getOrPut(() => BusinessOnboardingController(), permanent: true);

  @override
  void initState() {
    super.initState();
    controller.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CommonBackAppBar(isLeading: true, isShadowShow: false),
      body: Column(
        children: [
          const BusinessOnboardingProgressBar(currentStep: 1),
          SizedBox(height: SizeConfig.size20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
            child: CustomText(
              'Select your business category',
              fontSize: SizeConfig.size26,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
              color: AppColors.mainTextColor,
            ),
          ),
          SizedBox(height: SizeConfig.size10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
            child: CustomText(
              'Choose the category that best represents your business.',
              fontSize: SizeConfig.medium,
              textAlign: TextAlign.center,
              color: AppColors.secondaryTextColor,
            ),
          ),
          SizedBox(height: SizeConfig.size20),
          Expanded(
            child: Obx(() {
              if (controller.isCategoriesLoading.value &&
                  controller.allCategories.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                );
              }
              return _buildCategoryWrap();
            }),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryWrap() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size4,
      ),
      child: Obx(() {
        final all = controller.allCategories;
        final showAll = controller.showAllCategories.value;
        final visible = (showAll || all.length <= 9)
            ? all
            : all.sublist(0, 9);
        return Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size12,
              children: visible
                  .map((c) => _CategoryChip(
                        category: c,
                        controller: controller,
                      ))
                  .toList(),
            ),
            if (all.length > 9)
              Padding(
                padding: EdgeInsets.only(top: SizeConfig.size16),
                child: TextButton.icon(
                  onPressed: () => controller.showAllCategories.toggle(),
                  icon: Icon(
                    showAll ? Icons.remove : Icons.add,
                    color: AppColors.mainTextColor,
                    size: SizeConfig.size20,
                  ),
                  label: CustomText(
                    showAll ? 'Show less' : 'See more categories',
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: SizeConfig.size20),
          ],
        );
      }),
    );
  }

  Widget _buildBottomButton() {
    return Material(
      elevation: 0,
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size12,
          ),
          child: Obx(() {
            final canProceed = controller.canProceedFromCategory;
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
                  ? () => Get.toNamed(
                        RouteHelper
                            .getBusinessOnboardingHoursTypeScreenRoute(),
                      )
                  : null,
            );
          }),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final BusinessCategory category;
  final BusinessOnboardingController controller;

  const _CategoryChip({
    required this.category,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.isCategorySelected(category);
      return InkWell(
        borderRadius: BorderRadius.circular(SizeConfig.size30),
        onTap: () => controller.toggleCategory(category),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.mainTextColor.withValues(alpha: 0.08)
                : AppColors.whiteF3,
            borderRadius: BorderRadius.circular(SizeConfig.size30),
            border: Border.all(
              color: selected
                  ? AppColors.mainTextColor
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: CustomText(
            category.name ?? '',
            fontSize: SizeConfig.medium,
            color: AppColors.mainTextColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );
    });
  }
}
