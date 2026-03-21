import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/gst_details_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import 'package:BlueEra/widgets/common_drop_down.dart';

import '../../controller/gst_controller.dart';

class GstNumberScreen extends StatefulWidget {
  final String accountType;
  final BusinessType businessType;
  // final CategoryData? categoryData;
  final String categorySlugId;
  final String categoryName;
  final SubCategories? subCategory;

  GstNumberScreen({
    super.key,
    required this.accountType,
    required this.businessType,
    required this.categorySlugId,
    required this.categoryName,
    // this.categoryData,
    required this.subCategory
  });

  @override
  State<GstNumberScreen> createState() => _GstNumberScreenState();
}

class _GstNumberScreenState extends State<GstNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final authController = Get.find<AuthController>();

  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GstController gstController = Get.put(GstController());

  @override
  initState(){
    super.initState();
    authController.selectedTypeOfBusiness = widget.businessType;
    authController.selectedCategoryName = widget.categoryName;
    authController.selectedCategorySlugId = widget.categorySlugId;
    authController.selectedSubCategoryData = widget.subCategory;
    log("------------------ SELECTION DATA ------------------");
    log("Business Type    : ${authController.selectedTypeOfBusiness}");
    log("Category Name    : ${authController.selectedCategoryName}");
    log("Category Slug Id  : ${authController.selectedCategorySlugId}");
    log('sub category Name : ${authController.selectedSubCategoryData?.name}');
    log('sub category Slug Id : ${authController.selectedSubCategoryData?.sId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(SizeConfig.size15),
                padding: EdgeInsets.all(SizeConfig.size15),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(SizeConfig.size8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: SizeConfig.size10,
                      offset: Offset(0, SizeConfig.size2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.size15),
                    CustomText(
                      "Do you have a GST number?",
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CustomText(
                     "If yes, your business will be instantly marked as verified.",
                      fontSize: SizeConfig.medium,
                      color: AppColors.grey80,
                    ),
                    SizedBox(height: SizeConfig.size30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRadioOption(
                            true,'Yes, I have'),
                        SizedBox(width: SizeConfig.size20),
                        _buildRadioOption(
                            false, 'No, I don’t'),
                      ],
                    ),
                    SizedBox(
                      height: SizeConfig.size30,
                    ),
                    Obx(() {
                      if (authController.hasGstNumber.value) {
                        final isGstVerified = gstController.gstResponse.value.status == Status.COMPLETE;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonTextField(
                              textEditController: _emailController,
                              hintText: 'Enter Email linked to GST',
                              title: 'Enter Email',
                              readOnly: isGstVerified,
                              autoFillType: AutoFillType.email,
                              isValidate: false,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: SizeConfig.size15),
                            CommonTextField(
                              textEditController: _gstController,
                              hintText: 'Enter GST Number',
                              title: 'Enter GST Number',
                              maxLength: 15,
                              isValidate: false,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    authController.isValidate.value = false;
                                  });
                                  return 'Please enter your GST number';
                                }
                                final gstRegExp = RegExp(
                                  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                                );

                                if (!gstRegExp.hasMatch(value)) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    authController.isValidate.value = false;
                                  });
                                  return 'Please enter a valid GST number';
                                }

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  authController.isValidate.value = true;
                                });
                                return null;
                              },
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox();
                      }
                    }),
                    SizedBox(height: SizeConfig.size20),
                    
                    Obx(() {
                      final response = gstController.gstResponse.value;
                      if (authController.hasGstNumber.value && response.status == Status.COMPLETE) {
                        final GstDetailsModel gstData = response.data;
                        final data = gstData.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: SizeConfig.size20),
                              padding: EdgeInsets.all(SizeConfig.size12),
                              decoration: BoxDecoration(
                                color: AppColors.whiteF3,
                                borderRadius: BorderRadius.circular(SizeConfig.size8),
                                border: Border.all(color: AppColors.green4F, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "Trade Name: ${data?.tradeNam ?? 'N/A'}",
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainTextColor,
                                  ),
                                  SizedBox(height: SizeConfig.size4),
                                  CustomText(
                                    "Address: ${data?.pradr?.addr?.getFullAddress() ?? 'N/A'}",
                                    fontSize: SizeConfig.small,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                            // CustomText(
                            //   "GST State Code",
                            //   fontSize: SizeConfig.medium,
                            //   fontWeight: FontWeight.w600,
                            // ),
                            // SizedBox(height: SizeConfig.size8),
                            // Obx(() => CommonDropdown<Map<String, String>>(
                            //   items: GstController.gstStateCodes,
                            //   selectedValue: gstController.selectedStateCode.value != null
                            //       ? GstController.gstStateCodes.firstWhere(
                            //           (e) => e['code'] == gstController.selectedStateCode.value,
                            //           orElse: () => GstController.gstStateCodes.first,
                            //         )
                            //       : null,
                            //   hintText: 'Select State Code',
                            //   onChanged: (val) {
                            //     gstController.selectedStateCode.value = val?['code'];
                            //   },
                            //   displayValue: (item) => "${item['code']}: ${item['state']}",
                            // )),
                            // SizedBox(height: SizeConfig.size15),
                            CommonTextField(
                              textEditController: gstController.gstUsernameController,
                              hintText: 'Enter GST Username',
                              title: 'GST Username',
                              readOnly: gstController.otpResponse.value.status == Status.COMPLETE,
                              isValidate: false,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter GST username';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: SizeConfig.size15),
                            if (gstController.otpResponse.value.status == Status.COMPLETE) ...[
                              CustomText(
                                "Enter OTP",
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(height: SizeConfig.size8),
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
                                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                                    color: AppColors.white,
                                    border: Border.all(
                                      color: AppColors.greyE5,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: SizeConfig.size15),
                            ],
                          ],
                        );
                      } else if (authController.hasGstNumber.value && response.status == Status.ERROR) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: CustomText(
                            response.message ?? "Something went wrong",
                            color: Colors.red,
                            fontSize: SizeConfig.small,
                          ),
                        );
                      }
                      return const SizedBox();
                    }),

                    Obx(() {
                      if (authController.hasGstNumber.value && gstController.otpResponse.value.status == Status.ERROR) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: CustomText(
                            gstController.otpResponse.value.message ?? "OTP request failed",
                            color: Colors.red,
                            fontSize: SizeConfig.small,
                          ),
                        );
                      }
                      return const SizedBox();
                    }),

                    Obx(() {
                      if (authController.hasGstNumber.value && gstController.authTokenResponse.value.status == Status.ERROR) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: SizeConfig.size10),
                          child: CustomText(
                            gstController.authTokenResponse.value.message ?? "OTP verification failed",
                            color: Colors.red,
                            fontSize: SizeConfig.small,
                          ),
                        );
                      }
                      return const SizedBox();
                    }),

                    Obx(() {
                      final isOtpGenerated = gstController.otpResponse.value.status == Status.COMPLETE;
                      final isGstVerified = gstController.gstResponse.value.status == Status.COMPLETE;
                      return CustomBtn(
                        onTap: authController.hasGstNumber.value
                            ? authController.isValidate.value
                            ? () async {
                          if (_formKey.currentState!.validate()) {
                            if (isOtpGenerated) {
                              final otp = _otpController.text.trim();
                              if (otp.length == 6) {
                                await gstController.requestAuthToken(
                                  _emailController.text, otp,
                                );
                                if (gstController.authTokenResponse.value.status == Status.COMPLETE) {
                                  Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepOneRoute());
                                }
                              }
                            } else if (isGstVerified) {
                              gstController.requestOtp(_emailController.text);
                            } else {
                              gstController.getGstDetails(
                                _emailController.text, _gstController.text
                              );
                            }
                          }
                        }
                            : null
                            : () {
                          // No GST logic
                           Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepOneRoute());
                        },
                        title: gstController.isLoading.value
                            ? (isGstVerified
                                ? "Generating OTP..."
                                : "Verifying...")
                            : isOtpGenerated
                                ? "Verify OTP"
                                : isGstVerified
                                    ? "Generate OTP"
                                    : "Submit",
                        isValidate: authController.hasGstNumber.value
                            ? authController.isValidate.value
                            : true,
                        radius: SizeConfig.size8,
                      );
                    }),
                    
                    SizedBox(height: SizeConfig.size4),
                    if (authController.hasGstNumber.value)
                      Center(
                        child: TextButton(
                          onPressed: () => _skip(),
                          child: CustomText(
                            "Skip",
                            color: AppColors.primaryColor,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryColor,
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(bool value, String label) {
    return Obx(() {
      return InkWell(
        onTap: () {
          authController.isHaveGstApprove.value = value;
          if (value) {
            authController.isValidate.value = false;
            _gstController.clear();
            _emailController.clear();
          } else {
            gstController.resetState();
            _otpController.clear();
          }

          authController.hasGstNumber.value = value;
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: SizeConfig.size20,
              height: SizeConfig.size20,
              child: Radio<bool>(
                value: value,
                groupValue: authController.hasGstNumber.value,
                fillColor: WidgetStateProperty.all(AppColors.primaryColor),
                activeColor: AppColors.primaryColor,
                onChanged: (val) {
                  if (val == null) return;
                  authController.isHaveGstApprove.value = value;
                  if (value) {
                    authController.isValidate.value = false;
                    _gstController.clear();
                    _emailController.clear();
                  } else {
                    gstController.resetState();
                    _otpController.clear();
                  }

                  authController.hasGstNumber.value = value;
                },
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            CustomText(label)
          ],
        ),
      );
    });
  }

  Future<void> _skip() async {
    authController.isHaveGstApprove.value = false;
    Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepOneRoute());
  }

  Future<void> _addBusinessWithGST() async {
    if (authController.hasGstNumber.value) {
      await Get.find<AuthController>()
          .getGstVerify(gstNumber: _gstController.text);
    } else {
      authController.hasGstNumber.value = false;
      Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepOneRoute());
    }
  }
}
