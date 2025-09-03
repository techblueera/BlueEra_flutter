import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/email_verification_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/view_personal_details_controller.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({Key? key}) : super(key: key);

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final personalCreateProfileController =
      Get.put(PersonalCreateProfileController());
  final emailVerificationController = Get.put(EmailVerificationController());
  final ViewPersonalDetailsController viewPersonalDetailsController =
      Get.find<ViewPersonalDetailsController>();

  final TextEditingController locationController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isEmailValid = false;

  @override
  void dispose() {
    locationController.dispose();
    emailController.dispose();
    educationController.dispose();
    bioController.dispose();
    super.dispose();
  }

  // Email validation function
  bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  String? email;
  bool isEmailVerified = false;

  void calculateEmailAndIsEmailVerified() {
    final user =
        viewPersonalDetailsController.personalProfileDetails.value.user;

    email = user?.email;
    isEmailVerified = user?.emailVerified ?? false;
  }

  @override
  void initState() {
    super.initState();
    calculateEmailAndIsEmailVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
        title: 'Create Profile',
      ),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
          padding:
              EdgeInsets.symmetric(horizontal: 0, vertical: SizeConfig.size5),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size8,
                horizontal: SizeConfig.size20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Field
                  SizedBox(height: SizeConfig.size8),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RouteHelper.getSearchLocationScreenRoute(),
                        arguments: {
                          'onPlaceSelected':
                              (double? lat, double? lng, String? address) {
                            if (address != null) {
                              locationController.text = address;
                              personalCreateProfileController.setStartLocation(
                                  lat, lng, address);
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
                      readOnly: true,
                      // Make it read-only since we'll use the search screen
                    ),
                  ),

                  SizedBox(height: SizeConfig.size18),

                  CommonTextField(
                    // initialValue:  : null,
                    readOnly: isEmailVerified,
                    title: "Email",
                    textEditController: emailController,
                    hintText: isEmailVerified == true
                        ? email
                        : 'Enter your email address',
                    keyBoardType: TextInputType.emailAddress,
                    onChange: (value) {
                      setState(() {
                        isEmailValid = validateEmail(value);
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!validateEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(width: SizeConfig.size8),
                  // Obx(() => Padding(
                  //   padding:  EdgeInsets.only(right: SizeConfig.size10,top: SizeConfig.size10),
                  //   child: Align(
                  //     alignment: Alignment.centerRight,
                  //     child: GestureDetector(
                  //       onTap: () {
                  //         if (isEmailValid && !emailVerificationController.isVerifying.value) {
                  //           // Validate just the email field
                  //           if (emailController.text.isNotEmpty && validateEmail(emailController.text)) {
                  //             emailVerificationController.verifyEmail(emailController.text);
                  //           } else {
                  //             commonSnackBar(message: 'Please enter a valid email address');
                  //           }
                  //         }
                  //       },
                  //       child:  CustomText(
                  //         'Get Verify',
                  //         fontWeight: FontWeight.bold,
                  //         color: AppColors.primaryColor,
                  //       ),
                  //     ),
                  //   ),
                  // )),
                  Padding(
                    padding: EdgeInsets.only(
                        right: SizeConfig.size10, top: SizeConfig.size10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          if (isEmailValid &&
                              !emailVerificationController.isVerifying.value) {
                            // Validate just the email field
                            if (emailController.text.isNotEmpty &&
                                validateEmail(emailController.text)) {
                              emailVerificationController
                                  .verifyEmail(emailController.text);
                            } else {
                              commonSnackBar(
                                  message:
                                      'Please enter a valid email address');
                            }
                          }
                        },
                        child: CustomText(
                          isEmailVerified ? 'Verified' : 'Get Verify',
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: SizeConfig.size18),

                  // Education Field
                  CommonTextField(
                    title: 'Highest Education',
                    textEditController: educationController,
                    hintText: 'e.g., 12th, B.A, M.A, PhD',
                    // sIcon: Icon(Icons.arrow_drop_down),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your education';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: SizeConfig.size18),

                  CommonTextField(
                    title: 'About Me / Bio',
                    textEditController: bioController,
                    hintText: 'Write about yourself',
                    maxLine: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your bio';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: SizeConfig.size32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomBtn(
                          isValidate: true,
                          onTap: () {
                            Navigator.pop(context);
                          },
                          title: "Cancel",
                          bgColor: AppColors.white,
                          borderColor: AppColors.primaryColor,
                          textColor: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size16),
                      Expanded(
                        child: CustomBtn(
                          isValidate: true,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              // Save profile data
                              personalCreateProfileController
                                  .updateUserProfileDetails(
                                params: {
                                  ApiKeys.location:
                                      locationController.text.trim(),
                                  ApiKeys.user_cordinates: jsonEncode({
                                    ApiKeys.lat: personalCreateProfileController
                                        .locationLat?.value,
                                    ApiKeys.lon: personalCreateProfileController
                                        .locationLng?.value,
                                  }),
                                  ApiKeys.email: emailController.text.trim(),
                                  ApiKeys.highest_education:
                                      educationController.text.trim(),
                                  ApiKeys.bio: bioController.text,
                                },
                              );
                            }
                          },
                          title: "Save",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
