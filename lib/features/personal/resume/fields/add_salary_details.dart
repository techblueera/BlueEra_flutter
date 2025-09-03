  import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/resume/controller/salary_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

  class AddSalaryDetailsScreen extends StatefulWidget {
    final bool isEdit;
    const AddSalaryDetailsScreen({Key? key, this.isEdit = false}) : super(key: key);

    @override
    State<AddSalaryDetailsScreen> createState() => _AddSalaryDetailsScreenState();
  }

  class _AddSalaryDetailsScreenState extends State<AddSalaryDetailsScreen> {
    final SalaryController controller = Get.find<SalaryController>();

    final _formKey = GlobalKey<FormState>();

    @override
    void initState() {
      super.initState();

      if (widget.isEdit) {
        if (controller.workExperienceList.isNotEmpty) {
          final item = controller.workExperienceList[0];
          controller.grossSalaryController.text = item['grossSalary'] ?? '';
          controller.monthlyDeductionController.text = item['monthlyDeduction'] ?? '';
          controller.partTimeEarningController.text = item['partTimeEarning'] ?? '';
          controller.freelanceEarningController.text = item['freelanceEarning'] ?? '';
        }
      } else {
        controller.clearSalaryFields();
      }
    }

    @override
    Widget build(BuildContext context) {
      SizeConfig.init(context);
      return Scaffold(
        appBar: CommonBackAppBar(title: widget.isEdit ? "Edit Salary Details" : "Add Salary Details"),
        body: Padding(
          padding: EdgeInsets.all(SizeConfig.paddingL),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SizeConfig.size20)),
                  child: Padding(
                    padding: EdgeInsets.all(SizeConfig.size20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonTextField(
                            title: "Enter your Gross salary (Monthly)",
                            hintText: "Eg. ₹ 10,000",
                            textEditController: controller.grossSalaryController,
                            keyBoardType: TextInputType.number,
                            fontSize: SizeConfig.small,
                            onChange: (val) => controller.grossSalary.value = val,
                            isValidate: false,
                          ),
                          SizedBox(height: SizeConfig.size18),
                          CommonTextField(
                            title: "Total Monthly Deduction (Eg: EPF/TDS/TCS/PF-etc)",
                            hintText: "Eg. ₹ 10,000",
                            textEditController: controller.monthlyDeductionController,
                            keyBoardType: TextInputType.number,
                            fontSize: SizeConfig.small,
                            onChange: (val) => controller.monthlyDeduction.value = val,
                            isValidate: false,
                          ),
                          SizedBox(height: SizeConfig.size18),
                          CommonTextField(
                            title: "Earning Via Part Time Job (Monthly)",
                            hintText: "Eg. ₹ 10,000",
                            textEditController: controller.partTimeEarningController,
                            keyBoardType: TextInputType.number,
                            fontSize: SizeConfig.small,
                            onChange: (val) => controller.partTimeEarning.value = val,
                            isValidate: false,
                          ),
                          SizedBox(height: SizeConfig.size18),
                          CommonTextField(
                            title: "Earning Via Freelancing job (Monthly)",
                            hintText: "Eg. ₹ 10,000",
                            textEditController: controller.freelanceEarningController,
                            keyBoardType: TextInputType.number,
                            fontSize: SizeConfig.small,
                            onChange: (val) => controller.freelanceEarning.value = val,
                            isValidate: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size18),
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SizeConfig.size20)),
                  child: Padding(
                    padding: EdgeInsets.all(SizeConfig.size20),
                    child: Column(
                      children: [
                        Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: SizeConfig.paddingS),
                                    child: CustomText("Total Earning (Monthly) -"),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: CommonTextField(
                                    fontSize: SizeConfig.small,
                                    readOnly: true,
                                    isValidate: false,
                                    hintText: "₹ ${controller.totalMonthlyEarning.value}",
                                  ),
                                ),
                              ],
                            )),
                        SizedBox(height: SizeConfig.size18),
                        Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: SizeConfig.paddingS),
                                    child: CustomText("Your Annual Package -"),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: CommonTextField(
                                    readOnly: true,
                                    isValidate: false,
                                    fontSize: SizeConfig.small,
                                    hintText: "₹ ${controller.annualPackage.value}",
                                  ),
                                ),
                              ],
                            )),
                        SizedBox(height: SizeConfig.size40),
                        Obx(() => CustomBtn(
                              title: widget.isEdit ? "Update" : "Save",
                              textColor: Colors.white,
                              radius: SizeConfig.size8,
                              isValidate: controller.isSalaryFormValid.value,
                              onTap: controller.isSalaryFormValid.value
                                  ? () async {
                                      Map<String, dynamic> params = {
                                        "grossSalary": int.tryParse(
                                                controller.grossSalary.value.replaceAll(',', '').trim()) ??
                                            0,
                                        "monthlyDeduction": int.tryParse(
                                                controller.monthlyDeduction.value.replaceAll(',', '').trim()) ??
                                            0,
                                        "monthlyEarningViaPartTime": int.tryParse(
                                                controller.partTimeEarning.value.replaceAll(',', '').trim()) ??
                                            0,
                                        "monthlyEarningViaFreelancing": int.tryParse(
                                                controller.freelanceEarning.value.replaceAll(',', '').trim()) ??
                                            0,
                                        "monthlyTotalEarning":
                                            double.tryParse(controller.totalMonthlyEarning.value) ?? 0,
                                        "annualPackage": double.tryParse(controller.annualPackage.value) ?? 0,
                                      };

                                      await controller.addOrUpdateSalary(params);
                                    }
                                  : null,
                            )),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size24),
              ],
            ),
          ),
        ),
      );
    }
  }
