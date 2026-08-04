import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateBusinessAccountNewStepThree extends StatefulWidget {
  final String? city;
  const CreateBusinessAccountNewStepThree({super.key, this.city});

  @override
  State<CreateBusinessAccountNewStepThree> createState() =>
      _CreateBusinessAccountNewStepThreeState();
}

class _CreateBusinessAccountNewStepThreeState
    extends State<CreateBusinessAccountNewStepThree> {
  final nameTextController = TextEditingController();
  final yourRoleController = TextEditingController();
  final emailTextController = TextEditingController();
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  bool isFormValid = false;

  @override
  void initState() {
    super.initState();
    // Add listeners for validation
    nameTextController.addListener(_validateForm);
    yourRoleController.addListener(_validateForm);
    emailTextController.addListener(_validateForm);
  }

  void _validateForm() {
    String email = emailTextController.text.trim();
    bool isEmailValid = email.isEmpty ||
        (GetUtils.isEmail(email) && email.endsWith("@gmail.com"));

    setState(() {
      isFormValid = nameTextController.text.trim().isNotEmpty &&
          yourRoleController.text.trim().isNotEmpty &&
          isEmailValid;
    });
  }

  @override
  void dispose() {
    nameTextController.removeListener(_validateForm);
    yourRoleController.removeListener(_validateForm);
    emailTextController.removeListener(_validateForm);
    nameTextController.dispose();
    yourRoleController.dispose();
    emailTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: CommonBackAppBar(
            isLeading: true, title: AppStrings.businessDetailsTitle),
        body: SingleChildScrollView(
          child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16, vertical: SizeConfig.size30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CustomText(
                        AppStrings.ownerDetail,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),
                    CommonTextField(
                      textEditController: nameTextController,
                      inputLength: AppConstants.inputCharterLimit30,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                          RegularExpressionUtils.alphabetSpacePattern_,
                      title: AppStrings.yourNameHint,
                      hintText: AppConstants.name,
                      isValidate: false,
                      autoFillType: AutoFillType.name,
                    ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),
                    CommonTextField(
                      textEditController: yourRoleController,
                      inputLength: AppConstants.inputCharterLimit30,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                          RegularExpressionUtils.alphabetSpacePattern_,
                      title: AppStrings.yourRole,
                      hintText: AppStrings.yourRoleHint,
                      isValidate: false,
                    ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),
                    CommonTextField(
                      textEditController: emailTextController,
                      inputLength: AppConstants.inputCharterLimit50,
                      keyBoardType: TextInputType.emailAddress,
                      regularExpression: RegularExpressionUtils.emailPattern,
                      title: "${AppStrings.email} (Optional)",
                      hintText: AppStrings.emailHint,
                      isValidate: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        if (!GetUtils.isEmail(value)) {
                          return AppStrings.invalidEmail.tr;
                        }
                        if (!value.endsWith("@gmail.com")) {
                          return "Only @gmail.com allowed";
                        }
                        return null;
                      },
                      validationType: ValidationTypeEnum.email,
                      autoFillType: AutoFillType.email,
                    ),
                    SizedBox(
                      height: SizeConfig.size28,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomBtn(
                            radius: 10,
                            // Skipping the owner details still leads to the
                            // description step — it's skippable in its own turn.
                            onTap: _goToDescriptionStep,
                            title: AppStrings.skip,
                            bgColor: Colors.transparent,
                            textColor: AppColors.primaryColor,
                            borderColor: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(
                          width: SizeConfig.size10,
                        ),
                        Expanded(
                          child: Obx(() {
                            final loading = viewBusinessDetailsController
                                .isUpdateBusinessDetailsLoading.value;
                            final canSubmit = isFormValid && !loading;
                            return SizedBox(
                              height: SizeConfig.size44,
                              child: ElevatedButton.icon(
                                onPressed: canSubmit ? _onSubmit : null,
                                icon: loading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                label: Text(
                                  // Owner details are no longer the last step —
                                  // the description step follows.
                                  loading
                                      ? '${AppStrings.nextButton.tr}…'
                                      : AppStrings.nextButton.tr,
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
                                      ? AppColors.primaryColor
                                          .withValues(alpha: 0.5)
                                      : AppColors.greyB4,
                                  padding: EdgeInsets.symmetric(
                                    vertical: SizeConfig.size12,
                                    horizontal: SizeConfig.size16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }

  Future<void> _onSubmit() async {
    if (nameTextController.text.trim().length < 4) {
      commonSnackBar(message: "Name must be at least 4 characters.");
      return;
    }
    if (yourRoleController.text.trim().length < 4) {
      commonSnackBar(message: "Role must be at least 4 characters.");
      return;
    }
    if (emailTextController.text.trim().isNotEmpty) {
      final emailError =
          ValidationMethod.validateEmail(emailTextController.text.trim());
      if (emailError != null) {
        commonSnackBar(message: emailError);
        return;
      }
    }

    final reqParam = <String, dynamic>{
      ApiKeys.businessId: businessId,
      ApiKeys.owner_details: jsonEncode([
        {
          ApiKeys.name: nameTextController.text,
          ApiKeys.role_in_business: yourRoleController.text,
          ApiKeys.email: emailTextController.text,
        }
      ]),
    };

    await viewBusinessDetailsController.updateBusinessDetails(
      reqParam,
      showProgress: false,
    );
    if (!mounted) return;
    _goToDescriptionStep();
  }

  /// The business description now has a step of its own (step four), where the
  /// ready-written category suggestions are offered. `city` rides along for
  /// the AI generator there.
  void _goToDescriptionStep() {
    Get.toNamed(
      RouteHelper.getCreateBusinessAccountNewStepFourRoute(),
      arguments: {ApiKeys.city: widget.city},
    );
  }
}
