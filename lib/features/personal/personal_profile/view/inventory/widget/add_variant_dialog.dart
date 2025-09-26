import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class AddVariantDialog extends StatefulWidget {
  final AddProductViaAiController controller;

  const AddVariantDialog({
    super.key,
    required this.controller,
  });

  @override
  State<AddVariantDialog> createState() => _AddVariantDialogState();
}

class _AddVariantDialogState extends State<AddVariantDialog> {
  final titleController = TextEditingController();
  final detailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      'Add Variant',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size15),

                // Title Field (this will become the attributeKey)
                CommonTextField(
                  title: 'Variant Name',
                  hintText: 'e.g. size, storage, material',
                  textEditController: titleController,
                  isValidate: true,
                ),

                SizedBox(height: SizeConfig.size20),

                // Detail Input
                CommonTextField(
                  title: 'Details',
                  hintText: 'e.g. 10KG, 8GB, cotton',
                  textEditController: detailController,
                  isValidate: true,
                ),

                const SizedBox(height: 16),

                // Save Button
                CustomBtn(
                  title: 'Add Variant',
                  onTap: () {
                    if(formKey.currentState!.validate()){
                      final title = titleController.text.trim();
                      final details = detailController.text.trim();

                      // Use the title as the new attribute key
                      if (widget.controller.dynamicAttributes.containsKey(title)) {
                        final list = widget.controller.dynamicAttributes[title]!;
                        if (!list.contains(details)) list.add(details);
                      } else {
                        widget.controller.dynamicAttributes[title] = [details].obs;
                      }

                      widget.controller.dynamicAttributes.refresh();
                      widget.controller.selectVariantValue(title, details);
                      Get.back();
                    }
                  },
                  bgColor: AppColors.primaryColor,
                  textColor: AppColors.white,
                  height: 45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

