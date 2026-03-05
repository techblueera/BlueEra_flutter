import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/health_camp_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthCampFormScreen extends StatefulWidget {
  final HealthCamp? existing;

  const HealthCampFormScreen({super.key, this.existing});

  @override
  State<HealthCampFormScreen> createState() => _HealthCampFormScreenState();
}

class _HealthCampFormScreenState extends State<HealthCampFormScreen> {
  late final HealthCampController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<HealthCampController>()) {
      controller = Get.put(HealthCampController(), permanent: true);
    } else {
      controller = Get.find<HealthCampController>();
    }
    controller.preloadForm(widget.existing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.existing == null
              ? AppStrings.createHealthCamp.tr
              : AppStrings.editHealthCamp.tr),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextField(
                textEditController: controller.typeController,
                title: AppStrings.activityType.tr,
                hintText: AppStrings.egFreeHealthCheckup.tr,
                onChange: (val) {
                  controller.activityType.value = val;
                  controller.validateForm();
                },
              ),
              SizedBox(height: SizeConfig.size16),
              CommonTextField(
                textEditController: controller.descController,
                title: AppStrings.description.tr,
                hintText: AppStrings.describeTheCamp.tr,
                maxLine: 4,
                onChange: (val) => controller.validateForm(),
              ),
              SizedBox(height: SizeConfig.size16),
              CommonTextField(
                textEditController: controller.sqFootController,
                title: AppStrings.sqFoot.tr,
                hintText: "E.g. 200",
                keyBoardType: TextInputType.number,
                onChange: (val) => controller.validateForm(),
              ),
              SizedBox(height: SizeConfig.size16),
              Row(
                children: [

                  Expanded(
                    child: CommonTextField(
                      textEditController: controller.priceController,
                      title: AppStrings.price.tr,
                      hintText: "E.g. 499",
                      keyBoardType: TextInputType.number,
                      onChange: (val) => controller.validateForm(),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CommonTextField(
                      textEditController: controller.discountPriceController,
                      title: AppStrings.discountPrice.tr,
                      hintText: "E.g. 399",
                      keyBoardType: TextInputType.number,
                      onChange: (val) => controller.validateForm(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size16),
              CustomText(AppStrings.startDate.tr,
                  fontSize: 12, fontWeight: FontWeight.w400),
              SizedBox(height: SizeConfig.size8),
              Obx(() => NewDatePicker(
                    selectedDay: controller.startDay.value,
                    selectedMonth: controller.startMonth.value,
                    selectedYear: controller.startYear.value,
                    isFutureYear: true,
                    onDayChanged: (v) {
                      controller.startDay.value = v!;
                      controller.validateForm();
                    },
                    onMonthChanged: (v) {
                      controller.startMonth.value = v!;
                      controller.validateForm();
                    },
                    onYearChanged: (v) {
                      controller.startYear.value = v!;
                      controller.validateForm();
                    },
                  )),
              SizedBox(height: SizeConfig.size16),
              CustomText(AppStrings.endDate.tr, fontSize: 12, fontWeight: FontWeight.w400),
              SizedBox(height: SizeConfig.size8),
              Obx(() => NewDatePicker(
                    selectedDay: controller.endDay.value,
                    selectedMonth: controller.endMonth.value,
                    selectedYear: controller.endYear.value,
                    isFutureYear: true,
                    onDayChanged: (v) {
                      controller.endDay.value = v!;
                      controller.validateForm();
                    },
                    onMonthChanged: (v) {
                      controller.endMonth.value = v!;
                      controller.validateForm();
                    },
                    onYearChanged: (v) {
                      controller.endYear.value = v!;
                      controller.validateForm();
                    },
                  )),
              SizedBox(height: SizeConfig.size16),
              _buildSingleTimeDropdown(AppStrings.startTime.tr, controller.selectedTime),
              // SizedBox(height: SizeConfig.size16),
              // CommonTextField(
              //   textEditController:
              //       TextEditingController(text: controller.laboratoryId.value),
              //   title: "Laboratory ID",
              //   hintText: "E.g. 698b225f2c44cc586fa1d5c2",
              //   onChange: (val) {
              //     controller.laboratoryId.value = val.trim();
              //     controller.validateForm();
              //   },
              // ),
              SizedBox(height: SizeConfig.size20),
              Obx(() => CustomBtn(
                    title: widget.existing == null ? AppStrings.create.tr : AppStrings.update.tr,
                    isValidate: controller.isValid.value,
                    isLoading: controller.isLoading.value,
                    onTap: controller.isValid.value
                        ? () async {
                            bool ok;
                            if (widget.existing == null) {
                              ok = await controller.createCamp();
                            } else {
                              ok =
                                  await controller.updateCamp(widget.existing!);
                            }
                            if (ok) Get.back();
                          }
                        : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleTimeDropdown(String label, RxString selectedValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontSize: 12, fontWeight: FontWeight.w400),
        const SizedBox(height: 8),
        Obx(() => SizedBox(
              width: double.infinity,
              child: _buildDropdown(controller.timeSlots, selectedValue.value,
                  (val) {
                selectedValue.value = val!;
                controller.validateForm();
              }),
            )),
      ],
    );
  }

  Widget _buildDropdown(
      List<String> items, String currentValue, Function(String?) onChanged) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: AppColors.greyE5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : null,
          hint: CustomText(AppStrings.selectStartTime.tr),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.mainTextColor,
          ),
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: AppConstants.OpenSans,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: CustomText(
                value,
                fontSize: 12,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
