import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/common_singleton_class/user_session.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalAccountNewScreen extends StatefulWidget {
  final String accountType;
  final String professionTagId;
  final List<SubcategoriesFiledName>? professionSubCategory;
  final String? selfEmployment;
  final String? selfEmploymentTagId;

  PersonalAccountNewScreen(
      {
        super.key,
        required this.accountType,
        required this.professionTagId,
        this.professionSubCategory,
        this.selfEmployment,
        this.selfEmploymentTagId
      });

  @override
  State<PersonalAccountNewScreen> createState() => _PersonalAccountNewScreenState();
}

class _PersonalAccountNewScreenState extends State<PersonalAccountNewScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  final _nameTextController = TextEditingController();
  int? _selectedDay, _selectedMonth, _selectedYear;
  GenderType? _selectedGender;

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
  final locationController = Get.put(LocationController());
  bool crBtnLoading=false;

  String? _imagePath;
  String? _selectedProfessionTagId;
  String? _selectedSelfEmployment;
  String? _selectedSelfEmploymentTagId;
  List<SubcategoriesFiledName>? professionSubCategory;
  SubcategoriesFiledName? _selectedArtistObj;

  @override
  void initState() {
    super.initState();
    print(
        "AccountType: ${widget.accountType} | "
            // "Profession: ${widget.profession} | "
            "ProfessionSId: ${widget.professionTagId} | "
            "Profession sub category: ${widget.professionSubCategory ?? 'N/A'} | "
            "SelfEmployment: ${widget.selfEmployment ?? 'N/A'} | "
            "SelfEmploymentSId: ${widget.selfEmploymentTagId ?? 'N/A'}"
    );

    _selectedProfessionTagId = widget.professionTagId;
    if(_selectedProfessionTagId == SELF_EMPLOYED){
      _selectedSelfEmployment = widget.selfEmployment;
      _selectedSelfEmploymentTagId = widget.selfEmploymentTagId;
    }
    if(widget.professionSubCategory!=null){
      professionSubCategory = widget.professionSubCategory;
    }
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
    // final appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: SizeConfig.size8,
            right: SizeConfig.size8,
            top: SizeConfig.size15,
            bottom: 2 * kBottomNavigationBarHeight,
          ),
          child: Column(
            children: [
              CustomFormCard(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _selectImage(context),
                        child: Container(
                          padding: EdgeInsets.all(SizeConfig.size2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1.0,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.whiteF3,
                            child: _imagePath?.isNotEmpty == true
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image(
                                image: FileImage(File(_imagePath!))
                                  ..evict(),
                              ),
                            )
                                : LocalAssets(
                              imagePath: AppIconAssets.user_out_line,
                              imgColor: AppColors.secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: SizeConfig.size8),
                      InkWell(
                        onTap: () => _selectImage(context),
                        child: CustomText(
                          AppStrings.uploadYourPhotoLogo,
                          color: AppColors.mainTextColor,
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )
              ),

              SizedBox(
                  height: SizeConfig.paddingXSL
              ),

              CustomFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                          AppStrings.youHaveChosen,
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor
                      ),
                      SizedBox(
                        height: SizeConfig.paddingS,
                      ),
                      Container(
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10.0)
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CustomText(
                                    AppStrings.profession,
                                    color: AppColors.secondaryTextColor,
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400
                                ),
                                Expanded(
                                  child: CustomText(
                                      _selectedProfessionTagId,
                                      color: AppColors.primaryColor,
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w400
                                  ),
                                )
                              ],
                            ),

                            if(_selectedSelfEmployment!=null)
                            Padding(
                              padding: EdgeInsets.only(top: SizeConfig.paddingXSmall),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CustomText(
                                      "${AppStrings.workType.tr}: ",
                                      color: AppColors.secondaryTextColor,
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w400
                                  ),
                                  Expanded(
                                    child: CustomText(
                                        _selectedSelfEmployment,
                                        color: AppColors.primaryColor,
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  )
              ),

              SizedBox(
                height: SizeConfig.paddingXSL
              ),

              CustomFormCard(
                padding: EdgeInsets.all(
                  SizeConfig.paddingXSL
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SizedBox(height: SizeConfig.size10),
                    CustomText(
                      'Your Details',
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    SizedBox(height: SizeConfig.size10),


                    ///ENTER NAME...
                    CommonTextField(
                      textEditController: _nameTextController,
                      inputLength: 30,
                      keyBoardType: TextInputType.text,
                      regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                      title: 'Your Name',
                      titleColor: Colors.black,
                      hintText: AppConstants.name,
                      autovalidateMode: _autoValidate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        } else if (value.trim().length < 6) {
                          return 'Name must be at least 6 characters';
                        } else if (value.trim().length > 30) {
                          return 'Name must not exceed 30 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(
                      height: SizeConfig.size20,
                    ),

                    ///DOB selection
                    CustomText(
                      'Date Of Birth',
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
                      'Select Gender',
                      fontSize: SizeConfig.medium,
                    ),
                    SizedBox(
                      height: SizeConfig.size10,
                    ),

                    CommonDropdown<GenderType>(
                      items: GenderType.values,
                      selectedValue: _selectedGender,
                      hintText:'eg. Male, Female',
                      //appLocalizations?.selectGenderHint ?? '',
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

                    // SizedBox(
                    //   height: SizeConfig.size20,
                    // ),

                    if ((_selectedProfessionTagId == SELF_EMPLOYED)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
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

                    if ((_selectedProfessionTagId == CONTENT_CREATOR)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
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
                        hintText: "eg. Education,Poetry",
                      ),
                    ],

                    if ((_selectedProfessionTagId == SKILLED_WORKER)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),
                      CommonTextField(
                        textEditController: _skillWorkerSpecificationTextController,
                        inputLength: 24,
                        title: "Type Your Work Specification",
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        hintText: "eg. Helper",
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

                    if ((_selectedProfessionTagId == REG_UNION)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),
                      CommonTextField(
                        isValidate: false,

                        textEditController: _ngoNameTextController,
                        inputLength: 40,
                        title: "Type Your NGO / Society Name",
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        hintText: "eg. Auto Union",
                        // autovalidateMode: _autoValidate,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please enter NGO / Society ';
                        //   }
                        //   return null;
                        // }
                      ),
                    ],

                    if ((_selectedProfessionTagId == INDUSTRIALIST)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
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
                        hintText: "eg. TCS LTD",
                        // autovalidateMode: _autoValidate,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please enter company name';
                        //   }
                        //   return null;
                        // }
                      ),
                    ],

                    if ((_selectedProfessionTagId == HOMEMAKER)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
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
                        hintText: "eg. Cooking,Dancing",
                        // autovalidateMode: _autoValidate,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please enter Expertise';
                        //   }
                        //   return null;
                        // }
                      ),
                    ],

                    if ((_selectedProfessionTagId == SENIOR_CITIZEN)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),

                      CommonTextField(
                        isValidate: false,
                        textEditController: _SeniorTextController,
                        inputLength: 24,
                        title: "Type Your Expertise",
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        hintText: "eg. Banking,Teaching",
                        // autovalidateMode: _autoValidate,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please enter Expertise';
                        //   }
                        //   return null;
                        // }
                      ),
                    ],

                    if ((_selectedProfessionTagId == STUDENT)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _CourseTextController,
                        inputLength: 24,
                        title: "Enter your Education",
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        hintText: "eg. 10th,Diploma,BE,PHD",
                        // autovalidateMode: _autoValidate,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please enter Expertise';
                        //   }
                        //   return null;
                        // }
                      ),
                    ],

                    if ((_selectedProfessionTagId == ARTIST)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
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
                        items: professionSubCategory ?? [],
                        selectedValue: _selectedArtistObj,
                        hintText: 'eg.Painter...',
                        title: "Select Your Art / Skill",
                        displayValue: (selfEmployment) => selfEmployment.name ?? "",
                        onChanged: (value) {
                          setState(() {
                            _selectedArtistObj = value;
                          });
                        },
                      ),
                      if (_selectedArtistObj != null) ...[
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

                    if (_selectedProfessionTagId == OTHERS) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),

                      CommonTextField(
                        isValidate: false,
                        textEditController: _otherProfessionTextController,
                        inputLength: 13,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        titleColor: Colors.black,
                        hintText: 'Please specify (if other)',
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

                    if (_selectedProfessionTagId == POLITICIAN) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),

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

                    if ((_selectedProfessionTagId == GOVTPSU)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),

                      CommonTextField(
                        isValidate: false,
                        title: "Name of Department/PSU",
                        textEditController: departmentNameController,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern_,
                        titleColor: Colors.black,
                        hintText: "eg., Ministry of Education",
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
                        title: "SUB Division/Branch",
                        textEditController: subDivision,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern_,
                        titleColor: Colors.black,
                        hintText: "eg., Civil Engineering Division",
                      ),
                      SizedBox(height: SizeConfig.size18),
                    ],

                    if (_selectedProfessionTagId == PRIVATE_JOB) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),

                      CommonTextField(
                        isValidate: false,
                        textEditController: _sectorTextController,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        title: "Sector",
                        hintText: "eg. IT Sector",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Sector';
                          } if (value.trim().length > 24) {
                            return 'Sector must not exceed 24 characters';
                          }
                          return null;
                        },
                        // autovalidateMode: _autoValidate,
                      ),
                      SizedBox(height: SizeConfig.size18),
                    ],

                    if ((_selectedProfessionTagId == DIRECTOR)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
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
                        hintText: "eg. TCS LTD",
                        // autovalidateMode: _autoValidate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter company name';
                          }
                          return null;
                        }
                      ),
                    ],

                    if ((_selectedProfessionTagId != SELF_EMPLOYED) &&
                        (_selectedProfessionTagId != SKILLED_WORKER) &&
                        (_selectedProfessionTagId != ARTIST) &&
                        (_selectedProfessionTagId != CONTENT_CREATOR) &&
                        (_selectedProfessionTagId != HOMEMAKER) &&
                        (_selectedProfessionTagId != SENIOR_CITIZEN) &&
                        (_selectedProfessionTagId != FARMER) &&
                        (_selectedProfessionTagId != STUDENT) &&
                        (_selectedProfessionTagId != OTHERS)) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),

                      CommonTextField(
                        textEditController: _designationTextController,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        title: 'Designation',
                        hintText: "Enter your designation",
                        isValidate: false,
                      ),

                    ],

                    if ((_selectedProfessionTagId == POLITICIAN) ||
                        (_selectedProfessionTagId == GOVTPSU) ||
                        (_selectedProfessionTagId == CONTENT_CREATOR) ||
                        (_selectedProfessionTagId == REG_UNION) ||
                        (_selectedProfessionTagId == MEDIA) ||
                        (_selectedProfessionTagId == INDUSTRIALIST) ||
                        (_selectedProfessionTagId == ARTIST)||
                        (_selectedProfessionTagId == DIRECTOR)

                    ) ...[
                      SizedBox(
                        height: SizeConfig.paddingL,
                      ),

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
                                          Colors.black.withValues(alpha: 0.15))
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
                        hintText: "eg @Sachin",
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

                    ],

                    SizedBox(
                      height: SizeConfig.paddingL,
                    ),

                    if ((_selectedProfessionTagId != GOVTPSU) &&
                        (_selectedProfessionTagId != POLITICIAN) &&
                        (_selectedProfessionTagId != MEDIA) &&
                        (_selectedProfessionTagId != REG_UNION) &&
                        (_selectedProfessionTagId != INDUSTRIALIST) &&
                        (_selectedProfessionTagId != DIRECTOR)) ...[
                      ..._referralCodeEnable
                          ? [
                        CommonTextField(
                          isValidate: false,
                          textEditController: _referralCodeController,
                          inputLength: AppConstants.inputCharterLimit10,
                          keyBoardType: TextInputType.text,
                          regularExpression:
                          RegularExpressionUtils.alphanumericPattern,
                          title: "Referral Code",
                          hintText: "Enter Referral Code",
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
                              'Do you have refer code?',
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 8.0,
        child: Container(
          color: AppColors.white,
          child: Padding(
            padding: EdgeInsets.only(
                right: SizeConfig.size15,
                left: SizeConfig.size15,
                bottom: SizeConfig.size20,
                top: SizeConfig.size10),
            child: SafeArea(
              child: CustomBtn(
                isLoading: crBtnLoading,
                onTap: () => _onSubmitPressed(),
                title: AppStrings.submit,
                isValidate: true,
                radius: SizeConfig.size8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmitPressed() async {
    if (_imagePath?.isEmpty ?? true) {
      _selectImage(context);
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDay == null ||
          _selectedMonth == null ||
          _selectedYear == null) {
        commonSnackBar(message: 'Please select your date of birth');
        return;
      }
      if (_selectedProfessionTagId == ARTIST) {
        if (_selectedArtistObj?.name?.isEmpty ?? true) {
          commonSnackBar(message: 'Select your art / skill');

          return;
        }
      }
      if (_selectedProfessionTagId == REG_UNION) {
        if (_ngoNameTextController.text.isEmpty) {
          commonSnackBar(message: 'Enter your NGO / Society Name');

          return;
        }
      }

      if (_selectedProfessionTagId == OTHERS) {
        if (_otherProfessionTextController.text.isEmpty) {
          commonSnackBar(message: 'Please enter your Skill and Expertise');
          return;
        }
      }


      setState(() {
        crBtnLoading=true;
      });
      // final position = await getCurrentLocation();
      final locationData = await locationController.checkPermissionAndSetData();
      if (locationData != null) {

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
        if ((_selectedProfessionTagId == SELF_EMPLOYED)) {
          designation = _selectedSelfEmploymentTagId ?? "";
        } else {
          designation = _designationTextController.text.trim();
        }

        Map<String, dynamic> requestData = {
          ApiKeys.profile_image: imageByPart,
          ApiKeys.name: _nameTextController.text.trim(),
          ApiKeys.date_of_birth_Obj: jsonEncode({
            ApiKeys.date: _selectedDay,
            ApiKeys.month: _selectedMonth,
            ApiKeys.year: _selectedYear,
          }),
          ApiKeys.gender: _selectedGender?.name,

          ///CONDITION....
          ApiKeys.profession: _selectedProfessionTagId,
          ApiKeys.designation: designation,
          if (_selectedProfessionTagId == PRIVATE_JOB)
            ApiKeys.sector: _sectorTextController.text,
          if ((_selectedProfessionTagId == SELF_EMPLOYED))
            ApiKeys.specilization: _designationTextController.text,
          if (_selectedProfessionTagId == SKILLED_WORKER)
            ApiKeys.specilization: _skillWorkerSpecificationTextController.text,
          if (_selectedProfessionTagId == CONTENT_CREATOR)
            ApiKeys.specilization: _contentCraterTextController.text,

          ///USER NAME
          if ((_selectedProfessionTagId == CONTENT_CREATOR) ||
              (_selectedProfessionTagId == POLITICIAN) ||
              (_selectedProfessionTagId == REG_UNION) ||
              (_selectedProfessionTagId == INDUSTRIALIST) ||
              (_selectedProfessionTagId == ARTIST) ||
              (_selectedProfessionTagId == MEDIA) ||
              (_selectedProfessionTagId == GOVTPSU) ||
              (_selectedProfessionTagId == DIRECTOR))
            ApiKeys.username: userNameController.text,

          if (_selectedProfessionTagId == POLITICIAN)
            ApiKeys.department: politicalPartyController.text,
          if (_selectedProfessionTagId == GOVTPSU)
            ApiKeys.department: departmentNameController.text,
          if (_selectedProfessionTagId == GOVTPSU)
            ApiKeys.subDivision: subDivision.text,
          if (_selectedProfessionTagId == REG_UNION)
            ApiKeys.department: _ngoNameTextController.text,

          if (_selectedProfessionTagId == INDUSTRIALIST)
            ApiKeys.department: _companyNameTextController.text,
          if (_selectedProfessionTagId == DIRECTOR)
            ApiKeys.department: _companyNameTextController.text,
          if (_selectedProfessionTagId == STUDENT)
            ApiKeys.schoolOrCollegeName: _CourseTextController.text,
          if (_selectedProfessionTagId == OTHERS)
            ApiKeys.specilization: _otherProfessionTextController.text,
          if (_selectedProfessionTagId == ARTIST)
            ApiKeys.art: jsonEncode({
              ApiKeys.artName: _selectedArtistObj?.tagId,
              ApiKeys.artType: _artTypeController.text
            }),
          if (_selectedProfessionTagId == HOMEMAKER)
            ApiKeys.art: jsonEncode({
              ApiKeys.artName: _ExpertiseTextController.text,
            }),

          if (_selectedProfessionTagId == SENIOR_CITIZEN)
            ApiKeys.art: jsonEncode({
              ApiKeys.artName: _SeniorTextController.text,
            }),

          ApiKeys.referred_by_code:
          _referralCodeEnable ? _referralCodeController.text : null,
          // if (position?.latitude != null && position?.longitude != null)
          ApiKeys.user_cordinates: jsonEncode({
            ApiKeys.lat: locationData.lat,
            ApiKeys.lon: locationData.long,
          }),
        };
        logs("requestData PERSONAL ==== ${requestData}");
        await authController.addIndivisualUser(reqData: requestData);
        setState(() {
          crBtnLoading=false;
        });
      }
      else{
        commonSnackBar(
            message:
            "Please enable your location permission and gps to access app features.");
        return;
      }

    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
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
                        color: Colors.black.withValues(alpha: 0.15))
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
