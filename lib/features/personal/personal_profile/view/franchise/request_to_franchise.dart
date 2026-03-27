import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

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
      appBar: const CommonBackAppBar(title: "Franchise Inquiry"),
      body: SingleChildScrollView(
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
                      title: "Full Name",
                      textEditController: controller.fullNameController,
                      hintText: "E.g. 1 Year",
                    ),

                    SizedBox(height: SizeConfig.paddingM),
                    CommonTextField(
                      title: "Email",
                      textEditController: controller.emailController,
                      hintText: "E.g. inquiry@gmail.com",
                      keyBoardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    /// Phone Number
                    CustomText(
                      "Phone Number",
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
                    CustomText("Highest Educational Qualification",
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
                      "Select The Type of Partner you are interested to become?",
                      fontSize: SizeConfig.small,
                    ),

                    SizedBox(height: SizeConfig.size8),

                    Obx(() {
                      return CommonDropdown(
                        isExpanded: true,
                        items: const ["Business Partner", "Marketing Partner"],
                        selectedValue: controller.partnerType.value,
                        hintText: "E.g. Business Partner/ Marketing....",
                        onChanged: (value) {
                          controller.partnerType.value =
                              value ?? "Business Partner";
                        },
                        displayValue: (value) => value,
                      );
                    }),
                    SizedBox(height: SizeConfig.paddingM),


                    CommonTextField(
                      title: "Amount You Can Invest(In Rupees) ?",
                      textEditController: controller.investmentController,
                      hintText: "Enter amount",
                      maxLength: 12,
                      keyBoardType: TextInputType.number,
                    ),

                  
                    SizedBox(height: SizeConfig.paddingM),

                    CustomText(
                      "In Which Location You Want to Start Your Franchise?",
                    ),

                    SizedBox(height: SizeConfig.size8),

                    Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            return CommonDropdown(items:
                            controller.stateList,
                                selectedValue: controller.selectedState.value,
                                hintText: "Select State",
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
                            hintText: "E.g.Salem",
                            textEditController: controller
                                .cityController,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    CustomText(
                      "Have you ever worked in a business environment where you handled marketing, customer acquisition, or digital communication?",
                    ),

                    SizedBox(height: SizeConfig.size8),
                    Obx(() {
                      return CommonDropdown(
                          isExpanded: true,
                          items: const ["Yes", "No"],
                          selectedValue: controller.haveYouWorkedHere.value,
                          hintText: "E.g. Yes / No",
                          onChanged: (value) {
                            controller.haveYouWorkedHere.value = value ?? "No";
                          },
                          displayValue: (value) => value);
                    }),
                    SizedBox(height: SizeConfig.paddingM),


                    CommonTextField(
                      title: "Message",
                      textEditController: controller.messageController,
                      hintText:
                      "Hello Everyone @India User\nNow I am Using https://blueera.ai It's Amazing, I suggest to Join Me.",
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
                            "I hereby authorize you to send notifications via SMS/ RCS Messages/Promotional/informational Messages.",
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

                        title: "Send Message", onTap: () {
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
    );
  }
}