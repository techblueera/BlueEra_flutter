// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpPageScreen extends StatefulWidget {
  const OtpPageScreen({super.key, this.mobileNumber});

  final String? mobileNumber;

  @override
  State<OtpPageScreen> createState() => _OtpPageScreenState();
}

class _OtpPageScreenState extends State<OtpPageScreen> with CodeAutoFill {
  final _formKey = GlobalKey<FormState>();
  PinputAutovalidateMode _autoValidate = PinputAutovalidateMode.disabled;
  final TextEditingController _otpController = TextEditingController();

  static const int _initialSeconds = 30;
  Timer? _timer;
  int _secondsLeft = _initialSeconds;
  bool _isTimerActive = true;
  bool _isSubmitDisabled = false;

  @override
  void initState() {
    super.initState();
    _printAppSignature(); // 👈 print hash for Android backend SMS
    _startTimer();
    listenForCode();
  }

  void _startTimer() {
    _cancelTimer();
    setState(() {
      _secondsLeft = _initialSeconds;
      _isTimerActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        _cancelTimer();
        setState(() => _isTimerActive = false);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _cancelTimer() {
    if (_timer?.isActive ?? false) _timer?.cancel();
  }

  @override
  void dispose() {
    cancel();
    _cancelTimer();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _printAppSignature() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint("📲 App Signature (send this to backend SMS): $signature");
    } catch (e) {
      debugPrint("Error getting app signature: $e");
    }
  }

  @override
  void codeUpdated() {
    debugPrint("Received OTP: $code");
    if (code != null && code!.length == 6) {
      _otpController.text = code!;
      _onOtpChanged(code!); // trigger validation and submit
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        commonConformationDialog(
            context: context,
            text: "Are you sure you want to exit the app?",
            confirmCallback: () async {
              await SharedPreferenceUtils.clearPreference();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  RouteHelper.getMobileNumberLoginRoute(),
                      (Route<dynamic> route) => false);
            },
            cancelCallback: () {
              Navigator.of(context).pop(); // Close the dialog
            });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Column(
                  children: [
                    Spacer(flex: 1),
                    LocalAssets(
                      imagePath: AppIconAssets.blueEraIcon,
                      height: SizeConfig.size70,
                    ),
                    Container(
                      // color: Colors.red,
                      child: SizedBox(
                        height: SizeConfig.screenHeight / 2.6,
                        child: LocalAssets(imagePath: AppIconAssets.otp_bg),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CustomText(
                        loc.enterOtp,
                        fontWeight: FontWeight.bold,
                        fontSize: SizeConfig.large,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size20),
                    Pinput(
                      controller: _otpController,
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
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size10),
                          color: AppColors.white,
                          border: Border.all(
                            color: AppColors.greyE5,
                            width: 1,
                          ),
                          boxShadow: [AppShadows.textFieldShadow],
                        ),
                      ),
                      onChanged: _onOtpChanged,
                      // onCompleted: (_) => _onVerifyOtpPressed(context),
                      pinputAutovalidateMode: _autoValidate,
                      validator: (value) {
                        if (value == null || value.length != 6) {
                          return 'Please enter a valid 6 digit OTP';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: SizeConfig.size20),
                    CustomBtn(
                      onTap: () => _isSubmitDisabled
                          ? _onVerifyOtpPressed(context)
                          : null,
                      title: loc.submit,
                      isValidate: _isSubmitDisabled,
                    ),
                    SizedBox(height: SizeConfig.size30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          loc.didntGetOtp,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: _isTimerActive
                              ? CustomText(
                                  _formatTime(_secondsLeft),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                )
                              : InkWell(
                                  onTap: () => _onResendOtpPressed(context),
                                  child: CustomText(
                                    loc.resend,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primaryColor,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int secondsLeft) {
    final duration = Duration(seconds: secondsLeft);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds sec';
  }

  Future<void> _onOtpChanged(String value) async {
    setState(() => _isSubmitDisabled = value.length == 6);
    if (value.length == 6) {
      await Get.find<AuthController>().verifyOTP(otp: value);
    }
  }

  Future<void> _onVerifyOtpPressed(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_otpController.text.length == 6) {
        await Get.find<AuthController>().verifyOTP(otp: _otpController.text);
      }
    } else {
      setState(() {
        _autoValidate = PinputAutovalidateMode.onSubmit;
      });
    }
  }

  Future<void> _onResendOtpPressed(BuildContext context) async {
    if (widget.mobileNumber?.isEmpty ?? true) {
      commonSnackBar(message: 'Mobile number is not available');
      return;
    }
    await Get.find<AuthController>().sendOTP();
    // commonSnackBar(message: 'OTP resent successfully');
    if (Get.find<AuthController>().otpVerificationResponse.status ==
        Status.COMPLETE) {
      _otpController.clear();
      _startTimer();
      setState(() => _isSubmitDisabled = true);
    }
  }
}
