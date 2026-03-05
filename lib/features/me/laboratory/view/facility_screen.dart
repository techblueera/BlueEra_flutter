import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/facility_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({super.key});

  @override
  State<FacilityScreen> createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  late final FacilityController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FacilityController>()) {
      controller = Get.put(FacilityController(), permanent: true);
    } else {
      controller = Get.find<FacilityController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  CommonBackAppBar(title: AppStrings.facilities,),
      body: CommonCardWidget(
        child: SafeArea(
          child: Obx(() {
            return SingleChildScrollView(
              // padding: EdgeInsets.all(SizeConfig.size16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitch(
                      AppStrings.wheelchairAssistance.tr, controller.wheelchairAssistance),
                  _buildSwitch(AppStrings.doctorConsultationTieUp.tr,
                      controller.doctorConsultationTieUp),
                  _buildSwitch(AppStrings.insuranceCashlessSupport.tr,
                      controller.insuranceCashlessSupport),
                  _buildSwitch(AppStrings.homeSampleCollection.tr,
                      controller.homeSampleCollection),
                  _buildSwitch(AppStrings.digitalReport.tr,
                      controller.digitalReport),
                  // SizedBox(height: SizeConfig.size16),
                  _buildOtherSection(),
                  SizedBox(height: SizeConfig.size20),
                  CustomBtn(
                    title: AppStrings.save,
                    isValidate: controller.isValid.value,
                    isLoading: controller.isLoading.value,
                    onTap: controller.isValid.value
                        ? () async {
                            final ok = await controller.saveFacilities();
                            if (ok) Get.back();
                          }
                        : null,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButton: Obx(() {
        return Visibility(
          visible: controller.otherEnabled.value,
          child: FloatingActionButton(
            onPressed: controller.addOther,
            child: const Icon(
              Icons.add,
              color: AppColors.white,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSwitch(String title, RxBool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(title,
            fontSize: SizeConfig.size14, fontWeight: FontWeight.w600),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value.value,
            onChanged: (val) {
              value.value = val;
              controller.validateForm();
            },
            activeColor: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOtherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(AppStrings.otherFacilities.tr,
                fontSize: SizeConfig.size14, fontWeight: FontWeight.w600),
            Row(
              children: [
                CustomText(AppStrings.enable.tr,
                    fontSize: SizeConfig.small, color: AppColors.black28),
                SizedBox(width: SizeConfig.size8),
                Obx(() => Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: controller.otherEnabled.value,
                        onChanged: (val) {
                          controller.otherEnabled.value = val;
                          if (!val) {
                            controller.others.clear();
                            controller.otherLabelCtrls.clear();
                            controller.otherDetailsCtrls.clear();
                          }
                          controller.validateForm();
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                    )),
              ],
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() {
          if (!controller.otherEnabled.value) {
            return CustomText(AppStrings.turnOnCustomFacilities.tr,
                color: AppColors.black28);
          }
          return Column(
            children: [
              Column(
                children: List.generate(controller.others.length, (index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: SizeConfig.size10),
                    padding: EdgeInsets.all(SizeConfig.size12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText("${AppStrings.facility.tr} ${index + 1}",
                                fontWeight: FontWeight.w600),
                            Row(
                              children: [
                                CustomText(AppStrings.active.tr,
                                    fontSize: SizeConfig.small,
                                    color: AppColors.black28),
                                SizedBox(width: SizeConfig.size6),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: controller.others[index].isActive,
                                    onChanged: (val) => controller
                                        .toggleOtherActive(index, val),
                                    activeColor: AppColors.primaryColor,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      controller.removeOther(index),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                )
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size10),
                        CommonTextField(
                          title: AppStrings.label.tr,
                          hintText: AppStrings.egPickupDrop.tr,
                          textEditController: controller.otherLabelCtrls[index],
                          onChange: (_) => controller.updateOtherText(index),
                        ),
                        SizedBox(height: SizeConfig.size10),
                        CommonTextField(
                          title: AppStrings.details.tr,
                          hintText: AppStrings.describeTheFacility.tr,
                          textEditController:
                              controller.otherDetailsCtrls[index],
                          maxLine: 3,
                          onChange: (_) => controller.updateOtherText(index),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              PositiveCustomBtn(onTap: controller.addOther, title: AppStrings.addMore)
            ],
          );
        }),
      ],
    );
  }
}
