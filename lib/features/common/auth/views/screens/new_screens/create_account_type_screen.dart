import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/onboarding_category_model.dart';
import 'package:BlueEra/features/common/auth/views/widget/business_category_selection_dialog.dart';
import 'package:BlueEra/features/common/auth/views/widget/gradient_border_container.dart';
import 'package:BlueEra/features/common/auth/views/widget/business_sub_category_selection_dialog.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../model/get_categories_model.dart';

class CreateAccountTypeScreen extends StatefulWidget {

  const CreateAccountTypeScreen({super.key});

  @override
  State<CreateAccountTypeScreen> createState() => _CreateAccountTypeScreenState();
}

class _CreateAccountTypeScreenState extends State<CreateAccountTypeScreen> {
  final authController = getOrPut(() => AuthController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.selectedIndividualOnboardingProfile.value = OnBoardingCategoryModel(
        name: 'Social profile',
        slugId: SOCIAL_PROFILE,
        icon: AppIconAssets.politicianIcon,
        accountType: AppConstants.individual,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (!isGuestUser()) {
          commonConformationDialog(
            context: context,
            text: AppStrings.areYouSureYouWantToExitTheApp, // not in JSON yet
            confirmCallback: () async {
              await SharedPreferenceUtils.clearPreference();
              Navigator.of(context).pushNamedAndRemoveUntil(
                RouteHelper.getMobileNumberLoginRoute(),
                    (Route<dynamic> route) => false,
              );
              // Get.close(2);
            },
            cancelCallback: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          );
        } else {
          Navigator.of(context).pop(); // Close the dialog
        }
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          isLeading: true,
          appBarColor: Colors.white,
          title: AppStrings.chooseYourAccountType,
          onBackTap: () {
            if (!isGuestUser()) {
              commonConformationDialog(
                context: context,
                text: AppStrings.areYouSureYouWantToExitTheApp, // not in JSON yet
                confirmCallback: () async {
                  await SharedPreferenceUtils.clearPreference();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    RouteHelper.getMobileNumberLoginRoute(),
                        (Route<dynamic> route) => false,
                  );
                },
                cancelCallback: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              );
            } else {
              Navigator.of(context).pop(); // Close the dialog
            }
          },
        ),
        body: SafeArea(
            child:
            // Obx(()=> authController.isAppLoading.value
            //     ? const Center(child: CircularProgressIndicator())
            //     :
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                accountTypesList(),
                Expanded(
                    child: Obx(
                       () {
                        if (authController.selectedParentSlug.value == AppConstants.individual) {
                          switch (authController.selectedIndividualOnboardingProfile.value?.slugId) {
                            case SOCIAL_PROFILE:
                              return _socialProfilesContent(
                                  key: ValueKey(SOCIAL_PROFILE),
                                  arrIndividualCategory: individualOnboardingSocialProfileList);
                            case SELF_EMPLOYED:
                              return _selfWorkContent(
                                  key: ValueKey(SELF_EMPLOYED),
                                  arrSelfWorkTransportCategory: individualOnboardingSelfWorkTransportList,
                                  arrSelfWorkSkilledCategory: individualOnboardingSelfSkillWorkList
                              );
                            case CONSULTANT:
                              return _consultationContent(
                                  key: ValueKey(CONSULTANT),
                                  arrConsultationsCategory: individualOnboardingConsultationList);
                          }
                        } else {
                          switch (authController.selectedBusinessOnboardingProfile.value?.slugId) {
                            case FOOD:
                              return _foodNdGroceryContent(
                                  key: ValueKey(FOOD),
                                  arrGroceryCategory: businessOnboardingGroceriesCategories,
                                  arrFoodNdRestaurantCategory: businessOnboardingFoodsCategories,
                              );
                            case PRODUCT:
                              return _businessContent(
                                  key: ValueKey(PRODUCT),
                                  arrBusinessCategory: businessOnboardingProductsCategories);
                            case SERVICE:
                              return _businessContent(
                                  key: ValueKey(SERVICE),
                                  arrBusinessCategory: businessOnboardingServicesCategories);
                            case MANUFACTURING:
                              return _businessContent(
                                  key: ValueKey(MANUFACTURING),
                                  arrBusinessCategory: businessOnboardingManufacturingCategories);
                          }
                        }

                        return const SizedBox();
                      },
                    )
                ),
              ],
            ),
            // )
        )
      ),
    );
  }

  Widget accountTypesList() {
    return Container(
      width: 94,
      height: SizeConfig.screenHeight,
      color: AppColors.white,
      child: ListView(
        children: [
          Column(
            children: [

              SizedBox(
                height: SizeConfig.paddingXSL,
              ),

              Container(
                color: AppColors.lightGreenShade.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    GradientBorderContainer(
                      title: "Personal",
                      gradientColor: AppColors.lightGreenShade,
                    ),

                    ListView.builder(
                      itemCount: individualOnboardingProfilesCategory.length,
                      padding: EdgeInsets.only(bottom: SizeConfig.size20),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        var category = individualOnboardingProfilesCategory[index];
                        return Obx(()=> _categoryItem(
                          category.icon,
                          category.name,
                          selected: authController.selectedIndividualOnboardingProfile.value!=null
                              ? authController.selectedIndividualOnboardingProfile.value?.slugId == category.slugId
                              : false,
                          selectedColor: AppColors.lightGreenShade,
                          onTap: () {
                            authController.selectedIndividualOnboardingProfile.value = category;
                            authController.selectedBusinessOnboardingProfile.value = null;
                            authController.selectedParentSlug.value = AppConstants.individual;
                            // controller.selectedTabIndex.value = 0;
                            // log('new selection ${controller.selectedGroceryData.value}');
                            //
                            // /// api call
                            // controller.fetchBoth();

                          },
                        ));
                      },
                    ),
                  ],
                ),
              ),

              Container(
                color: AppColors.blueShade.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    GradientBorderContainer(
                      title: "Business",
                      gradientColor: AppColors.blueShade,
                    ),

                    ListView.builder(
                      itemCount: businessOnboardingProfilesCategory.length,
                      padding: EdgeInsets.only(bottom: SizeConfig.size30),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        var category = businessOnboardingProfilesCategory[index];
                        return Obx(()=> _categoryItem(
                          category.icon,
                          category.name,
                          selected: authController.selectedBusinessOnboardingProfile.value!=null
                              ? authController.selectedBusinessOnboardingProfile.value?.slugId == category.slugId
                              : false,
                          selectedColor: AppColors.blueShade,
                          onTap: () {
                            authController.selectedBusinessOnboardingProfile.value = category;
                            authController.selectedIndividualOnboardingProfile.value = null;
                            authController.selectedParentSlug.value = AppConstants.business;
                            // controller.selectedTabIndex.value = 0;
                            // log('new selection ${controller.selectedGroceryData.value}');
                            //
                            // /// api call
                            // controller.fetchBoth();

                          },
                        ));
                      },
                    ),
                  ],
                ),
              )


            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(
      String icon,
      String label,
      { bool selected = false,
        required Color selectedColor,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: selected ? 10 : 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            gradient: selected ? LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                selectedColor.withValues(alpha: 0.4),
                selectedColor.withValues(alpha: 0.1),
              ],
            ) : null,
            borderRadius: BorderRadius.circular(4),
            border: selected
                ? Border(
                left: BorderSide(
                    color: selectedColor,
                    width: 4,
                    style: BorderStyle.solid))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white),
                  padding: EdgeInsets.all(8),
                  // padding: EdgeInsets.all(selected ? 10 : 0),
                  child:
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack, // Gives a "pop" effect
                    height: selected ? 44 : 38, // Grow from 40 to 50
                    width: selected ? 44 : 38,
                    child: LocalAssets(
                      imagePath: icon,
                      height: selected ? 44 : 38,
                      width: selected ? 44 : 38,
                      // boxFix: BoxFit.contain, // Ensure image scales correctly
                    ),
                  ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                style: TextStyle(
                  fontSize: selected ? 11 : 10,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.mainTextColor : AppColors.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  // Remove style here since AnimatedDefaultTextStyle handles it
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialProfilesContent({
    Key? key,
    required List<OnBoardingCategoryModel> arrIndividualCategory}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: arrIndividualCategory.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var item = arrIndividualCategory[index];
              return _commonCard(item, textMaxLine: 1);
            },
            padding: EdgeInsets.only(bottom: SizeConfig.size16),
            shrinkWrap: true,
          ),

          _otherOptionCreation()
        ],
      ),
    );
  }

  Widget _selfWorkContent({
    Key? key,
    required List<OnBoardingCategoryModel> arrSelfWorkTransportCategory,
    required List<OnBoardingCategoryModel> arrSelfWorkSkilledCategory,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
              'Self Work (Transport)',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: arrSelfWorkTransportCategory.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var item = arrSelfWorkTransportCategory[index];
              return _commonCard(item, textMaxLine: 1);
            },
            padding: EdgeInsets.zero,
            shrinkWrap: true,
          ),

          SizedBox(height: SizeConfig.paddingM),

          CustomText(
              'Self Work (Skill Work)',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: arrSelfWorkSkilledCategory.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var item = arrSelfWorkSkilledCategory[index];
              return _commonCard(item, textMaxLine: 1);
            },
            padding: EdgeInsets.only(bottom: SizeConfig.size16),
            shrinkWrap: true,
          ),

          _otherOptionCreation()
        ],
      ),
    );
  }

  Widget _consultationContent({
    Key? key,
    required List<OnBoardingCategoryModel> arrConsultationsCategory}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: AppColors.redLite.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: AppColors.redLite,
              )
            ),
            child: CustomText(
                'If You Have Any Consulting Farm Then Choose business-service Account',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: AppColors.redLite
            ),
          ),

          SizedBox(height: SizeConfig.paddingM),

          CustomText(
              'For Individual - Choose Your Sector',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: arrConsultationsCategory.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var item = arrConsultationsCategory[index];
              return _commonCard(item, textMaxLine: 2);
            },
            padding: EdgeInsets.only(bottom: SizeConfig.size16),
            shrinkWrap: true,
          ),

          _otherOptionCreation()
        ],
      ),
    );
  }

  Widget _foodNdGroceryContent({
    Key? key,
    required List<OnBoardingCategoryModel> arrGroceryCategory,
    required List<OnBoardingCategoryModel> arrFoodNdRestaurantCategory,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
              'Grocery',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: arrGroceryCategory.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var item = arrGroceryCategory[index];
              return _commonCard(item, textMaxLine: 1);
            },
            padding: EdgeInsets.zero,
            shrinkWrap: true,
          ),

          SizedBox(height: SizeConfig.paddingM),

          CustomText(
              'Food & Restaurant',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: arrFoodNdRestaurantCategory.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              var item = arrFoodNdRestaurantCategory[index];
              return _commonCard(item, textMaxLine: 2);
            },
            padding: EdgeInsets.only(bottom: SizeConfig.size16),
            shrinkWrap: true,
          ),

          _otherOptionCreation()
        ],
      ),
    );
  }

  Widget _businessContent({
    Key? key,
    required List<OnBoardingCategoryModel> arrBusinessCategory}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            physics: NeverScrollableScrollPhysics(),
            itemCount: arrBusinessCategory.length,
            itemBuilder: (context, index) {
              var item = arrBusinessCategory[index];
              return _commonCard(item, textMaxLine: 2);
            },
            padding: EdgeInsets.only(bottom: SizeConfig.size16),
            shrinkWrap: true,
          ),

          _otherOptionCreation()
        ],
      ),
    );
  }

  Widget _commonCard(OnBoardingCategoryModel category, {int? textMaxLine}) {
    return GestureDetector(
      onTap: () {
        if(category.accountType == AppConstants.business){
          if(category.businessType == BusinessType.Manufacturing){
            if(category.businessType == null) return;
            navigateToGstScreen(
                context,
                businessType: category.businessType!,
                categorySlugId: category.slugId,
                categoryName: category.name,
            );
          } else if(category.businessType == BusinessType.Motel ||
              category.businessType == BusinessType.Healthcare ||
              category.businessType == BusinessType.Siksha){
            _showBusinessCategoryDialog(category.businessType!);
          }else{
            _showBusinessSubCategoryDialog(
                businessType: category.businessType!,
                categorySlugId: category.slugId,
                categoryName: category.name
            );
          }
        }else{
          log("---------------- LOG DATA ----------------");
          log("${ApiKeys.argProfileType} : ${category.individualType?.tagId}");
          log("${ApiKeys.argProfessionTagId}    : ${category.slugId}");
          log("${ApiKeys.argProfession}    : ${category.name}");
          log("------------------------------------------");

          Get.toNamed(
            RouteHelper.getPersonalAccountNewScreenRoute(),
            arguments: {
              ApiKeys.argAccountType: AppConstants.individual,
              ApiKeys.argProfileType: category.individualType,
              ApiKeys.argProfessionTagId: category.slugId,
              ApiKeys.argProfession: category.name,
            },
          );

        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.greyE5
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: SizedBox(
                height: SizeConfig.size130,
                width: double.infinity,
                child: LocalAssets(
                  imagePath: category.icon,
                  boxFix: BoxFit.fill,
                  height: SizeConfig.size140,
                  width: double.infinity,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size8,
                  vertical: SizeConfig.size8
              ),
              child: CustomText(
                category.name,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
                maxLines: textMaxLine,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otherOptionCreation(){
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(bottom: SizeConfig.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
              'Others',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor
          ),
          SizedBox(
            height: SizeConfig.size6,
          ),
          CustomText(
              'If you do not find a suitable option, you can create one here. Please proceed without concern',
              fontSize: SizeConfig.extraSmall,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor
          ),
        ],
      ),
    );
  }

  Future<void> _showBusinessSubCategoryDialog({
    required BusinessType businessType,
    required String categorySlugId,
    required String categoryName
  }) async {

    // 1. Show the Dialog and wait for result
    final SubCategories? selected = await showDialog<SubCategories>(
      context: context,
      builder: (context) {
        return BusinessSubCategorySelectionDialog(
          authController: authController,
          businessType: businessType,
          categorySlugId: categorySlugId,
          categoryName: categoryName
        );
      },
    );

    // 2. If user selected something and clicked Next
    if (selected != null) {
      navigateToGstScreen(
          context,
          businessType: businessType,
          categorySlugId: categorySlugId,
          categoryName: categoryName,
          subCategory: selected
       );
     }
    }

  void navigateToGstScreen(
      BuildContext context, {
        required BusinessType businessType,
        required String categorySlugId,
        required String categoryName,
        SubCategories? subCategory,
      }) {
    Navigator.pushNamed(
      context,
      RouteHelper.getGstNumberScreenRoute(),
      arguments: {
        ApiKeys.argAccountType: AppConstants.business,
        ApiKeys.argBusinessType: businessType,
        ApiKeys.argCategoryId: categorySlugId,
        ApiKeys.argCategoryName: categoryName,
        ApiKeys.argSubCategory: subCategory,
      },
    );
  }

  Future<void>  _showBusinessCategoryDialog(BusinessType businessType){
    return showDialog<SubCategories>(
      context: context,
      builder: (context) {
        return BusinessCategorySelectionDialog(
            authController: authController,
            businessType: businessType
        );
      },
    );
  }

}

