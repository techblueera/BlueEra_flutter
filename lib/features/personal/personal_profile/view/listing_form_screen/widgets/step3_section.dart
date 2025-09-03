import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../listing_form_screen_controller.dart';

class Step3Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step3Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Add Product Features',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size16),
        // Features list
        Obx(() => Column(
              children: List.generate(controller.featureControllers.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.size16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CommonTextField(
                          title: 'Feature ${i + 1}',
                          hintText: 'E.g. Vorem ipsum dolor sit amet,',
                          textEditController: controller.featureControllers[i],
                          maxLine: 2,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      if (controller.featureControllers.length > 1)
                        InkWell(
                          onTap: () => controller.removeFeature(i),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.only(top: SizeConfig.size20),
                            child: Icon(
                              Icons.delete_outline,
                              color: AppColors.primaryColor,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            )),
        SizedBox(height: SizeConfig.size16),
        GestureDetector(
          onTap: controller.addFeature,
          child: Row(
            children: [
              Image.asset("assets/icons/add_icon.png",
                  color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              CustomText("Add More Option", color: AppColors.primaryColor),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        // Add Link
        GestureDetector(
          onTap: controller.showLinkField.toggle,
          child: Row(
            children: [
              Image.asset("assets/icons/add_icon.png",
                  color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              CustomText("Add Link (Reference / Website)",
                  color: AppColors.primaryColor),
            ],
          ),
        ),
        Obx(() => controller.showLinkField.value
            ? Padding(
                padding: EdgeInsets.only(top: SizeConfig.size12),
                child: CommonTextField(
                  title: "Link (Reference / Website)",
                  hintText: "https://example.com",
                  textEditController: controller.linkController,
                ),
              )
            : const SizedBox.shrink()),
        SizedBox(height: SizeConfig.size20),
        // Options (attribute/value)
        CustomText(
          'Options',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size12),
        Obx(() => Column(
              children: List.generate(controller.optionAttributeControllers.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.size12),
                  child: Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          title: 'Attribute',
                          hintText: 'e.g. Color',
                          textEditController: controller.optionAttributeControllers[i],
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      Expanded(
                        child: CommonTextField(
                          title: 'Value',
                          hintText: 'e.g. Black',
                          textEditController: controller.optionValueControllers[i],
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      if (controller.optionAttributeControllers.length > 1)
                        InkWell(
                          onTap: () => controller.removeOption(i),
                          child: const Icon(Icons.delete_outline, color: AppColors.primaryColor),
                        ),
                    ],
                  ),
                );
              }),
            )),
        SizedBox(height: SizeConfig.size8),
        GestureDetector(
          onTap: controller.addOption,
          child: Row(
            children: [
              Image.asset("assets/icons/add_icon.png",
                  color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              CustomText("Add Option", color: AppColors.primaryColor),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size24),
        // Add More Details launcher (kept as before)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              'Add More Details',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            GestureDetector(
              onTap: controller.toggleMoreDetails,
              child: Container(
                width: 32,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
