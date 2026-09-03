import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_privacy_condition_controller.dart';
import 'package:BlueEra/features/me/others/model/otherTNC_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtherPrivacyConditionFormScreen extends StatefulWidget {
  final OtherTNCData? item;

  const OtherPrivacyConditionFormScreen({super.key, this.item});

  @override
  State<OtherPrivacyConditionFormScreen> createState() =>
      _OtherPrivacyConditionFormScreenState();
}

class _OtherPrivacyConditionFormScreenState
    extends State<OtherPrivacyConditionFormScreen> {
  final controller = Get.find<AutomotivePrivacyConditionController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.title.value = "";
    controller.description.value = "";
    if (widget.item != null) {
      controller.setFormData(widget.item ?? OtherTNCData());
    } else {
      controller.clearForm();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: widget.item == null
            ? AppStrings.otherAddPrivacyTnc.tr
            : AppStrings.otherEditPrivacyTnc.tr,
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              CommonTextField(
                title: AppStrings.title.tr,
                textEditController: controller.titleController,
                hintText: AppStrings.enterTitle.tr,
                onChange: (val) {
                  controller.title.value = val;
                },
              ),
              const SizedBox(height: 16),
              Obx(() {
                return AiDescriptionField(
                  label: AppStrings.otherTncLabel.tr,
                  hintText:
                      AppStrings.otherTellAboutPrivacyTnc.tr,
                  controller: controller.descriptionController,
                  rxValue: controller.description,
                  // Your RX variable from the controller
                  aiType: "Privacy Policy & Condition",
                  aiData: {
                    "title": controller.title.value,
                  },
                );
              }),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.item == null) {
                      controller.createOtherTNCController();
                    } else {
                      controller.updateOtherTNCController(
                        widget.item?.sId ?? "",
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: CustomText(
                    widget.item == null ? AppStrings.create.tr : AppStrings.update.tr,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16), // Padding for bottom safe area
            ],
          ),
        ),
      ),
    );
  }
}
