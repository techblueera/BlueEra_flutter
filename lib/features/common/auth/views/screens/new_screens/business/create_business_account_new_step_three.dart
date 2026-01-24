import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/business_description/business_description_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CreateBusinessAccountNewStepThree extends StatefulWidget {
  final String? city;
  const CreateBusinessAccountNewStepThree({
    super.key,
    this.city
  });

  @override
  State<CreateBusinessAccountNewStepThree> createState() =>
      _CreateBusinessAccountNewStepThreeState();
}

class _CreateBusinessAccountNewStepThreeState
    extends State<CreateBusinessAccountNewStepThree> {
  final nameTextController = TextEditingController();
  final yourRoleController = TextEditingController();
  final emailTextController = TextEditingController();
  final descriptionController = Get.put(BusinessDescriptionController());
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
    viewBusinessDetailsController.listingDescriptionController.value.addListener(_validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      aiGeneratedBusinessDesc());

  }

  Future<void> aiGeneratedBusinessDesc() async {
   await descriptionController.generateDescriptions(
        onSaved: _validateForm,
        bodyRequest: {
          ApiKeys.business_name:
          viewBusinessDetailsController
              .businessProfileDetails
              ?.data
              ?.businessName,
          ApiKeys.category:
          viewBusinessDetailsController
              .businessProfileDetails
              ?.data
              ?.categoryDetails
              ?.name,
          ApiKeys.sub_category:
          viewBusinessDetailsController
              .businessProfileDetails
              ?.data
              ?.subCategoryDetails
              ?.name,
          ApiKeys.city: widget.city
        });
  }


  void _validateForm() {
    setState(() {
      isFormValid = nameTextController.text.trim().isNotEmpty &&
          yourRoleController.text.trim().isNotEmpty &&
          emailTextController.text.trim().isNotEmpty &&
          viewBusinessDetailsController.listingDescriptionController.value
              .text
              .trim()
              .isNotEmpty;
    });
  }


  @override
  void dispose() {
    nameTextController.dispose();
    yourRoleController.dispose();
    emailTextController.dispose();
    nameTextController.removeListener(_validateForm);
    yourRoleController.removeListener(_validateForm);
    emailTextController.removeListener(_validateForm);
    viewBusinessDetailsController
        .listingDescriptionController
        .value
        .removeListener(_validateForm);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: CommonBackAppBar(
            isLeading: true,
            title: AppStrings.businessDetailsTitle
        ),
        body: AbsorbPointer(
          absorbing: viewBusinessDetailsController.isUpdateBusinessDetailsLoading.value,
          child: SingleChildScrollView(
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
          
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          AppStrings.shortBusinessDescription,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                        Obx(()=> !descriptionController.isLoading.value
                            ? InkWell(
                            onTap: () async {
                              await aiGeneratedBusinessDesc();
                              if (!mounted) return;
                              _validateForm();
                            },
                            child: LocalAssets(
                              height: 25,
                              width: 25,
                              imgColor: AppColors.primaryColor,
                              imagePath: AppIconAssets.ai_generative,
                            )) : SizedBox(
                                height: 25,
                                width: 25,
                              child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                            )),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingXSL),
                    CommonTextField(
                      validator: null,
                      borderWidth: 0,
                      borderColor: Colors.transparent,
                      hintText:
                      AppStrings.businessDescriptionExample,
                      textEditController: viewBusinessDetailsController
                          .listingDescriptionController.value,
                      maxLine: 5,
                      isValidate: false,
                      maxLength: AppConstants.inputCharterLimit400,
                      onChange: (val) {
                        viewBusinessDetailsController.businessDescription.value = val;
                        viewBusinessDetailsController.listingDescriptionController.value.text = val;
                        _validateForm();
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AppConstants.inputCharterLimit400,
                        ),
                        NoLeadingSpaceFormatter(),
                        NoConsecutiveSpacesFormatter(),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size10),
                    Obx(() {
                      return Align(
                        alignment: Alignment.bottomRight,
                        child: CustomText(
                          "${viewBusinessDetailsController.businessDescription.value.length}/${AppConstants.inputCharterLimit400}",
                          color: AppColors.grey9B,
                          fontSize: SizeConfig.small,
                        ),
                      );
                    }),
                    SizedBox(
                      height: SizeConfig.size28,
                    ),
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
                      inputLength: AppConstants.inputCharterLimit50,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
                      title: AppStrings.yourNameHint,
                      hintText: AppConstants.name,
                      isValidate: false,
                    ),
                    SizedBox(
                      height: SizeConfig.size20,
                    ),
                    CommonTextField(
                      textEditController: yourRoleController,
                      inputLength: AppConstants.inputCharterLimit50,
                      keyBoardType: TextInputType.text,
                      regularExpression:
                      RegularExpressionUtils.alphabetSpacePattern,
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
                      title: AppStrings.email,
                      hintText: AppStrings.emailHint,
                      isValidate: true,
                      validationType: ValidationTypeEnum.email,
                    ),
                    SizedBox(
                      height: SizeConfig.size28,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomBtn(
                            radius: 10,
                            onTap: () {
                              Get.toNamed(RouteHelper.getAddBusinessLivePhotoRoute());
                            },
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
                          child: Obx(()=> CustomBtn(
                            radius: 10,
                            onTap: isFormValid
                                ? () async {
          
                              /// Submit action
                              Map<String, dynamic> reqParam = {
                                ApiKeys.businessId: businessId,
                                ApiKeys.business_description:
                                viewBusinessDetailsController
                                    .businessDescription.value,
                                ApiKeys.owner_details: jsonEncode([
                                  {
                                    ApiKeys.name: nameTextController.text,
                                    ApiKeys.role_in_business:
                                    yourRoleController.text,
                                    ApiKeys.email: emailTextController.text
                                  }
                                ]),
                              };
                              await viewBusinessDetailsController
                                  .updateBusinessDetails(reqParam, showProgress: false);
                              Get.toNamed(RouteHelper.getAddBusinessLivePhotoRoute());
                            }
                                : null,
                            title: viewBusinessDetailsController.isUpdateBusinessDetailsLoading.value
                                ? null
                                : AppStrings.submit,
                            isLoading: viewBusinessDetailsController.isUpdateBusinessDetailsLoading.value,
                            isValidate: isFormValid,
                          )),
                        ),
                      ],
                    ),
          
                  ],
                ),
              ),
            ),
          ),
        ));
  }

}
