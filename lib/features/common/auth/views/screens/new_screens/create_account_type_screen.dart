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
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/auth/views/widget/business_category_selection_dialog.dart';
import 'package:BlueEra/features/common/auth/views/widget/business_sub_category_selection_dialog.dart';
import 'package:BlueEra/features/common/auth/views/widget/gradient_border_container.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../model/get_categories_model.dart';

class CreateAccountTypeScreen extends StatefulWidget {
  final String? accountType;

  /// When [accountType] is [AppConstants.individual], this chooses which
  /// entry in [individualOnboardingProfilesCategory] is preselected on
  /// entry. Used by [ChooseAccountTypeScreen] so the Professional card
  /// lands on "Skill Work / Self Employee" (index 1) and the Personal
  /// card lands on "Social profile" (index 0).
  final int initialIndividualIndex;

  const CreateAccountTypeScreen({
    super.key,
    this.accountType,
    this.initialIndividualIndex = 0,
  });

  @override
  State<CreateAccountTypeScreen> createState() => _CreateAccountTypeScreenState();
}

class _CreateAccountTypeScreenState extends State<CreateAccountTypeScreen> {
  final authController = getOrPut(() => AuthController());

  bool get _showIndividualSidebar =>
      widget.accountType == null ||
      widget.accountType == AppConstants.individual;

  bool get _showBusinessSidebar =>
      widget.accountType == null ||
      widget.accountType == AppConstants.business;

  @override
  void initState() {
    super.initState();
    authController.getAllIndividualProfession();
    authController.getAllBusinessCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.accountType == AppConstants.business) {
        authController.selectedIndividualOnboardingProfile.value = null;
        authController.selectedBusinessOnboardingProfile.value =
            businessOnboardingProfilesCategory.first;
        authController.selectedParentSlug.value = AppConstants.business;
      } else {
        authController.selectedBusinessOnboardingProfile.value = null;
        // Clamp the incoming index so an out-of-bounds value still
        // falls back to the first item safely.
        final idx = widget.initialIndividualIndex.clamp(
          0,
          individualOnboardingProfilesCategory.length - 1,
        );
        authController.selectedIndividualOnboardingProfile.value =
            individualOnboardingProfilesCategory[idx];
        authController.selectedParentSlug.value = AppConstants.individual;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // if (!isGuestUser()) {
        //   commonConformationDialog(
        //     context: context,
        //     text: AppStrings.areYouSureYouWantToExitTheApp, // not in JSON yet
        //     confirmCallback: () async {
        //       await SharedPreferenceUtils.clearPreference();
        //       Navigator.of(context).pushNamedAndRemoveUntil(
        //         RouteHelper.getMobileNumberLoginRoute(),
        //             (Route<dynamic> route) => false,
        //       );
        //       // Get.close(2);
        //     },
        //     cancelCallback: () {
        //       Navigator.of(context).pop(); // Close the dialog
        //     },
        //   );
        // } else {
        //   Navigator.of(context).pop(); // Close the dialog
        // }
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          isLeading: true,
          appBarColor: Colors.white,
          title: AppStrings.chooseYourAccountType,
          onBackTap: () {
            Navigator.of(context).pop();
            // if (!isGuestUser()) {
            //   commonConformationDialog(
            //     context: context,
            //     text: AppStrings.areYouSureYouWantToExitTheApp, // not in JSON yet
            //     confirmCallback: () async {
            //       await SharedPreferenceUtils.clearPreference();
            //       Navigator.of(context).pushNamedAndRemoveUntil(
            //         RouteHelper.getMobileNumberLoginRoute(),
            //             (Route<dynamic> route) => false,
            //       );
            //     },
            //     cancelCallback: () {
            //       Navigator.of(context).pop(); // Close the dialog
            //     },
            //   );
            // } else {
            //   Navigator.of(context).pop(); // Close the dialog
            // }
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
                          if(authController.isProfessionLoading.value)
                            return Center(
                              child: CircularProgressIndicator(),
                            );

                          switch (authController.selectedIndividualOnboardingProfile.value?.slugId) {
                            case SOCIAL_PROFILE:
                              return _socialProfilesContent(
                                  key: ValueKey(SOCIAL_PROFILE),
                                  arrIndividualCategory: authController.individualOnboardingSocialProfileList);
                            case SELF_EMPLOYED:
                              return _selfWorkContent(
                                  key: ValueKey(SELF_EMPLOYED),
                                  arrSelfWorkTransportCategory: authController.individualOnboardingGigWorkList,
                                  arrSelfWorkSkilledCategory: authController.individualOnboardingSkillWorkList
                              );
                            case CONSULTANT:
                              return _consultationContent(
                                  key: ValueKey(CONSULTANT),
                                  arrConsultationsCategory: authController.individualOnboardingConsultationList);
                          }
                        } else {
                          if(authController.isAllBusinessCategoriesLoading.value)
                            return Center(
                              child: CircularProgressIndicator(),
                            );

                          switch (authController.selectedBusinessOnboardingProfile.value?.slugId) {
                              case FOOD:
                                return _foodNdGroceryContent(
                                  key: ValueKey(FOOD),
                                  arrGroceryCategory: authController.businessOnboardingGroceriesCategories,
                                  arrFoodNdRestaurantCategory: authController.businessOnboardingFoodsCategories,
                                );
                              case PRODUCT:
                                return _businessContent(
                                    key: ValueKey(PRODUCT),
                                    arrBusinessCategory: authController.businessOnboardingProductsCategories);
                              case SERVICE_OTHERS:
                                return _businessOtherServiceContent(
                                  key: ValueKey(SERVICE_OTHERS),
                                );
                              case SERVICE:
                                return _businessContent(
                                    key: ValueKey(SERVICE),
                                    arrBusinessCategory: authController.businessOnboardingServicesCategories);
                              case MANUFACTURING:
                                return _businessContent(
                                    key: ValueKey(MANUFACTURING),
                                    arrBusinessCategory: authController.businessOnboardingManufacturingCategories);
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
      width: SizeConfig.screenWidth * 0.18,
      height: SizeConfig.screenHeight,
      color: AppColors.white,
      child: ListView(
        children: [
          Column(
            children: [

              SizedBox(
                height: SizeConfig.paddingXSL,
              ),

              if (_showIndividualSidebar)
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
                          category.icon ?? '',
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

              if (_showBusinessSidebar)
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
                          category.icon ?? '',
                          category.name,
                          selected: authController.selectedBusinessOnboardingProfile.value!=null
                              ? authController.selectedBusinessOnboardingProfile.value?.slugId == category.slugId
                              : false,
                          selectedColor: AppColors.blueShade,
                          onTap: () {
                            authController.selectedBusinessOnboardingProfile.value = category;
                            authController.selectedIndividualOnboardingProfile.value = null;
                            authController.selectedParentSlug.value = AppConstants.business;
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
      child: Padding(
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
                  child: AnimatedContainer(
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
    required List<ProfessionTypeData> arrIndividualCategory}) {
    if(arrIndividualCategory.isEmpty )
      return EmptyStateWidget(
        message: 'No profession found',
      );

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
              return _individualCommonCard(item, textMaxLine: 1);
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
    required List<ProfessionTypeData> arrSelfWorkTransportCategory,
    required List<ProfessionTypeData> arrSelfWorkSkilledCategory,
  }) {
    if(arrSelfWorkTransportCategory.isEmpty ||
        arrSelfWorkSkilledCategory.isEmpty)
      return EmptyStateWidget(
        message: 'No profession found',
      );

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
              return _individualCommonCard(item, textMaxLine: 1);
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
              return _individualCommonCard(item, textMaxLine: 1);
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
    required List<ProfessionTypeData> arrConsultationsCategory}) {
    if(arrConsultationsCategory.isEmpty)
      return EmptyStateWidget(
        message: 'No profession found',
      );

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
              return _individualCommonCard(item, textMaxLine: 2);
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
    required List<CategoryData> arrGroceryCategory,
    required List<CategoryData> arrFoodNdRestaurantCategory,
  }) {
    if(arrGroceryCategory.isEmpty ||
        arrFoodNdRestaurantCategory.isEmpty)
      return EmptyStateWidget(
        message: 'No category found',
      );

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

          CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.paddingXSL),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              itemCount: arrGroceryCategory.length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var item = arrGroceryCategory[index];
                return _businessCommonCard(item, textMaxLine: 1);
              },
              padding: EdgeInsets.zero,
              shrinkWrap: true,
            ),
          ),

          SizedBox(height: SizeConfig.paddingM),

          CustomText(
              'Food & Restaurant',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor
          ),

          SizedBox(height: SizeConfig.paddingXSL),

          CustomFormCard(
            padding: EdgeInsets.all(SizeConfig.paddingXSL),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              itemCount: arrFoodNdRestaurantCategory.length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var item = arrFoodNdRestaurantCategory[index];
                return _businessCommonCard(item, textMaxLine: 2);
              },
              padding: EdgeInsets.only(bottom: SizeConfig.size16),
              shrinkWrap: true,
            ),
          ),

          SizedBox(height: SizeConfig.paddingM),

          _otherOptionCreation()
        ],
      ),
    );
  }

  Widget _businessContent({
    Key? key,
    required List<CategoryData> arrBusinessCategory}) {
    if(arrBusinessCategory.isEmpty)
      return EmptyStateWidget(
        message: 'No category found',
      );

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
              return _businessCommonCard(item, textMaxLine: 2);
            },
            padding: EdgeInsets.only(bottom: SizeConfig.size16),
            shrinkWrap: true,
          ),

          _otherOptionCreation()
        ],
      ),
    );
  }

  Widget _individualCommonCard(
      ProfessionTypeData category,
      {int? textMaxLine}) {

    return CommonServiceCard(
      service: category,
      getName: (item) => item.name ?? '',
      getIcon: (item) => item.imageUrl ?? '',
      iconHeight: SizeConfig.size60,
      boxShadow: [],
      textMaxLine: textMaxLine,
      onTap: (category) {
        log("---------------- LOG DATA ----------------");
        log("${ApiKeys.argProfileType} : ${category.individualProfileType?.tagId}");
        log("${ApiKeys.argProfessionTagId}    : ${category.tagId}");
        log("${ApiKeys.argProfession}    : ${category.name}");
        log("------------------------------------------");

        Get.toNamed(
          RouteHelper.getPersonalAccountNewScreenRoute(),
          arguments: {
            ApiKeys.argAccountType: AppConstants.individual,
            ApiKeys.argProfileType: category.individualProfileType,
            ApiKeys.argProfessionTagId: category.tagId,
            ApiKeys.argProfession: category.name,
          },
        );
      },
    );
  }


  Widget _businessOtherServiceContent({Key? key}) {
    final Map<String, List<CategoryData>> onboardingBusinessMap = {
      'Automotive Services': authController.businessOnboardingAutomotiveServicesCategories,
      'Health Care': authController.businessOnboardingHealthcareSectorsCategories,
      'Hospitality & Stay': authController.businessOnboardingHospitalityStayCategories,
      'Education & Training Sectors': authController.businessOnboardingEducationTrainingCategories,
      'Financial Sectors': authController.businessOnboardingFinancialSectorsCategories,
    };

    return SingleChildScrollView(
      key: key,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size10,
      ),
      child: Column(
        children: onboardingBusinessMap.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: SizeConfig.size10),
            child: CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.paddingXSL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    entry.key,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w600,
                  ),

                  SizedBox(height: SizeConfig.paddingXSL),

                  MasonryGridView.count(
                    shrinkWrap: true,
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entry.value.length,
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      var category = entry.value[index];
                      return _businessCommonCard(category);
                    },
                  )

                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _businessCommonCard(
      CategoryData category,
      {int? textMaxLine}) {
    return CommonServiceCard(
      service: category,
      getName: (item) => item.name ?? '',
      getIcon: (item) => item.imageUrl ?? '',
      iconHeight: SizeConfig.size60,
      boxShadow: [],
      textMaxLine: textMaxLine,
      onTap: (category) {
        if(category.businessType == BusinessType.Manufacturing){
          if(category.businessType == null) return;
          navigateToGstScreen(
            context,
            businessType: category.businessType!,
            categorySlugId: category.tagId!,
            categoryName: category.name!,
          );
        }
        else{
          _showBusinessSubCategoryDialog(
            businessType: category.businessType!,
            categorySlugId: category.tagId!,
            categoryName: category.name!,
          );
        }
      },
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

