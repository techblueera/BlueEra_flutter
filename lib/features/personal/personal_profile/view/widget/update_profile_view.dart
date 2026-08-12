import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/view/aadhaar_locked_field.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/ai_suggestion_field.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/common_drop_down.dart';
import '../../../../../widgets/new_common_date_selection_dropdown.dart';
import '../../controller/email_verification_controller.dart';

class UpdateProfileScreen extends StatefulWidget {
  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen>
    with WidgetsBindingObserver {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final emailController = TextEditingController();
  final educationController = TextEditingController();
  final designationController = TextEditingController();
  final specializationController = TextEditingController();
  final professionOthersController = TextEditingController();
  final addBio = TextEditingController();
  final sectorTextController = TextEditingController();
  final _skillWorkerSpecificationTextController = TextEditingController();
  final _contentCraterTextController = TextEditingController();
  final _CourseTextController = TextEditingController();
  final _SeniorTextController = TextEditingController();
  final _ExpertiseTextController = TextEditingController();
  final _companyNameTextController = TextEditingController();
  final _ngoNameTextController = TextEditingController();
  final _artTypeController = TextEditingController();
  final emailVerificationController = Get.put(EmailVerificationController());
  final politicalPartyController = TextEditingController();
  final departmentNameController = TextEditingController();
  final subDivision = TextEditingController();
  bool updateBtnLoading = false;
  final personalCreateProfileController =
      Get.find<PersonalCreateProfileController>();
  final viewProfileController = Get.find<ViewPersonalDetailsController>();

  /// Name, gender and date of birth are frozen once the Aadhaar is verified —
  /// the card established them. Read inside the form's `Obx`, and the record it
  /// depends on is loaded in [initState], so the lock is in place by the time
  /// the fields are interactive.
  bool get _identityLocked => viewProfileController.isAadhaarVerified;
  bool isProfileCreateStatus = false;
  final authController = Get.find<AuthController>();
  AutovalidateMode _autoValidate = AutovalidateMode.always;

  clearTextFiled() {
    _artTypeController.clear();
    _ngoNameTextController.clear();
    _companyNameTextController.clear();
    _ExpertiseTextController.clear();
    _SeniorTextController.clear();
    _CourseTextController.clear();
    _contentCraterTextController.clear();
    designationController.clear();
    sectorTextController.clear();
    specializationController.clear();
    professionOthersController.clear();
    subDivision.clear();
    departmentNameController.clear();
    politicalPartyController.clear();
    _skillWorkerSpecificationTextController.clear();
    setState(() {});
  }


  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // Name / gender / DOB lock on a verified Aadhaar, and that record lives on
    // the rider onboarding response rather than the personal profile — load it
    // so the fields are correct from the first frame the user can touch them.
    // Cache-first and coalesced, so this is usually free.
    viewProfileController.ensureAadhaarStatusLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      isProfileCreateStatus =
          viewProfileController.personalProfileDetails.value.isProfileCreated ??
              false;
      nameController.text =
          viewProfileController.personalProfileDetails.value.user?.name ?? "";
      addBio.text =
          viewProfileController.personalProfileDetails.value.user?.bio ?? "";

      designationController.text = viewProfileController
              .personalProfileDetails.value.user?.designation ??
          "";

      emailController.text =
          viewProfileController.personalProfileDetails.value.user?.email ?? "";
      educationController.text = viewProfileController
              .personalProfileDetails.value.user?.highestEducation ??
          "";
      locationController.text =
          viewProfileController.personalProfileDetails.value.user?.location ??
              "";
      personalCreateProfileController.imagePath?.value = viewProfileController
              .personalProfileDetails.value.user?.profileImage ??
          "";
      personalCreateProfileController.coverImagePath?.value =
          viewProfileController
                  .personalProfileDetails.value.user?.coverPicture ??
              "";
      personalCreateProfileController.selectedGender
          .value = GenderTypeExtension.fromString((viewProfileController
                  .personalProfileDetails.value.user?.gender?.isNotEmpty ??
              false)
          ? viewProfileController.personalProfileDetails.value.user?.gender ??
              "male"
          : "male");

      personalCreateProfileController.selectedDay?.value = viewProfileController
              .personalProfileDetails.value.user?.dateOfBirth?.date
              ?.toInt() ??
          0;
      personalCreateProfileController.selectedMonth?.value =
          viewProfileController
                  .personalProfileDetails.value.user?.dateOfBirth?.month
                  ?.toInt() ??
              0;
      personalCreateProfileController.selectedYear?.value =
          viewProfileController
                  .personalProfileDetails.value.user?.dateOfBirth?.year
                  ?.toInt() ??
              0;
      personalCreateProfileController.selectedProfession.value =
          viewProfileController.personalProfileDetails.value.user?.profession ??
              OTHERS;
      selectedProfession =
          personalCreateProfileController.selectedProfession.value;

      /// OTHERS
      if (selectedProfession == OTHERS) {
        professionOthersController.text = viewProfileController
                .personalProfileDetails.value.user?.specilization ??
            "";
      }

      ///SELF EMPLOYEE
      if (selectedProfession == SELF_EMPLOYED) {
        personalCreateProfileController.selectedSubProfession.value =
            viewProfileController
                    .personalProfileDetails.value.user?.designation ??
                "OTHERS";

        personalCreateProfileController.selectedSubProfessionObj.value =
            SubcategoriesFiledName(
                tagId: viewProfileController
                    .personalProfileDetails.value.user?.designation,
                name: viewProfileController
                    .personalProfileDetails.value.user?.designation);

        specializationController.text = viewProfileController
                .personalProfileDetails.value.user?.specilization ??
            "";
      }

      ///PRIVATE JOB
      if (selectedProfession == PRIVATE_JOB) {
        sectorTextController.text =
            viewProfileController.personalProfileDetails.value.user?.sector ??
                "";
      }

      ///SKILL WORKER..
      if (selectedProfession == SKILLED_WORKER) {
        _skillWorkerSpecificationTextController.text = viewProfileController
                .personalProfileDetails.value.user?.specilization ??
            "";
      }

      ///CONTENT CREATER
      if (selectedProfession == CONTENT_CREATOR) {
        _contentCraterTextController.text = viewProfileController
                .personalProfileDetails.value.user?.specilization ??
            "";
      }

      ///POLITICIAN
      if (selectedProfession == POLITICIAN) {
        politicalPartyController.text = viewProfileController
                .personalProfileDetails.value.user?.department ??
            "";
      }

      ///GOVT PSU
      if (selectedProfession == GOVTPSU) {
        departmentNameController.text = viewProfileController
                .personalProfileDetails.value.user?.department ??
            "";
        subDivision.text = viewProfileController
                .personalProfileDetails.value.user?.subDivision ??
            "";
      }

      ///NGO
      if (selectedProfession == REG_UNION) {
        _ngoNameTextController.text = viewProfileController
                .personalProfileDetails.value.user?.department ??
            "";
      }

      ///ARTIST
      if (selectedProfession == ARTIST) {
        personalCreateProfileController.selectedSubProfession.value =
            viewProfileController
                    .personalProfileDetails.value.user?.art?.artName ??
                "OTHERS";

        personalCreateProfileController.selectedSubProfessionObj.value =
            SubcategoriesFiledName(
                tagId: viewProfileController
                    .personalProfileDetails.value.user?.art?.artName,
                name: viewProfileController
                    .personalProfileDetails.value.user?.art?.artName);

        _artTypeController.text = viewProfileController
                .personalProfileDetails.value.user?.art?.artType ??
            "";
      }

      personalCreateProfileController.selectedProfessionObj.value =
          ProfessionTypeData(
              tagId: selectedProfession,
              name: selectedProfession?.toLowerCase());
    });
    tempImgPath = personalCreateProfileController.imagePath?.value;
    Future.delayed(Duration(seconds: 1), () {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      viewProfileController.viewPersonalProfile();
    }
  }

  bool onChangedEmail = false;
  String? selectedProfession;
  String? tempImgPath;

  @override
  Widget build(BuildContext context) {
    // Leaving without saving must put the profile photo back: picking one
    // writes straight into the shared controller, so an un-saved pick would
    // otherwise follow the user out to every other screen reading it.
    //
    // `canPop: false` + an explicit `Get.back()` rather than letting the pop
    // through, so the restore is guaranteed to run before the route goes —
    // matching the app bar's own back handler above. Same contract the
    // WillPopScope this replaced had (it returned false and popped itself).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Get.back();
        personalCreateProfileController.imagePath?.value = tempImgPath ?? "";
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          isLeading: true,
          title: AppStrings.editProfile,
          onBackTap: () {
            Get.back();
            personalCreateProfileController.imagePath?.value =
                tempImgPath ?? "";
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size18,
                        vertical: SizeConfig.size10),
                    child: Column(
                      children: [
                        Obx(() {
                          return Column(
                            children: [
                              SizedBox(height: SizeConfig.size10),

                              ///UPLOAD PROFILE....
                              Center(
                                child: CommonProfileImage(
                                  imagePath: personalCreateProfileController
                                          .imagePath?.value ??
                                      "",
                                  onImageUpdate: (image) {
                                    personalCreateProfileController
                                        .imagePath?.value = image;
                                    personalCreateProfileController
                                        .isImageUpdated.value = true;
                                    filedValidation();
                                  },
                                  dialogTitle: AppStrings.uploadProfilePicture,
                                ),
                              ),
                              SizedBox(height: SizeConfig.size14),
                              CustomText(
                                AppStrings.profilePicture,
                                fontWeight: FontWeight.bold,
                                fontSize: SizeConfig.large,
                              ),
                              SizedBox(height: SizeConfig.size8),
                              CustomText(AppStrings.updatePhotoMessage,
                                  color: AppColors.grey80,
                                  fontSize: SizeConfig.medium),
                              SizedBox(height: SizeConfig.size24),

                              // Name / gender / date of birth are frozen once
                              // the Aadhaar is verified: the card established
                              // them, so editing them here would undo the
                              // verification. Everything else on this screen
                              // (photo, email, location, bio, profession)
                              // stays editable.
                              AadhaarLockedField(
                                locked: _identityLocked,
                                child: CommonTextField(
                                  title: AppStrings.fullName,
                                  hintText: AppStrings.enterFullName,
                                  inputLength: 30,
                                  textEditController: nameController,
                                  validationType: ValidationTypeEnum.name,
                                  autovalidateMode: _autoValidate,
                                  readOnly: _identityLocked,
                                  onChange: (val) {
                                    filedValidation();
                                  },
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return AppStrings.pleaseEnterName.tr;
                                    }
                                    // The 6–30 rule polices what a user TYPES.
                                    // A name off an Aadhaar card is neither
                                    // typed nor editable, so enforcing it on a
                                    // locked field would be a dead end — a
                                    // genuine short name would fail forever
                                    // with no way to correct it.
                                    if (_identityLocked) return null;
                                    if (value.trim().length < 6) {
                                      return AppStrings.nameMinLength.tr;
                                    } else if (value.trim().length > 30) {
                                      return AppStrings.nameMaxLength.tr;
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              SizedBox(height: SizeConfig.size18),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: CustomText(
                                  AppStrings.gender,
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: SizeConfig.paddingXSL),
                              AadhaarLockedField(
                                locked: _identityLocked,
                                child: CommonDropdown<GenderType>(
                                  items: GenderType.values,
                                  selectedValue: personalCreateProfileController
                                      .selectedGender.value,
                                  hintText: AppStrings.selectGender,
                                  displayValue: (value) => value.displayName,
                                  onChanged: (value) {
                                    personalCreateProfileController
                                        .selectedGender.value = value;
                                  },
                                  validator: (value) {
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: SizeConfig.size18),
                              Row(
                                children: [
                                  CustomText(
                                    AppStrings.dateOfBirth,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                              SizedBox(height: SizeConfig.paddingXSL),
                              AadhaarLockedField(
                                locked: _identityLocked,
                                child: NewDatePicker(
                                  isAgeValidation15: true,
                                  selectedDay: personalCreateProfileController
                                      .selectedDay?.value,
                                  selectedMonth: personalCreateProfileController
                                      .selectedMonth?.value,
                                  selectedYear: personalCreateProfileController
                                      .selectedYear?.value,
                                  onDayChanged: (value) {
                                    personalCreateProfileController
                                        .selectedDay?.value = value ?? 0;
                                  },
                                  onMonthChanged: (value) {
                                    personalCreateProfileController
                                        .selectedMonth?.value = value ?? 0;
                                  },
                                  onYearChanged: (value) {
                                    personalCreateProfileController
                                        .selectedYear?.value = value ?? 0;
                                  },
                                ),
                              ),
                              SizedBox(height: SizeConfig.size18),

                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteHelper.getSearchLocationScreenRoute(),
                                    arguments: {
                                      'onPlaceSelected': (double? lat,
                                          double? lng,
                                          String? address,
                                          bool? currentLocationSelected) {
                                        if (address != null) {
                                          locationController.text = address;
                                          personalCreateProfileController
                                              .setStartLocation(
                                                  lat, lng, address);
                                        }
                                      },
                                      ApiKeys.fromScreen: ""
                                    },
                                  );
                                },
                                child: CommonTextField(
                                  textEditController: locationController,
                                  hintText: "e.g.Rajiv Chowk, Delhi",
                                  isValidate: false,
                                  title: AppStrings.location,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RouteHelper
                                          .getSearchLocationScreenRoute(),
                                      arguments: {
                                        'onPlaceSelected': (
                                          double? lat,
                                          double? lng,
                                          String? address,
                                        ) {
                                          if (address != null) {
                                            locationController.text = address;
                                            personalCreateProfileController
                                                .setStartLocation(
                                                    lat, lng, address);
                                          }
                                        },
                                        ApiKeys.fromScreen: ""
                                      },
                                    );
                                  },
                                  // onChange: (value) => controller.validateForm(),
                                  readOnly: true,
                                  // Make it read-only since we'll use the search screen
                                ),
                              ),
                              SizedBox(height: SizeConfig.size18),

                              CommonTextField(
                                key: const ValueKey('edit_profile_email_field'),
                                title: AppStrings.email,
                                hintText: AppStrings.enterEmailAddress,
                                textEditController: emailController,
                                validationType: ValidationTypeEnum.email,
                                readOnly: (viewProfileController
                                        .verifiedEmail.value ==
                                    emailController.text),
                                onChange: (val) {
                                  emailVerificationController.isVerified.value =
                                      false;
                                  filedValidation();
                                },
                                sIcon: (viewProfileController
                                            .verifiedEmail.value ==
                                        emailController.text)
                                    ? Icon(
                                        Icons.verified_user_outlined,
                                        color: AppColors.green39,
                                      )
                                    : null,
                              ),

                              if (viewProfileController.verifiedEmail.value !=
                                  emailController.text)
                                Padding(
                                  padding: EdgeInsets.only(
                                      right: SizeConfig.size10,
                                      top: SizeConfig.size10),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        // Validate just the email field
                                        if (emailController.text.isNotEmpty &&
                                            validateEmail(
                                                emailController.text)) {
                                          emailVerificationController
                                              .verifyEmail(
                                                  emailController.text);
                                        } else {
                                          commonSnackBar(
                                              message: AppStrings.invalidEmail);
                                        }
                                      },
                                      child: CustomText(
                                        AppStrings.getVerify,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),

                              // CustomText("title")
                              SizedBox(height: SizeConfig.size18),
                              CommonTextField(
                                title: AppStrings.highestEducation,
                                hintText: "eg. 12th, B.A, M.A, PhD",
                                textEditController: educationController,
                                maxLength: 16,
                                onChange: (val) {
                                  filedValidation();
                                },
                                validator: (value) {
                                  if (value!.trim().length < 2) {
                                    return AppStrings.educationMinLength.tr;
                                  } else if (value.trim().length > 16) {
                                    return AppStrings.educationMaxLength.tr;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: SizeConfig.size18),
                              /*     Row(
                                children: [
                                  CustomText(
                                    AppStrings.selectYourProfession,
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                              SizedBox(height: SizeConfig.paddingXSL),
                              GetBuilder<AuthController>(
                                  builder: (authController) {
                                    final selectedValue = personalCreateProfileController.selectedProfession.value;

                                    log('Comparing: Controller Value ($selectedValue) vs Local Variable ($selectedProfession)');

                                    if (selectedValue == selectedProfession) {
                                      log('Values are equal. Proceeding with lookup.');
                                    }

                                    final selectedProfessionData = authController.professionTypeDataList.firstWhereOrNull(
                                          (e) => e.tagId == selectedProfession,
                                    );

                                    if (selectedProfessionData != null) {
                                      authController.clearSubCategoryData();

                                      // Directly add the subcategories without needing to access .first of a list
                                      authController.subcategoriesFiledNameList.addAll(
                                        selectedProfessionData.subcategoriesFiledName ?? [],
                                      );
                                      log('Updated subcategories: ${authController.subcategoriesFiledNameList}');
                                    } else {
                                      log('No profession found for the selected tagId');
                                    }
                                return CommonDropdownDialog<ProfessionTypeData>(
                                  items: authController.professionTypeDataList,
                                  selectedValue: personalCreateProfileController
                                      .selectedProfessionObj.value,
                                  hintText: AppConstants.selectProfession,
                                  title: AppStrings.selectYourProfession,
                                  displayValue: (profession) =>
                                      profession.name ?? "",
                                  onChanged: (value) {
                                    log('selected profession tagId -- ${value?.tagId}');
                                    log('selected profession name -- ${value?.name}');
                                    personalCreateProfileController
                                        .selectedSubProfessionObj.value = null;

                                    authController.clearSubCategoryData();

                                    personalCreateProfileController
                                        .selectedProfessionObj.value = value;
                                    personalCreateProfileController.selectedProfession.value = value?.tagId;
                                    selectedProfession = personalCreateProfileController.selectedProfession.value;
                                    log('selected profession -- $selectedProfession');
                                    authController.subcategoriesFiledNameList
                                        .addAll(value?.subcategoriesFiledName ??
                                            []);
                                    clearTextFiled();
                                    setState(() {});
                                  },
                                );
                              }),*/

                              // SizedBox(height: SizeConfig.size18),

                              /*    if (selectedProfession == OTHERS) ...[
                                CommonTextField(
                                  hintText: AppStrings.enterProfessionIfOthers,
                                  title: AppStrings.specifyProfession,
                                  isValidate: false,
                                  inputLength: 24,
                                  textEditController: professionOthersController,
                                ),
                                SizedBox(height: SizeConfig.size18),
                              ],

                              if (selectedProfession == SELF_EMPLOYED) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),

                                ///selectYourProfession
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: CustomText(
                                    AppStrings.selectWorkType,
                                    fontSize: SizeConfig.medium,
                                  ),
                                ),
                                SizedBox(
                                  height: SizeConfig.size10,
                                ),
                                Obx(() {
                                  return CommonDropdownDialog<
                                      SubcategoriesFiledName>(
                                    items: authController
                                        .subcategoriesFiledNameList,
                                    title: AppStrings.selectWorkType,
                                    selectedValue:
                                        personalCreateProfileController
                                            .selectedSubProfessionObj.value,
                                    hintText: AppStrings.professionExample,
                                    displayValue: (selfEmployment) =>
                                        selfEmployment.name ?? "",
                                    onChanged: (value) {
                                      personalCreateProfileController
                                          .selectedSubProfessionObj
                                          .value = value;
                                      personalCreateProfileController
                                          .selectedSubProfession
                                          .value = value?.tagId;
                                      filedValidation();
                                    },
                                  );
                                }),
                                SizedBox(
                                  height: SizeConfig.size15,
                                ),
                                CommonTextField(
                                  textEditController: specializationController,
                                  inputLength: 24,
                                  // maxLength: 24,
                                  isValidate: false,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  titleColor: Colors.black,
                                  hintText: AppStrings.pleaseSpecifyWorkType,
                                ),
                                SizedBox(
                                  height: SizeConfig.size15,
                                ),
                              ],

                              if ((selectedProfession == CONTENT_CREATOR)) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  isValidate: false,

                                  textEditController:
                                      _contentCraterTextController,
                                  // inputLength: 13,
                                  inputLength: 24,
                                  title: AppStrings.typeYourSpecification,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  hintText: AppStrings.specificationExample,
                                ),
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                              ],

                              if ((selectedProfession == SKILLED_WORKER)) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  textEditController:
                                  _skillWorkerSpecificationTextController,
                                  inputLength: 24,
                                  title: AppStrings.typeWorkSpecification,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  hintText:AppStrings.workExample,
                                  isValidate: false,
                                ),
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                              ],

                              if ((selectedProfession == REG_UNION)) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  isValidate: false,
                                  textEditController: _ngoNameTextController,
                                  inputLength: 40,
                                  title: AppStrings.typeNGOName,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  hintText:AppStrings.ngoExample,
                                ),
                                // SizedBox(
                                //   height: SizeConfig.size18,
                                // ),
                              ],

                              if ((selectedProfession == INDUSTRIALIST)) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  isValidate: false,
                                  textEditController: _companyNameTextController,
                                  // inputLength: 13,
                                  inputLength: 24,
                                  title: AppStrings.typeCompanyName,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  hintText: AppStrings.companyExample,
                                ),
                                // SizedBox(
                                //   height: SizeConfig.size18,
                                // ),
                              ],

                              if ((selectedProfession == HOMEMAKER)) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  isValidate: false,
                                  textEditController: _ExpertiseTextController,
                                  inputLength: 24,
                                  title: AppStrings.typeExpertise,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  hintText:AppStrings.expertiseExample1,
                                ),
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                              ],

                              if ((selectedProfession == SENIOR_CITIZEN)) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  isValidate: false,
                                  textEditController: _SeniorTextController,
                                  inputLength: 24,
                                  title: AppStrings.typeExpertise,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  hintText:AppStrings.expertiseExample2,
                                ),
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                              ],

                              if ((selectedProfession == STUDENT)) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  isValidate: false,
                                  textEditController: _CourseTextController,
                                  inputLength: 24,
                                  title: AppStrings.whichClassStudy,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  hintText: AppStrings.studyExample,
                                ),
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                              ],

                              if ((selectedProfession == ARTIST)) ...[
                                SizedBox(height: SizeConfig.size18),

                                ///selectYourProfession
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: CustomText(
                                    AppStrings.selectArtSkill,
                                    fontSize: SizeConfig.medium,
                                  ),
                                ),
                                SizedBox(
                                  height: SizeConfig.size10,
                                ),
                                CommonDropdownDialog<SubcategoriesFiledName>(
                                  items:
                                      authController.subcategoriesFiledNameList,
                                  title: AppStrings.selectArtSkill,
                                  selectedValue: personalCreateProfileController
                                      .selectedSubProfessionObj.value,
                                  hintText: AppStrings.artExample,
                                  displayValue: (selfEmployment) =>
                                      selfEmployment.name ?? "",
                                  onChanged: (value) {
                                    personalCreateProfileController
                                        .selectedSubProfessionObj.value = value;
                                    personalCreateProfileController
                                        .selectedSubProfession
                                        .value = value?.tagId;
                                  },
                                ),
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),

                                if (personalCreateProfileController
                                        .selectedSubProfessionObj.value !=
                                    null) ...[
                                  CommonTextField(
                                    isValidate: false,
                                    textEditController: _artTypeController,
                                    // inputLength: 13,
                                    inputLength: 24,
                                    keyBoardType: TextInputType.text,
                                    regularExpression: RegularExpressionUtils
                                        .alphabetSpacePattern,
                                    titleColor: Colors.black,
                                    hintText: AppStrings.pleaseSpecifyArtType,
                                  ),
                                  SizedBox(
                                    height: SizeConfig.size18,
                                  ),
                                ],
                              ],

                              if ((selectedProfession == POLITICIAN)) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  title: AppStrings.politicalParty,
                                  inputLength: 24,
                                  hintText:
                                  AppStrings.enterPoliticalParty,
                                  textEditController: politicalPartyController,
                                  isValidate: false,
                                ),
                                // SizedBox(height: SizeConfig.size18),
                              ],

                              if (selectedProfession == GOVTPSU) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  title: AppStrings.departmentName,
                                  textEditController: departmentNameController,
                                  inputLength: 24,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern_,
                                  titleColor: Colors.black,
                                  hintText: AppStrings.departmentExample,
                                  isValidate: false,
                                ),
                                SizedBox(height: SizeConfig.size18),
                                CommonTextField(
                                  title: AppStrings.subDivision,
                                  textEditController: subDivision,
                                  inputLength: 24,
                                  isValidate: false,
                                  keyBoardType: TextInputType.text,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern_,
                                  titleColor: Colors.black,
                                  hintText: AppStrings.subDivisionExample,
                                ),
                                // SizedBox(height: SizeConfig.size18),
                              ],

                              if (selectedProfession == PRIVATE_JOB) ...[
                                SizedBox(
                                  height: SizeConfig.size18,
                                ),
                                CommonTextField(
                                  textEditController: sectorTextController,
                                  inputLength: 24,
                                  keyBoardType: TextInputType.text,
                                  // isValidate: false,
                                  regularExpression: RegularExpressionUtils
                                      .alphabetSpacePattern,
                                  title: AppStrings.sector,
                                  hintText: AppStrings.sectorExample,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppStrings.enterSector.tr;
                                    }
                                    if (value.trim().length > 24) {
                                      return AppStrings.sectorMaxLength.tr;
                                    }
                                    return null;
                                  },
                                ),
                                // SizedBox(height: SizeConfig.size18),
                              ],

                              if (selectedProfession == DIRECTOR) ...[
                                SizedBox(height: SizeConfig.size18),
                                CommonTextField(
                                    isValidate: false,
                                    textEditController: _companyNameTextController,
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
                                // SizedBox(height: SizeConfig.size18)
                              ],

                              if ((selectedProfession != SELF_EMPLOYED) &&
                                  (selectedProfession != SKILLED_WORKER) &&
                                  (selectedProfession != ARTIST) &&
                                  (selectedProfession != CONTENT_CREATOR) &&
                                  (selectedProfession != HOMEMAKER) &&
                                  (selectedProfession != SENIOR_CITIZEN) &&
                                  (selectedProfession != FARMER) &&
                                  (selectedProfession != STUDENT) &&
                                  (selectedProfession != OTHERS)) ...[
                                SizedBox(height: SizeConfig.size18),

                                CommonTextField(
                                  title: AppStrings.designation,
                                  inputLength: 24,
                                  isValidate: false,
                                  hintText:AppStrings.enterDesignation,
                                  textEditController: designationController,
                                  onChange: (val) {
                                    // filedValidation();
                                  },
                                ),
                                SizedBox(height: SizeConfig.size18),
                              ],*/
                              AiSuggestionField(
                                title: AppStrings.aboutMe,
                                apiType: AppStrings.bio,
                                textController: addBio,
                                bodyRequest: {
                                  ApiKeys.profession: selectedProfession,
                                  ApiKeys.designation:
                                      designationController.text,
                                  ApiKeys.date_of_birth_Obj: {
                                    ApiKeys.year:
                                        personalCreateProfileController
                                            .selectedYear?.value,
                                    ApiKeys.month:
                                        personalCreateProfileController
                                            .selectedMonth?.value,
                                    ApiKeys.date:
                                        personalCreateProfileController
                                            .selectedDay?.value
                                  },
                                  ApiKeys.gender:
                                      personalCreateProfileController
                                          .selectedGender.value?.name
                                },
                                onSaved: filedValidation,

                                // call your validation here
                                onChange:
                                    filedValidation, // when user edits manually
                              ),

                              SizedBox(height: SizeConfig.size24),
                            ],
                          );
                        }),
                        Row(
                          children: [
                            Expanded(
                              child: PositiveCustomBtn(
                                radius: 10,
                                onTap: () {
                                  Get.back();
                                },
                                bgColor: AppColors.white,
                                title: AppStrings.cancel,
                                textColor: AppColors.primaryColor,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size16),
                            Expanded(
                                child: CustomBtn(
                                    isLoading: updateBtnLoading,
                                    radius: 10,
                                    isValidate: filedValidation(),
                                    onTap: filedValidation()
                                        ? () async {
                                            if (viewProfileController
                                                    .personalProfileDetails
                                                    .value
                                                    .user
                                                    ?.emailVerified ==
                                                true) {
                                              setState(() {
                                                updateBtnLoading =
                                                    !updateBtnLoading;
                                              });
                                              if (selectedProfession ==
                                                  ARTIST) {
                                                if (personalCreateProfileController
                                                        .selectedSubProfessionObj
                                                        .value
                                                        ?.name
                                                        ?.isEmpty ??
                                                    true) {
                                                  commonSnackBar(
                                                      message: AppStrings
                                                          .selectArtSkillLower);

                                                  return;
                                                }
                                              }
                                              if (selectedProfession ==
                                                  REG_UNION) {
                                                if (_ngoNameTextController
                                                    .text.isEmpty) {
                                                  commonSnackBar(
                                                      message: AppStrings
                                                          .enterNGOName);

                                                  return;
                                                }
                                              }

                                              if (selectedProfession ==
                                                  OTHERS) {
                                                if (professionOthersController
                                                    .text.isEmpty) {
                                                  commonSnackBar(
                                                      message: AppStrings
                                                          .enterSkillExpertise);
                                                  return;
                                                }
                                              }

                                              String? designation;
                                              if (selectedProfession ==
                                                  SELF_EMPLOYED) {
                                                designation =
                                                    personalCreateProfileController
                                                            .selectedSubProfessionObj
                                                            .value
                                                            ?.tagId ??
                                                        "";
                                              } else {
                                                designation =
                                                    designationController.text;
                                              }

                                              Map<String, dynamic> params = {
                                                if ((personalCreateProfileController
                                                            .imagePath
                                                            ?.value
                                                            .isNotEmpty ??
                                                        false) &&
                                                    personalCreateProfileController
                                                        .isImageUpdated.value)
                                                  ApiKeys.profile_image:
                                                      await multiPartImage(
                                                    imagePath:
                                                        personalCreateProfileController
                                                                .imagePath
                                                                ?.value ??
                                                            "",
                                                  ),
                                                // Identity fields are omitted
                                                // entirely for an Aadhaar-
                                                // verified account. The locked
                                                // inputs are the affordance;
                                                // this is the guarantee, and it
                                                // also keeps a save of the
                                                // OTHER fields from being
                                                // rejected wholesale by a
                                                // backend that refuses them.
                                                if (!_identityLocked &&
                                                    nameController
                                                        .text.isNotEmpty)
                                                  ApiKeys.name: nameController
                                                      .text
                                                      .trim(),
                                                ApiKeys.location:
                                                    locationController.text
                                                        .trim(),
                                                ApiKeys.user_cordinates:
                                                    jsonEncode({
                                                  ApiKeys.lat:
                                                      personalCreateProfileController
                                                          .locationLat?.value,
                                                  ApiKeys.lon:
                                                      personalCreateProfileController
                                                          .locationLng?.value,
                                                }),
                                                ApiKeys.email:
                                                    emailController.text.trim(),
                                                ApiKeys.highest_education:
                                                    educationController.text
                                                        .trim(),
                                                // if (shouldShowField('designation'))
                                                ApiKeys.profession:
                                                    personalCreateProfileController
                                                            .selectedProfession
                                                            .value ??
                                                        '',
                                                ApiKeys.designation:
                                                    designation,

                                                if (selectedProfession ==
                                                    SELF_EMPLOYED)
                                                  ApiKeys.specilization:
                                                      specializationController
                                                          .text,
                                                if (selectedProfession ==
                                                    OTHERS)
                                                  ApiKeys.specilization:
                                                      professionOthersController
                                                          .text,

                                                if ((selectedProfession ==
                                                    POLITICIAN))
                                                  'political_party':
                                                      politicalPartyController
                                                          .text
                                                          .trim(),
                                                if (selectedProfession ==
                                                    PRIVATE_JOB)
                                                  ApiKeys.sector:
                                                      sectorTextController.text,

                                                if (!_identityLocked)
                                                  ApiKeys.gender:
                                                      personalCreateProfileController
                                                          .selectedGender
                                                          .value
                                                          ?.name
                                                          .toLowerCase(),
                                                if (addBio.text.isNotEmpty)
                                                  ApiKeys.bio: addBio.text,

                                                if (!_identityLocked)
                                                  ApiKeys.date_of_birth_Obj:
                                                      jsonEncode({
                                                    ApiKeys.date:
                                                        personalCreateProfileController
                                                            .selectedDay?.value,
                                                    ApiKeys.month:
                                                        personalCreateProfileController
                                                            .selectedMonth
                                                            ?.value,
                                                    ApiKeys.year:
                                                        personalCreateProfileController
                                                            .selectedYear
                                                            ?.value,
                                                  }),

                                                ///SKILL WORKER..
                                                if (selectedProfession ==
                                                    SKILLED_WORKER)
                                                  ApiKeys.specilization:
                                                      _skillWorkerSpecificationTextController
                                                          .text,

                                                ///CONTENT_CREATOR
                                                if (selectedProfession ==
                                                    CONTENT_CREATOR)
                                                  ApiKeys.specilization:
                                                      _contentCraterTextController
                                                          .text,

                                                ///GOVT PSU
                                                if (selectedProfession ==
                                                    GOVTPSU)
                                                  ApiKeys.department:
                                                      departmentNameController
                                                          .text,
                                                if (selectedProfession ==
                                                    GOVTPSU)
                                                  ApiKeys.subDivision:
                                                      subDivision.text,

                                                ///NGO
                                                if (selectedProfession ==
                                                    REG_UNION)
                                                  ApiKeys.department:
                                                      _ngoNameTextController
                                                          .text,

                                                ///Artist...
                                                if (selectedProfession ==
                                                    ARTIST)
                                                  ApiKeys.art: jsonEncode({
                                                    ApiKeys.artName:
                                                        personalCreateProfileController
                                                            .selectedSubProfessionObj
                                                            .value
                                                            ?.name,
                                                    ApiKeys.artType:
                                                        _artTypeController.text
                                                  }),
                                              };
                                              await personalCreateProfileController
                                                  .updateUserProfileDetails(
                                                params: params,
                                              );
                                              setState(() {
                                                updateBtnLoading =
                                                    !updateBtnLoading;
                                              });
                                            } else {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    // constraints: BoxConstraints(
                                                    //   maxHeight: 200
                                                    // ),
                                                    scrollable: false,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),

                                                    content: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Center(
                                                            child: CustomText(
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              AppStrings
                                                                  .emailVerificationRequired,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: SizeConfig
                                                                .size8,
                                                          ),
                                                          Center(
                                                            child: CustomText(
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              AppStrings
                                                                  .emailVerificationMessage,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: AppColors
                                                                  .grayText,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: SizeConfig
                                                                .size4,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }
                                          }
                                        : null,
                                    title: AppStrings.update))
                          ],
                        ),
                        SizedBox(
                          height: SizeConfig.size10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: kToolbarHeight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  filedValidation() {
    bool isValid = true;
    if (nameController.text.isEmpty ||
        nameController.text.trim().length < 6 ||
        nameController.text.trim().length > 30) isValid = false;

    if (personalCreateProfileController.isImageUpdated.value) isValid = true;
    if (locationController.text.isEmpty) isValid = false;
    if (ValidationMethod.validateEmail(emailController.text) != null)
      isValid = false;
    if (emailController.text.isEmpty) isValid = false;
    if (educationController.text.isEmpty ||
        educationController.text.trim().length < 2 ||
        educationController.text.trim().length > 16) isValid = false;

    if (selectedProfession == OTHERS && professionOthersController.text.isEmpty)
      isValid = false;
    if ((selectedProfession == PRIVATE_JOB) &&
        sectorTextController.text.isEmpty) isValid = false;
    if (addBio.text.isEmpty || addBio.text.length < 50) isValid = false;

    setState(() {});
    return isValid;
  }
}
