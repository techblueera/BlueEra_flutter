import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/type_of_business_model.dart';
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down_icon_dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class BusinessAccountScreen extends StatefulWidget {
  BusinessAccountScreen({super.key});

  @override
  State<BusinessAccountScreen> createState() => _BusinessAccountScreenState();
}

class _BusinessAccountScreenState extends State<BusinessAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  BusinessType? _typeOfBusiness;
  NatureOfBusiness? _selectedNatureOfBusiness;
  CategoryData? _selectedCategoryOfBusiness;
  SubCategories? _selectedSubCategoryOfBusiness;
  BusinessCategory? selectedTypeOfBusiness;

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
                  "Business Details",
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

                      title: AppStrings.businessName,
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
                  AppStrings.dateOfIncorporation,
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
                  AppStrings.typeOfBusiness,
                  fontSize: SizeConfig.medium,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),

                CommonDropdownIconDialog<BusinessCategory>(
                  items: typeOfBusinessList,
                  selectedValue: selectedTypeOfBusiness,
                  hintText: AppStrings.selectNatureOfBusiness,
                  displayValue: (profession) => profession.title,
                  title: "Nature of the Business" ,
                  onChanged: (value) {
                    setState(() {
                      selectedTypeOfBusiness = value;
                      _selectedCategoryOfBusiness = null;
                      _selectedSubCategoryOfBusiness = null;
                      authController.businessSubCategoriesList.clear();
                      authController.subCategorySpecializationTextController
                          .clear();
                      // _typeOfBusiness = type;
                      if (value?.type == BusinessType.Product.name) {
                        _typeOfBusiness = BusinessType.Product;
                      } else if (value?.type == BusinessType.Service.name) {
                        _typeOfBusiness = BusinessType.Service;
                      } else if (value?.type == BusinessType.Food.name) {
                        _typeOfBusiness = BusinessType.Food;
                      } else {
                        _typeOfBusiness = BusinessType.Both;
                      }
                    });
                  },
                  displayValueSubTitle: (profession) => profession.subTitle,
                  displayValueImagePath: (profession) => profession.icon,
                ),

                // SizedBox(
                //   height: SizeConfig.size20,
                // ),

                _typeOfBusiness?.name.toLowerCase() != "both"
                    ? GetBuilder<AuthController>(
                        builder: (controller) {
                          final categoriesList = controller.businessCategories;
                          if (categoriesList.isEmpty)
                            return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: SizeConfig.size20,
                              ),
                              CustomText(
                                AppStrings.categoryOfBusiness,
                                fontSize: SizeConfig.medium,
                              ),
                              SizedBox(
                                height: SizeConfig.size10,
                              ),
                              CommonDropdownDialog<CategoryData>(
                                items: categoriesList
                                    .where((e) =>
                                        e.type?.toLowerCase() ==
                                        _typeOfBusiness?.name.toLowerCase())
                                    .toList(),
                                selectedValue: _selectedCategoryOfBusiness,
                                title: AppStrings.categoryOfBusiness ,
                                hintText: AppStrings.selectBusinessCategory.tr,
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
                                  AppStrings.subCategory,
                                  fontSize: SizeConfig.medium,
                                ),
                              ),
                              SizedBox(
                                height: SizeConfig.size10,
                              ),
                              CommonDropdownDialog<SubCategories>(
                                items: authController.businessSubCategoriesList,
                                selectedValue: _selectedSubCategoryOfBusiness,
                                hintText: AppStrings.selectSubCategory,
                                title:AppStrings.selectSubCategory,
                                displayValue: (category) => "${category.name}",
                                onChanged: (value) {
                                  authController
                                      .subCategorySpecializationTextController
                                      .clear();
                                  setState(() {
                                    _selectedSubCategoryOfBusiness = value;
                                  });
                                },
                              ),
                              SizedBox(
                                height: SizeConfig.size20,
                              ),
// inside your screen/widget

                              CommonTextField(
                                textEditController: authController
                                    .subCategorySpecializationTextController,
                                hintText:AppStrings.businessSpecializationHint,
                                title: AppStrings.businessSpecializationOptional,
                                maxLine: 1,
                                maxLength: 24,
                                keyBoardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                isValidate: false,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(
                                      RegularExpressionUtils
                                          .alphabetPatternSpace)),
                                  NoLeadingSpaceFormatter(),
                                  NoConsecutiveSpacesFormatter(),
                                ],
                                // we will handle validation manually
                                onChange: (val) {
                                  String newVal = val;
                                  authController
                                      .categorySpecializationText.value = val;
                                  // Allow only alphabets + spaces
                                  if (!RegExp(r'^[a-zA-Z ]*$')
                                      .hasMatch(newVal)) {
                                    authController.errorMessage.value =
                                        "Special characters are not allowed";
                                  } else if (newVal.isEmpty) {
                                    authController.errorMessage.value =
                                        "Please enter business specialization";
                                  } else if (newVal.length < 8) {
                                    authController.errorMessage.value =
                                        "Mini 8 char required";
                                  } else if (newVal.length > 24) {
                                    authController.errorMessage.value =
                                        "Maxi 24 char allowed";
                                  } else {
                                    authController.errorMessage.value = "";
                                  }

                                },
                              ),

                              SizedBox(height: 5),

                              // 👇 Error/Helper Message
                              Obx(() => authController
                                          .errorMessage.value.isNotEmpty &&
                                      (authController.categorySpecializationText
                                          .value.isNotEmpty)
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: CustomText(
                                        authController.errorMessage.value,
                                        color: Colors.red,
                                        fontSize: 12,
                                        textAlign: TextAlign.left,
                                      ),
                                    )
                                  : SizedBox()),

                              // 👇 Counter (bottom right)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Obx(() => CustomText(
                                      "${authController.categorySpecializationText.value.length}/24",
                                      color: Colors.grey,
                                      fontSize: 12,
                                    )),
                              ),
                            ],
                          );
                        },
                      )
                    : SizedBox(),
                //               : CommonTextField(
                //                   textEditController:
                //                       authController.businessOtherCategoryTextController,
                //                   // inputLength: AppConstants.inputCharterLimit30,
                //                   maxLength: AppConstants.inputCharterLimit30,
                //                   keyBoardType: TextInputType.text,
                //                   regularExpression:
                //                       RegularExpressionUtils.alphabetSpacePattern,
                //
                //                   title: "",
                //                   hintText: "Enter Category of Business",
                //                   isValidate: true,
                //                  //  autovalidateMode: _autoValidate,
                //                   // onChange: (val) {
                //                   //   setState(() {});
                //                   // },
                //
                //               onChange: (val) {
                // authController.businessName.value = val;
                // setState(() {});
                // },
                //
                //   validator: (value) {
                //     if (authController.businessName.value.isEmpty) {
                //       return 'Please enter your Category of Business';
                //     } else if (authController.businessName.value.length <
                //         5) {
                //       return 'Minimum 5 characters required';
                //     }
                //     return null;
                //   },
                //                 ),
                SizedBox(height: SizeConfig.size20),

                if (selectedTypeOfBusiness?.type ==
                    BusinessType.Product.name) ...[
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  CustomText(
                    "Nature of the Business",
                    fontSize: SizeConfig.medium,
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  CommonDropdownDialog<NatureOfBusiness>(
                    items: NatureOfBusiness.values,
                    selectedValue: _selectedNatureOfBusiness,
                    hintText: AppStrings.selectNatureOfBusiness,
                    displayValue: (profession) => profession.displayName,
                    title:
                        "Nature of the Business",
                    onChanged: (value) {
                      setState(() {
                        _selectedNatureOfBusiness = value;
                      });
                    },
                  ),
                  if (_selectedNatureOfBusiness == NatureOfBusiness.OTHERS) ...[
                    SizedBox(height: SizeConfig.size20),
                    CommonTextField(
                      textEditController:
                          authController.otherNatureOfBusinessTextController,
                      inputLength: AppConstants.inputCharterLimit100,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                          RegularExpressionUtils.alphabetSpacePattern,
                      titleColor: Colors.black,
                      hintText: 'Please specify (if other)',
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
                ],

                ..._referralCodeEnable
                    ? [
                        CommonTextField(
                          textEditController:
                              authController.referralCodeController,
                          inputLength: AppConstants.inputCharterLimit10,
                          keyBoardType: TextInputType.text,
                          regularExpression:
                              RegularExpressionUtils.alphanumericPattern,
                          title: "Referral Code",
                          hintText: "Enter Referral Code",
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
                              'Do you have refer code?',
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
          title: AppStrings.submit,
          isValidate: true,
          radius: SizeConfig.size8,
        ),
      )),
    );
  }

  final locationController = Get.put(LocationController());

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
      return;
    }

    print("Selected Business Type: $_typeOfBusiness");

    // 1️⃣ Type of business required
    if (_typeOfBusiness == null ||
        (_typeOfBusiness?.name.trim().isEmpty ?? true)) {
      commonSnackBar(message: "Please select type of business");
      return;
    }

    // 2️⃣ Business name required
    if (authController.businessNameTextController.text.trim().isEmpty) {
      commonSnackBar(message: "Please enter business name");
      return;
    }

    // 3️⃣ Category required ONLY IF type != "both"
    if (_typeOfBusiness?.name.toLowerCase() != "both") {
      if (_selectedCategoryOfBusiness?.id == null ||
          _selectedCategoryOfBusiness!.id!.isEmpty) {
        commonSnackBar(message: "Please select business category");
        return;
      }
    }

    // Sub-category NOT required anymore — removed

    // ---------- FILE + REQUEST BELOW NO CHANGE ----------
    final imageFile = (UserSession().imagePath != null)
        ? File(UserSession().imagePath!)
        : null;

    dio.MultipartFile? imageByPart;
    if (imageFile?.path.isNotEmpty ?? false) {
      String fileName = imageFile?.path.split('/').last ?? "";
      imageByPart = await dio.MultipartFile.fromFile(
        imageFile!.path,
        filename: fileName,
      );
    }
    final locationData = await locationController.checkPermissionAndSetData();
    if (locationData != null) {
      Map<String, dynamic> requestData = {
        ApiKeys.logo_image: imageByPart,
        ApiKeys.business_name: authController.businessNameTextController.text,
        ApiKeys.business_location: jsonEncode({
          ApiKeys.lat: locationData.lat.toString(),
          ApiKeys.lon: locationData.long.toString(),
        }),
        ApiKeys.type_of_business: _typeOfBusiness?.name,
        ApiKeys.nature_of_business: _selectedNatureOfBusiness?.name,
        ApiKeys.date_of_incorporation: {
          ApiKeys.date: authController.selectedDay?.value,
          ApiKeys.month: authController.selectedMonth?.value,
          ApiKeys.year: authController.selectedYear?.value
        },
        // Category logic based on "both"
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

        if (authController
            .subCategorySpecializationTextController.text.isNotEmpty)
          ApiKeys.specification:
              authController.subCategorySpecializationTextController.text,
      };

      await authController.addBusinessUser(reqData: requestData);
    } else {
      commonSnackBar(
          message:
              "Please enable your location permission and gps to access app features.");
      return;
    }
  }
}
