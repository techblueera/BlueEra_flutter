import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
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

  bool isAuthorized = false;

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    return Scaffold(
      appBar: const CommonBackAppBar(title: AppStrings.franchiseInquiry),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                      title: AppStrings.fullName.tr,
                      textEditController: controller.fullNameController,
                      hintText: AppStrings.fullNameHint.tr,
                    ),

                    SizedBox(height: SizeConfig.paddingM),
                    CommonTextField(
                      title: AppStrings.email.tr,
                      textEditController: controller.emailController,
                      hintText: AppStrings.emailHint.tr,
                      keyBoardType: TextInputType.emailAddress,
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
                            hintText: "1234567890",
                            maxLength: 10,
                            keyBoardType: TextInputType.number,
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
                        items: const ["Business Partner", "Marketing Partner"],
                        selectedValue: controller.partnerType.value,
                        hintText: AppStrings.partnerTypeHint.tr,
                        onChanged: (value) {
                          controller.partnerType.value =
                              value ?? "Business Partner";
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
                          value: isAuthorized,
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

                    SizedBox(height: SizeConfig.size30),

                    Obx(() {
                      return CustomBtn(
                        isLoading: controller.enquiryBtnLoading.value,
                        isValidate: true,

                        title: AppStrings.sendMessage.tr, onTap: () {
                        if (_formKey.currentState!.validate()) {
                          controller.enquiryFranchise();
                        }
                        //
                      },
                      );
                    }),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}