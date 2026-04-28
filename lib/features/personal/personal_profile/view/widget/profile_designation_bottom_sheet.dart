import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/individual_profile_type_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/string_utils.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/individual_field_response_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_drop_down_icon_dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Profile-data bottom sheet — mirrors `_showCategoryBottomSheet` in
/// `personal_profile_setup_new_screen.dart`. Lives here as a standalone function so
/// any "Edit profile" surface (the [EditProfileBottomSheet], the dashboards,
/// etc.) can pop the same designation editor without duplicating ~600 lines
/// of profession/designation logic.
///
/// Returns `true` when the user submitted a save successfully so the caller
/// can refresh dependent UI; `null` if the sheet was dismissed without
/// saving.
Future<bool?> showProfileDesignationSheet(BuildContext context) {
  final controller =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final authController = getOrPut(() => AuthController());
  final personalController = getOrPut(() => PersonalCreateProfileController());

  final user = controller.personalProfileDetails.value.user;
  IndividualProfileTypeModel _selectedProfileType =
      IndividualProfileTypeModel.fromString(user?.profileType ?? SOCIAL_PROFILE);
  ProfessionTypeData? _selectedProfession;
  List<ProfessionTypeData> professionCategoryList = <ProfessionTypeData>[];

  final designation = user?.designation ?? '';
  IndividualFields? _selectedContentCreatorSpecialization;
  SubCategories? _selectedDesignationObj;
  final _designationController = TextEditingController();

  final _specializationCtrl = TextEditingController();
  final _ngoNameTextCtrl = TextEditingController();
  final _expertiseTextCtrl = TextEditingController();
  final _seniorTextCtrl = TextEditingController();
  final _courseTextCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _sectorTextCtrl = TextEditingController();
  final _governmentNameCtrl = TextEditingController();
  final _politicalPartyCtrl = TextEditingController();
  final _departmentNameCtrl = TextEditingController();
  final _subDivisionCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void updateCategoryOfProfession(String typeId) {
    switch (typeId) {
      case SOCIAL_PROFILE:
        professionCategoryList =
            authController.individualOnboardingSocialProfileList;
        break;
      case GIG_WORKER:
        professionCategoryList = authController.individualOnboardingGigWorkList;
        break;
      case SELF_EMPLOYED:
        professionCategoryList =
            authController.individualOnboardingSkillWorkList;
        break;
      case PROFESSIONAL:
        professionCategoryList =
            authController.individualOnboardingConsultationList;
        break;
      default:
        professionCategoryList = const [];
    }
  }

  void initData() {
    if (authController.professionTypeDataList.isEmpty) {
      authController.getAllIndividualProfession().then((_) {
        updateCategoryOfProfession(_selectedProfileType.type);
      });
    }
    updateCategoryOfProfession(_selectedProfileType.type);

    final currentSlug = user?.profession;
    if (currentSlug != null && currentSlug.isNotEmpty) {
      _selectedProfession = professionCategoryList
          .firstWhereOrNull((e) => e.tagId == currentSlug);
    }
    if (_selectedProfession == null) return;

    if (_selectedProfileType.type == PROFESSIONAL ||
        _selectedProfession?.tagId == CONTENT_CREATOR ||
        _selectedProfession?.tagId == ARTIST) {
      authController
          .fetchIndividualFields(tagId: _selectedProfession!.tagId ?? '')
          .then((_) {
        if (authController.arrIndividualFields.isEmpty) return;

        if (_selectedProfession?.tagId == CONTENT_CREATOR) {
          final mainList = authController.arrIndividualFields;
          _selectedContentCreatorSpecialization =
              mainList.firstWhereOrNull((e) => e.name == designation);
        }

        final subList =
            authController.arrIndividualFields[0].subcategories ?? [];
        _selectedDesignationObj =
            subList.firstWhereOrNull((e) => e.name == designation);
      });
    } else if (_selectedProfession?.tagId == HOMEMAKER) {
      _expertiseTextCtrl.text = designation;
    } else if (_selectedProfession?.tagId == SENIOR_CITIZEN) {
      _seniorTextCtrl.text = designation;
    } else {
      _designationController.text = designation;
    }

    if (_selectedProfileType.type == SELF_EMPLOYED ||
        _selectedProfileType.type == GIG_WORKER) {
      _specializationCtrl.text = user?.specilization ?? '';
    }
    if (_selectedProfession?.tagId == PRIVATE_JOB) {
      _sectorTextCtrl.text = user?.sector ?? '';
    }
    if (_selectedProfession?.tagId == GOVERNMENT_JOB) {
      _governmentNameCtrl.text = user?.department ?? '';
    }
    if (_selectedProfession?.tagId == POLITICIAN) {
      _politicalPartyCtrl.text = user?.department ?? '';
    }
    if (_selectedProfession?.tagId == GOVTPSU) {
      _departmentNameCtrl.text = user?.department ?? '';
      _subDivisionCtrl.text = user?.subDivision ?? '';
    }
    if (_selectedProfession?.tagId == REG_UNION ||
        _selectedProfession?.tagId == NGO) {
      _ngoNameTextCtrl.text = user?.department ?? '';
    }
    if (_selectedProfession?.tagId == INDUSTRIALIST ||
        _selectedProfession?.tagId == DIRECTOR) {
      _companyNameCtrl.text = user?.department ?? '';
    }
    if (_selectedProfession?.tagId == STUDENT) {
      _courseTextCtrl.text = user?.schoolOrCollegeName ?? '';
    }
  }

  Future<bool> onSubmit() async {
    if (_selectedProfileType.type == PROFESSIONAL) {
      if (_selectedDesignationObj?.name?.isEmpty ?? true) {
        commonSnackBar(message: 'Select your profession');
        return false;
      }
    }
    if (_selectedProfession?.tagId == ARTIST) {
      if (_selectedDesignationObj?.name?.isEmpty ?? true) {
        commonSnackBar(message: 'Select your art / skill');
        return false;
      }
    }
    if (_selectedProfession?.tagId == REG_UNION ||
        _selectedProfession?.tagId == NGO) {
      if (_ngoNameTextCtrl.text.isEmpty) {
        commonSnackBar(message: 'Enter your NGO / Society Name');
        return false;
      }
    }
    if (_selectedProfession?.tagId == CONTENT_CREATOR) {
      if (_selectedContentCreatorSpecialization?.name?.isEmpty ?? true) {
        commonSnackBar(message: 'Select your Field');
        return false;
      }
      if (_selectedDesignationObj?.name?.isEmpty ?? true) {
        commonSnackBar(message: 'Select your Specification');
        return false;
      }
    }

    String? designation;
    if (_selectedProfileType.type == SELF_EMPLOYED ||
        _selectedProfileType.type == GIG_WORKER) {
      designation = formatRole(_selectedProfession?.tagId ?? '');
    } else if (_selectedProfileType.type == PROFESSIONAL) {
      designation = _selectedDesignationObj?.name;
    } else {
      switch (_selectedProfession?.tagId) {
        case STUDENT:
          designation = formatRole(STUDENT);
          break;
        case FARMER:
          designation = formatRole(FARMER);
          break;
        case HOMEMAKER:
          designation = _expertiseTextCtrl.text.trim();
          break;
        case SENIOR_CITIZEN:
          designation = _seniorTextCtrl.text.trim();
          break;
        case ARTIST:
        case CONTENT_CREATOR:
          designation = _selectedDesignationObj?.name;
          break;
        default:
          designation = _designationController.text.trim();
      }
    }

    final requestData = <String, dynamic>{
      ApiKeys.profileType: _selectedProfileType.type,
      ApiKeys.profession: _selectedProfession?.tagId,
      ApiKeys.designation: designation,
      if (_selectedProfession?.tagId == PRIVATE_JOB)
        ApiKeys.sector: _sectorTextCtrl.text,
      if (_selectedProfileType.type == SELF_EMPLOYED ||
          _selectedProfileType.type == GIG_WORKER)
        ApiKeys.specilization: _specializationCtrl.text.trim(),
      if (_selectedProfession?.tagId == CONTENT_CREATOR)
        ApiKeys.specilization: _selectedContentCreatorSpecialization?.name,
      if (_selectedProfession?.tagId == GOVERNMENT_JOB)
        ApiKeys.department: _governmentNameCtrl.text.trim(),
      if (_selectedProfession?.tagId == POLITICIAN)
        ApiKeys.department: _politicalPartyCtrl.text.trim(),
      if (_selectedProfession?.tagId == GOVTPSU)
        ApiKeys.department: _departmentNameCtrl.text.trim(),
      if (_selectedProfession?.tagId == GOVTPSU)
        ApiKeys.subDivision: _subDivisionCtrl.text.trim(),
      if (_selectedProfession?.tagId == REG_UNION ||
          _selectedProfession?.tagId == NGO)
        ApiKeys.department: _ngoNameTextCtrl.text.trim(),
      if (_selectedProfession?.tagId == INDUSTRIALIST)
        ApiKeys.department: _companyNameCtrl.text.trim(),
      if (_selectedProfession?.tagId == DIRECTOR)
        ApiKeys.department: _companyNameCtrl.text.trim(),
      if (_selectedProfession?.tagId == STUDENT)
        ApiKeys.schoolOrCollegeName: _courseTextCtrl.text.trim(),
    };

    log('requestData PERSONAL ==== $requestData');
    await personalController.updateUserProfileDetails(
      params: requestData,
      isFromProfileOnly: true,
      showProgress: false,
    );
    return true;
  }

  initData();

  return Get.bottomSheet<bool>(
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return SafeArea(
          child: Container(
            padding:
                const EdgeInsets.only(bottom: 30, right: 20, left: 20, top: 5),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            'Profile Data',
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.large,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    CustomText(
                      'Select Profile Type',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdownIconDialog<IndividualProfileTypeModel>(
                      items: profileTypeList,
                      selectedValue: _selectedProfileType,
                      title: 'Select Profile Type',
                      hintText: 'Select Profile Type',
                      displayValue: (item) => item.title,
                      displayValueSubTitle: (item) => item.subTitle,
                      displayValueImagePath: (item) => item.icon,
                      onChanged: (val) {
                        if (val == null ||
                            _selectedProfileType.type == val.type) return;
                        _selectedProfession = null;
                        _designationController.clear();
                        _selectedContentCreatorSpecialization = null;
                        _selectedDesignationObj = null;
                        setState(() {
                          _selectedProfileType = val;
                          updateCategoryOfProfession(val.type);
                        });
                      },
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    CustomText(
                      'Select Profession',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdownDialog<ProfessionTypeData>(
                      items: professionCategoryList,
                      selectedValue: _selectedProfession,
                      title: 'Select Profession',
                      hintText: _selectedProfileType.hintText,
                      displayValue: (item) => (item.name ?? '').tr,
                      onChanged: (val) {
                        if (val == null ||
                            _selectedProfession?.tagId == val.tagId) return;
                        _designationController.clear();
                        _selectedContentCreatorSpecialization = null;
                        _selectedDesignationObj = null;
                        _selectedProfession = val;
                        if (_selectedProfileType.type == PROFESSIONAL ||
                            _selectedProfession?.tagId == CONTENT_CREATOR ||
                            _selectedProfession?.tagId == ARTIST) {
                          authController.fetchIndividualFields(
                              tagId: _selectedProfession?.tagId ?? '');
                        }
                        setState(() {});
                      },
                    ),
                    if (_selectedProfileType.type == SELF_EMPLOYED ||
                        _selectedProfileType.type == GIG_WORKER) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _specializationCtrl,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        titleColor: Colors.black,
                        title: 'Specialization',
                        hintText: 'Please specify work type',
                      ),
                    ],
                    if (_selectedProfileType.type == PROFESSIONAL) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CustomText(
                        'Expertise',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Obx(() => authController.isIndividualFieldLoading.value
                          ? const Center(child: CircularProgressIndicator())
                          : CommonDropdownDialog<SubCategories>(
                              items: List<SubCategories>.from(
                                  authController.arrIndividualFields.isNotEmpty
                                      ? (authController.arrIndividualFields[0]
                                              .subcategories ??
                                          [])
                                      : []),
                              selectedValue: _selectedDesignationObj,
                              title: 'Expertise',
                              hintText: 'Select expertise',
                              displayValue: (s) => s.name ?? '',
                              onChanged: (value) {
                                setState(() => _selectedDesignationObj = value);
                              },
                            )),
                    ],
                    if (_selectedProfession?.tagId == ARTIST) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CustomText(
                        'Select Your Art / Skill',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Obx(() => authController.isIndividualFieldLoading.value
                          ? const Center(child: CircularProgressIndicator())
                          : CommonDropdownDialog<SubCategories>(
                              items: List<SubCategories>.from(
                                  authController.arrIndividualFields.isNotEmpty
                                      ? (authController.arrIndividualFields[0]
                                              .subcategories ??
                                          [])
                                      : []),
                              selectedValue: _selectedDesignationObj,
                              title: 'Select Your Art / Skill',
                              hintText: 'Select expertise',
                              displayValue: (s) => s.name ?? '',
                              onChanged: (value) {
                                setState(() => _selectedDesignationObj = value);
                              },
                            )),
                    ],
                    if (_selectedProfession?.tagId == CONTENT_CREATOR) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      Obx(() => authController.isIndividualFieldLoading.value
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  'Select your Field',
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.mainTextColor,
                                ),
                                SizedBox(height: SizeConfig.size10),
                                CommonDropdownDialog<IndividualFields>(
                                  items: authController.arrIndividualFields,
                                  selectedValue:
                                      _selectedContentCreatorSpecialization,
                                  title: 'Select your Field',
                                  hintText: 'Select expertise',
                                  displayValue: (value) => value.name ?? '',
                                  onChanged: (value) {
                                    _selectedContentCreatorSpecialization =
                                        value;
                                    authController.arrIndividualSubCategories
                                      ..clear()
                                      ..addAll(
                                          _selectedContentCreatorSpecialization
                                                  ?.subcategories ??
                                              []);
                                    setState(() {});
                                  },
                                ),
                                SizedBox(height: SizeConfig.paddingM),
                                CustomText(
                                  'Select Your Specification',
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.mainTextColor,
                                ),
                                SizedBox(height: SizeConfig.size10),
                                CommonDropdownDialog<SubCategories>(
                                  items: authController
                                      .arrIndividualSubCategories,
                                  selectedValue: _selectedDesignationObj,
                                  title: 'Select Your Specification',
                                  hintText: 'Select expertise',
                                  displayValue: (s) => s.name ?? '',
                                  onChanged: (value) {
                                    setState(
                                        () => _selectedDesignationObj = value);
                                  },
                                ),
                              ],
                            )),
                    ],
                    if (_selectedProfession?.tagId == REG_UNION ||
                        _selectedProfession?.tagId == NGO) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _ngoNameTextCtrl,
                        inputLength: 40,
                        title: 'Type Your NGO / Society Name',
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        hintText: 'eg. Auto Union',
                      ),
                    ],
                    if (_selectedProfession?.tagId == INDUSTRIALIST ||
                        _selectedProfession?.tagId == DIRECTOR) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _companyNameCtrl,
                        inputLength: 24,
                        title: 'Type Your Company Name',
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        hintText: 'eg. TCS LTD',
                      ),
                    ],
                    if (_selectedProfession?.tagId == HOMEMAKER) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _expertiseTextCtrl,
                        inputLength: 24,
                        title: 'Type Your Expertise',
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        hintText: 'eg. Cooking,Dancing',
                      ),
                    ],
                    if (_selectedProfession?.tagId == SENIOR_CITIZEN) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _seniorTextCtrl,
                        inputLength: 24,
                        title: 'Type Your Expertise',
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        hintText: 'eg. Banking,Teaching',
                      ),
                    ],
                    if (_selectedProfession?.tagId == STUDENT) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _courseTextCtrl,
                        inputLength: 24,
                        title: 'Enter your Education',
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        hintText: 'eg. 10th,Diploma,BE,PHD',
                      ),
                    ],
                    if (_selectedProfession?.tagId == POLITICIAN) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        title: 'Political Party',
                        hintText:
                            'Enter political party or organization name',
                        textEditController: _politicalPartyCtrl,
                        inputLength: 50,
                      ),
                    ],
                    if (_selectedProfession?.tagId == GOVTPSU) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        title: 'Name of Department/PSU',
                        textEditController: _departmentNameCtrl,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern_,
                        titleColor: Colors.black,
                        hintText: 'eg., Ministry of Education',
                      ),
                      SizedBox(height: SizeConfig.size18),
                      CommonTextField(
                        isValidate: false,
                        title: 'SUB Division/Branch',
                        textEditController: _subDivisionCtrl,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern_,
                        titleColor: Colors.black,
                        hintText: 'eg., Civil Engineering Division',
                      ),
                    ],
                    if (_selectedProfession?.tagId == GOVERNMENT_JOB) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _governmentNameCtrl,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: 'Name of Government/PSU',
                        hintText: 'Eg. ONGC',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Name of Government/PSU';
                          }
                          if (value.trim().length > 24) {
                            return 'Name of Government/PSU must not exceed 24 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (_selectedProfession?.tagId == PRIVATE_JOB) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _sectorTextCtrl,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: 'Sector',
                        hintText: 'eg. IT Sector',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Sector';
                          }
                          if (value.trim().length > 24) {
                            return 'Sector must not exceed 24 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                    if ((_selectedProfileType.type != SELF_EMPLOYED) &&
                        (_selectedProfileType.type != GIG_WORKER) &&
                        (_selectedProfileType.type != PROFESSIONAL) &&
                        (_selectedProfession?.tagId != ARTIST) &&
                        (_selectedProfession?.tagId != CONTENT_CREATOR) &&
                        (_selectedProfession?.tagId != HOMEMAKER) &&
                        (_selectedProfession?.tagId != SENIOR_CITIZEN) &&
                        (_selectedProfession?.tagId != FARMER) &&
                        (_selectedProfession?.tagId != STUDENT) &&
                        (_selectedProfession?.tagId != OTHERS)) ...[
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        isValidate: false,
                        textEditController: _designationController,
                        inputLength: 24,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        title: 'Designation / Expertise',
                        hintText: 'Enter your designation/expertise',
                      ),
                    ],
                    SizedBox(height: SizeConfig.paddingL),
                    Obx(() => CustomBtn(
                          isLoading: personalController.updateBtnLoading.value,
                          onTap: () async {
                            final ok = await onSubmit();
                            if (ok && Get.isBottomSheetOpen == true) {
                              Get.back<bool>(result: true);
                            }
                          },
                          title: personalController.updateBtnLoading.value
                              ? null
                              : AppStrings.done,
                          radius: SizeConfig.size8,
                          bgColor: AppColors.primaryColor,
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
