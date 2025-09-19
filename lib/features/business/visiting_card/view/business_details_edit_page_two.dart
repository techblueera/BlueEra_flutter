import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controller/view_business_details_controller.dart';
import '../../auth/model/viewBusinessProfileModel.dart';

class BusinessDetailsEditPageTwo extends StatefulWidget {
  const BusinessDetailsEditPageTwo({
    super.key,
    required this.paramsMap,
    this.prevBusinessDetails,
    this.isFromCreateUser = false,
  });

  final bool isFromCreateUser;

  final Map<String, dynamic> paramsMap;
  final BusinessProfileDetails? prevBusinessDetails;

  @override
  State<BusinessDetailsEditPageTwo> createState() =>
      _BusinessDetailsEditPageTwoState();
}

class _BusinessDetailsEditPageTwoState
    extends State<BusinessDetailsEditPageTwo> {
  final TextEditingController nameTextController = TextEditingController();
  final TextEditingController yourRoleController = TextEditingController();
  final TextEditingController emailTextController = TextEditingController();
  final TextEditingController businessDescriptionController =
      TextEditingController();

  bool validate = false;

  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    // TODO: implement initState
    if (widget.prevBusinessDetails != null) {
      final data = widget.prevBusinessDetails;
      if (data?.ownerDetails != null &&
          (data?.ownerDetails?.isNotEmpty ?? false)) {
        nameTextController.text = data?.ownerDetails?.first.name ?? '';
        emailTextController.text = data?.ownerDetails?.first.email ?? '';
        subCategoryTextController.text = data?.category_other ?? '';
        yourRoleController.text =
            data?.ownerDetails?.first.role_in_business ?? '';
      }
      businessDescriptionController.text = data?.businessDescription ?? '';
    }
    super.initState();
  }

  final subCategoryTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: "Business Details (Step 2 of 2)",
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16, vertical: SizeConfig.size30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "Category of Business",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                Obx(() {
                  return viewBusinessDetailsController
                              .selectedBusinessType?.value.name
                              .toLowerCase() !=
                          "both"
                      ? Column(
                          children: [
                            CommonDropdownDialog<CategoryData>(
                              items: viewBusinessDetailsController
                                  .businessCategoriesList
                                  .where((e) =>
                                      e.type?.toLowerCase() ==
                                      viewBusinessDetailsController
                                          .selectedBusinessType?.value.name
                                          .toLowerCase())
                                  .toList(),
                              title:  "Category of Business",
                              // items: viewBusinessDetailsController
                              //     .businessCategoriesList,
                              selectedValue: viewBusinessDetailsController
                                  .selectedCategoryOfBusiness.value,
                              hintText:
                                  appLocalizations?.selectCategoryOfBusiness ??
                                      "",
                              displayValue: (category) => "${category.name}",

                              onChanged: (value) {
                                viewBusinessDetailsController
                                    .businessSubCategoriesList
                                    .clear();
                                viewBusinessDetailsController
                                    .businessSubCategoriesList
                                    .addAll(value?.subCategories ?? []);
                                viewBusinessDetailsController
                                    .selectedSubCategoryOfBusinessNew
                                    .value = null;

                                viewBusinessDetailsController
                                    .selectedCategoryOfBusiness
                                    .value = value ?? CategoryData();
                              },
                            ),
                            SizedBox(
                              height: SizeConfig.size20,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                appLocalizations?.subCategory,
                                fontSize: SizeConfig.medium,
                              ),
                            ),
                            SizedBox(
                              height: SizeConfig.size10,
                            ),
                            CommonDropdownDialog<SubCategories>(
                              items: viewBusinessDetailsController
                                  .businessSubCategoriesList,
                              selectedValue: viewBusinessDetailsController
                                  .selectedSubCategoryOfBusinessNew.value,
                              hintText: "Select Sub Category",
                              title: "Select Sub Category",

                              displayValue: (category) => "${category.name}",
                              onChanged: (value) {
                                viewBusinessDetailsController
                                    .selectedSubCategoryOfBusinessNew
                                    .value = value;
                              },
                            ),
                          ],
                        )
                      : CommonTextField(
                          textEditController: subCategoryTextController,
                          maxLength: AppConstants.inputCharterLimit30,
                          keyBoardType: TextInputType.text,
                          regularExpression:
                              RegularExpressionUtils.alphabetSpacePattern,
                          title: "",
                          hintText: "Enter Category of Business",
                          isValidate: true,
                          onChange: (val) {
                            setState(() {});
                          },
                          validator: (value) {
                            // if (authController.businessName.value.isEmpty) {
                            //   return 'Please enter your business or organization name';
                            // } else if (authController.businessName.value.length <
                            //     5) {
                            //   return 'Minimum 5 characters required';
                            // }
                            return null;
                          },
                        );
                }),
                SizedBox(
                  height: SizeConfig.size20,
                ),
                /*    CustomText(
                  "Sub-category",
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                Obx(() {
                  // return CommonDropdown<GenderType>(
                  //   items: GenderType.values,
                  //   selectedValue: personalCreateProfileController
                  //       .selectedGender.value,
                  //   hintText: "Select Gender",
                  //   displayValue: (value) => value.displayName,
                  //   onChanged: (value) {
                  //     personalCreateProfileController
                  //         .selectedGender.value = value;
                  //   },
                  //   validator: (value) {
                  //     return null;
                  //   },
                  // );
                  return CommonDropdown<SubCategoryData>(
                    items: viewBusinessDetailsController.subCategoriesList,
                    selectedValue: viewBusinessDetailsController
                        .selectedSubCategoryOfBusiness.value,
                    hintText:"Select Sub category",
                    // hintText: appLocalizations?.subCategory.tr ?? "",

                    displayValue: (category) => category.name??"Select Sub category",
                    onChanged: (value) {
                      viewBusinessDetailsController
                          .selectedSubCategoryOfBusiness.value =
                          value ?? SubCategoryData();
                    },
                    validator: (value) {
                      if (value == null) {
                        return appLocalizations?.subCategory;
                      }
                      return null;
                    },
                  );
                }),
                SizedBox(
                  height: SizeConfig.size20,
                ),*/
                /*      CommonTextField(
                  textEditController: businessDescriptionController,
                  inputLength: AppConstants.inputCharterLimit50,
                  keyBoardType: TextInputType.text,
                  regularExpression:
                  RegularExpressionUtils.alphabetSpacePatternDigitSpace,
                  title: "Business Description",
                  hintText:
                  "Eg., Visit our store for casual and traditional wear...",
                  isValidate: false,
                  maxLine: 3,
                  onChange: (value) => validateForm(),
                ),*/
                // SizedBox(
                //   height: 28,
                // ),
                Center(
                  child: CustomText(
                    "Owner Details",
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),
                CommonTextField(
                  textEditController: nameTextController,
                  inputLength: AppConstants.inputCharterLimit50,
                  keyBoardType: TextInputType.text,
                  regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                  title: "Your Name",
                  hintText: AppConstants.name,
                  isValidate: false,
                  onChange: (value) => validateForm(),
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),
                CommonTextField(
                  textEditController: yourRoleController,
                  inputLength: AppConstants.inputCharterLimit50,
                  keyBoardType: TextInputType.text,
                  regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                  title: appLocalizations?.yourRoleInTheBusiness,
                  hintText: appLocalizations?.coFounderOwner,
                  isValidate: false,
                  onChange: (value) => validateForm(),
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),
                CommonTextField(
                  textEditController: emailTextController,
                  inputLength: AppConstants.inputCharterLimit50,
                  keyBoardType: TextInputType.emailAddress,
                  regularExpression: RegularExpressionUtils.emailPattern,
                  title: appLocalizations?.email,
                  hintText: appLocalizations?.email,
                  isValidate: true,
                  validationType: ValidationTypeEnum.email,
                  onChange: (value) => validateForm(),
                ),
                SizedBox(
                  height: SizeConfig.size28,
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        radius: 10,
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        title: "Previous",
                        bgColor: Colors.transparent,
                        textColor: AppColors.primaryColor,
                        borderColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(
                      width: SizeConfig.size10,
                    ),
                    Expanded(
                      child: CustomBtn(
                        radius: 10,
                        bgColor: AppColors.primaryColor,
                        onTap: () async {
                          Map<String, dynamic> updatedParams = widget.paramsMap;

                          if (viewBusinessDetailsController
                                  .selectedBusinessType?.value.name
                                  .toLowerCase() ==
                              "both") {
                            if (subCategoryTextController.text.isEmpty) {
                              commonSnackBar(
                                  message: "Please Enter Category of Business");
                              return;
                            }
                          }
                          updatedParams.addAll({
                            ///ADDED KEY OTHER KEY HARD CODED AS PER DISCUSIION
                            ApiKeys.category_Of_Business:
                                (viewBusinessDetailsController
                                            .selectedBusinessType?.value.name
                                            .toLowerCase() ==
                                        "both")
                                    ? "68a80b766fdb4e82b42b77c0"
                                    : viewBusinessDetailsController
                                        .selectedCategoryOfBusiness.value?.id,
                            if (viewBusinessDetailsController
                                    .selectedBusinessType?.value.name
                                    .toLowerCase() ==
                                "both")
                              ApiKeys.category_other:
                                  subCategoryTextController.text,

                            if (viewBusinessDetailsController
                                    .selectedSubCategoryOfBusinessNew
                                    .value
                                    ?.sId
                                    ?.isNotEmpty ??
                                false)
                              ApiKeys.sub_category_Of_Business:
                                  viewBusinessDetailsController
                                      .selectedSubCategoryOfBusinessNew
                                      .value
                                      ?.sId,

                            // "sub_category_Of_Business":
                            // viewBusinessDetailsController
                            //     .selectedSubCategoryOfBusiness.value?.id ?? '',
                            // :
                            //     businessDescriptionController.text,
                            ApiKeys.owner_details: jsonEncode([
                              {
                                ApiKeys.name: nameTextController.text,
                                ApiKeys.role_in_business:
                                    yourRoleController.text,
                                ApiKeys.email: emailTextController.text
                              }
                            ]),
                          });
                          await Get.find<ViewBusinessDetailsController>()
                              .updateBusinessDetails(updatedParams);
                          if (widget.isFromCreateUser == false) {
                            Navigator.of(context).pop(); // First pop
                            Navigator.of(context).pop();
                          } else {
                            Get.offNamedUntil(
                              RouteHelper.getBottomNavigationBarScreenRoute(),
                              (route) => false,
                            );
                          }
                        },
                        title: "Save",
                        isValidate: validate,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void validateForm() {
    final validations = {
      'Name': nameTextController.text.isNotEmpty,
      "Category":
          viewBusinessDetailsController.selectedCategoryOfBusiness.value !=
              null,
      'Your Role': yourRoleController.text.isNotEmpty,
      'Email': emailTextController.text.isNotEmpty,
    };

    final hasEmptyField = validations.values.contains(false);

    if (hasEmptyField) {
      validate = false;
      setState(() {});
      return;
    }

    validate = true;
    setState(() {});
  }
}
