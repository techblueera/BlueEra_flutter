import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/business_profile_category.dart';
import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
import 'package:BlueEra/features/common/store/widget/icon_grid_item.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateNewAccountScreen extends StatefulWidget {
  @override
  State<CreateNewAccountScreen> createState() => _CreateNewAccountScreenState();
}

class _CreateNewAccountScreenState extends State<CreateNewAccountScreen> {
  final authController = Get.isRegistered<AuthController>()
                 ? Get.find<AuthController>()
                 : Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    authController.loadIndividualAndBusinessCategoryData();
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
          child: Obx(()=> authController.isAppLoading.value
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Individual Categories

                  /// Social Profile
                  CustomFormCard(
                      padding: EdgeInsets.all(
                        SizeConfig.size10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                              title: AppStrings.socialProfile
                          ),
                          SizedBox(height: SizeConfig.size15),
                          genericIconGrid<IndividualProfileCategory>(
                              items: individualSocialProfileList,
                              labelBuilder: (c) => c.name,
                              iconBuilder: (c) => c.icon,
                              onTap: (c) {
                                print("You tapped slugId → ${c.slugId}");
                                print("You tapped professionSId → ${c.professionTagId}");
                               if(c.slugId != OTHERS){
                                 Get.toNamed(
                                   RouteHelper.getPersonalAccountNewScreenRoute(),
                                   arguments: {
                                     ApiKeys.argAccountType: AppConstants.individual,
                                     ApiKeys.argProfessionTagId: c.professionTagId,
                                     ApiKeys.argProfessionSubCategory: c.professionSubCategory,
                                   },
                                 );
                               }else{
                                 showProfileCategoryDialog(context);
                               }
                              }
                          )
                        ],
                      )
                  ),
                  SizedBox(height: SizeConfig.size10),

                  /// Join As - Earn With BlueEra
                  CustomFormCard(
                      padding: EdgeInsets.all(
                        SizeConfig.size10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            title: AppStrings.joinAsEarnWithBlueEra,
                          ),
                          SizedBox(height: SizeConfig.size15),
                          genericIconGrid<IndividualProfileCategory>(
                              items: individualSelfEmployedList,
                              labelBuilder: (c) => c.name,
                              iconBuilder: (c) => c.icon,
                              onTap: (c){
                                print("You tapped slugId → ${c.slugId}");
                                print("You tapped professionSId → ${c.professionTagId}");
                                print("You tapped selfEmployment → ${c.selfEmployment}");
                                print("You tapped selfEmploymentSId → ${c.selfEmploymentTagId}");
                                Get.toNamed(
                                  RouteHelper.getPersonalAccountNewScreenRoute(),
                                  arguments: {
                                    ApiKeys.argAccountType: AppConstants.individual,
                                    ApiKeys.argProfessionTagId: c.professionTagId,
                                    ApiKeys.argSelfEmployment: c.selfEmployment,
                                    ApiKeys.argSelfEmploymentTagId: c.selfEmploymentTagId,
                                  },
                                );
                              }
                          )

                        ],
                      )
                  ),
                  SizedBox(height: SizeConfig.size20),

                  CustomText(
                      AppStrings.listYourBusiness,
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w600
                  ),

                  SizedBox(height: SizeConfig.size15),


                  /// Business Categories
                  // authController.isCategoryLoading.value ?
                  // Align(
                  //     alignment: Alignment.center,
                  //     child: Padding(
                  //       padding: const EdgeInsets.all(20.0),
                  //       child: CircularProgressIndicator(),
                  //     ))
                  //     :
                  Column(
                    children: [
                      /// Grocery/Food/Restaurant
                      CustomFormCard(
                          padding: EdgeInsets.all(
                            SizeConfig.size10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(
                                  title: AppStrings.groceryFoodRestaurant
                              ),
                              SizedBox(height: SizeConfig.size15),
                              genericIconGrid<BusinessProfileCategory>(
                                items: businessFoodsCategories,
                                labelBuilder: (c) => c.name,
                                iconBuilder: (c) => c.icon,
                                onTap: (category) {
                                  print("You tapped → ${category.slugId}");
                                  print("You tapped category name → ${category.name}");
                                  print("You tapped category id → ${category.categoryData}");
                                  _showDropdownDialog(
                                    businessType: BusinessType.Food,
                                    categoryData: category.categoryData,
                                  );
                                },
                              )

                            ],
                          )
                      ),
                      SizedBox(height: SizeConfig.size10),

                      /// Shop/Store/Showroom
                      CustomFormCard(
                          padding: EdgeInsets.all(
                            SizeConfig.size10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(
                                  title: AppStrings.shopStoreShowroom
                              ),
                              SizedBox(height: SizeConfig.size15),
                              genericIconGrid<BusinessProfileCategory>(
                                  items: businessProductsCategories,
                                  labelBuilder: (c) => c.name,
                                  iconBuilder: (c) => c.icon,
                                onTap: (category) {
                                  _showDropdownDialog(
                                      businessType: BusinessType.Product,
                                      categoryData: category.categoryData
                                  );
                                },
                              )
                            ],
                          )
                      ),
                      SizedBox(height: SizeConfig.size10),

                      /// Services
                      CustomFormCard(
                          padding: EdgeInsets.all(
                            SizeConfig.size10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(
                                  title: AppStrings.services
                              ),
                              SizedBox(height: SizeConfig.size15),
                              genericIconGrid<BusinessProfileCategory>(
                                items: businessServicesCategories,
                                labelBuilder: (c) => c.name,
                                iconBuilder: (c) => c.icon,
                                onTap: (category) {
                                  print("You tapped → ${category.slugId}");
                                  print("You tapped category id → ${category.categoryData}");
                                  print("You tapped category name → ${category.name}");
                                  _showDropdownDialog(
                                      businessType: BusinessType.Service,
                                      categoryData: category.categoryData
                                  );
                                },
                              )

                            ],
                          )
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size10),
                  CustomFormCard(
                      padding: EdgeInsets.all(
                        SizeConfig.size10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          LocalAssets(
                            imagePath: AppIconAssets.otherBusinessRelatedIcon,
                            height: SizeConfig.size30,
                            width: SizeConfig.size30,
                          ),
                          SizedBox(width: SizeConfig.size10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                    AppStrings.othersManufacturingUnitIndustryFactory,
                                    fontSize: SizeConfig.small,
                                    color: AppColors.mainTextColor,
                                    fontWeight: FontWeight.w600
                                ),
                                SizedBox(height: SizeConfig.size6),
                                CustomText(
                                    AppStrings.manufacturingRelatedBusinessInfo,
                                    fontSize: SizeConfig.extraSmall,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400
                                ),
                              ],
                            ),
                          )

                        ],
                      )
                  ),

                  SizedBox(height: SizeConfig.size10),
                  InkWell(
                    onTap: (){},
                    child: CustomFormCard(
                      padding: EdgeInsets.all(
                        SizeConfig.size10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                           Container(
                             width: SizeConfig.size25,
                             height: SizeConfig.size25,
                             decoration: BoxDecoration(
                               border: Border.all(
                                 color: AppColors.primaryColor,
                                 width: 2.0
                               ),
                               shape: BoxShape.circle,
                             ),
                             alignment: Alignment.center,
                             child: Icon(
                               Icons.question_mark_outlined,
                               size: SizeConfig.size16,
                               color: AppColors.primaryColor
                             ),
                           ),

                          SizedBox(width: SizeConfig.size10),

                          Expanded(
                            child: CustomText(
                                AppStrings.needHelp,
                                fontSize: SizeConfig.small,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600
                            ),
                          )

                        ],
                      )
                    ),
                  ),

                  SizedBox(height: kToolbarHeight),

                ],
              ),
            ),
          ),
         ),
        )
      ),
    );
  }

  void showProfileCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.all(
             SizeConfig.size20
          ),
          child: Container(
            padding: EdgeInsets.only(
              left: SizeConfig.size20,
              right: SizeConfig.size20,
              top: SizeConfig.size10,
              bottom: SizeConfig.size20,
            ),
            constraints: BoxConstraints(
              maxHeight: Get.height * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomText(
                        AppStrings.selectYourProfession,
                        fontWeight: FontWeight.bold,
                        fontSize: SizeConfig.extraLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: ()=> Get.back(),
                      icon: Icon(
                        Icons.close,
                      ),
                    )
                  ],
                ),

                SizedBox(height: SizeConfig.size15),

                SingleChildScrollView(
                  child: genericIconGrid<IndividualProfileCategory>(
                    items: individualOtherSocialProfileList,
                    labelBuilder: (c) => c.name,
                    iconBuilder: (c) => c.icon,
                    onTap: (c) {
                      print("You tapped slugId → ${c.slugId}");
                      print("You tapped professionTagId → ${c.professionTagId}");

                      Navigator.pop(context); // Close dialog

                      Get.toNamed(
                        RouteHelper.getPersonalAccountNewScreenRoute(),
                        arguments: {
                          ApiKeys.argAccountType: AppConstants.individual,
                          ApiKeys.argProfessionTagId: c.professionTagId,
                          ApiKeys.argProfessionSubCategory: c.professionSubCategory,
                        },
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader({required String title}) {
    return CustomText(
        title,
        fontSize: SizeConfig.large,
        color: AppColors.mainTextColor,
        fontWeight: FontWeight.w600
    );
  }

  Widget genericIconGrid<T>({
    required List<T> items,
    required String Function(T item) labelBuilder,
    required String Function(T item) iconBuilder,
    void Function(T item)? onTap,
  }) {
    const crossAxisCount = 4;
    const mainAxisSpacing = 16.0;

    // Split into rows of 4
    final rows = <List<T>>[];

    for (int i = 0; i < items.length; i += crossAxisCount) {
      rows.add(
        items.sublist(
          i,
          (i + crossAxisCount).clamp(0, items.length),
        ),
      );
    }

    return Column(
      children: List.generate(rows.length, (rowIndex) {
        final rowItems = rows[rowIndex];
        final isLastRow = rowIndex == rows.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLastRow ? 0 : mainAxisSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(crossAxisCount * 2 - 1, (i) {
              if (i.isEven) {
                final itemIndex = i ~/ 2;

                if (itemIndex < rowItems.length) {
                  final item = rowItems[itemIndex];

                  return Expanded(
                    child: IconGridItem(
                      label: labelBuilder(item),
                      icon: iconBuilder(item),
                      onTap: () {
                        if (onTap != null) onTap(item);
                      },
                    ),
                  );
                } else {
                  return const Expanded(child: SizedBox());
                }
              } else {
                return SizedBox(width: SizeConfig.size8);
              }
            }),
          ),
        );
      }),
    );
  }

  Future<void> _showDropdownDialog({required BusinessType businessType, CategoryData? categoryData}) async {
    if (categoryData == null
        || categoryData.subCategories == null
        || (categoryData.subCategories?.isEmpty ?? false)) return;

    SubCategories? selectedSubCat;

    final selected = await showDialog<SubCategories>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: EdgeInsets.all(SizeConfig.size16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: DialogThemeData().backgroundColor,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      AppStrings.selectSubCategory,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.size16,
                    ),
                    SizedBox(height: SizeConfig.size12),

                    /// Safe ListView
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: categoryData.subCategories?.length,
                        itemBuilder: (context, index) {
                          final item = categoryData.subCategories?[index];
                          final isSelected = selectedSubCat?.sId == item?.sId;

                          return Container(
                            color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                            child: ListTile(
                              title: CustomText(
                                item?.name ?? AppStrings.unknown,
                                fontWeight: FontWeight.w400,
                                fontSize: SizeConfig.size15,
                              ),
                              onTap: () {
                                setState(() {
                                  selectedSubCat = item;
                                });
                              },
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: Colors.green, size: 22)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: SizeConfig.size12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: CustomBtn(
                          onTap: ()=> Navigator.of(context).pop(selectedSubCat),
                          title: AppStrings.next,
                          height: SizeConfig.size30,
                          width: SizeConfig.size60,
                          bgColor: AppColors.primaryColor
                      ),
                    )

                  ],
                ),
              ),
            );
          },
        );
      },
    );

    /// If a subcategory was selected
    if (selected != null) {
      Navigator.pushNamed(
        context,
        RouteHelper.getGstNumberScreenRoute(),
        arguments: {
          ApiKeys.argAccountType: AppConstants.business,
          ApiKeys.argBusinessType: businessType,
          ApiKeys.argCategoryData: categoryData,
          ApiKeys.argSubCategory: selected,
        },
      );
    }
  }

}
