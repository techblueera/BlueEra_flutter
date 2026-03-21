import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../../personal/personal_profile/controller/languge_list_controller.dart';

class MobileNumberScreen extends StatefulWidget {
  MobileNumberScreen({super.key});

  @override
  State<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends State<MobileNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  final _authController = Get.put(AuthController());
  late LanguageListController langController;

  @override
  void initState() {
    _getPhoneNumber();
    langController = Get.find<LanguageListController>();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Spacer(flex: 1),

                  LocalAssets(
                    imagePath: AppIconAssets.blueEraIcon,
                    height: SizeConfig.size70,
                  ),

                  LocalAssets(
                    imagePath: AppIconAssets.login_bg,
                    height: SizeConfig.screenHeight / 2.2,
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: CustomText(
                      langController.tr('Login / Sign Up'),
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.large,
                    ),
                  ),

                  SizedBox(height: SizeConfig.size6),
                  SizedBox(height: SizeConfig.size10),

                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: SizeConfig.size45,
                        width: SizeConfig.size57,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.greyE5,
                            width: 1,
                          ),
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [AppShadows.textFieldShadow],
                        ),
                        child: CustomText("+91", fontSize: SizeConfig.large),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: CommonTextField(
                          textEditController:
                          _authController.mobileNumberEditController,
                          inputLength: 10,
                          maxLength: 10,
                          keyBoardType: TextInputType.number,
                          regularExpression:
                          RegularExpressionUtils.digitsPattern,
                          validationType: ValidationTypeEnum.pNumber,
                          hintText: langController.tr('Enter your mobile number'),
                          autoFillType: AutoFillType.phone,
                          hintStyle: TextStyle(
                            fontSize: langController.selectedCode.value == 'ta' ? 12 : 14,
                          ),                          onTapOutsideTrue: false,
                          autovalidateMode: _autoValidate,
                          validator: (value) {
                            if (value?.length != 10) {
                              return langController.tr('Please enter valid mobile number');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size6),
                  SizedBox(height: SizeConfig.size10),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By continuing you agree to ',
                            style: const TextStyle(
                              fontFamily: AppConstants.OpenSans,
                            ),
                          ),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontFamily: AppConstants.OpenSans,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.to(CommonWebView(
                                  urlLink: tncLink,
                                  urlTitle: 'Terms & Conditions',
                                ));
                                // Handle Terms & Conditions tap
                                print('Tapped Terms & Conditions');
                              },
                          ),
                          const TextSpan(text: ' and\n'),
                          TextSpan(
                            text: 'Privacy Policy.',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontFamily: AppConstants.OpenSans,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.to(CommonWebView(
                                  urlLink: privacyLink,
                                  urlTitle: 'Privacy Policy',
                                ));

                                // Handle Privacy Policy tap
                                print('Tapped Privacy Policy');
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Center(
                  //   child: RichText(
                  //     textAlign: TextAlign.center,
                  //     text: TextSpan(
                  //       style: const TextStyle(
                  //         fontSize: 12,
                  //         color: Colors.black87,
                  //       ),
                  //       children: [
                  //         TextSpan(
                  //           text: langController.tr('agreeToTermsText') ??
                  //               'By continuing you agree to ',
                  //           style: const TextStyle(
                  //             fontFamily: AppConstants.OpenSans,
                  //           ),
                  //         ),
                  //         TextSpan(
                  //           text: langController.tr('termsAndConditions') ??
                  //               'Terms & Conditions',
                  //           style: const TextStyle(
                  //             color: AppColors.primaryColor,
                  //             fontFamily: AppConstants.OpenSans,
                  //           ),
                  //           recognizer: TapGestureRecognizer()
                  //             ..onTap = () {
                  //               Get.to(CommonWebView(
                  //                 urlLink: tncLink,
                  //                 urlTitle: 'Terms & Conditions',
                  //               ));
                  //             },
                  //         ),
                  //         TextSpan(
                  //           text: langController.tr('andText') ?? ' and\n',
                  //         ),
                  //         TextSpan(
                  //           text: langController.tr('privacyPolicy') ??
                  //               'Privacy Policy.',
                  //           style: const TextStyle(
                  //             color: AppColors.primaryColor,
                  //             fontFamily: AppConstants.OpenSans,
                  //           ),
                  //           recognizer: TapGestureRecognizer()
                  //             ..onTap = () {
                  //               Get.to(CommonWebView(
                  //                 urlLink: privacyLink,
                  //                 urlTitle: 'Privacy Policy',
                  //               ));
                  //             },
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  SizedBox(height: SizeConfig.size20),

                  CustomBtn(
                    bgColor: AppColors.primaryColor,
                    textColor: AppColors.white,
                    title: langController.tr('Get OTP'),
                    onTap: () => _onNextButtonPressed(context),
                  ),

                  SizedBox(height: SizeConfig.size22),

                  // Example (if you later add Guest login)
                  // CustomText(
                  //   langController.tr('loginAsGuest') ?? "Login as Guest",
                  //   color: Colors.blue,
                  //   fontWeight: FontWeight.w500,
                  //   decoration: TextDecoration.underline,
                  //   decorationColor: AppColors.primaryColor,
                  // ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///Show Bottom sheet...
  Future<void> _onNextButtonPressed(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      Get.find<AuthController>().isOtpType.value = AppConstants.SMS;
      await Get.find<AuthController>().sendOTP();
      unFocus();
    } else {
      setState(() {
        _autoValidate = AutovalidateMode.always;
      });
    }
  }

  Future<void> _getPhoneNumber() async {
    try {
      final autoFill = SmsAutoFill();
      final phone = await autoFill.hint;

      // Modified logic to get the last 10 digits
      if (phone != null) {
        // Remove any non-digit characters first
        String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

        // Get the last 10 digits
        if (digitsOnly.length >= 10) {
          _authController.mobileNumberEditController.text =
              digitsOnly.substring(digitsOnly.length - 10);
        } else {
          // If less than 10 digits, use whatever is available
          _authController.mobileNumberEditController.text = digitsOnly;
        }
      } else {
        _authController.mobileNumberEditController.text = '';
      }

      // log('Phone Number from GetMethod ${mobileController.text}');
    } on Exception {
      // Handle exceptions
    }
  }
}
