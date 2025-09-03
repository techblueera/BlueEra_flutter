import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/views/widget/business_type_common_widget.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessAccountScreen extends StatefulWidget {
  BusinessAccountScreen({super.key});

  @override
  State<BusinessAccountScreen> createState() => _BusinessAccountScreenState();
}

class _BusinessAccountScreenState extends State<BusinessAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  BusinessType? _typeOfBusiness = BusinessType.Product;
  SizeOfBusiness? _selectedNatureOfBusiness;
  CategoryData? _selectedCategoryOfBusiness;
  SubCategories? _selectedSubCategoryOfBusiness;

  bool _referralCodeEnable = false;
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.getAllCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(
              left: SizeConfig.size15,
              right: SizeConfig.size15,
              top: SizeConfig.size15,
              bottom: SizeConfig.size100,
            ),
            padding: EdgeInsets.all(SizeConfig.size15),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(SizeConfig.size10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: SizeConfig.size5,
                  offset: Offset(0, SizeConfig.size2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: SizeConfig.size8,
                ),
                CustomText(
                  appLocalizations?.businessDetails,
                  fontSize: SizeConfig.extraLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),

                ///ENTER ORG/COMPANY NAME...
                Obx(() {
                  return IgnorePointer(
                    ignoring:
                        (authController.isHaveGstApprove.value) ? true : false,
                    child: CommonTextField(
                      textEditController:
                          authController.businessNameTextController,
                      // inputLength: AppConstants.inputCharterLimit30,
                      maxLength: AppConstants.inputCharterLimit30,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                          RegularExpressionUtils.alphabetSpacePattern,

                      title: appLocalizations?.businessName,
                      hintText: AppConstants.businessName,
                      isValidate: true,
                      // autovalidateMode: _autoValidate,
                      onChange: (val) {
                        authController.businessName.value = val;
                        setState(() {});
                      },

                      validator: (value) {
                        if (authController.businessName.value.isEmpty) {
                          return 'Please enter your business or organization name';
                        } else if (authController.businessName.value.length <
                            5) {
                          return 'Minimum 5 characters required';
                        }
                        return null;
                      },
                    ),
                  );
                }),
                SizedBox(height: SizeConfig.size10),
                if (!authController.isHaveGstApprove.value)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Obx(() => CustomText(
                          "${authController.businessName.value.length}/${AppConstants.inputCharterLimit30}",
                          color: AppColors.grey9B,
                          fontSize: SizeConfig.small,
                        )),
                  ),

                SizedBox(
                  height: SizeConfig.size20,
                ),

                ///DOB selection
                CustomText(
                  appLocalizations?.dateOfIncorporation,
                  fontSize: SizeConfig.medium,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                Obx(() {
                  return IgnorePointer(
                    ignoring:
                        (authController.isHaveGstApprove.value) ? true : false,
                    child: NewDatePicker(
                      selectedDay: authController.selectedDay?.value,
                      selectedMonth: authController.selectedMonth?.value,
                      selectedYear: authController.selectedYear?.value,
                      onDayChanged: (value) {
                        authController.selectedDay?.value = value ?? 0;
                      },
                      onMonthChanged: (value) {
                        authController.selectedMonth?.value = value ?? 0;
                      },
                      onYearChanged: (value) {
                        authController.selectedYear?.value = value ?? 0;
                      },
                    ),
                  );
                }),
                SizedBox(
                  height: SizeConfig.size20,
                ),

                CustomText(
                  appLocalizations?.typeOfBusiness,
                  fontSize: SizeConfig.medium,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BusinessTypeCard(
                      type: BusinessType.Product,
                      icon: AppIconAssets.store,
                      title: appLocalizations?.shopStore ?? "",
                      subtitle: appLocalizations?.egClothesFood ?? "",
                      selectedType: _typeOfBusiness ?? BusinessType.Both,
                      onSelect: (type) {
                        // typeOfServiceTextController.clear();
                        _selectedCategoryOfBusiness = null;
                        _selectedSubCategoryOfBusiness = null;
                        authController.businessSubCategoriesList.clear();
                        _typeOfBusiness = type;
                        setState(() {});
                      },
                    ),
                    SizedBox(width: SizeConfig.size8),
                    BusinessTypeCard(
                      type: BusinessType.Service,
                      icon: AppIconAssets.service,
                      title: appLocalizations?.provideServices ?? "",
                      subtitle: appLocalizations?.egDoctorTutor ?? "",
                      selectedType: _typeOfBusiness ?? BusinessType.Both,
                      onSelect: (type) {
                        _selectedCategoryOfBusiness = null;
                        _selectedSubCategoryOfBusiness = null;
                        authController.businessSubCategoriesList.clear();
                        _typeOfBusiness = type;
                        setState(() {});
                      },
                    ),
                    SizedBox(width: SizeConfig.size8),
                    BusinessTypeCard(
                      type: BusinessType.Both,
                      icon: AppIconAssets.store_service,
                      title: "Other",
                      subtitle: appLocalizations?.egBikeShowroom ?? "",
                      selectedType: _typeOfBusiness ?? BusinessType.Both,
                      onSelect: (type) {
                        _selectedCategoryOfBusiness = null;
                        _selectedSubCategoryOfBusiness = null;
                        authController.businessSubCategoriesList.clear();

                        _typeOfBusiness = type;

                        setState(() {});
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),
                CustomText(
                  appLocalizations?.categoryOfBusiness,
                  fontSize: SizeConfig.medium,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                _typeOfBusiness?.name.toLowerCase() != "both"
                    ? GetBuilder<AuthController>(
                        builder: (controller) {
                          final categoriesList = controller.businessCategories;
                          if (categoriesList.isEmpty)
                            return const SizedBox.shrink();

                          return Column(
                            children: [
                              CommonDropdownDialog<CategoryData>(
                                items: categoriesList
                                    .where((e) =>
                                        e.type?.toLowerCase() ==
                                        _typeOfBusiness?.name.toLowerCase())
                                    .toList(),
                                selectedValue: _selectedCategoryOfBusiness,
                                title:  appLocalizations?.categoryOfBusiness??"Category of Business",
                                hintText: appLocalizations
                                        ?.selectCategoryOfBusiness ??
                                    "",
                                displayValue: (category) => "${category.name}",
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryOfBusiness = value;
                                    authController.businessSubCategoriesList
                                        .clear();

                                    authController.businessSubCategoriesList
                                        .addAll(value?.subCategories ?? []);
                                    _selectedSubCategoryOfBusiness = null;
                                  });
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
                                items: authController.businessSubCategoriesList,
                                selectedValue: _selectedSubCategoryOfBusiness,
                                hintText: "Select Sub Category",
                                title: "Select Sub Category",
                                displayValue: (category) => "${category.name}",
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSubCategoryOfBusiness = value;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      )
                    : CommonTextField(
                        textEditController:
                            authController.businessOtherCategoryTextController,
                        // inputLength: AppConstants.inputCharterLimit30,
                        maxLength: AppConstants.inputCharterLimit30,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,

                        title: "",
                        hintText: "Enter Category of Business",
                        isValidate: true,
                        // autovalidateMode: _autoValidate,
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
                      ),
                SizedBox(
                  height: SizeConfig.size20,
                ),

                CustomText(
                  appLocalizations?.natureOfBusiness,
                  fontSize: SizeConfig.medium,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),

                CommonDropdownDialog<SizeOfBusiness>(
                  items: SizeOfBusiness.values,
                  selectedValue: _selectedNatureOfBusiness,
                  hintText: appLocalizations?.selectNatureOfTheBusiness ?? "",
                  displayValue: (profession) => profession.displayName,
                  title: appLocalizations?.natureOfBusiness??"Nature of the Business",
                  onChanged: (value) {
                    setState(() {
                      _selectedNatureOfBusiness = value;
                    });
                  },
                ),

                if (_selectedNatureOfBusiness == SizeOfBusiness.OTHERS) ...[
                  SizedBox(height: SizeConfig.size20),
                  CommonTextField(
                    textEditController:
                        authController.otherNatureOfBusinessTextController,
                    inputLength: AppConstants.inputCharterLimit100,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    titleColor: Colors.black,
                    hintText: appLocalizations?.pleaseSpecifyIfOther,
                    autovalidateMode: _autoValidate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter other nature of business';
                      }
                      return null;
                    },
                  ),
                ],

                SizedBox(height: SizeConfig.size20),
                ..._referralCodeEnable
                    ? [
                        CommonTextField(
                          textEditController:
                              authController.referralCodeController,
                          inputLength: AppConstants.inputCharterLimit10,
                          keyBoardType: TextInputType.text,
                          regularExpression:
                              RegularExpressionUtils.alphanumericPattern,
                          title: appLocalizations?.referralCode,
                          hintText: appLocalizations?.enterReferCode,
                          autovalidateMode: _autoValidate,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your referral code";
                            }
                            return null;
                          },
                        ),
                      ]
                    : [
                        Center(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _referralCodeEnable = true),
                            child: CustomText(
                              appLocalizations?.youHaveReferCode,
                              color: AppColors.primaryColor,
                              decoration: TextDecoration.underline,
                              fontSize: SizeConfig.medium,
                              decorationColor: AppColors.primaryColor,
                            ),
                          ),
                        )
                      ],
              ],
            ),
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
          child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
        child: CustomBtn(
          onTap: () => _onSubmit(),
          title: appLocalizations?.submit,
          isValidate: true,
          radius: SizeConfig.size8,
        ),
      )),
    );
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (authController.selectedDay?.value == null ||
          authController.selectedMonth?.value == null ||
          authController.selectedYear?.value == null) {
        commonSnackBar(message: "Please select date of incorporation");
        return;
      }
      if (_typeOfBusiness == null) {
        commonSnackBar(message: "Please select type of business");
        return;
      }
      if (_typeOfBusiness?.name.toLowerCase() == "both") {
        if (authController
            .businessOtherCategoryTextController.value.text.isEmpty) {
          commonSnackBar(message: "Please Enter Category of Business");
        }
      }

      final imageFile = (UserSession().imagePath != null)
          ? File(UserSession().imagePath!)
          : null;
      dio.MultipartFile? imageByPart;
      if (imageFile?.path.isNotEmpty ?? false) {
        String fileName = imageFile?.path.split('/').last ?? "";
        imageByPart = await dio.MultipartFile.fromFile(imageFile?.path ?? "",
            filename: fileName);
      }
      Map<String, dynamic> requestData = {
        ApiKeys.contact_no: authController.mobileNumberEditController.text,
        ApiKeys.account_type: AppConstants.business.toUpperCase(),
        ApiKeys.logo_image: imageByPart,
        ApiKeys.business_name: authController.businessNameTextController.text,
        ApiKeys.date_of_incorporation_date: authController.selectedDay?.value,
        ApiKeys.date_of_incorporation_month:
            authController.selectedMonth?.value,
        ApiKeys.date_of_incorporation_year: authController.selectedYear?.value,
        ApiKeys.type_of_business: _typeOfBusiness?.name,
        ApiKeys.nature_of_business: _selectedNatureOfBusiness?.name,

        ///ADDED KEY OTHER KEY HARD CODED AS PER DISCUSIION
        ApiKeys.category_Of_Business:
            (_typeOfBusiness?.name.toLowerCase() == "both")
                ? "68a80b766fdb4e82b42b77c0"
                : _selectedCategoryOfBusiness?.id,
        if (_typeOfBusiness?.name.toLowerCase() == "both")
          ApiKeys.category_other:
              authController.businessOtherCategoryTextController.text,
        if (_selectedSubCategoryOfBusiness?.sId?.isNotEmpty ?? false)
          ApiKeys.sub_category_Of_Business: _selectedSubCategoryOfBusiness?.sId,

        if ((authController.gstVerifyModel?.value.success ?? false) &&
            (authController.gstVerifyModel?.value.data?.gstin?.isNotEmpty ??
                false))
          ApiKeys.gst_have: true,
        if ((authController.gstVerifyModel?.value.success ?? false) &&
            (authController.gstVerifyModel?.value.data?.gstin?.isNotEmpty ??
                false))
          ApiKeys.gst_number: authController.gstVerifyModel?.value.data?.gstin,
        ApiKeys.gst_verified: ((authController.gstVerifyModel?.value.success ??
                    false) &&
                (authController.gstVerifyModel?.value.data?.gstin?.isNotEmpty ??
                    false))
            ? true
            : false,
        if (authController.referralCodeController.text.isNotEmpty)
          ApiKeys.referral_code: authController.referralCodeController.text,
      };
      await authController.addNewUser(reqData: requestData);
    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  }
}
