import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../personal/personal_profile/controller/languge_list_controller.dart';

class GstNumberScreen extends StatefulWidget {
  final String accountType;
  final BusinessType businessType;

  final String categorySlugId;
  final String categoryName;
  final SubCategories? subCategory;

  GstNumberScreen(
      {super.key,
      required this.accountType,
      required this.businessType,
      required this.categorySlugId,
      required this.categoryName,
      required this.subCategory});

  @override
  State<GstNumberScreen> createState() => _GstNumberScreenState();
}

class _GstNumberScreenState extends State<GstNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final authController = Get.find<AuthController>();
  late LanguageListController langController;

  final TextEditingController _gstController = TextEditingController();

  @override
  initState() {
    super.initState();
    langController = Get.find<LanguageListController>();
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
  void dispose() {
    _gstController.dispose();
    super.dispose();
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
                      AppStrings.doYouHaveGstNumber.tr,
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CustomText(
                      AppStrings.gstVerifiedHint.tr,
                      fontSize: SizeConfig.medium,
                      color: AppColors.grey80,
                    ),
                    SizedBox(height: SizeConfig.size30),
                    Obx(() => RadioGroup<bool>(
                          groupValue: authController.hasGstNumber.value,
                          onChanged: (val) {
                            if (val == null) return;
                            _onRadioChanged(val);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRadioOption(true, AppStrings.yesIHave.tr),
                              SizedBox(width: SizeConfig.size20),
                              _buildRadioOption(false, AppStrings.noIDont.tr),
                            ],
                          ),
                        )),
                    SizedBox(height: SizeConfig.size30),
                    Obx(() {
                      if (!authController.hasGstNumber.value) {
                        return const SizedBox();
                      }
                      return CommonTextField(
                        textEditController: _gstController,
                        hintText: AppStrings.enterGstNumberLabel.tr,
                        title: AppStrings.enterGstNumberLabel.tr,
                        maxLength: 15,
                        isValidate: false,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(15),
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]')),
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.toUpperCase(),
                            ),
                          ),
                        ],
                        onChange: (_) => _validateAll(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.pleaseEnterGstNumber.tr;
                          }
                          if (!_gstRegExp.hasMatch(value)) {
                            return AppStrings.pleaseEnterValidGstNumber.tr;
                          }
                          return null;
                        },
                      );
                    }),
                    SizedBox(height: SizeConfig.size20),
                    Obx(() {
                      final isLoading =
                          authController.isGstVerifyLoading.value;
                      return CustomBtn(
                        onTap: authController.hasGstNumber.value
                            ? (authController.isValidate.value && !isLoading)
                                ? () async {
                                    if (_formKey.currentState!.validate()) {
                                      await authController.getGstVerify(
                                        gstNumber: _gstController.text.trim(),
                                      );
                                    }
                                  }
                                : null
                            : () {
                                Get.toNamed(RouteHelper
                                    .getCreateBusinessAccountNewStepOneRoute());
                              },
                        title: isLoading
                            ? AppStrings.verifyingDots.tr
                            : AppStrings.submit.tr,
                        isValidate: authController.hasGstNumber.value
                            ? authController.isValidate.value
                            : true,
                        radius: SizeConfig.size8,
                      );
                    }),
                    SizedBox(height: SizeConfig.size4),
                    Obx(() {
                      if (!authController.hasGstNumber.value) {
                        return const SizedBox();
                      }
                      return Center(
                        child: TextButton(
                          onPressed: () => _skip(),
                          child: CustomText(
                            AppStrings.skip.tr,
                            color: AppColors.primaryColor,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryColor,
                          ),
                        ),
                      );
                    }),
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
      final groupValue = authController.hasGstNumber.value;
      return InkWell(
        onTap: () => _onRadioChanged(value),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: SizeConfig.size20,
              height: SizeConfig.size20,
              child: Radio<bool>(
                value: value,
                groupValue: groupValue,
                onChanged: (val) {
                  if (val == null) return;
                  _onRadioChanged(val);
                },
                fillColor: WidgetStateProperty.all(AppColors.primaryColor),
                activeColor: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            CustomText(label)
          ],
        ),
      );
    });
  }

  void _onRadioChanged(bool value) {
    authController.isHaveGstApprove.value = value;
    if (value) {
      authController.isValidate.value = false;
      _gstController.clear();
    } else {
      _gstController.clear();
    }
    authController.hasGstNumber.value = value;
  }

  Future<void> _skip() async {
    authController.isHaveGstApprove.value = false;
    Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepOneRoute());
  }

  void _validateAll() {
    final gst = _gstController.text.trim();
    authController.isValidate.value = _gstRegExp.hasMatch(gst);
  }

  // GSTIN format (15 chars):
  //  [0-9]{2}     state code
  //  [A-Z]{5}     PAN first 5 chars
  //  [0-9]{4}     PAN next 4 digits
  //  [A-Z]{1}     PAN last char
  //  [1-9A-Z]{1}  entity number
  //  [A-Z]{1}     defaults to 'Z' but spec allows any uppercase letter
  //  [0-9A-Z]{1}  checksum
  static final RegExp _gstRegExp = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}[A-Z]{1}[0-9A-Z]{1}$',
  );
}
