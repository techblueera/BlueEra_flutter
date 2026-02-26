import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/model/personal_profile_details_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/commom_textfield.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../../widgets/new_common_date_selection_dropdown.dart';
import '../controller/referral_controller.dart';

class JoinAsBDMScreen extends StatefulWidget {
  const JoinAsBDMScreen({Key? key}) : super(key: key);

  @override
  State<JoinAsBDMScreen> createState() => _JoinAsBDMScreenState();
}

class _JoinAsBDMScreenState extends State<JoinAsBDMScreen> {
  final controller = Get.find<ReferralController>();
  final _formKey = GlobalKey<FormState>();

  Widget _sectionCard({required String title, required Widget child}) {
    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CustomText(
        text,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.black,
      ),
    );
  }

  @override
  initState(){
    super.initState();
    if(accountTypeGlobal == AppConstants.individual){
      User? user = Get.find<ViewPersonalDetailsController>().personalProfileDetails.value.user;
      controller.fullNameController.text = user?.name??'';
      controller.emailController.text = user?.email??'';
      controller.selectedDay?.value = user?.dateOfBirth?.date?? 0;
      controller.selectedMonth?.value = user?.dateOfBirth?.month?? 0;
      controller.selectedYear?.value = user?.dateOfBirth?.year?? 0;
      controller.alternatePhoneNumberController.text = user?.contactNo??'';
      controller.workLocationPinCodeController.text = user?.pincode.toString()??'';
      controller.addressController.text = user?.location.toString()??'';
      // controller.cityController.text = user?.city??'';

    }else{
       var businessProfileDetails = Get.find<ViewBusinessDetailsController>().businessProfileDetails?.data;
       controller.fullNameController.text = businessProfileDetails?.ownerDetails?[0].name??'';
       controller.emailController.text = businessProfileDetails?.ownerDetails?[0].email??'';
       controller.selectedDay?.value = businessProfileDetails?.dateOfIncorporation?.date?? 0;
       controller.selectedMonth?.value = businessProfileDetails?.dateOfIncorporation?.month?? 0;
       controller.selectedYear?.value = businessProfileDetails?.dateOfIncorporation?.year?? 0;
       controller.alternatePhoneNumberController.text = businessProfileDetails?.userContactNo??'';
       controller.workLocationPinCodeController.text = businessProfileDetails?.pincode.toString()??'';
       controller.addressController.text = businessProfileDetails?.address??'';
       // controller.cityController.text = businessProfileDetails?.cityStatePincode??'';

       print("📝 Alternate Phone Number: ${businessProfileDetails?.userContactNo??''}");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Join As Business Development",
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                _sectionCard(
                  title: "Personal Details",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextField(
                        title: "Full Name",
                        hintText: AppConstants.name,
                        inputLength: AppConstants.inputCharterLimit30,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        textEditController: controller.fullNameController,
                        isValidate: true,
                        validationType: ValidationTypeEnum.name,
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.emailController,
                        inputLength: AppConstants.inputCharterLimit50,
                        keyBoardType: TextInputType.emailAddress,
                        regularExpression: RegularExpressionUtils.emailPattern,
                        title: AppStrings.email,
                        hintText: AppStrings.emailHint,
                        isValidate: true,
                        validationType: ValidationTypeEnum.email,
                      ),
                
                
                      SizedBox(height: SizeConfig.paddingM),
                      Obx(()=> NewDatePicker(
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
                      )),
                      SizedBox(height: SizeConfig.paddingM),
                
                      _label("Alternate Phone Number"),
                      Row(
                        children: [
                          Container(
                            height: 46,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.coloGreyText.withValues(alpha: 0.5)),
                            ),
                            child: CustomText(
                              "+91",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: CommonTextField(
                              hintText: "1234567890",
                              keyBoardType: TextInputType.number,
                              textEditController: controller
                                  .alternatePhoneNumberController,
                              maxLength: AppConstants.inputCharterLimit10,
                              isValidate: true,
                              validationType: ValidationTypeEnum.name,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                
                      _label("Highest Educational Qualification"),
                      Obx(() => CommonDropdown<Qualification>(
                        items: Qualification.values,
                        selectedValue: controller.selectQualification.value,
                        hintText: AppStrings.qualificationsHint,
                        onChanged: (val) {
                          controller.selectQualification.value = val;
                        },
                        displayValue: (item) => item.displayName,
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your highest education';
                          }
                          return null;
                        },
                      ))

                
                    ],
                  ),
                ),
                SizedBox(height: SizeConfig.paddingXSL),
                
                /// LOCATION DETAILS
                _sectionCard(
                  title: "Location Details",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextField(
                        textEditController: controller.workLocationPinCodeController,
                        title: "Work Location Pin Code",
                        inputLength: AppConstants.inputCharterLimit6,
                        keyBoardType: TextInputType.number,
                        regularExpression: RegularExpressionUtils.digitsPattern,
                        hintText: AppStrings.pincodeHint,
                        isValidate: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.pleaseEnterPinCode.tr;
                          } else if (!RegExp(RegularExpressionUtils.pinCodeRegExp)
                              .hasMatch(value)) {
                            return AppStrings.enterValidIndianPincode.tr;
                          }
                          return null;
                        },
                
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      _label(
                          "In Which Location You Want to Start Your Franchise?"),
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
                          SizedBox(width: 12),
                          Expanded(
                            child: CommonTextField(
                              hintText: "E.g.Salem",
                              textEditController: controller
                                  .cityController,
                              isValidate: true,
                            ),
                          ),
                
                          // Expanded(
                          //   child: Obx(() {
                          //     // Disable city search if no state is selected yet
                          //     bool isStateSelected = controller.selectedState.value.isNotEmpty;
                          //
                          //     return Autocomplete<Map<String, dynamic>>(
                          //       // 1. Fetch suggestions as the user types
                          //       optionsBuilder: (TextEditingValue textEditingValue) async {
                          //         if (textEditingValue.text.length < 2 || !isStateSelected) {
                          //           return const Iterable<Map<String, dynamic>>.empty();
                          //         }
                          //
                          //         // MAGIC TRICK: Append the selected state to the query so Google
                          //         // only searches for cities inside that specific state.
                          //         String smartQuery = "${textEditingValue.text}, ${controller.selectedState.value}";
                          //
                          //         ResponseModel response = await PlaceRepo().getCitiesByState(smartQuery);
                          //
                          //         // ADD THIS TO DEBUG:
                          //         print("Data Type: ${response.response?.data.runtimeType}");
                          //
                          //         // Return the list of predictions
                          //         if (response.response?.data != null && response.response?.data['predictions'] != null) {
                          //           List<dynamic> rawPredictions = response.response?.data['predictions'];
                          //           return rawPredictions.map((e) => e as Map<String, dynamic>).toList();
                          //         }
                          //         return const Iterable<Map<String, dynamic>>.empty();
                          //       },
                          //
                          //       // 2. Format how the option looks in the dropdown list
                          //       displayStringForOption: (Map<String, dynamic> option) {
                          //         // Google gives "Salem, Tamil Nadu, India". We just want "Salem".
                          //         String description = option['description'] ?? '';
                          //         return description.split(',').first.trim();
                          //       },
                          //
                          //       // 3. What happens when they tap a city from the list
                          //       onSelected: (Map<String, dynamic> selection) {
                          //         String fullDescription = selection['description'] ?? '';
                          //         String cityName = fullDescription.split(',').first.trim();
                          //
                          //         // Save the selected city to your controller
                          //         controller.cityController.text = cityName;
                          //         // Optionally: controller.selectedCity.value = cityName;
                          //       },
                          //
                          //       // 4. Wrap your exact UI component here
                          //       fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                          //         return CommonTextField(
                          //           hintText: isStateSelected ? "Search City" : "Select State First",
                          //           textEditController: textController,
                          //           focusNode: focusNode,
                          //           readOnly: !isStateSelected, // Prevent typing if state is empty
                          //         );
                          //       },
                          //     );
                          //   }),
                          // ),
                
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                
                      CommonTextField(
                        title: "Address",
                        regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                        hintText: AppStrings.addressHint,
                        isValidate: false,
                        textEditController: controller.addressController,
                        inputLength: AppConstants.inputCharterLimit50,
                
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                
                      /// TERMS CHECKBOX
                      InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          controller.termAccept.value = !controller.termAccept.value;
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              // aligns to top corner perfectly
                              child: Obx(() {
                                return Checkbox(
                                  value: controller.termAccept.value,
                                  onChanged: (v) {
                                      controller.termAccept.value = v ?? false;
                                  },
                                  checkColor: AppColors.white,
                                  materialTapTargetSize: MaterialTapTargetSize
                                      .shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide(color: AppColors.coloGreyText),
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomText(
                                "I Accept All Terms & Condition And I hereby authorize you to send notifications via SMS/RCS Messages/ Promotional/informational Messages.",
                                fontSize: 13,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                
                      /// SUBMIT BUTTON
                      Obx(() {
                        return CustomBtn(
                            isValidate: true,
                            isLoading: controller.bdmRegisterLoading.value,
                            onTap: () {
                              if(!_formKey.currentState!.validate()) return;
                
                              if (!controller.termAccept.value) {
                                commonSnackBar(
                                  message: "Accept Terms&Conditions",
                                );
                                return;
                
                              }
                              controller.bdmRegisterStepOneApi();
                            },
                            title: controller.bdmRegisterLoading.value ? null  : "Submit");
                      }),
                
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}