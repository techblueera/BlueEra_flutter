import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
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

class PersonalAccountScreen extends StatefulWidget {
  PersonalAccountScreen({super.key});

  @override
  State<PersonalAccountScreen> createState() => _PersonalAccountScreenState();
}

class _PersonalAccountScreenState extends State<PersonalAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  final _nameTextController = TextEditingController();
  int? _selectedDay, _selectedMonth, _selectedYear;
  GenderType? _selectedGender;
  String? _selectedProfession;
  ProfessionTypeData? selectedProfessionObj;
  String? _selectedSelfEmployment;
  SubcategoriesFiledName? _selectedSelfEmploymentObj;

  final _contentCraterTextController = TextEditingController();
  final _skillWorkerSpecificationTextController = TextEditingController();
  final _otherProfessionTextController = TextEditingController();
  final _designationTextController = TextEditingController();
  final _artTypeController = TextEditingController();
  final _ngoNameTextController = TextEditingController();
  final _ExpertiseTextController = TextEditingController();
  final _SeniorTextController = TextEditingController();
  final _CourseTextController = TextEditingController();
  final _companyNameTextController = TextEditingController();
  final _sectorTextController = TextEditingController();
  bool _referralCodeEnable = false;
  final _referralCodeController = TextEditingController();
  final politicalPartyController = TextEditingController();
  final userNameController = TextEditingController();
  final departmentNameController = TextEditingController();
  final subDivision = TextEditingController();
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    apiCalling();
  }

  ///API CALLING...
  apiCalling() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await authController.getAllProfessionController();
    });
  }

  clearTextFiled() {
    _CourseTextController.clear();
    _artTypeController.clear();
    _contentCraterTextController.clear();
    _skillWorkerSpecificationTextController.clear();
    _otherProfessionTextController.clear();
    _designationTextController.clear();
    _ngoNameTextController.clear();
    _ExpertiseTextController.clear();
    _SeniorTextController.clear();
    _companyNameTextController.clear();
    _sectorTextController.clear();
    _referralCodeController.clear();
    politicalPartyController.clear();
    userNameController.clear();
    departmentNameController.clear();
    subDivision.clear();
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
                color: Colors.black38,
                blurRadius: SizeConfig.size10,
                offset: Offset(0, SizeConfig.size2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SizedBox(height: SizeConfig.size10),
                CustomText(
                  appLocalizations?.yourDetails,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
                SizedBox(height: SizeConfig.size10),

                ///ENTER NAME...
                CommonTextField(
                    textEditController: _nameTextController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: appLocalizations?.yourName,
                    titleColor: Colors.black,
                    hintText: AppConstants.name,
                    autovalidateMode: _autoValidate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    }),
                SizedBox(
                  height: SizeConfig.size20,
                ),

                ///DOB selection
                CustomText(
                  appLocalizations?.dateOfBirth,
                  fontSize: SizeConfig.medium,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                NewDatePicker(
                  selectedDay: _selectedDay,
                  selectedMonth: _selectedMonth,
                  selectedYear: _selectedYear,
                  isAgeValidation15: true,
                  onDayChanged: (value) {
                    setState(() {
                      _selectedDay = value;
                    });
                  },
                  onMonthChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                  onYearChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),
                // Gender
                CustomText(
                  appLocalizations?.selectGender,
                  fontSize: SizeConfig.medium,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                CommonDropdown<GenderType>(
                  items: GenderType.values,
                  selectedValue: _selectedGender,
                  hintText: appLocalizations?.selectGenderHint ?? '',
                  displayValue: (value) => value.displayName,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),

                ///selectYourProfession
                CustomText(
                  appLocalizations?.selectYourProfession,
                  fontSize: SizeConfig.medium,
                ),
                SizedBox(
                  height: SizeConfig.size10,
                ),
                GetBuilder<AuthController>(builder: (authController) {
                  return CommonDropdownDialog<ProfessionTypeData>(
                    items: authController.professionTypeDataList,
                    selectedValue: selectedProfessionObj,
                    hintText: AppConstants.selectProfession,
                    title: appLocalizations?.selectYourProfession ?? "Select",
                    displayValue: (profession) => profession.name ?? "",
                    onChanged: (value) {
                      _selectedSelfEmploymentObj = null;
                      authController.subcategoriesFiledNameList.clear();

                      clearTextFiled();
                      setState(() {
                        _selectedProfession = value?.tagId;
                        selectedProfessionObj = value;
                      });
                    },
                  );
                }),

                if ((_selectedProfession == SELF_EMPLOYED)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  ///selectYourProfession
                  CustomText(
                    "Select Work Type",
                    fontSize: SizeConfig.medium,
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),

                  CommonDropdownDialog<SubcategoriesFiledName>(
                    items: selectedProfessionObj?.subcategoriesFiledName ?? [],
                    selectedValue: _selectedSelfEmploymentObj,
                    hintText: AppConstants.selectSelfEmployee,
                    title: "Select Work Type",
                    displayValue: (selfEmployment) => selfEmployment.name ?? "",
                    onChanged: (value) {
                      setState(() {
                        _selectedSelfEmploymentObj = value;
                        _selectedSelfEmployment = value?.tagId;
                      });
                    },
                  ),
                  SizedBox(
                    height: SizeConfig.size15,
                  ),
                  CommonTextField(
                    isValidate: false,

                    textEditController: _designationTextController,
                    // inputLength: 13,
                    inputLength: 24,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    titleColor: Colors.black,
                    hintText: "Please specify work type",
                  ),
                ],

                if ((_selectedProfession == CONTENT_CREATOR)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    isValidate: false,

                    textEditController: _contentCraterTextController,
                    // inputLength: 13,
                    inputLength: 24,
                    title: "Type Your Specification",
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "Eg. Education,Poetry",
                  ),
                ],

                if ((_selectedProfession == SKILLED_WORKER)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    textEditController: _skillWorkerSpecificationTextController,
                    inputLength: 24,
                    title: "Type Your Work Specification",
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "Eg. Helper",
                    isValidate: false,
                    // autovalidateMode: _autoValidate,
                    /*   validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter work specification';
                        }
                        return null;
                      }*/
                  ),
                ],

                if ((_selectedProfession == REG_UNION)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    isValidate: false,

                    textEditController: _ngoNameTextController,
                    inputLength: 40,
                    title: "Type Your NGO / Society Name",
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "Eg. Auto Union",
                    // autovalidateMode: _autoValidate,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter NGO / Society ';
                    //   }
                    //   return null;
                    // }
                  ),
                ],
                if ((_selectedProfession == INDUSTRIALIST)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    isValidate: false,

                    textEditController: _companyNameTextController,
                    // inputLength: 13,
                    inputLength: 24,
                    title: "Type Your Company Name",
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "Eg. TCS LTD",
                    // autovalidateMode: _autoValidate,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter company name';
                    //   }
                    //   return null;
                    // }
                  ),
                ],

                if ((_selectedProfession == HOMEMAKER)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    isValidate: false,

                    textEditController: _ExpertiseTextController,
                    // inputLength: 13,
                    inputLength: 24,
                    title: "Type Your Expertise",
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "Eg. Cooking,Dancing",
                    // autovalidateMode: _autoValidate,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter Expertise';
                    //   }
                    //   return null;
                    // }
                  ),
                ],
                if ((_selectedProfession == SENIOR_CITIZEN_RETIRED)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    isValidate: false,

                    textEditController: _SeniorTextController,
                    inputLength: 24,
                    title: "Type Your Expertise",
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "Eg. Banking,Teaching",
                    // autovalidateMode: _autoValidate,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter Expertise';
                    //   }
                    //   return null;
                    // }
                  ),
                ],
                if ((_selectedProfession == STUDENT)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                  CommonTextField(
                    isValidate: false,

                    textEditController: _CourseTextController,
                    inputLength: 24,
                    title: "Which class you study?",
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "Eg. 10th,Diploma,BE,PHD",
                    // autovalidateMode: _autoValidate,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter Expertise';
                    //   }
                    //   return null;
                    // }
                  ),
                ],

                if ((_selectedProfession == ARTIST)) ...[
                  SizedBox(
                    height: SizeConfig.size20,
                  ),

                  ///selectYourProfession
                  CustomText(
                    "Select Your Art / Skill",
                    fontSize: SizeConfig.medium,
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  CommonDropdownDialog<SubcategoriesFiledName>(
                    items: selectedProfessionObj?.subcategoriesFiledName ?? [],
                    selectedValue: _selectedSelfEmploymentObj,
                    hintText: AppConstants.selectSelfArtist,
                    title: "Select Your Art / Skill",
                    displayValue: (selfEmployment) => selfEmployment.name ?? "",
                    onChanged: (value) {
                      setState(() {
                        _selectedSelfEmploymentObj = value;
                        _selectedSelfEmployment = value?.tagId;
                      });
                    },
                  ),
                  /* CommonDropdownDialog<ArtistCategory>(
                    items: ArtistCategory.values,
                    selectedValue: _selectedArtistCategory,
                    hintText: AppConstants.selectSelfArtist,
                    title: "Select Your Art / Skill",
                    displayValue: (selfEmployment) =>
                    selfEmployment.displayName,
                    onChanged: (value) {
                      setState(() {
                        _selectedArtistCategory = value;
                      });
                    },
                    // validator: (value) {
                    //   if (value == null) {
                    //     return 'Select your art / skill';
                    //   }
                    //   return null;
                    // },
                  ),*/
                  if (_selectedSelfEmploymentObj != null) ...[
                    SizedBox(
                      height: SizeConfig.size15,
                    ),
                    CommonTextField(
                      isValidate: false,

                      textEditController: _artTypeController,
                      // inputLength: 13,
                      inputLength: 24,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                          RegularExpressionUtils.alphabetSpacePattern,
                      titleColor: Colors.black,
                      hintText: "Please Specify Art Type",
                      // autovalidateMode: _autoValidate,
                      // validator: (value) {
                      //   if (value == null || value.isEmpty) {
                      //     return 'Please enter art specification';
                      //   }
                      //   return null;
                      // }
                    ),
                  ],
                ],

                SizedBox(
                  height: SizeConfig.size20,
                ),
                if (_selectedProfession == OTHERS) ...[
                  CommonTextField(
                    isValidate: false,

                    textEditController: _otherProfessionTextController,
                    inputLength: 13,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    titleColor: Colors.black,
                    hintText: appLocalizations?.pleaseSpecifyIfOther,
                    // autovalidateMode: _autoValidate,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter other profession name';
                    //   }
                    //   return null;
                    // }
                  ),
                  SizedBox(height: SizeConfig.size20),
                  CommonTextField(
                    isValidate: false,

                    textEditController: _designationTextController,
                    inputLength: 24,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: "Designation / Expertise",
                    hintText: "Enter your designation/expertise",
                    // autovalidateMode: _autoValidate,
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter your designation or expertise';
                    //   }
                    //   return null;
                    // },
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                ],
                if (_selectedProfession == POLITICIAN) ...[
                  // if (shouldShowField('politicalParty')) ...[
                  CommonTextField(
                    isValidate: false,
                    title: "Political Party",
                    hintText: "Enter political party or organization name",
                    textEditController: politicalPartyController,
                    inputLength: 50,
                  ),
                  SizedBox(height: SizeConfig.size18),
                ],

                if ((_selectedProfession == GOVTPSU)) ...[
                  CommonTextField(
                    isValidate: false,

                    title: "Name of Department/PSU",
                    textEditController: departmentNameController,
                    inputLength: 24,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern_,
                    titleColor: Colors.black,
                    hintText: "Eg., Ministry of Education",
                    // validator: (value) {
                    //   if (value == null || value.isEmpty) {
                    //     return 'Please enter your department name';
                    //   }
                    //   return null;
                    // }
                  ),
                  SizedBox(height: SizeConfig.size18),
                  CommonTextField(
                    isValidate: false,
                    title: "SUB Division / Branch",
                    textEditController: subDivision,
                    inputLength: 24,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern_,
                    titleColor: Colors.black,
                    hintText: "Eg., Civil Engineering Division",
                  ),
                  SizedBox(height: SizeConfig.size18),
                ],
                if (_selectedProfession == PRIVATE_JOB) ...[
                  CommonTextField(
                    isValidate: false,

                    textEditController: _sectorTextController,
                    inputLength: AppConstants.inputCharterLimit250,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: "Sector",
                    hintText: "Eg. IT Sector",
                    // autovalidateMode: _autoValidate,
                  ),
                  SizedBox(height: SizeConfig.size18),
                ],

                if ((_selectedProfession != SELF_EMPLOYED) &&
                    (_selectedProfession != SKILLED_WORKER) &&
                    (_selectedProfession != ARTIST) &&
                    (_selectedProfession != CONTENT_CREATOR) &&
                    (_selectedProfession != HOMEMAKER) &&
                    (_selectedProfession != SENIOR_CITIZEN_RETIRED) &&
                    (_selectedProfession != FARMER) &&
                    (_selectedProfession != STUDENT) &&
                    (_selectedProfession != OTHERS)) ...[
                  CommonTextField(
                    textEditController: _designationTextController,
                    inputLength: 24,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: appLocalizations?.designation,
                    hintText: "Enter your designation",
                    isValidate: false,
                  ),
                  SizedBox(
                    height: SizeConfig.size20,
                  ),
                ],
                if ((_selectedProfession == POLITICIAN) ||
                    (_selectedProfession == GOVTPSU) ||
                    (_selectedProfession == CONTENT_CREATOR) ||
                    (_selectedProfession == REG_UNION) ||
                    (_selectedProfession == MEDIA) ||
                    (_selectedProfession == INDUSTRIALIST) ||
                    (_selectedProfession == ARTIST)) ...[
                  Obx(() {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText("Create Your Own Username"),
                        if (authController.isShowCheck.value)
                          Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 0.0),
                                child: InkWell(
                                  onTap: userNameController.text.isNotEmpty
                                      ? () {
                                          authController
                                              .getCheckUsernameController(
                                                  value:
                                                      userNameController.text);
                                        }
                                      : null,
                                  child: CustomText(
                                    "Check",
                                    color: userNameController.text.isNotEmpty
                                        ? AppColors.primaryColor
                                        : AppColors.secondaryTextColor,
                                  ),
                                ),
                              )),
                      ],
                    );
                  }),
                  // SizedBox(height: SizeConfig.size5),

                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(
                            authController.userNameList.length, (i) {
                          final isSelected =
                              authController.selectedIndex.value == i;
                          return GestureDetector(
                            onTap: () {
                              userNameController.text =
                                  authController.userNameList[i];
                              authController.select(i);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.black,
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            blurRadius: 6,
                                            spreadRadius: 0.5,
                                            color:
                                                Colors.black.withOpacity(0.15))
                                      ]
                                    : null,
                              ),
                              child: CustomText(
                                authController.userNameList[i],
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: SizeConfig.small,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                  CommonTextField(
                    textEditController: userNameController,
                    inputLength: 15,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphanumericPattern,
                    titleColor: Colors.black,
                    hintText: "Eg @Sachin",
                    isValidate: false,
                    prefixText: userNameController.text.isNotEmpty ? "@" : "",
                    validator: (value) {
                      if (value == null || value.trim().length < 7) {
                        return "Username must be at least 7 characters";
                      }
                      return null;
                    },
                    onChange: (value) {
                      authController.isShowCheck.value = true;
                      setState(() {});
                    },
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  // SizedBox(
                  //   height: SizeConfig.size20,
                  // ),
                ],

                if ((_selectedProfession != GOVTPSU) &&
                    (_selectedProfession != POLITICIAN) &&
                    (_selectedProfession != MEDIA) &&
                    (_selectedProfession != REG_UNION) &&
                    (_selectedProfession != INDUSTRIALIST)) ...[
                  ..._referralCodeEnable
                      ? [
                          CommonTextField(
                            isValidate: false,

                            textEditController: _referralCodeController,
                            inputLength: AppConstants.inputCharterLimit10,
                            keyBoardType: TextInputType.text,
                            regularExpression:
                                RegularExpressionUtils.alphanumericPattern,
                            title: appLocalizations?.referralCode,
                            hintText: appLocalizations?.enterReferralCode,
                            // autovalidateMode: _autoValidate,
                            // validator: (value) {
                            //   if (value == null || value.isEmpty) {
                            //     return 'Please enter your referral code';
                            //   }
                            //   return null;
                            // },
                          )
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
                          ),
                        ],
                  // SizedBox(height: SizeConfig.size10,),
                  // Padding(
                  //   padding: EdgeInsets.symmetric(
                  //       horizontal: SizeConfig.size15, vertical: 5),
                  //   child: CustomBtn(
                  //     onTap: () => _onSubmitPressed(),
                  //     title: appLocalizations?.submit,
                  //     isValidate: true,
                  //     radius: SizeConfig.size8,
                  //   ),
                  // )
                ],
              ],
            ),
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              right: SizeConfig.size15,
              left: SizeConfig.size15,
              bottom: SizeConfig.size20,
              top: SizeConfig.size10),
          child: CustomBtn(
            onTap: () => _onSubmitPressed(),
            title: appLocalizations?.submit,
            isValidate: true,
            radius: SizeConfig.size8,
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmitPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDay == null ||
          _selectedMonth == null ||
          _selectedYear == null) {
        commonSnackBar(message: 'Please select your date of birth');
        return;
      }
      if (_selectedProfession == ARTIST) {
        if (_selectedSelfEmploymentObj?.name?.isEmpty ?? true) {
          commonSnackBar(message: 'Select your art / skill');

          return;
        }
      }
      if (_selectedProfession == REG_UNION) {
        if (_ngoNameTextController.text.isEmpty) {
          commonSnackBar(message: 'Enter your NGO / Society Name');

          return;
        }
      }

      if (_selectedProfession == OTHERS) {
        if (_otherProfessionTextController.text.isEmpty) {
          commonSnackBar(message: 'Please enter your Skill and Expertise');
          return;
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
      String? designation;
      if ((_selectedProfession == SELF_EMPLOYED)) {
        designation = _selectedSelfEmployment ?? "";
      } else {
        designation = _designationTextController.text;
      }

      /*  Map<String, dynamic> requestData = {
        ApiKeys.contact_no: authController.mobileNumberEditController.text,
        ApiKeys.account_type: AppConstants.individual.toUpperCase(),
        ApiKeys.profile_image: imageByPart,
        ApiKeys.name: _nameTextController.text,
        ApiKeys.date_of_birth: _selectedDay,
        ApiKeys.date_of_birth_month: _selectedMonth,
        ApiKeys.date_of_birth_year: _selectedYear,
        ApiKeys.gender: _selectedGender?.name,

        ///CONDITION....
        ApiKeys.profession: _selectedProfession,
        ApiKeys.designation: designation,
        if (_selectedProfession == PRIVATE_JOB)
          ApiKeys.sector: _sectorTextController.text,
        if ((_selectedProfession == SELF_EMPLOYED))
          ApiKeys.specilization: _designationTextController.text,
        if (_selectedProfession == SKILLED_WORKER)
          ApiKeys.specilization: _skillWorkerSpecificationTextController.text,
        if (_selectedProfession == CONTENT_CREATOR)
          ApiKeys.specilization: _contentCraterTextController.text,

        ///USER NAME
        if ((_selectedProfession == CONTENT_CREATOR) ||
            (_selectedProfession == POLITICIAN) ||
            (_selectedProfession == REG_UNION) ||
            (_selectedProfession == INDUSTRIALIST) ||
            (_selectedProfession == ARTIST) ||
            (_selectedProfession == MEDIA) ||
            (_selectedProfession == GOVTPSU))
          ApiKeys.username: userNameController.text,

        if (_selectedProfession == POLITICIAN)
          ApiKeys.department: politicalPartyController.text,
        if (_selectedProfession == GOVTPSU)
          ApiKeys.department: departmentNameController.text,
        if (_selectedProfession == GOVTPSU)
          ApiKeys.subDivision: subDivision.text,
        if (_selectedProfession == REG_UNION)
          ApiKeys.department: _ngoNameTextController.text,

        if (_selectedProfession == INDUSTRIALIST)
          ApiKeys.department: _companyNameTextController.text,

        if (_selectedProfession == STUDENT)
          ApiKeys.schoolOrCollegeName: _CourseTextController.text,
        if (_selectedProfession == OTHERS)
          ApiKeys.specilization: _otherProfessionTextController.text,
        if (_selectedProfession == ARTIST)
          ApiKeys.art: jsonEncode({
            ApiKeys.artName: _selectedSelfEmploymentObj?.tagId,
            ApiKeys.artType: _artTypeController.text
          }),
        if (_selectedProfession == HOMEMAKER)
          ApiKeys.art: jsonEncode({
            ApiKeys.artName: _ExpertiseTextController.text,
          }),

        if (_selectedProfession == SENIOR_CITIZEN_RETIRED)
          ApiKeys.art: jsonEncode({
            ApiKeys.artName: _SeniorTextController.text,
          }),

        ApiKeys.referred_by_code:
        _referralCodeEnable ? _referralCodeController.text : null,
      };*/
      Map<String, dynamic> requestData = {
        ApiKeys.profile_image: imageByPart,
        ApiKeys.name: _nameTextController.text,
        "date_of_birth": jsonEncode({
          ApiKeys.date: _selectedDay,
          ApiKeys.month: _selectedMonth,
          ApiKeys.year: _selectedYear,
        }),
        ApiKeys.gender: _selectedGender?.name,

        ///CONDITION....
        ApiKeys.profession: _selectedProfession,
        ApiKeys.designation: designation,
        if (_selectedProfession == PRIVATE_JOB)
          ApiKeys.sector: _sectorTextController.text,
        if ((_selectedProfession == SELF_EMPLOYED))
          ApiKeys.specilization: _designationTextController.text,
        if (_selectedProfession == SKILLED_WORKER)
          ApiKeys.specilization: _skillWorkerSpecificationTextController.text,
        if (_selectedProfession == CONTENT_CREATOR)
          ApiKeys.specilization: _contentCraterTextController.text,

        ///USER NAME
        if ((_selectedProfession == CONTENT_CREATOR) ||
            (_selectedProfession == POLITICIAN) ||
            (_selectedProfession == REG_UNION) ||
            (_selectedProfession == INDUSTRIALIST) ||
            (_selectedProfession == ARTIST) ||
            (_selectedProfession == MEDIA) ||
            (_selectedProfession == GOVTPSU))
          ApiKeys.username: userNameController.text,

        if (_selectedProfession == POLITICIAN)
          ApiKeys.department: politicalPartyController.text,
        if (_selectedProfession == GOVTPSU)
          ApiKeys.department: departmentNameController.text,
        if (_selectedProfession == GOVTPSU)
          ApiKeys.subDivision: subDivision.text,
        if (_selectedProfession == REG_UNION)
          ApiKeys.department: _ngoNameTextController.text,

        if (_selectedProfession == INDUSTRIALIST)
          ApiKeys.department: _companyNameTextController.text,

        if (_selectedProfession == STUDENT)
          ApiKeys.schoolOrCollegeName: _CourseTextController.text,
        if (_selectedProfession == OTHERS)
          ApiKeys.specilization: _otherProfessionTextController.text,
        if (_selectedProfession == ARTIST)
          ApiKeys.art: jsonEncode({
            ApiKeys.artName: _selectedSelfEmploymentObj?.tagId,
            ApiKeys.artType: _artTypeController.text
          }),
        if (_selectedProfession == HOMEMAKER)
          ApiKeys.art: jsonEncode({
            ApiKeys.artName: _ExpertiseTextController.text,
          }),

        if (_selectedProfession == SENIOR_CITIZEN_RETIRED)
          ApiKeys.art: jsonEncode({
            ApiKeys.artName: _SeniorTextController.text,
          }),

        ApiKeys.referred_by_code:
            _referralCodeEnable ? _referralCodeController.text : null,
      };
      logs("requestData PERSONAL ==== ${requestData}");
      await authController.addIndivisualUser(reqData: requestData);
    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  }
}

class UsernamePicker extends StatelessWidget {
  UsernamePicker({super.key});

  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(authController.userNameList.length, (i) {
            final isSelected = authController.selectedIndex.value == i;
            return GestureDetector(
              onTap: () {
                authController.select(i);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.black,
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              blurRadius: 6,
                              spreadRadius: 0.5,
                              color: Colors.black.withOpacity(0.15))
                        ]
                      : null,
                ),
                child: CustomText(
                  authController.userNameList[i],
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: SizeConfig.small,
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}
