import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/new_common_date_selection_dropdown.dart';
import '../../controller/referral_controller.dart';

class JoinAsBDMScreen extends StatefulWidget {
  const JoinAsBDMScreen({Key? key}) : super(key: key);

  @override
  State<JoinAsBDMScreen> createState() => _JoinAsBDMScreenState();
}

class _JoinAsBDMScreenState extends State<JoinAsBDMScreen> {

  final controller = getOrPut(() => ReferralController());


  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8,),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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

  Widget _dropdownBox(String hint) {
    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coloGreyText.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            hint,
            fontSize: 16,
            color: AppColors.coloGreyText,
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.secondaryTextColor)
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonBackAppBar(
        title: "Join As Business Development",
      ),
      body: SingleChildScrollView(
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
                    hintText: "E.g.1 Year",
                    textEditController: controller.fullNameController,
                  ),
                  SizedBox(height: 16),
                  CommonTextField(
                    title: "Email",
                    hintText: "E.g. inquiry@gmail.com",
                    textEditController: controller.emailController,
                  ),
                  SizedBox(height: 16),

                  _label("D.O.B"),
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
                  SizedBox(height: 16),

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
                              color: AppColors.coloGreyText.withOpacity(0.5)),
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
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  _label("Highest Educational Qualification"),
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

                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),

            /// LOCATION DETAILS
            _sectionCard(
              title: "Location Details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonTextField(
                    title: "Work Location Pin Code",
                    hintText: "E.g.456856",
                    keyBoardType: TextInputType.number,
                    textEditController: controller
                        .workLocationPinCodeController,
                  ),
                  SizedBox(height: 16),
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
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  CommonTextField(
                    title: "Address",
                    hintText:
                    "E.g. Lucknow , Utter pradesh, Lorem Ipsum Dolor...",
                    maxLine: 3,
                    textEditController: controller.addressController,

                  ),
                  SizedBox(height: 16),

                  /// TERMS CHECKBOX
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        // aligns to top corner perfectly
                        child: Obx(() {
                          return Checkbox(
                            value: controller.termAccept.value,
                            onChanged: (v) {
                              setState(() {
                                controller.termAccept.value = v ?? false;
                              });
                            },
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
                  SizedBox(height: 10),

                  /// SUBMIT BUTTON
                  Obx(() {
                    return CustomBtn(
                        isValidate: true,
                        isLoading: controller.submitLoading.value,
                        onTap: () {
                          if (controller.termAccept.value) {
                            controller.joinAsBdmApi();
                          } else {
                            commonSnackBar(
                              message: "Accept Terms&Conditions",
                            );
                          }
                          // Get.to(JoinBdmDocumentVerifiedPage());
                        }, title: "Submit");
                  }),

                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}