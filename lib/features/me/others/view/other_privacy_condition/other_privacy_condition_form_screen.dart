import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/others/controller/other_privacy_condition_controller.dart';
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
  final controller = Get.find<OtherPrivacyConditionController>();

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
            ? "Add Privacy Policy & Condition"
            : "Edit Privacy Policy & Condition",
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              CommonTextField(
                title: "Title",
                textEditController: controller.titleController,
                hintText: "Enter Title",
                onChange: (val) {
                  controller.title.value = val;
                },
              ),
              const SizedBox(height: 16),
              Obx(() {
                return AiDescriptionField(
                  label: "Privacy Policy & Condition",
                  hintText:
                      "Tell us more about the Privacy Policy & Condition...",
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
                    widget.item == null ? "Create" : "Update",
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
