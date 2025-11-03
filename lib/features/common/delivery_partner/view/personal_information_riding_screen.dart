import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/email_verification_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:BlueEra/widgets/update_contact_number.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonalInformationRidingScreen extends StatefulWidget {
  const PersonalInformationRidingScreen({super.key});

  @override
  State<PersonalInformationRidingScreen> createState() => _PersonalInformationRidingScreenState();
}

class _PersonalInformationRidingScreenState extends State<PersonalInformationRidingScreen> {
  final controller = Get.put(DeliveryPartnerController());
  final viewProfileController = Get.find<ViewPersonalDetailsController>();
  final emailVerificationController = Get.put(EmailVerificationController());
  final langController = Get.put(LanguageListController());

  @override
  void initState() {
    loadInitData();
    super.initState();
  }

  Future<void> loadInitData() async {
    await viewProfileController.viewPersonalProfile();
    controller.fullNameController.text =
        viewProfileController.personalProfileDetails.value.user?.name ?? "";
    controller.emailController.text =
        viewProfileController.personalProfileDetails.value.user?.email ?? "";
    controller.mobileNumberController.text = viewProfileController
        .personalProfileDetails.value.user?.contactNo??'';
    controller.selectedGender
        .value = GenderTypeExtension.fromString((viewProfileController
        .personalProfileDetails.value.user?.gender?.isNotEmpty ??
        false)
        ? viewProfileController.personalProfileDetails.value.user?.gender ??
        "Male"
        : "Male");
    controller.selectedDay?.value = viewProfileController
        .personalProfileDetails.value.user?.dateOfBirth?.date
        ?.toInt() ??
        0;
    controller.selectedMonth?.value =
        viewProfileController
            .personalProfileDetails.value.user?.dateOfBirth?.month
            ?.toInt() ??
            0;
    controller.selectedYear?.value =
        viewProfileController
            .personalProfileDetails.value.user?.dateOfBirth?.year
            ?.toInt() ??
            0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Flat/Room",
        // onBackTap: onBackPressed,
        buildCustomWidget: ()=> Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  "Step-1/6",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Obx((){
          if(viewProfileController.viewPersonalResponse.value.status == Status.COMPLETE){
            return CustomFormCard(
              child: Form(
                key: controller.formKeyStep1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonTextField(
                      title: "Full Name",
                      hintText: "Enter your full name",
                      textEditController: controller.fullNameController,
                      validationType: ValidationTypeEnum.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        } else if (value.trim().length < 6) {
                          return 'Name must be at least 6 characters';
                        } else if (value.trim().length > 30) {
                          return 'Name must not exceed 30 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    CustomText(
                      "Gender",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdown<GenderType>(
                      items: GenderType.values,
                      selectedValue: controller.selectedGender.value,
                      hintText: "Select Gender",
                      displayValue: (value) => value.displayName,
                      onChanged: (value) {
                        controller.selectedGender.value = value;
                      },
                      validator: (value) {
                        return null;
                      },
                    ),
                    SizedBox(height: SizeConfig.paddingM),
                    NewDatePicker(
                      isAgeValidation15: true,
                      selectedDay: controller
                          .selectedDay?.value,
                      selectedMonth: controller
                          .selectedMonth?.value,
                      selectedYear: controller
                          .selectedYear?.value,
                      onDayChanged: (value) {
                        controller
                            .selectedDay?.value = value ?? 0;
                      },
                      onMonthChanged: (value) {
                        controller
                            .selectedMonth?.value = value ?? 0;
                      },
                      onYearChanged: (value) {
                        controller
                            .selectedYear?.value = value ?? 0;
                      },
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          "Contact Number",
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w400,
                          color: AppColors.mainTextColor,
                        ),
                        InkWell(
                          onTap: () async {
                            final result = await CommonMobileOtpDialog().show(context);

                            if (result == true) {
                              // ✅ OTP successfully verified
                              print("OTP verification successful");
                            } else {
                              // ❌ Either cancelled or verification failed
                              print("OTP verification failed or cancelled");
                            }

                          },
                          child: CustomText(
                            "Edit",
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: SizeConfig.size45,
                          width: SizeConfig.size57,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.greyE5,
                              width: 1,
                            ),
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [AppShadows.textFieldShadow],
                          ),
                          child: CustomText("+91", fontSize: SizeConfig.large),
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: CommonTextField(
                            textEditController: controller.mobileNumberController,
                            inputLength: 10,
                            maxLength: 10,
                            keyBoardType: TextInputType.number,
                            regularExpression:
                            RegularExpressionUtils.digitsPattern,
                            validationType: ValidationTypeEnum.pNumber,
                            hintText: langController.tr('Enter your mobile number'),
                            hintStyle: TextStyle(
                              fontSize: langController.selectedCode.value == 'ta' ? 12 : 14,
                            ),                          onTapOutsideTrue: false,
                            validator: (value) {
                              if (value?.length != 10) {
                                return langController.tr('Please enter valid mobile number');
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingM),

                    CommonTextField(
                      title: "Email",
                      hintText: "Enter your email address",
                      textEditController: controller.emailController,
                      validationType: ValidationTypeEnum.email,
                      onChange: (val) {
                        // filedValidation();
                      },
                      sIcon: (viewProfileController
                          .personalProfileDetails.value.user?.emailVerified == true)
                          ? Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.green39,
                      )
                          : null,
                    ),
                    if(viewProfileController.personalProfileDetails
                        .value.user?.emailVerified ==
                        false)
                      ...[
                        SizedBox(height: SizeConfig.size8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {

                              // Validate just the email field
                              if (controller.emailController.text.isNotEmpty &&
                                  validateEmail(controller.emailController.text)) {
                                emailVerificationController
                                    .verifyEmail(controller.emailController.text);
                              } else {
                                commonSnackBar(
                                    message:
                                    'Please enter a valid email address');
                              }

                            },
                            child: CustomText(
                              'Get Verify',
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],


                    SizedBox(height: SizeConfig.paddingL),
                    CustomBtn(
                      title: controller.isPersonalInformationLoading.value
                          ? null
                          : 'Next',
                      onTap: ()=> controller.ridersOnboardingPersonalInformationApi(),
                      radius: 10.0,
                      bgColor: AppColors.primaryColor,
                      isLoading: controller.isPersonalInformationLoading.value,
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: CircularProgressIndicator(),
          );

        }),
      )
    );
  }
}
