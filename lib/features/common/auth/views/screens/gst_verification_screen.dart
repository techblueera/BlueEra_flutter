import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GstNumberScreen extends StatefulWidget {
  @override
  State<GstNumberScreen> createState() => _GstNumberScreenState();
}

class _GstNumberScreenState extends State<GstNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final authController = Get.find<AuthController>();

  final TextEditingController _gstController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
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
                      appLocalizations?.doYouHaveAGSTNumberTitle,
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CustomText(
                      appLocalizations?.doYouHaveAGSTNumberSubTitle,
                      fontSize: SizeConfig.medium,
                      color: AppColors.grey80,
                    ),
                    SizedBox(height: SizeConfig.size30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRadioOption(
                            true, appLocalizations?.yesIHave ?? ""),
                        SizedBox(width: SizeConfig.size20),
                        _buildRadioOption(
                            false, appLocalizations?.noIDont ?? ""),
                      ],
                    ),
                    SizedBox(
                      height: SizeConfig.size30,
                    ),
                    Obx(() {
                      if (authController.hasGstNumber.value) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonTextField(
                              textEditController: _gstController,
                              hintText: appLocalizations?.enterGSTNumber,
                              title: appLocalizations?.enterGSTNumber,
                              maxLength: 15,
                              isValidate: false,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  authController.isValidate.value = false;
                                  return 'Please enter your GST number';
                                }

                                // ✅ Check format using GST regex
                                final gstRegExp = RegExp(
                                  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
                                );

                                if (!gstRegExp.hasMatch(value)) {
                                  authController.isValidate.value = false;
                                  return 'Please enter a valid GST number';
                                }

                                // ✅ Valid GST number
                                authController.isValidate.value = true;
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
                    /*   (_hasGstNumber == false)
                        ?*/

                    Obx(() {
                      return CustomBtn(
                        onTap: authController.hasGstNumber.value
                            ? authController.isValidate.value
                                ? () => _addBusinessWithGST()
                                : () => null
                            : () => _addBusinessWithGST(),
                        title: appLocalizations?.submit,
                        isValidate: authController.hasGstNumber.value
                            ? authController.isValidate.value
                                ? true
                                : false
                            : true,
                        radius: SizeConfig.size8,
                      );
                    })
                    /*   : CustomBtn(
                            onTap: () => _requestOtp(),
                            title: appLocalizations?.requestOTP,
                            isValidate: true,
                            radius: SizeConfig.size8,
                          )*/
                    ,
                    SizedBox(height: SizeConfig.size4),
                    if (authController.hasGstNumber.value)
                      Center(
                        child: TextButton(
                          onPressed: () => _skip(),
                          child: CustomText(
                            appLocalizations?.skip,
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

  // Future<void> _requestOtp() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     Navigator.pushNamed(context, RouteHelper.getBusinessAccountRoute());
  //   } else {
  //     setState(() {
  //       _autoValidate = AutovalidateMode.always;
  //     });
  //   }
  // }

  Future<void> _skip() async {
    authController.isHaveGstApprove.value = false;

    Navigator.pushNamed(context, RouteHelper.getBusinessAccountRoute());
  }

  Future<void> _addBusinessWithGST() async {
    if (authController.hasGstNumber.value) {
      await Get.find<AuthController>()
          .getGstVerify(gstNumber: _gstController.text);
    } else {
      authController.hasGstNumber.value = false;
      Get.toNamed(RouteHelper.getBusinessAccountRoute());
    }
  }
}
