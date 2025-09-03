// import 'dart:convert';
//
// import 'package:BlueEra/core/api/apiService/api_keys.dart';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_enum.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/core/constants/regular_expression.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/constants/snackbar_helper.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/core/services/multipart_image_service.dart';
// import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
// import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
// import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
// import 'package:BlueEra/widgets/common_circular_profile_image.dart';
// import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../../../widgets/commom_textfield.dart';
// import '../../../../../widgets/common_back_app_bar.dart';
// import '../../../../../widgets/common_drop_down.dart';
// import '../../../../../widgets/new_common_date_selection_dropdown.dart';
//
// class UpdateProfileScreen extends StatefulWidget {
//   @override
//   State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
// }
//
// class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
//   final nameController = TextEditingController();
//   final locationController = TextEditingController();
//   final emailController = TextEditingController();
//   final educationController = TextEditingController();
//   final designationController = TextEditingController();
//   final specializationController = TextEditingController();
//   final professionOthersController = TextEditingController();
//   final organizationController = TextEditingController();
//   final addBio = TextEditingController();
//   final sectorTextController = TextEditingController();
//   final _skillWorkerSpecificationTextController = TextEditingController();
//   final _contentCraterTextController = TextEditingController();
//   final _CourseTextController = TextEditingController();
//   final _SeniorTextController = TextEditingController();
//   final _ExpertiseTextController = TextEditingController();
//   final _companyNameTextController = TextEditingController();
//   final _ngoNameTextController = TextEditingController();
//   final _artTypeController = TextEditingController();
//
//   // final skillsController = TextEditingController();
//   final politicalPartyController = TextEditingController();
//
//   // final userNameController = TextEditingController();
//   final departmentNameController = TextEditingController();
//   final subDivision = TextEditingController();
//
//   final personalCreateProfileController =
//       Get.put(PersonalCreateProfileController());
//   final viewProfileController = Get.find<ViewPersonalDetailsController>();
//   bool isProfileCreateStatus = false;
//   final authController = Get.find<AuthController>();
//
//   clearTextFiled() {
//     _artTypeController.clear();
//     _ngoNameTextController.clear();
//     _companyNameTextController.clear();
//     _ExpertiseTextController.clear();
//     _SeniorTextController.clear();
//     _CourseTextController.clear();
//     _contentCraterTextController.clear();
//     designationController.clear();
//     sectorTextController.clear();
//     specializationController.clear();
//     professionOthersController.clear();
//     subDivision.clear();
//     departmentNameController.clear();
//     politicalPartyController.clear();
//     _skillWorkerSpecificationTextController.clear();
//     setState(() {});
//   }
//
//   ///API CALLING...
//   apiCalling() {
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       ///GETTING PROFESSION DATA LIST...
//       await authController.getAllProfessionController();
//     });
//   }
//
//   @override
//   void initState() {
//     apiCalling();
//
//     isProfileCreateStatus =
//         viewProfileController.personalProfileDetails.value.isProfileCreated ??
//             false;
//     nameController.text =
//         viewProfileController.personalProfileDetails.value.user?.name ?? "";
//     addBio.text =
//         viewProfileController.personalProfileDetails.value.user?.bio ?? "";
//
//     designationController.text =
//         viewProfileController.personalProfileDetails.value.user?.designation ??
//             "";
//
//     emailController.text =
//         viewProfileController.personalProfileDetails.value.user?.email ?? "";
//     educationController.text = viewProfileController
//             .personalProfileDetails.value.user?.highestEducation ??
//         "";
//     organizationController.text = viewProfileController
//             .personalProfileDetails.value.user?.currentOrganisation ??
//         "";
//     locationController.text =
//         viewProfileController.personalProfileDetails.value.user?.location ?? "";
//     personalCreateProfileController.imagePath?.value =
//         viewProfileController.personalProfileDetails.value.user?.profileImage ??
//             "";
//     personalCreateProfileController.selectedGender.value =
//         GenderTypeExtension.fromString((viewProfileController
//                     .personalProfileDetails.value.user?.gender?.isNotEmpty ??
//                 false)
//             ? viewProfileController.personalProfileDetails.value.user?.gender ??
//                 "male"
//             : "male");
//
//     personalCreateProfileController.selectedDay?.value = viewProfileController
//             .personalProfileDetails.value.user?.dateOfBirth?.date
//             ?.toInt() ??
//         0;
//     personalCreateProfileController.selectedMonth?.value = viewProfileController
//             .personalProfileDetails.value.user?.dateOfBirth?.month
//             ?.toInt() ??
//         0;
//     personalCreateProfileController.selectedYear?.value = viewProfileController
//             .personalProfileDetails.value.user?.dateOfBirth?.year
//             ?.toInt() ??
//         0;
//     personalCreateProfileController.selectedProfession.value =
//         ProfessionTypeExtension.fromString(viewProfileController
//                 .personalProfileDetails.value.user?.profession ??
//             "OTHERS");
//     selectedProfession =
//         personalCreateProfileController.selectedProfession.value;
//     if (viewProfileController.personalProfileDetails.value.user?.profession ==
//         ProfessionType.OTHERS.name) {
//       professionOthersController.text = viewProfileController
//               .personalProfileDetails.value.user?.specilization ??
//           "";
//     }
//     ///SELF EMPLOYEE
//     if (selectedProfession == ProfessionType.SELF_EMPLOYED) {
//       personalCreateProfileController.selectedSelfEmployment.value =
//           SelfEmploymentTypeExtension.fromString(viewProfileController
//                   .personalProfileDetails.value.user?.designation ??
//               "OTHERS");
//       specializationController.text = viewProfileController
//               .personalProfileDetails.value.user?.specilization ??
//           "";
//     }
//
//     ///PRIVATE JOB
//     if (selectedProfession == ProfessionType.PRIVATE_JOB) {
//       sectorTextController.text =
//           viewProfileController.personalProfileDetails.value.user?.sector ?? "";
//     }
//
//     ///SKILL WORKER..
//     if (selectedProfession == ProfessionType.SKILLED_WORKER) {
//       _skillWorkerSpecificationTextController.text = viewProfileController
//               .personalProfileDetails.value.user?.specilization ??
//           "";
//     }
//
//     ///CONTENT CREATER
//     if (selectedProfession == ProfessionType.CONTENT_CREATOR) {
//       _contentCraterTextController.text = viewProfileController
//               .personalProfileDetails.value.user?.specilization ??
//           "";
//     }
//
//     ///POLITICIAN
//     if (selectedProfession == ProfessionType.POLITICIAN) {
//       politicalPartyController.text = viewProfileController
//               .personalProfileDetails.value.user?.specilization ??
//           "";
//     }
//
//     ///GOVT PSU
//     if (selectedProfession == ProfessionType.GOVTPSU) {
//       departmentNameController.text =
//           viewProfileController.personalProfileDetails.value.user?.department ??
//               "";
//       subDivision.text = viewProfileController
//               .personalProfileDetails.value.user?.subDivision ??
//           "";
//     }
//
//     ///NGO
//     if (selectedProfession == ProfessionType.REG_UNION) {
//       _ngoNameTextController.text =
//           viewProfileController.personalProfileDetails.value.user?.department ??
//               "";
//     }
//
//     ///ARTIST
//     if (selectedProfession == ProfessionType.ARTIST) {
//       personalCreateProfileController.selectedArtistCategory.value =
//           ArtistCategoryExtension.fromString(viewProfileController
//                   .personalProfileDetails.value.user?.art?.artName ??
//               "OTHERS");
//       _artTypeController.text = viewProfileController
//               .personalProfileDetails.value.user?.art?.artType ??
//           "";
//     }
//     super.initState();
//   }
//
//   ProfessionType? selectedProfession;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonBackAppBar(isLeading: true, title: "Update Profile"),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//                 horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
//             child: Column(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12)),
//                   padding: EdgeInsets.symmetric(
//                       horizontal: SizeConfig.size18,
//                       vertical: SizeConfig.size10),
//                   child: Obx(() {
//                     selectedProfession = personalCreateProfileController
//                         .selectedProfession.value;
//
//                     return Column(
//                       children: [
//                         SizedBox(height: SizeConfig.size10),
//
//                         ///UPLOAD PROFILE....
//                         if (shouldShowField('profileImage')) ...[
//                           Center(
//                             child: CommonProfileImage(
//                               imagePath: personalCreateProfileController
//                                       .imagePath?.value ??
//                                   "",
//                               onImageUpdate: (image) {
//                                 personalCreateProfileController
//                                     .imagePath?.value = image;
//                                 personalCreateProfileController
//                                     .isImageUpdated.value = true;
//                               },
//                             ),
//                           ),
//                           SizedBox(height: SizeConfig.size14),
//                           CustomText(
//                             "Profile Picture",
//                             fontWeight: FontWeight.bold,
//                             fontSize: SizeConfig.large,
//                           ),
//                           SizedBox(height: SizeConfig.size8),
//                           CustomText("You can update your photo anytime.",
//                               color: AppColors.grey80,
//                               fontSize: SizeConfig.medium),
//                           SizedBox(height: SizeConfig.size24),
//                         ],
//
//                         if (shouldShowField('fullName')) ...[
//                           CommonTextField(
//                             title: "Full Name",
//                             hintText: "Enter your full name",
//                             textEditController: nameController,
//                             validationType: ValidationTypeEnum.name,
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (shouldShowField('gender')) ...[
//                           Align(
//                             alignment: Alignment.centerLeft,
//                             child: CustomText(
//                               "Gender",
//                               fontSize: SizeConfig.medium,
//                               fontWeight: FontWeight.w500,
//                               color: AppColors.black,
//                             ),
//                           ),
//                           SizedBox(height: SizeConfig.paddingXSL),
//                           CommonDropdown<GenderType>(
//                             items: GenderType.values,
//                             selectedValue: personalCreateProfileController
//                                 .selectedGender.value,
//                             hintText: "Select Gender",
//                             displayValue: (value) => value.displayName,
//                             onChanged: (value) {
//                               personalCreateProfileController
//                                   .selectedGender.value = value;
//                             },
//                             validator: (value) {
//                               return null;
//                             },
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (shouldShowField('dateOfBirth')) ...[
//                           Row(
//                             children: [
//                               CustomText(
//                                 "Date of Birth",
//                                 fontWeight: FontWeight.w500,
//                                 color: AppColors.black,
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: SizeConfig.paddingXSL),
//                           NewDatePicker(
//                             isAgeValidation15: true,
//                             selectedDay: personalCreateProfileController
//                                 .selectedDay?.value,
//                             selectedMonth: personalCreateProfileController
//                                 .selectedMonth?.value,
//                             selectedYear: personalCreateProfileController
//                                 .selectedYear?.value,
//                             onDayChanged: (value) {
//                               personalCreateProfileController
//                                   .selectedDay?.value = value ?? 0;
//                             },
//                             onMonthChanged: (value) {
//                               personalCreateProfileController
//                                   .selectedMonth?.value = value ?? 0;
//                             },
//                             onYearChanged: (value) {
//                               personalCreateProfileController
//                                   .selectedYear?.value = value ?? 0;
//                             },
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//
//                         if (shouldShowField('location')) ...[
//                           InkWell(
//                             onTap: () {
//                               Navigator.pushNamed(
//                                 context,
//                                 RouteHelper.getSearchLocationScreenRoute(),
//                                 arguments: {
//                                   'onPlaceSelected': (double? lat,
//                                       double? lng,
//                                       String? address,
//                                       bool? currentLocationSelected) {
//                                     if (address != null) {
//                                       locationController.text = address;
//                                       personalCreateProfileController
//                                           .setStartLocation(lat, lng, address);
//                                     }
//                                   },
//                                   ApiKeys.fromScreen: ""
//                                 },
//                               );
//                             },
//                             child: CommonTextField(
//                               textEditController: locationController,
//                               hintText: "E.g., Rajiv Chowk, Delhi",
//                               isValidate: false,
//                               title: "Location",
//
//                               // onChange: (value) => controller.validateForm(),
//                               readOnly: true,
//                               // Make it read-only since we'll use the search screen
//                             ),
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (shouldShowField('email')) ...[
//                           CommonTextField(
//                             title: "Email",
//                             hintText: "Enter your email address",
//                             textEditController: emailController,
//                             validationType: ValidationTypeEnum.email,
//                             onChange: (val) {
//                               filedValidation();
//                             },
//                             sIcon: viewProfileController.personalProfileDetails
//                                         .value.user?.emailVerified ??
//                                     false
//                                 ? Icon(
//                                     Icons.verified_user_outlined,
//                                     color: AppColors.green39,
//                                   )
//                                 : null,
//                           ),
//                           // CustomText("title")
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (shouldShowField('highestEducation')) ...[
//                           CommonTextField(
//                             title: "Highest Education",
//                             hintText: "Eg. 12th, B.A, M.A, PhD",
//                             textEditController: educationController,
//                             onChange: (val) {
//                               filedValidation();
//                             },
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (shouldShowField('profession')) ...[
//                           Row(
//                             children: [
//                               CustomText(
//                                 "Select your Profession",
//                                 fontSize: SizeConfig.medium,
//                                 fontWeight: FontWeight.w500,
//                                 color: AppColors.black,
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: SizeConfig.paddingXSL),
//                           CommonDropdownDialog<ProfessionType>(
//                             items: ProfessionType.values,
//                             selectedValue: personalCreateProfileController
//                                 .selectedProfession.value,
//                             hintText: AppConstants.selectProfession,
//                             title: "Select your Profession",
//                             displayValue: (profession) =>
//                                 profession.displayName,
//                             onChanged: (value) {
//                               personalCreateProfileController
//                                   .selectedProfession.value = value!;
//                               clearTextFiled();
//                               setState(
//                                   () {}); // Trigger rebuild for dynamic fields
//                             },
//                             // validator: (value) {
//                             //   if (value == null) {
//                             //     return 'Please select your profession';
//                             //   }
//                             //   return null;
//                             // },
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//
//                         if (shouldShowField('professionOthers') &&
//                             personalCreateProfileController
//                                     .selectedProfession.value?.name ==
//                                 AppConstants.Others) ...[
//                           CommonTextField(
//                             hintText: "Enter Your Profession (If Others)",
//                             title: "Specify Profession",
//                             isValidate: false,
//                             textEditController: professionOthersController,
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (personalCreateProfileController
//                                 .selectedProfession.value ==
//                             ProfessionType.SELF_EMPLOYED) ...[
//                           // SizedBox(
//                           //   height: SizeConfig.size20,
//                           // ),
//
//                           ///selectYourProfession
//                           Align(
//                             alignment: Alignment.centerLeft,
//                             child: CustomText(
//                               "Select Work Type",
//                               fontSize: SizeConfig.medium,
//                             ),
//                           ),
//                           SizedBox(
//                             height: SizeConfig.size10,
//                           ),
//                           Obx(() {
//                             return CommonDropdownDialog<SelfEmploymentType>(
//                               items: SelfEmploymentType.values,
//                               title: "Select Work Type",
//
//                               selectedValue: personalCreateProfileController
//                                   .selectedSelfEmployment.value,
//                               hintText: AppConstants.selectSelfEmployee,
//                               displayValue: (selfEmployment) =>
//                                   selfEmployment.displayName,
//                               onChanged: (value) {
//                                 personalCreateProfileController
//                                     .selectedSelfEmployment.value = value;
//                               },
//                               // validator: (value) {
//                               //   if (value == null) {
//                               //     return 'Please select your work type';
//                               //   }
//                               //
//                               //   filedValidation();
//                               //
//                               //   return null;
//                               // },
//                             );
//                           }),
//                           SizedBox(
//                             height: SizeConfig.size15,
//                           ),
//                           CommonTextField(
//                             textEditController: specializationController,
//                             inputLength: 24,
//                             // maxLength: 24,
//                             isValidate: false,
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             titleColor: Colors.black,
//                             hintText: "Please specify work type",
//                           ),
//                           SizedBox(
//                             height: SizeConfig.size15,
//                           ),
//                         ],
//                         if ((selectedProfession ==
//                             ProfessionType.SKILLED_WORKER)) ...[
//                           CommonTextField(
//                             textEditController:
//                                 _skillWorkerSpecificationTextController,
//                             inputLength: 24,
//                             title: "Type Your Work Specification",
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             hintText: "Eg. Helper",
//                             isValidate: false,
//                           ),
//                           SizedBox(
//                             height: SizeConfig.size20,
//                           ),
//                         ],
//                         if ((selectedProfession ==
//                             ProfessionType.CONTENT_CREATOR)) ...[
//                           CommonTextField(
//                             isValidate: false,
//
//                             textEditController: _contentCraterTextController,
//                             // inputLength: 13,
//                             inputLength: 24,
//                             title: "Type Your Specification",
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             hintText: "Eg. Education,Poetry",
//                             // autovalidateMode: _autoValidate,
//                             // validator: (value) {
//                             //   if (value == null || value.isEmpty) {
//                             //     return 'Please enter work specification';
//                             //   }
//                             //   return null;
//                             // }
//                           ),
//                           SizedBox(
//                             height: SizeConfig.size20,
//                           ),
//                         ],
//
//                         if ((selectedProfession ==
//                             ProfessionType.REG_UNION)) ...[
//                           CommonTextField(
//                             isValidate: false,
//
//                             textEditController: _ngoNameTextController,
//                             inputLength: 40,
//                             title: "Type Your NGO / Society Name",
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             hintText: "Eg. Auto Union",
//                             // autovalidateMode: _autoValidate,
//                             // validator: (value) {
//                             //   if (value == null || value.isEmpty) {
//                             //     return 'Please enter NGO / Society ';
//                             //   }
//                             //   return null;
//                             // }
//                           ),
//                           SizedBox(
//                             height: SizeConfig.size20,
//                           ),
//                         ],
//                         if ((selectedProfession ==
//                             ProfessionType.INDUSTRIALIST)) ...[
//                           SizedBox(
//                             height: SizeConfig.size20,
//                           ),
//                           CommonTextField(
//                             isValidate: false,
//
//                             textEditController: _companyNameTextController,
//                             // inputLength: 13,
//                             inputLength: 24,
//                             title: "Type Your Company Name",
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             hintText: "Eg. TCS LTD",
//                             // autovalidateMode: _autoValidate,
//                             // validator: (value) {
//                             //   if (value == null || value.isEmpty) {
//                             //     return 'Please enter company name';
//                             //   }
//                             //   return null;
//                             // }
//                           ),
//                         ],
//
//                         if ((selectedProfession ==
//                             ProfessionType.HOMEMAKER)) ...[
//                           SizedBox(
//                             height: SizeConfig.size20,
//                           ),
//                           CommonTextField(
//                             isValidate: false,
//
//                             textEditController: _ExpertiseTextController,
//                             // inputLength: 13,
//                             inputLength: 24,
//                             title: "Type Your Expertise",
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             hintText: "Eg. Cooking,Dancing",
//                             // autovalidateMode: _autoValidate,
//                             // validator: (value) {
//                             //   if (value == null || value.isEmpty) {
//                             //     return 'Please enter Expertise';
//                             //   }
//                             //   return null;
//                             // }
//                           ),
//                         ],
//                         if ((selectedProfession ==
//                             ProfessionType.SENIOR_CITIZEN_RETIRED)) ...[
//                           SizedBox(
//                             height: SizeConfig.size20,
//                           ),
//                           CommonTextField(
//                             isValidate: false,
//
//                             textEditController: _SeniorTextController,
//                             inputLength: 24,
//                             title: "Type Your Expertise",
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             hintText: "Eg. Banking,Teaching",
//                             // autovalidateMode: _autoValidate,
//                             // validator: (value) {
//                             //   if (value == null || value.isEmpty) {
//                             //     return 'Please enter Expertise';
//                             //   }
//                             //   return null;
//                             // }
//                           ),
//                         ],
//                         if ((selectedProfession == ProfessionType.STUDENT)) ...[
//                           SizedBox(
//                             height: SizeConfig.size20,
//                           ),
//                           CommonTextField(
//                             isValidate: false,
//
//                             textEditController: _CourseTextController,
//                             inputLength: 24,
//                             title: "Which class you study?",
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             hintText: "Eg. 10th,Diploma,BE,PHD",
//                             // autovalidateMode: _autoValidate,
//                             // validator: (value) {
//                             //   if (value == null || value.isEmpty) {
//                             //     return 'Please enter Expertise';
//                             //   }
//                             //   return null;
//                             // }
//                           ),
//                         ],
//
//                         if ((selectedProfession == ProfessionType.ARTIST)) ...[
//                           ///selectYourProfession
//                           Align(
//                             alignment: Alignment.centerLeft,
//                             child: CustomText(
//                               "Select Your Art / Skill",
//                               fontSize: SizeConfig.medium,
//                             ),
//                           ),
//                           SizedBox(
//                             height: SizeConfig.size10,
//                           ),
//
//                           CommonDropdownDialog<ArtistCategory>(
//                             items: ArtistCategory.values,
//                             selectedValue: personalCreateProfileController
//                                 .selectedArtistCategory.value,
//                             hintText: AppConstants.selectSelfArtist,
//                             displayValue: (selfEmployment) =>
//                                 selfEmployment.displayName,
//                             onChanged: (value) {
//                               personalCreateProfileController
//                                   .selectedArtistCategory.value = value;
//                             },
//                             title: "Select Your Art / Skill",
//
//                             // validator: (value) {
//                             //   if (value == null) {
//                             //     return 'Select your art / skill';
//                             //   }
//                             //   return null;
//                             // },
//                           ),
//                           SizedBox(
//                             height: SizeConfig.size20,
//                           ),
//
//                           if (personalCreateProfileController
//                                   .selectedArtistCategory.value !=
//                               null) ...[
//                             CommonTextField(
//                               isValidate: false,
//
//                               textEditController: _artTypeController,
//                               // inputLength: 13,
//                               inputLength: 24,
//                               keyBoardType: TextInputType.text,
//                               regularExpression:
//                                   RegularExpressionUtils.alphabetSpacePattern,
//                               titleColor: Colors.black,
//                               hintText: "Please Specify Art Type",
//                               // autovalidateMode: _autoValidate,
//                               // validator: (value) {
//                               //   if (value == null || value.isEmpty) {
//                               //     return 'Please enter art specification';
//                               //   }
//                               //   return null;
//                               // }
//                             ),
//                             SizedBox(
//                               height: SizeConfig.size20,
//                             ),
//                           ],
//                         ],
//
//                         if (selectedProfession ==
//                             ProfessionType.PRIVATE_JOB) ...[
//                           CommonTextField(
//                             textEditController: sectorTextController,
//                             inputLength: AppConstants.inputCharterLimit250,
//                             keyBoardType: TextInputType.text,
//                             isValidate: false,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern,
//                             title: "Sector",
//                             hintText: "Eg. IT Sector",
//                             // validator: (value) {
//                             //   if (value == null || value.isEmpty) {
//                             //     return 'Please enter your sector';
//                             //   }
//                             //   return null;
//                             // },
//                             // onChange: (val) {
//                             //   filedValidation();
//                             // },
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//
//                         // if (shouldShowField('skills')) ...[
//                         //   CommonTextField(
//                         //     title: "Skills",
//                         //     hintText: "Enter your skills (comma separated)",
//                         //     textEditController: skillsController,
//                         //     onChange: (val) {
//                         //       filedValidation();
//                         //     },
//                         //   ),
//                         //   SizedBox(height: SizeConfig.size18),
//                         // ],
//
//                         if (shouldShowField('politicalParty')) ...[
//                           CommonTextField(
//                             title: "Political Party",
//                             inputLength: 24,
//                             hintText:
//                                 "Enter political party or organization name",
//                             textEditController: politicalPartyController,
//                             isValidate: false,
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         // if (shouldShowField('userName')) ...[
//                         //   CommonTextField(
//                         //       title: "Username",
//                         //       textEditController: userNameController,
//                         //       inputLength: 15,
//                         //       keyBoardType: TextInputType.text,
//                         //       regularExpression:
//                         //           RegularExpressionUtils.alphabetPattern,
//                         //       titleColor: Colors.black,
//                         //       hintText: "Eg @Sachin131",
//                         //       prefixText:
//                         //           userNameController.text.isNotEmpty ? "@" : "",
//                         //       onChange: (val) {
//                         //         filedValidation();
//                         //       },
//                         //       validator: (value) {
//                         //         if (value == null || value.isEmpty) {
//                         //           return 'Please enter your username';
//                         //         }
//                         //         return null;
//                         //       }),
//                         //   SizedBox(height: SizeConfig.size18),
//                         // ],
//                         if (shouldShowField('nameofDepartment')) ...[
//                           CommonTextField(
//                             title: "Name of Department/PSU",
//                             textEditController: departmentNameController,
//                             inputLength: 24,
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern_,
//                             titleColor: Colors.black,
//                             hintText: "Eg., Ministry of Education",
//                             isValidate: false,
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (shouldShowField('subDivision')) ...[
//                           CommonTextField(
//                             title: "SUB Division / Branch",
//                             textEditController: subDivision,
//                             inputLength: 24,
//                             isValidate: false,
//                             keyBoardType: TextInputType.text,
//                             regularExpression:
//                                 RegularExpressionUtils.alphabetSpacePattern_,
//                             titleColor: Colors.black,
//                             hintText: "Eg., Civil Engineering Division",
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if ((selectedProfession !=
//                                 ProfessionType.SELF_EMPLOYED) &&
//                             (selectedProfession !=
//                                 ProfessionType.SKILLED_WORKER) &&
//                             (selectedProfession != ProfessionType.ARTIST) &&
//                             (selectedProfession !=
//                                 ProfessionType.CONTENT_CREATOR) &&
//                             (selectedProfession != ProfessionType.HOMEMAKER) &&
//                             (selectedProfession !=
//                                 ProfessionType.SENIOR_CITIZEN_RETIRED) &&
//                             (selectedProfession != ProfessionType.FARMER) &&
//                             (selectedProfession != ProfessionType.STUDENT) &&
//                             (selectedProfession != ProfessionType.OTHERS)) ...[
//                           CommonTextField(
//                             title: "Designation",
//                             inputLength: 24,
//                             isValidate: false,
//                             hintText: "Enter your designation",
//                             textEditController: designationController,
//                             onChange: (val) {
//                               // filedValidation();
//                             },
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (shouldShowField('organization')) ...[
//                           CommonTextField(
//                             title: "Current Organization",
//                             hintText: AppConstants.companyOrg,
//                             textEditController: organizationController,
//                             onChange: (val) {
//                               filedValidation();
//                             },
//                           ),
//                           SizedBox(height: SizeConfig.size18),
//                         ],
//                         if (shouldShowField('bio')) ...[
//                           CommonTextField(
//                             title: "About Me /Bio",
//                             hintText: AppConstants.myBio,
//                             textEditController: addBio,
//                             maxLine: 3,
//                             maxLength: 250,
//                             onChange: (val) {
//                               filedValidation();
//                             },
//                           ),
//                           SizedBox(height: SizeConfig.size24),
//                         ],
//                       ],
//                     );
//                   }),
//                 ),
//                 SizedBox(
//                   height: SizeConfig.size20,
//                 ),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: PositiveCustomBtn(
//                         onTap: () {
//                           Get.back();
//                         },
//                         bgColor: AppColors.white,
//                         title: "Cancel",
//                         textColor: AppColors.primaryColor,
//                       ),
//                     ),
//                     SizedBox(width: SizeConfig.size16),
//                     Expanded(
//                         child: CustomBtn(
//                             isValidate: filedValidation(),
//                             onTap: filedValidation()
//                                 ? () async {
//                                     if (selectedProfession ==
//                                         ProfessionType.ARTIST) {
//                                       if (personalCreateProfileController
//                                               .selectedArtistCategory
//                                               .value
//                                               ?.name
//                                               .isEmpty ??
//                                           true) {
//                                         commonSnackBar(
//                                             message: 'Select your art / skill');
//
//                                         return;
//                                       }
//                                     }
//                                     if (selectedProfession ==
//                                         ProfessionType.REG_UNION) {
//                                       if (_ngoNameTextController.text.isEmpty) {
//                                         commonSnackBar(
//                                             message:
//                                                 'Enter your NGO / Society Name');
//
//                                         return;
//                                       }
//                                     }
//
//                                     if (selectedProfession ==
//                                         ProfessionType.OTHERS) {
//                                       if (professionOthersController
//                                           .text.isEmpty) {
//                                         commonSnackBar(
//                                             message:
//                                                 'Please enter your Skill and Expertise');
//                                         return;
//                                       }
//                                     }
//                                     // if ((personalCreateProfileController
//                                     //         .selectedSelfEmployment.value ==
//                                     //     ProfessionType.SELF_EMPLOYED)) {
//                                     //   if (personalCreateProfileController
//                                     //           .selectedSelfEmployment
//                                     //           .value
//                                     //           ?.name
//                                     //           .isEmpty ??
//                                     //       true) {
//                                     //     commonSnackBar(
//                                     //         message: 'Please select work type');
//                                     //
//                                     //     return;
//                                     //   }
//                                     //   if (specializationController
//                                     //       .text.isEmpty) {
//                                     //     commonSnackBar(
//                                     //         message:
//                                     //             'Please enter specialization');
//                                     //
//                                     //     return;
//                                     //   }
//                                     // }
//                                     // if (personalCreateProfileController
//                                     //         .selectedSelfEmployment.value ==
//                                     //     ProfessionType.PRIVATE_JOB) {
//                                     //   if (sectorTextController.text.isEmpty) {
//                                     //     commonSnackBar(
//                                     //         message:
//                                     //             'Please enter your sector');
//                                     //
//                                     //     return;
//                                     //   }
//                                     // }
//                                     String? designation;
//                                     if (personalCreateProfileController
//                                             .selectedProfession.value ==
//                                         ProfessionType.SELF_EMPLOYED) {
//                                       designation =
//                                           personalCreateProfileController
//                                                   .selectedSelfEmployment
//                                                   .value
//                                                   ?.name ??
//                                               "";
//                                     } else {
//                                       designation = designationController.text;
//                                     }
//
//                                     Map<String, dynamic> params = {
//                                       if ((personalCreateProfileController
//                                                   .imagePath
//                                                   ?.value
//                                                   .isNotEmpty ??
//                                               false) &&
//                                           personalCreateProfileController
//                                               .isImageUpdated.value)
//                                         ApiKeys.profile_image:
//                                             await multiPartImage(
//                                           imagePath:
//                                               personalCreateProfileController
//                                                       .imagePath?.value ??
//                                                   "",
//                                         ),
//                                       if (nameController.text.isNotEmpty)
//                                         ApiKeys.name:
//                                             nameController.text.trim(),
//                                       ApiKeys.location:
//                                           locationController.text.trim(),
//                                       ApiKeys.user_cordinates: jsonEncode({
//                                         ApiKeys.lat:
//                                             personalCreateProfileController
//                                                 .locationLat?.value,
//                                         ApiKeys.lon:
//                                             personalCreateProfileController
//                                                 .locationLng?.value,
//                                       }),
//                                       ApiKeys.email:
//                                           emailController.text.trim(),
//                                       ApiKeys.highest_education:
//                                           educationController.text.trim(),
//                                       // if (shouldShowField('designation'))
//                                       ApiKeys.profession:
//                                           personalCreateProfileController
//                                                   .selectedProfession
//                                                   .value
//                                                   ?.name ??
//                                               '',
//                                       ApiKeys.designation: designation,
//
//                                       if (personalCreateProfileController
//                                               .selectedProfession.value ==
//                                           ProfessionType.SELF_EMPLOYED)
//                                         ApiKeys.specilization:
//                                             specializationController.text,
//                                       if (personalCreateProfileController
//                                               .selectedProfession.value ==
//                                           ProfessionType.OTHERS)
//                                         ApiKeys.specilization:
//                                             professionOthersController.text,
//                                       if (shouldShowField('organization'))
//                                         ApiKeys.current_organisation:
//                                             organizationController.text.trim(),
//                                       // if (shouldShowField('skills'))
//                                       //   'skills': skillsController.text.trim(),
//                                       if (shouldShowField('politicalParty'))
//                                         'political_party':
//                                             politicalPartyController.text
//                                                 .trim(),
//                                       if (personalCreateProfileController
//                                               .selectedProfession.value ==
//                                           ProfessionType.PRIVATE_JOB)
//                                         ApiKeys.sector:
//                                             sectorTextController.text,
//
//                                       ApiKeys.gender:
//                                           personalCreateProfileController
//                                               .selectedGender.value?.name,
//                                       if (addBio.text.isNotEmpty)
//                                         ApiKeys.bio: addBio.text,
//
//                                       ApiKeys.dob_date:
//                                           personalCreateProfileController
//                                               .selectedDay,
//                                       ApiKeys.dob_month:
//                                           personalCreateProfileController
//                                               .selectedMonth,
//                                       ApiKeys.dob_year:
//                                           personalCreateProfileController
//                                               .selectedYear,
//
//                                       ///SKILL WORKER..
//                                       if (selectedProfession ==
//                                           ProfessionType.SKILLED_WORKER)
//                                         ApiKeys.specilization:
//                                             _skillWorkerSpecificationTextController
//                                                 .text,
//
//                                       ///CONTENT_CREATOR
//                                       if (selectedProfession ==
//                                           ProfessionType.CONTENT_CREATOR)
//                                         ApiKeys.specilization:
//                                             _contentCraterTextController.text,
//
//                                       ///GOVT PSU
//                                       if (selectedProfession ==
//                                           ProfessionType.GOVTPSU)
//                                         ApiKeys.department:
//                                             departmentNameController.text,
//                                       if (selectedProfession ==
//                                           ProfessionType.GOVTPSU)
//                                         ApiKeys.subDivision: subDivision.text,
//
//                                       ///NGO
//                                       if (selectedProfession ==
//                                           ProfessionType.REG_UNION)
//                                         ApiKeys.department:
//                                             _ngoNameTextController.text,
//
//                                       ///Artist...
//                                       if (selectedProfession ==
//                                           ProfessionType.ARTIST)
//                                         ApiKeys.art: jsonEncode({
//                                           ApiKeys.artName:
//                                               personalCreateProfileController
//                                                   .selectedArtistCategory
//                                                   .value
//                                                   ?.name,
//                                           ApiKeys.artType:
//                                               _artTypeController.text
//                                         }),
//                                     };
//                                     print("Update Params: $params");
//                                     await personalCreateProfileController
//                                         .updateUserProfileDetails(
//                                       params: params,
//                                     );
//                                   }
//                                 : null,
//                             title: "Update"))
//                   ],
//                 ),
//                 SizedBox(
//                   height: kToolbarHeight,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   List<String> getCurrentFields() {
//     if (personalCreateProfileController.selectedProfession.value == null) {
//       return [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'bio'
//       ];
//     }
//     return getFieldsForProfession()[
//             personalCreateProfileController.selectedProfession.value] ??
//         [
//           'profileImage',
//           'fullName',
//           'gender',
//           'dateOfBirth',
//           'location',
//           'email',
//           'highestEducation',
//           'profession',
//           'bio'
//         ];
//   }
//
//   bool shouldShowField(String fieldName) {
//     return getCurrentFields().contains(fieldName);
//   }
//
//   filedValidation() {
//     List<String> currentFields = getCurrentFields();
//
//     bool isValid = true;
//
//     if (currentFields.contains('location') && locationController.text.isEmpty)
//       isValid = false;
//     if (currentFields.contains('email') && emailController.text.isEmpty)
//       isValid = false;
//     if (currentFields.contains('highestEducation') &&
//         educationController.text.isEmpty) isValid = false;
//     if (currentFields.contains('organization') &&
//         organizationController.text.isEmpty) isValid = false;
//     if (currentFields.contains('bio') && addBio.text.isEmpty) isValid = false;
//     // if (currentFields.contains('skills') && skillsController.text.isEmpty)
//     //   isValid = false;
//     // if (currentFields.contains('politicalParty') &&
//     //     politicalPartyController.text.isEmpty) isValid = false;
//
//     // if (currentFields.contains('designation') &&
//     //     designationController.text.isEmpty) isValid = false;
//
//     if (personalCreateProfileController.selectedProfession.value?.name ==
//             AppConstants.Others &&
//         professionOthersController.text.isEmpty) isValid = false;
//     if ((personalCreateProfileController.selectedProfession.value ==
//             ProfessionType.PRIVATE_JOB) &&
//         sectorTextController.text.isEmpty) isValid = false;
//
//     setState(() {});
//     return isValid;
//   }
//
//   Map<ProfessionType, List<String>> getFieldsForProfession() {
//     return {
//       ProfessionType.PRIVATE_JOB: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'designation',
//         'organization',
//         'bio'
//       ],
//       ProfessionType.GOVERNMENT_JOB: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'designation',
//         'organization',
//         'bio'
//       ],
//       ProfessionType.ARTIST: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'organization',
//         'skills',
//         'bio'
//       ],
//       ProfessionType.MEDIA: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'organization',
//         'skills',
//         'bio'
//       ],
//       ProfessionType.SOCIALIST: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'organization',
//         'skills',
//         'bio'
//       ],
//       ProfessionType.HOMEMAKER: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'bio'
//       ],
//       ProfessionType.FARMER: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'bio'
//       ],
//       ProfessionType.SENIOR_CITIZEN_RETIRED: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'bio'
//       ],
//       ProfessionType.STUDENT: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'bio'
//       ],
//       ProfessionType.POLITICIAN: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'politicalParty',
//         'userName',
//         'designation',
//         'bio'
//       ],
//       ProfessionType.GOVTPSU: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'userName',
//         'nameofDepartment',
//         'subDivision',
//         'designation',
//         'bio'
//       ],
//       ProfessionType.SKILLED_WORKER: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'skills',
//         'bio'
//       ],
//       ProfessionType.INDUSTRIALIST: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'organization',
//         'bio'
//       ],
//       ProfessionType.SELF_EMPLOYED: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'skills',
//         'bio'
//       ],
//       ProfessionType.OTHERS: [
//         'profileImage',
//         'fullName',
//         'gender',
//         'dateOfBirth',
//         'location',
//         'email',
//         'highestEducation',
//         'profession',
//         'professionOthers',
//         'bio'
//       ],
//     };
//   }
// }
