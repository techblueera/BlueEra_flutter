import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/widget/add_service_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalServiceOffered extends StatefulWidget {

  const ProfessionalServiceOffered({
    super.key,
  });

  @override
  State<ProfessionalServiceOffered> createState() => _ProfessionalServiceOfferedState();
}

class _ProfessionalServiceOfferedState extends State<ProfessionalServiceOffered> {
  final controller = Get.find<AiProfessionalsController>();

  @override
  void initState() {
    super.initState();
    controller.loadAllServices();
  }

  void _toggleSelection(String option) {
    setState(() {
      if (controller.selectedServicesOffered.contains(option)) {
        controller.selectedServicesOffered.remove(option);
      } else {
        controller.selectedServicesOffered.add(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.proConsultServiceOffered.tr),
      body: Padding(
        padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size15,
            horizontal: SizeConfig.size8
        ),
        child: Obx(() {
          // Show Loader
          if (controller.isLoading.value) {
            return Center(
                child: CircularProgressIndicator()
            );
          }

          if(controller.servicesOffered.isEmpty){
            return EmptyStateWidget(
                message: AppStrings.proConsultServiceOfferedUnavailable.tr
            );
          }

          return SingleChildScrollView(
            child: CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
                children: [
                  ListView.builder(
                    // Add +1 for the "Add More" button
                    itemCount: controller.servicesOffered.length + 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {

                      // --- Case 1: "Add More Services" Button (Last Item) ---
                      if (index == controller.servicesOffered.length) {
                        return TextButton(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddServiceBottomSheet(
                              onUpload: (List<String> newServices) {
                                setState(() {
                                  controller.servicesOffered.addAll(newServices);
                                  controller.selectedServicesOffered.addAll(newServices);
                                });
                              },
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.add, color: AppColors.primaryColor, size: 20),
                              SizedBox(width: SizeConfig.size8),
                              CustomText(
                                  AppStrings.proConsultAddMoreServices.tr,
                                  fontSize: SizeConfig.large,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primaryColor
                              ),
                            ],
                          ),
                        );
                      }

                      // --- Case 2: Standard Option Item ---
                      final option = controller.servicesOffered[index];
                      final isSelected = controller.selectedServicesOffered.contains(option);

                      return Theme(
                        data: ThemeData(unselectedWidgetColor: Colors.grey.shade300),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
                          dense: true,
                          activeColor: AppColors.primaryColor,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: CustomText(
                              option,
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor
                          ),
                          value: isSelected,
                          onChanged: (val) => _toggleSelection(option),
                        ),
                      );
                    },
                  ),

                  // --- SAVE BUTTON ---
                  if(controller.servicesOffered.isNotEmpty ||
                      (controller.getProfessionalServiceRes?.value.data?.servicesOffered?.isNotEmpty??false))
                    Padding(
                      padding: EdgeInsets.only(
                        left: SizeConfig.size10,
                        top: SizeConfig.size10,
                        right: SizeConfig.size10,
                      ),
                      child: CustomBtn(
                        title: controller.isUpdateServiceOfferedLoading.value ? null : AppStrings.update.tr,
                        isLoading: controller.isUpdateServiceOfferedLoading.value,
                        onTap: () {
                          controller.updateServicesOffered();
                        },
                        bgColor: AppColors.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          );

        }),
      ),
    );
  }
}