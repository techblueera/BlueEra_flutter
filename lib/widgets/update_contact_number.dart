import 'dart:async';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class CommonMobileOtpDialog {
  Future<bool?> show(BuildContext context) async {
    final mobileController = TextEditingController();
    final otpController = TextEditingController();
    final langController = Get.find<LanguageListController>();

    bool isOtpSent = false;
    bool isSendingOtp = false;
    bool isVerifyingOtp = false;
    bool isTimerActive = false;
    int secondsLeft = 30;
    Timer? timer;

    /// Starts the resend timer
    void startTimer(StateSetter setState) {
      timer?.cancel();
      secondsLeft = 30;
      isTimerActive = true;
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsLeft == 0) {
          t.cancel();
          setState(() => isTimerActive = false);
        } else {
          setState(() => secondsLeft--);
        }
      });
    }

    /// Show main dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              contentPadding: EdgeInsets.all(SizeConfig.size20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      langController.tr("Mobile Number Verification"),
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: SizeConfig.size20),

                    /// Step 1: Enter Mobile Number
                    if (!isOtpSent)
                      _buildMobileStep(
                        context: context,
                        langController: langController,
                        mobileController: mobileController,
                        isSendingOtp: isSendingOtp,
                        setSending: (sending) => setState(() => isSendingOtp = sending),
                        onSendOtp: () async {
                          if (mobileController.text.length != 10) {
                            commonSnackBar(
                              message: langController.tr(
                                  'Please enter valid mobile number'),
                            );
                            return;
                          }
                          setState(() => isSendingOtp = true);
                          final success = await sendOTP({
                            ApiKeys.contact_no: mobileController.text,
                            ApiKeys.type: AppConstants.SMS,
                          });

                          if (success) {
                            setState(() {
                              isSendingOtp = false;
                              isOtpSent = true;
                            });
                            startTimer(setState);
                          }
                          setState(() => isSendingOtp = false);
                        },
                      ),

                    /// Step 2: Enter OTP
                    if (isOtpSent)
                      _buildOtpStep(
                        context: context,
                        langController: langController,
                        mobileController: mobileController,
                        otpController: otpController,
                        isVerifyingOtp: isVerifyingOtp,
                        isTimerActive: isTimerActive,
                        secondsLeft: secondsLeft,
                        onResend: () => startTimer(setState),
                        onEditNumber: () {
                          timer?.cancel();
                          setState(() {
                            isOtpSent = false;
                            isTimerActive = false;
                            otpController.clear();
                          });
                        },
                       setVerifying: (verifying) => setState(() => isVerifyingOtp = verifying),
                       onVerify: () async {
                          if (otpController.text.length != 6) {
                            commonSnackBar(
                              message: langController
                                  .tr('Please enter valid OTP'),
                            );
                            return;
                          }

                          log('call verify otp');
                          // Example logic for verifying OTP:
                          // setState(() => isVerifyingOtp = true);
                          // final verified = await verifyOTP({
                          //   ApiKeys.contact_no: mobileController.text,
                          //   ApiKeys.otp: otpController.text,
                          // });
                          // setState(() => isVerifyingOtp = false);
                          // if (verified) Navigator.of(context).pop(true);
                        },
                      ),

                    SizedBox(height: SizeConfig.size15),
                    CustomBtn(
                      bgColor: Colors.grey[300],
                      textColor: Colors.black,
                      title: langController.tr('Cancel'),
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    timer?.cancel();
    return result;
  }

  /// --- MOBILE INPUT STEP ---
  Widget _buildMobileStep({
    required BuildContext context,
    required LanguageListController langController,
    required TextEditingController mobileController,
    required bool isSendingOtp,
    required Function(bool) setSending,
    required VoidCallback onSendOtp,
  }   ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              height: SizeConfig.size45,
              width: SizeConfig.size57,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyE5),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.white,
                boxShadow: [AppShadows.textFieldShadow],
              ),
              child: CustomText("+91", fontSize: SizeConfig.large),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CommonTextField(
                textEditController: mobileController,
                keyBoardType: TextInputType.number,
                inputLength: 10,
                maxLength: 10,
                hintText: langController.tr('Enter your mobile number'),
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size25),
        CustomBtn(
          bgColor: AppColors.primaryColor,
          textColor: AppColors.white,
          title: isSendingOtp
              ? langController.tr('Sending...')
              : langController.tr('Send OTP'),
          onTap: isSendingOtp ? null : onSendOtp,
        ),
      ],
    );
  }

  /// --- OTP INPUT STEP ---
  Widget _buildOtpStep({
    required BuildContext context,
    required LanguageListController langController,
    required TextEditingController mobileController,
    required TextEditingController otpController,
    required bool isVerifyingOtp,
    required bool isTimerActive,
    required int secondsLeft,
    required VoidCallback onResend,
    required VoidCallback onEditNumber,
    required Function(bool) setVerifying,
    required VoidCallback onVerify,
  }) {
    return Column(
      children: [
        CustomText(
          "+91 ${mobileController.text}",
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: SizeConfig.size10),
        InkWell(
          onTap: onEditNumber,
          child: CustomText(
            langController.tr("✎ Edit number"),
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
        SizedBox(height: SizeConfig.size20),
        Pinput(
          controller: otpController,
          length: 6,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          defaultPinTheme: PinTheme(
            width: 50,
            height: 50,
            textStyle: TextStyle(
              fontSize: SizeConfig.medium,
              color: Colors.black,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.white,
              border: Border.all(color: AppColors.greyE5),
              boxShadow: [AppShadows.textFieldShadow],
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size15),

        /// Timer + Resend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CustomText(langController.tr("Didn't get OTP?")),
            isTimerActive
                ? CustomText(
              "00:${secondsLeft.toString().padLeft(2, '0')} sec",
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            )
                : InkWell(
              onTap: onResend,
              child: CustomText(
                langController.tr('Resend Code'),
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size25),
        CustomBtn(
          bgColor: AppColors.primaryColor,
          textColor: AppColors.white,
          title: isVerifyingOtp
              ? langController.tr('Verifying...')
              : langController.tr('Verify OTP'),
          onTap: isVerifyingOtp ? null : onVerify,
        ),
      ],
    );
  }

  /// --- API CALLS ---
  Future<bool> sendOTP(Map<String, dynamic> params) async {
    try {
      ResponseModel response =
      await AuthRepo().authMobileOtpSendRepo(bodyRequest: params);
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        return true;
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }

  Future<bool> verifyOTP(Map<String, dynamic> params) async {
    try {
      ResponseModel response =
      await AuthRepo().authMobileOtpVerifyRepo(bodyRequest: params);

      if (response.statusCode == 200) {
        return true;
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
    } catch (e) {
      commonSnackBar(message: e.toString());
      return false;
    }
  }
}
