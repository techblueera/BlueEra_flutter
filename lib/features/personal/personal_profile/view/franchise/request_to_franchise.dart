import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_enum.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../controller/profile_controller.dart';


class FranchiseInquiryScreen extends StatefulWidget {
  const FranchiseInquiryScreen({super.key});

  @override
  State<FranchiseInquiryScreen> createState() =>
      _FranchiseInquiryScreenState();
}

class _FranchiseInquiryScreenState extends State<FranchiseInquiryScreen> {

  final controller = getOrPut(() => VisitProfileController());
  final _formKey = GlobalKey<FormState>();
  bool isAuthorized = false;

  /// Validate, then send. The two dropdowns and the consent box are checked by
  /// hand: they aren't [FormField]s, so `Form.validate()` never sees them.
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (controller.selectQualification.value.isEmpty) {
      commonSnackBar(message: AppStrings.qualificationRequired.tr);
      return;
    }
    if (controller.partnerType.value.isEmpty) {
      commonSnackBar(message: AppStrings.partnerTypeRequired.tr);
      return;
    }
    if (!isAuthorized) {
      commonSnackBar(message: AppStrings.acceptTermsRequired.tr);
      return;
    }
    controller.enquiryFranchise();
  }

  /// Send, pinned to the bottom of the screen instead of the bottom of the
  /// form.
  ///
  /// This form is long enough that the button used to be several scrolls below
  /// the fold — the action was only reachable by scrolling to the end, which
  /// also hid whether it was still loading once the user scrolled away. The
  /// Scaffold lifts a `bottomNavigationBar` above the keyboard, so it stays put
  /// and visible while the fields are being filled in.
  Widget _submitBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.paddingM,
        SizeConfig.size10,
        SizeConfig.paddingM,
        SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        // A hairline rather than a shadow: the form sits on a tinted page and
        // the bar is white, so the edge is what separates them.
        border: Border(top: BorderSide(color: AppColors.greyE5)),
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => CustomBtn(
            isLoading: controller.enquiryBtnLoading.value,
            isValidate: true,
            title: AppStrings.sendMessage.tr,
            onTap: _submit,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(title: AppStrings.franchiseInquiry),
      bottomNavigationBar: _submitBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 8.0,
        ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        /*    Container(
              height: SizeConfig.size200,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),

                  color: AppColors.white
              ),
              padding: EdgeInsets.all(14),
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.whiteE5
                ),
                child: Center(
                  child: Container(
                    height: SizeConfig.size50,
                    width: SizeConfig.size50,
                    decoration: BoxDecoration(
                      color: AppColors.black65,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow,
                        color: AppColors.white,
                        size: SizeConfig.size30),
                  ),
                ),
              ),
            ),

            SizedBox(height: SizeConfig.size10),
              */
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  CommonTextField(
                    title:"First Name",
                    textEditController: controller.fullNameController,
                    hintText: AppStrings.fullNameHint.tr,
                    validationMessage: AppStrings.firstNameRequired.tr,
                  ),

                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    title: "Last Name",
                    textEditController: controller.lastNameController,
                    hintText: "Patel",
                    validationMessage: AppStrings.lastNameRequired.tr,
                  ),

                  SizedBox(height: SizeConfig.paddingM),
                  CommonTextField(
                    title: AppStrings.email.tr,
                    textEditController: controller.emailController,
                    hintText: AppStrings.emailHint.tr,
                    keyBoardType: TextInputType.emailAddress,
                    validationType: ValidationTypeEnum.email,
                    validationMessage: AppStrings.validEmailRequired.tr,
                  ),
                  SizedBox(height: SizeConfig.paddingM),

                  /// Phone Number
                  CustomText(
                    AppStrings.phoneNumberLabel,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingM,
                            vertical: SizeConfig.size12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.greyE5),
                        ),
                        child: CustomText(
                          "+91",
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: SizeConfig.paddingS),
                      Expanded(
                        child: CommonTextField(
                          textEditController: controller.phoneController,
                          hintText: "9934567890",
                          maxLength: 10,
                          keyBoardType: TextInputType.number,
                          validationType: ValidationTypeEnum.pNumber,
                          validationMessage: AppStrings.validPhoneRequired.tr,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingM),
                  CustomText(AppStrings.highestEducationalQualification,
                    fontSize: 12,),
                  SizedBox(height: SizeConfig.size8,),
                  Obx(() =>
                      CommonDropdown<String>(
                        items: controller.qualificationsList,
                        selectedValue:
                        controller.selectQualification.value.isEmpty
                            ? null
                            : controller.selectQualification.value,
                        hintText: AppStrings.qualificationsHint,
                        onChanged: (val) =>
                        controller.selectQualification.value = val ?? "",
                        displayValue: (item) => item,
                      )),

                  SizedBox(height: SizeConfig.paddingM),
                  CustomText(
                    AppStrings.selectPartnerTypeQuestion,
                    fontSize: SizeConfig.small,
                  ),

                  SizedBox(height: SizeConfig.size8),

                  Obx(() {
                    return CommonDropdown(
                      isExpanded: true,
                      items: const ["Business Partner", "Marketing Partner", "Franchise Partner"],
                      selectedValue: controller.partnerType.value.isEmpty
                          ? null
                          : controller.partnerType.value,
                      hintText: AppStrings.partnerTypeHint.tr,
                      onChanged: (value) {
                        controller.partnerType.value =
                            value ?? "";
                      },
                      displayValue: (value) => value,
                    );
                  }),
                  SizedBox(height: SizeConfig.paddingM),


                  CommonTextField(
                    title: AppStrings.amountYouCanInvest.tr,
                    textEditController: controller.investmentController,
                    hintText: AppStrings.enterAmount.tr,
                    maxLength: 12,
                    keyBoardType: TextInputType.number,
                    validationMessage: AppStrings.investmentAmountRequired.tr,
                  ),


                  SizedBox(height: SizeConfig.paddingM),

                  CustomText(
                    AppStrings.franchiseLocationQuestion,
                  ),

                  SizedBox(height: SizeConfig.size8),

                  Row(
                    children: [
                      Expanded(
                        child: Obx(() {
                          return CommonDropdown(items:
                          controller.stateList,
                              selectedValue: controller.selectedState.value,
                              hintText: AppStrings.selectState.tr,
                              onChanged: (val) {
                                controller.selectState(val ?? '');
                              },
                              displayValue: (value) => value
                          );
                        }),
                      ),
                      SizedBox(width: SizeConfig.paddingM),
                      Expanded(
                        child: CommonTextField(
                          hintText: AppStrings.cityHint.tr,
                          textEditController: controller
                              .cityController,
                          validationMessage: AppStrings.cityRequired.tr,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.paddingM),

                  CustomText(
                    AppStrings.workedInBusinessQuestion,
                  ),

                  SizedBox(height: SizeConfig.size8),
                  Obx(() {
                    return CommonDropdown(
                        isExpanded: true,
                        items: const ["Yes", "No"],
                        selectedValue: controller.haveYouWorkedHere.value,
                        hintText: AppStrings.yesNoHint.tr,
                        onChanged: (value) {
                          controller.haveYouWorkedHere.value = value ?? "No";
                        },
                        displayValue: (value) => value);
                  }),
                  SizedBox(height: SizeConfig.paddingM),


                  CommonTextField(
                    title: AppStrings.message.tr,
                    textEditController: controller.messageController,
                    hintText:
                    AppStrings.franchiseMessageHint.tr,
                    maxLine: 5,
                    minLines: 4,
                    hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.placeHolder
                    ),
                  ),

                  SizedBox(height: SizeConfig.size10),

                  /// Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Checkbox(
                        value: isAuthorized,checkColor: AppColors.white,
                        activeColor: AppColors.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            isAuthorized = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: CustomText(
                          AppStrings.franchiseAuthorizationConsent,
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),

                  // Submit lives in the Scaffold's bottom bar — see
                  // [_submitBar].
                  SizedBox(height: SizeConfig.size10),
                ],
              ),
            ),
          ],
        ),
      ),
            ),
    );
  }
}
