import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/common_drop_down.dart';
import '../../../../../widgets/new_common_date_selection_dropdown.dart';

class UpdateProfileScreen extends StatefulWidget {
  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final emailController = TextEditingController();
  final educationController = TextEditingController();
  final designationController = TextEditingController();
  final specializationController = TextEditingController();
  final professionOthersController = TextEditingController();
  // final organizationController = TextEditingController();
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

  // final skillsController = TextEditingController();
  final politicalPartyController = TextEditingController();

  // final userNameController = TextEditingController();
  final departmentNameController = TextEditingController();
  final subDivision = TextEditingController();

  final personalCreateProfileController =
      Get.put(PersonalCreateProfileController());
  final viewProfileController = Get.find<ViewPersonalDetailsController>();
  bool isProfileCreateStatus = false;
  final authController = Get.find<AuthController>();

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

  ///API CALLING...
  apiCalling() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ///GETTING PROFESSION DATA LIST...
      await authController.getAllProfessionController();
    });
  }

  @override
  void initState() {
    apiCalling();

    isProfileCreateStatus =
        viewProfileController.personalProfileDetails.value.isProfileCreated ??
            false;
    nameController.text =
        viewProfileController.personalProfileDetails.value.user?.name ?? "";
    addBio.text =
        viewProfileController.personalProfileDetails.value.user?.bio ?? "";

    designationController.text =
        viewProfileController.personalProfileDetails.value.user?.designation ??
            "";

    emailController.text =
        viewProfileController.personalProfileDetails.value.user?.email ?? "";
    educationController.text = viewProfileController
            .personalProfileDetails.value.user?.highestEducation ??
        "";
    // organizationController.text = viewProfileController
    //         .personalProfileDetails.value.user?.currentOrganisation ??
    //     "";
    locationController.text =
        viewProfileController.personalProfileDetails.value.user?.location ?? "";
    personalCreateProfileController.imagePath?.value =
        viewProfileController.personalProfileDetails.value.user?.profileImage ??
            "";
    personalCreateProfileController.selectedGender.value =
        GenderTypeExtension.fromString((viewProfileController
                    .personalProfileDetails.value.user?.gender?.isNotEmpty ??
                false)
            ? viewProfileController.personalProfileDetails.value.user?.gender ??
                "male"
            : "male");

    personalCreateProfileController.selectedDay?.value = viewProfileController
            .personalProfileDetails.value.user?.dateOfBirth?.date
            ?.toInt() ??
        0;
    personalCreateProfileController.selectedMonth?.value = viewProfileController
            .personalProfileDetails.value.user?.dateOfBirth?.month
            ?.toInt() ??
        0;
    personalCreateProfileController.selectedYear?.value = viewProfileController
            .personalProfileDetails.value.user?.dateOfBirth?.year
            ?.toInt() ??
        0;
    personalCreateProfileController.selectedProfession.value =
        viewProfileController.personalProfileDetails.value.user?.profession ??
            "OTHERS";
    selectedProfession =
        personalCreateProfileController.selectedProfession.value;
    if (viewProfileController.personalProfileDetails.value.user?.profession ==
        OTHERS) {
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
          viewProfileController.personalProfileDetails.value.user?.sector ?? "";
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
      departmentNameController.text =
          viewProfileController.personalProfileDetails.value.user?.department ??
              "";
      subDivision.text = viewProfileController
              .personalProfileDetails.value.user?.subDivision ??
          "";
    }

    ///NGO
    if (selectedProfession == REG_UNION) {
      _ngoNameTextController.text =
          viewProfileController.personalProfileDetails.value.user?.department ??
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
    selectedProfession = personalCreateProfileController
        .selectedProfession.value;
    personalCreateProfileController
        .selectedProfessionObj.value =
        ProfessionTypeData(
            tagId: selectedProfession,
            name: selectedProfession?.toLowerCase());
    super.initState();
  }

  String? selectedProfession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(isLeading: true, title: "Update Profile"),
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
                  child: Obx(() {


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
                              personalCreateProfileController.imagePath?.value =
                                  image;
                              personalCreateProfileController
                                  .isImageUpdated.value = true;
                            },
                          ),
                        ),
                        SizedBox(height: SizeConfig.size14),
                        CustomText(
                          "Profile Picture",
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.large,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        CustomText("You can update your photo anytime.",
                            color: AppColors.grey80,
                            fontSize: SizeConfig.medium),
                        SizedBox(height: SizeConfig.size24),

                        CommonTextField(
                          title: "Full Name",
                          hintText: "Enter your full name",
                          textEditController: nameController,
                          validationType: ValidationTypeEnum.name,
                        ),
                        SizedBox(height: SizeConfig.size18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomText(
                            "Gender",
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        CommonDropdown<GenderType>(
                          items: GenderType.values,
                          selectedValue: personalCreateProfileController
                              .selectedGender.value,
                          hintText: "Select Gender",
                          displayValue: (value) => value.displayName,
                          onChanged: (value) {
                            personalCreateProfileController
                                .selectedGender.value = value;
                          },
                          validator: (value) {
                            return null;
                          },
                        ),
                        SizedBox(height: SizeConfig.size18),
                        Row(
                          children: [
                            CustomText(
                              "Date of Birth",
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        NewDatePicker(
                          isAgeValidation15: true,
                          selectedDay: personalCreateProfileController
                              .selectedDay?.value,
                          selectedMonth: personalCreateProfileController
                              .selectedMonth?.value,
                          selectedYear: personalCreateProfileController
                              .selectedYear?.value,
                          onDayChanged: (value) {
                            personalCreateProfileController.selectedDay?.value =
                                value ?? 0;
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
                                    // bool? currentLocationSelected
                                    ) {
                                  if (address != null) {
                                    locationController.text = address;
                                    personalCreateProfileController
                                        .setStartLocation(lat, lng, address);
                                  }
                                },
                                ApiKeys.fromScreen: ""
                              },
                            );
                          },
                          child: CommonTextField(
                            textEditController: locationController,
                            hintText: "E.g., Rajiv Chowk, Delhi",
                            isValidate: false,
                            title: "Location",

                            // onChange: (value) => controller.validateForm(),
                            readOnly: true,
                            // Make it read-only since we'll use the search screen
                          ),
                        ),
                        SizedBox(height: SizeConfig.size18),
                        CommonTextField(
                          title: "Email",
                          hintText: "Enter your email address",
                          textEditController: emailController,
                          validationType: ValidationTypeEnum.email,
                          onChange: (val) {
                            filedValidation();
                          },
                          sIcon: viewProfileController.personalProfileDetails
                                      .value.user?.emailVerified ??
                                  false
                              ? Icon(
                                  Icons.verified_user_outlined,
                                  color: AppColors.green39,
                                )
                              : null,
                        ),
                        // CustomText("title")
                        SizedBox(height: SizeConfig.size18),
                        CommonTextField(
                          title: "Highest Education",
                          hintText: "Eg. 12th, B.A, M.A, PhD",
                          textEditController: educationController,
                          onChange: (val) {
                            filedValidation();
                          },
                        ),
                        SizedBox(height: SizeConfig.size18),
                        Row(
                          children: [
                            CustomText(
                              "Select your Profession",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.paddingXSL),
                        GetBuilder<AuthController>(builder: (authController) {
                          final dataList = authController.professionTypeDataList
                              .where((e) =>
                          e.tagId ==
                              personalCreateProfileController
                                  .selectedProfession.value)
                              .toList();
                          if (dataList.isNotEmpty) {
                            authController.subcategoriesFiledNameList.addAll(dataList.first.subcategoriesFiledName ?? []);
                          }
                          return CommonDropdownDialog<ProfessionTypeData>(
                            items: authController.professionTypeDataList,
                            selectedValue: personalCreateProfileController
                                .selectedProfessionObj.value,
                            hintText: AppConstants.selectProfession,
                            title: "Select your Profession",
                            displayValue: (profession) => profession.name ?? "",
                            onChanged: (value) {
                              personalCreateProfileController
                                  .selectedSubProfessionObj.value=null;
                              authController.subcategoriesFiledNameList.clear();

                              personalCreateProfileController
                                  .selectedProfession.value = value?.tagId;
                              personalCreateProfileController
                                  .selectedProfessionObj.value = value;
                              logs(" profession.name==== ${    personalCreateProfileController
                                  .selectedProfessionObj.value?.name}");

                              authController.subcategoriesFiledNameList.addAll(value?.subcategoriesFiledName??[]);
                              clearTextFiled();
                              setState(
                                  () {});
                            },
                            // validator: (value) {
                            //   if (value == null) {
                            //     return 'Please select your profession';
                            //   }
                            //   return null;
                            // },
                          );
                        }),
                        SizedBox(height: SizeConfig.size18),

                        if (personalCreateProfileController
                                .selectedProfession.value ==
                            AppConstants.Others) ...[
                          CommonTextField(
                            hintText: "Enter Your Profession (If Others)",
                            title: "Specify Profession",
                            isValidate: false,
                            textEditController: professionOthersController,
                          ),
                          SizedBox(height: SizeConfig.size18),
                        ],
                        if (personalCreateProfileController
                                .selectedProfession.value ==
                            SELF_EMPLOYED) ...[
                          // SizedBox(
                          //   height: SizeConfig.size20,
                          // ),

                          ///selectYourProfession
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CustomText(
                              "Select Work Type",
                              fontSize: SizeConfig.medium,
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.size10,
                          ),
                          Obx(() {
                            return CommonDropdownDialog<SubcategoriesFiledName>(
                              items:  authController.subcategoriesFiledNameList,
                              title: "Select Work Type",
                              selectedValue: personalCreateProfileController
                                  .selectedSubProfessionObj.value,
                              hintText: AppConstants.selectSelfEmployee,
                              displayValue: (selfEmployment) =>
                                  selfEmployment.name ?? "",
                              onChanged: (value) {
                                personalCreateProfileController
                                    .selectedSubProfessionObj.value = value;
                                personalCreateProfileController
                                    .selectedSubProfession.value = value?.tagId;
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
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                            titleColor: Colors.black,
                            hintText: "Please specify work type",
                          ),
                          SizedBox(
                            height: SizeConfig.size15,
                          ),
                        ],
                        if ((selectedProfession == SKILLED_WORKER)) ...[
                          CommonTextField(
                            textEditController:
                                _skillWorkerSpecificationTextController,
                            inputLength: 24,
                            title: "Type Your Work Specification",
                            keyBoardType: TextInputType.text,
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                            hintText: "Eg. Helper",
                            isValidate: false,
                          ),
                          SizedBox(
                            height: SizeConfig.size20,
                          ),
                        ],
                        if ((selectedProfession == CONTENT_CREATOR)) ...[
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
                            // autovalidateMode: _autoValidate,
                            // validator: (value) {
                            //   if (value == null || value.isEmpty) {
                            //     return 'Please enter work specification';
                            //   }
                            //   return null;
                            // }
                          ),
                          SizedBox(
                            height: SizeConfig.size20,
                          ),
                        ],

                        if ((selectedProfession == REG_UNION)) ...[
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
                          SizedBox(
                            height: SizeConfig.size20,
                          ),
                        ],
                        if ((selectedProfession == INDUSTRIALIST)) ...[
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

                        if ((selectedProfession == HOMEMAKER)) ...[

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
                          SizedBox(
                            height: SizeConfig.size20,
                          ),
                        ],
                        if ((selectedProfession == SENIOR_CITIZEN_RETIRED)) ...[
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
                        if ((selectedProfession == STUDENT)) ...[

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
                          SizedBox(
                            height: SizeConfig.size20,
                          ),
                        ],

                        if ((selectedProfession == ARTIST)) ...[
                          ///selectYourProfession
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CustomText(
                              "Select Your Art / Skill",
                              fontSize: SizeConfig.medium,
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.size10,
                          ),
                          CommonDropdownDialog<SubcategoriesFiledName>(
                            items:  authController.subcategoriesFiledNameList,
                            title:  "Select Your Art / Skill",
                            selectedValue: personalCreateProfileController
                                .selectedSubProfessionObj.value,
                            hintText: AppConstants.selectSelfArtist,
                            displayValue: (selfEmployment) =>
                                selfEmployment.name ?? "",
                            onChanged: (value) {
                              personalCreateProfileController
                                  .selectedSubProfessionObj.value = value;
                              personalCreateProfileController
                                  .selectedSubProfession.value = value?.tagId;
                            },
                          ),
                          // CommonDropdownDialog<ArtistCategory>(
                          //   items: ArtistCategory.values,
                          //   selectedValue: personalCreateProfileController
                          //       .selectedArtistCategory.value,
                          //   hintText: AppConstants.selectSelfArtist,
                          //   displayValue: (selfEmployment) =>
                          //   selfEmployment.displayName,
                          //   onChanged: (value) {
                          //     personalCreateProfileController
                          //         .selectedArtistCategory.value = value;
                          //   },
                          //   title: "Select Your Art / Skill",
                          //
                          //   // validator: (value) {
                          //   //   if (value == null) {
                          //   //     return 'Select your art / skill';
                          //   //   }
                          //   //   return null;
                          //   // },
                          // ),
                          SizedBox(
                            height: SizeConfig.size20,
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
                              regularExpression:
                                  RegularExpressionUtils.alphabetSpacePattern,
                              titleColor: Colors.black,
                              hintText: "Please Specify Art Type",
                            ),
                            SizedBox(
                              height: SizeConfig.size20,
                            ),
                          ],
                        ],

                        if (selectedProfession == PRIVATE_JOB) ...[
                          CommonTextField(
                            textEditController: sectorTextController,
                            inputLength: AppConstants.inputCharterLimit250,
                            keyBoardType: TextInputType.text,
                            isValidate: false,
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern,
                            title: "Sector",
                            hintText: "Eg. IT Sector",
                            // validator: (value) {
                            //   if (value == null || value.isEmpty) {
                            //     return 'Please enter your sector';
                            //   }
                            //   return null;
                            // },
                            // onChange: (val) {
                            //   filedValidation();
                            // },
                          ),
                          SizedBox(height: SizeConfig.size18),
                        ],

                        // if (shouldShowField('skills')) ...[
                        //   CommonTextField(
                        //     title: "Skills",
                        //     hintText: "Enter your skills (comma separated)",
                        //     textEditController: skillsController,
                        //     onChange: (val) {
                        //       filedValidation();
                        //     },
                        //   ),
                        //   SizedBox(height: SizeConfig.size18),
                        // ],

                        if ((selectedProfession == POLITICIAN)) ...[
                          CommonTextField(
                            title: "Political Party",
                            inputLength: 24,
                            hintText:
                                "Enter political party or organization name",
                            textEditController: politicalPartyController,
                            isValidate: false,
                          ),
                          SizedBox(height: SizeConfig.size18),
                        ],
                        if (selectedProfession == GOVTPSU) ...[
                          CommonTextField(
                            title: "Name of Department/PSU",
                            textEditController: departmentNameController,
                            inputLength: 24,
                            keyBoardType: TextInputType.text,
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern_,
                            titleColor: Colors.black,
                            hintText: "Eg., Ministry of Education",
                            isValidate: false,
                          ),
                          SizedBox(height: SizeConfig.size18),
                        ],
                        if ((selectedProfession == GOVTPSU)) ...[
                          CommonTextField(
                            title: "SUB Division / Branch",
                            textEditController: subDivision,
                            inputLength: 24,
                            isValidate: false,
                            keyBoardType: TextInputType.text,
                            regularExpression:
                                RegularExpressionUtils.alphabetSpacePattern_,
                            titleColor: Colors.black,
                            hintText: "Eg., Civil Engineering Division",
                          ),
                          SizedBox(height: SizeConfig.size18),
                        ],
                        if ((selectedProfession != SELF_EMPLOYED) &&
                            (selectedProfession != SKILLED_WORKER) &&
                            (selectedProfession != ARTIST) &&
                            (selectedProfession != CONTENT_CREATOR) &&
                            (selectedProfession != HOMEMAKER) &&
                            (selectedProfession != SENIOR_CITIZEN_RETIRED) &&
                            (selectedProfession != FARMER) &&
                            (selectedProfession != STUDENT) &&
                            (selectedProfession != OTHERS)) ...[
                          CommonTextField(
                            title: "Designation",
                            inputLength: 24,
                            isValidate: false,
                            hintText: "Enter your designation",
                            textEditController: designationController,
                            onChange: (val) {
                              // filedValidation();
                            },
                          ),
                          SizedBox(height: SizeConfig.size18),
                        ],
                        // CommonTextField(
                        //   title: "Current Organization",
                        //   hintText: AppConstants.companyOrg,
                        //   textEditController: organizationController,
                        //   onChange: (val) {
                        //     filedValidation();
                        //   },
                        // ),
                        // SizedBox(height: SizeConfig.size18),
                        CommonTextField(
                          title: "About Me /Bio",
                          hintText: AppConstants.myBio,
                          textEditController: addBio,
                          maxLine: 3,
                          maxLength: 250,
                          onChange: (val) {
                            filedValidation();
                          },
                        ),
                        SizedBox(height: SizeConfig.size24),
                      ],
                    );
                  }),
                ),
                SizedBox(
                  height: SizeConfig.size20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: PositiveCustomBtn(
                        onTap: () {
                          Get.back();
                        },
                        bgColor: AppColors.white,
                        title: "Cancel",
                        textColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size16),
                    Expanded(
                        child: CustomBtn(
                            isValidate: filedValidation(),
                            onTap: filedValidation()
                                ? () async {
                                    if (selectedProfession == ARTIST) {
                                      if (personalCreateProfileController
                                              .selectedSubProfessionObj
                                              .value
                                              ?.name
                                              ?.isEmpty ??
                                          true) {
                                        commonSnackBar(
                                            message: 'Select your art / skill');

                                        return;
                                      }
                                    }
                                    if (selectedProfession == REG_UNION) {
                                      if (_ngoNameTextController.text.isEmpty) {
                                        commonSnackBar(
                                            message:
                                                'Enter your NGO / Society Name');

                                        return;
                                      }
                                    }

                                    if (selectedProfession == OTHERS) {
                                      if (professionOthersController
                                          .text.isEmpty) {
                                        commonSnackBar(
                                            message:
                                                'Please enter your Skill and Expertise');
                                        return;
                                      }
                                    }
                                    // if ((personalCreateProfileController
                                    //         .selectedSelfEmployment.value ==
                                    //     SELF_EMPLOYED)) {
                                    //   if (personalCreateProfileController
                                    //           .selectedSelfEmployment
                                    //           .value
                                    //           ?.name
                                    //           .isEmpty ??
                                    //       true) {
                                    //     commonSnackBar(
                                    //         message: 'Please select work type');
                                    //
                                    //     return;
                                    //   }
                                    //   if (specializationController
                                    //       .text.isEmpty) {
                                    //     commonSnackBar(
                                    //         message:
                                    //             'Please enter specialization');
                                    //
                                    //     return;
                                    //   }
                                    // }
                                    // if (personalCreateProfileController
                                    //         .selectedSelfEmployment.value ==
                                    //     PRIVATE_JOB) {
                                    //   if (sectorTextController.text.isEmpty) {
                                    //     commonSnackBar(
                                    //         message:
                                    //             'Please enter your sector');
                                    //
                                    //     return;
                                    //   }
                                    // }
                                    String? designation;
                                    if (personalCreateProfileController
                                            .selectedProfession.value ==
                                        SELF_EMPLOYED) {
                                      designation =
                                          personalCreateProfileController
                                                  .selectedSubProfessionObj
                                                  .value
                                                  ?.name ??
                                              "";
                                    } else {
                                      designation = designationController.text;
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
                                                      .imagePath?.value ??
                                                  "",
                                        ),
                                      if (nameController.text.isNotEmpty)
                                        ApiKeys.name:
                                            nameController.text.trim(),
                                      ApiKeys.location:
                                          locationController.text.trim(),
                                      ApiKeys.user_cordinates: jsonEncode({
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
                                          educationController.text.trim(),
                                      // if (shouldShowField('designation'))
                                      ApiKeys.profession:
                                          personalCreateProfileController
                                                  .selectedProfession.value ??
                                              '',
                                      ApiKeys.designation: designation,

                                      if (personalCreateProfileController
                                              .selectedProfession.value ==
                                          SELF_EMPLOYED)
                                        ApiKeys.specilization:
                                            specializationController.text,
                                      if (personalCreateProfileController
                                              .selectedProfession.value ==
                                          OTHERS)
                                        ApiKeys.specilization:
                                            professionOthersController.text,
                                      // ApiKeys.current_organisation:
                                      //     organizationController.text.trim(),
                                      // if (shouldShowField('skills'))
                                      //   'skills': skillsController.text.trim(),
                                      if ((selectedProfession == POLITICIAN))
                                        'political_party':
                                            politicalPartyController.text
                                                .trim(),
                                      if (personalCreateProfileController
                                              .selectedProfession.value ==
                                          PRIVATE_JOB)
                                        ApiKeys.sector:
                                            sectorTextController.text,

                                      ApiKeys.gender:
                                          personalCreateProfileController
                                              .selectedGender.value?.name,
                                      if (addBio.text.isNotEmpty)
                                        ApiKeys.bio: addBio.text,

                                      ApiKeys.dob_date:
                                          personalCreateProfileController
                                              .selectedDay,
                                      ApiKeys.dob_month:
                                          personalCreateProfileController
                                              .selectedMonth,
                                      ApiKeys.dob_year:
                                          personalCreateProfileController
                                              .selectedYear,

                                      ///SKILL WORKER..
                                      if (selectedProfession == SKILLED_WORKER)
                                        ApiKeys.specilization:
                                            _skillWorkerSpecificationTextController
                                                .text,

                                      ///CONTENT_CREATOR
                                      if (selectedProfession == CONTENT_CREATOR)
                                        ApiKeys.specilization:
                                            _contentCraterTextController.text,

                                      ///GOVT PSU
                                      if (selectedProfession == GOVTPSU)
                                        ApiKeys.department:
                                            departmentNameController.text,
                                      if (selectedProfession == GOVTPSU)
                                        ApiKeys.subDivision: subDivision.text,

                                      ///NGO
                                      if (selectedProfession == REG_UNION)
                                        ApiKeys.department:
                                            _ngoNameTextController.text,

                                      ///Artist...
                                      if (selectedProfession == ARTIST)
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
                                    print("Update Params: $params");
                                    await personalCreateProfileController
                                        .updateUserProfileDetails(
                                      params: params,
                                    );
                                  }
                                : null,
                            title: "Update"))
                  ],
                ),
                SizedBox(
                  height: kToolbarHeight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  filedValidation() {
    bool isValid = true;

    if (locationController.text.isEmpty) isValid = false;
    if (emailController.text.isEmpty) isValid = false;
    if (educationController.text.isEmpty) isValid = false;
    // if (organizationController.text.isEmpty) isValid = false;
    // if (addBio.text.isEmpty) isValid = false;
    // if (currentFields.contains('skills') && skillsController.text.isEmpty)
    //   isValid = false;
    // if (currentFields.contains('politicalParty') &&
    //     politicalPartyController.text.isEmpty) isValid = false;

    // if (currentFields.contains('designation') &&
    //     designationController.text.isEmpty) isValid = false;

    if (personalCreateProfileController.selectedProfession.value ==
            AppConstants.Others &&
        professionOthersController.text.isEmpty) isValid = false;
    if ((personalCreateProfileController.selectedProfession.value ==
            PRIVATE_JOB) &&
        sectorTextController.text.isEmpty) isValid = false;

    setState(() {});
    return isValid;
  }
}
