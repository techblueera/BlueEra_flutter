import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/store/widget/StoreCategory.dart';
import 'package:BlueEra/features/common/store/widget/icon_grid_item.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../personal/personal_profile/controller/languge_list_controller.dart';

class CreateNewAccountScreen extends StatefulWidget {
  @override
  State<CreateNewAccountScreen> createState() => _CreateNewAccountScreenState();
}

class _CreateNewAccountScreenState extends State<CreateNewAccountScreen> {
  int? _selectedIndex;
  String? _imagePath;
  late LanguageListController langController;
  final authController = Get.isRegistered<AuthController>()
                 ? Get.find<AuthController>()
                 : Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    langController = Get.find<LanguageListController>();
    /// individual Categories
    authController.getAllProfessionController();

   /// Business Categories
    authController.getAllNewCategories();
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
            text: "Are you sure you want to exit the app?", // not in JSON yet
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
                text: "Are you sure you want to exit the app?", // not in JSON yet
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8,
                vertical: SizeConfig.size10,
              ),
              child: Obx(()=> Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

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
                          _iconGrid(
                              individualSocialProfileList,
                              onTap: (category) {}
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
                          _iconGrid(
                              individualSelfEmployedList,
                              onTap: (category){
                                print("You tapped → ${category.slugId}");
                                print("You tapped category name → ${category.name}");

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

                  authController.isCategoryLoading.value ?
                  Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ))
                      : Column(
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
                              _iconGrid(
                                businessFoodsCategories,
                                onTap: (category) {
                                  print("You tapped → ${category.slugId}");
                                  print("You tapped category name → ${category.name}");
                                  print("You tapped category id → ${category.categoryData}");
                                  _showDropdownDialog(
                                      category.categoryData
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
                              _iconGrid(
                                businessProductsCategories,
                                onTap: (category) {
                                  _showDropdownDialog(
                                      category.categoryData
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
                              _iconGrid(
                                businessServicesCategories,
                                onTap: (category) {
                                  print("You tapped → ${category.slugId}");
                                  print("You tapped category id → ${category.categoryData}");
                                  print("You tapped category name → ${category.name}");
                                  _showDropdownDialog(
                                      category.categoryData
                                  );
                                },
                              )

                            ],
                          )
                      ),
                    ],
                  ),

                  SizedBox(height: kToolbarHeight),

                ],
              ))
              ,
            ),
          ),
        ),
      ),
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

  Widget _iconGrid(
      List<ProfileCategory> items, {
        void Function(ProfileCategory category)? onTap,
      }) {
    const crossAxisCount = 4;
    const mainAxisSpacing = 16.0;

    // Split into rows of 4
    final rows = <List<ProfileCategory>>[];

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
              // Even index → actual item
              // Odd index → spacing
              if (i.isEven) {
                final itemIndex = i ~/ 2;

                if (itemIndex < rowItems.length) {
                  final category = rowItems[itemIndex];

                  return Expanded(
                    child: IconGridItem(
                      label: category.name,
                      icon: category.icon,
                      onTap: () {
                        if (onTap != null) onTap(category);
                      },
                    ),
                  );
                } else {
                  return const Expanded(child: SizedBox());
                }
              } else {
                // spacing between items
                return SizedBox(width: SizeConfig.size8);
              }
            }),
          ),
        );
      }),
    );
  }

  Future<void> _showDropdownDialog(CategoryData? categoryData) async {
    if (categoryData == null || categoryData.subCategories == null || (categoryData.subCategories?.isEmpty ?? false)) return;

    final selected = await showDialog<SubCategories>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).dialogBackgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  'Select Sub Category',
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

                      return ListTile(
                        title: CustomText(
                          item?.name ?? 'Unknown',
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.size15,
                        ),
                        onTap: () => Navigator.of(context).pop(item),
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

    /// If a subcategory was selected
    if (selected != null) {
      Navigator.pushNamed(
        context,
        RouteHelper.getCreateUserAccountRoute(),
        arguments: {
          ApiKeys.argAccountType: AppConstants.business,
          ApiKeys.argCategoryData: categoryData,
          ApiKeys.argSubCategory: selected,
        },
      );
    }
  }


  Future<void> _selectImage(BuildContext context) async {
    final String? selected = await SelectProfilePictureDialog.showLogoDialog(
      context,
      AppStrings.uploadProfilePicture,
    );

    if (selected?.isNotEmpty ?? false) {
      _imagePath = selected;
      UserSession().imagePath = selected;
      setState(() {});
      if (_selectedIndex != null) _navigateToCreateAccount();
    }
  }

  void _onGetStartedPressed() {
    if (_imagePath?.isEmpty ?? true) {
      _selectImage(context);
      return;
    }
    _navigateToCreateAccount();
  }

  void _navigateToCreateAccount() {
    if (_selectedIndex == null) {
      commonSnackBar(message:"Select Account Type");
      return;
    }
    final accountType =
    _selectedIndex == 0 ? AppConstants.individual : AppConstants.business;
    UserSession().userType = accountType;
    // SharedPreferenceUtils.setSecureValue(
    //     SharedPreferenceUtils.accountType, accountType);
    Navigator.pushNamed(
      context,
      RouteHelper.getCreateUserAccountRoute(),
      arguments: {ApiKeys.argAccountType: accountType},
    );
  }
}
