import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
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
  bool _acceptedTerms = false;
  bool _isMobileValid = false;

  bool get _canSubmit => _isMobileValid && _acceptedTerms;

  @override
  void initState() {
    _getPhoneNumber();
    langController = Get.find<LanguageListController>();
    _authController.mobileNumberEditController.addListener(_onMobileChanged);
    // AuthController is permanent, so a stale LOADING from a previous send
    // could otherwise mount this screen with the overlay already showing.
    // Reset to INITIAL on entry (mirrors OtpPageScreen).
    _authController.mobileNoOtpSendResponse.value =
        ApiResponse.initial('Initial');

    super.initState();
  }

  @override
  void dispose() {
    _authController.mobileNumberEditController.removeListener(_onMobileChanged);
    super.dispose();
  }

  void _onMobileChanged() {
    final isValid =
        _authController.mobileNumberEditController.text.length == 10;
    if (isValid != _isMobileValid) {
      setState(() {
        _isMobileValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Padding(
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
                      AppStrings.loginSignup.tr,
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.large,
                    ),
                  ),

                  SizedBox(height: SizeConfig.size16),

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
                          textInputAction: TextInputAction.done,
                          regularExpression:
                          RegularExpressionUtils.digitsPattern,
                          validationType: ValidationTypeEnum.pNumber,
                          hintText: AppStrings.enterMobileNumberHint.tr,
                          autoFillType: AutoFillType.phone,
                          hintStyle: TextStyle(
                            fontSize: langController.selectedCode.value == 'ta' ? 12 : 14,
                          ),                          onTapOutsideTrue: false,
                          autovalidateMode: _autoValidate,
                          onChange: (value) {
                            if (value.length == 10) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                          onDone: (_) => _onNextButtonPressed(context),
                          validator: (value) {
                            if (value?.length != 10) {
                              return AppStrings.pleaseEnterValidMobileNo.tr;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size6),
                  SizedBox(height: SizeConfig.size10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          activeColor: AppColors.primaryColor,
                          checkColor: AppColors.white,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (val) {
                            setState(() {
                              _acceptedTerms = val ?? false;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Expanded(
                        child: RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: AppStrings.byContinuingYouAgree.tr,
                                style: const TextStyle(
                                  fontFamily: AppConstants.OpenSans,
                                  fontSize: 14,

                                ),
                              ),
                              TextSpan(
                                text: " ${AppStrings.termsConditions.tr} ",
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontFamily: AppConstants.OpenSans,
                                  fontSize: 14,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Get.to(() => CommonWebView(
                                          urlLink: tncLink,
                                          urlTitle:
                                              AppStrings.termsConditions.tr,
                                        ));
                                  },
                              ),
                              TextSpan(text: "${AppStrings.andText.tr} "),
                              TextSpan(
                                text: AppStrings.privacyPolicyDot.tr,
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                  fontFamily: AppConstants.OpenSans,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Get.to(() => CommonWebView(
                                          urlLink: privacyLink,
                                          urlTitle:
                                              AppStrings.privacyPolicy.tr,
                                        ));
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.size20),

                  Obx(() {
                    final loading = _authController
                            .mobileNoOtpSendResponse.value.status ==
                        Status.LOADING;
                    final canSubmit = _canSubmit && !loading;
                    return SizedBox(
                      width: double.infinity,
                      height: SizeConfig.size44,
                      child: ElevatedButton.icon(
                        onPressed: canSubmit
                            ? () => _onNextButtonPressed(context)
                            : null,
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const SizedBox.shrink(),
                        label: Text(
                          loading
                              ? '${AppStrings.getOtp.tr}…'
                              : AppStrings.getOtp.tr,
                          style: TextStyle(
                            fontFamily: AppConstants.OpenSans,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          disabledBackgroundColor: loading
                              ? AppColors.primaryColor.withValues(alpha: 0.5)
                              : AppColors.grey9B,
                          padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.size12,
                            horizontal: SizeConfig.size16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(SizeConfig.size8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    );
                  }),

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
          // Dimmed full-screen overlay while sendOTP is in flight — catches
          // taps so the user can't double-submit or re-tap Get OTP mid-request.
          // The inline button spinner above signals progress; this just adds
          // the visual veil. Mirrors OtpPageScreen's verifyOTP overlay.
          Obx(() {
            final loading =
                _authController.mobileNoOtpSendResponse.value.status ==
                    Status.LOADING;
            if (!loading) return const SizedBox.shrink();
            return Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.20),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  ///Show Bottom sheet...
  Future<void> _onNextButtonPressed(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptedTerms) {
        commonSnackBar(
            message: AppStrings.pleaseAcceptTermsAndConditions.tr);
        return;
      }
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
