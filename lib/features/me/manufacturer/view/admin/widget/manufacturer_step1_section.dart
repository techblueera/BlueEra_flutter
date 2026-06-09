import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManufacturerStep1Section extends StatefulWidget {
  final ManufacturerProductController controller;

  const ManufacturerStep1Section({super.key, required this.controller});

  @override
  State<ManufacturerStep1Section> createState() =>
      _ManufacturerStep1SectionState();
}

class _ManufacturerStep1SectionState extends State<ManufacturerStep1Section> {
  late String originalProductName;
  late String originalBrand;
  late String originalDescription;
  late List<String> originalTags;

  @override
  void initState() {
    super.initState();
    originalProductName = widget.controller.productNameController.text;
    originalBrand = widget.controller.brandController.text;
    originalDescription = widget.controller.productDescriptionController.text;
    originalTags = List<String>.from(widget.controller.tags);
  }

  Future<bool> handleBackPress(BuildContext context) async {
    bool shouldPop = false;

    await showCommonDialog(
      context: context,
      text: AppStrings.doYouReallyWantToGoBack,
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
      confirmCallback: () {
        Get.close(2);
        shouldPop = true;
      },
      cancelCallback: () {
        // Restore old values when user cancels pop
        widget.controller.productNameController.text = originalProductName;
        widget.controller.brandController.text = originalBrand;
        widget.controller.productDescriptionController.text =
            originalDescription;
        widget.controller.tags.value = List<String>.from(originalTags);
        Navigator.of(context).pop();
        shouldPop = false;
      },
    );

    return shouldPop;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await handleBackPress(context);
        if (shouldPop) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.productDetails,
          onBackTap: () async {
            final shouldPop = await handleBackPress(context);
            if (shouldPop) {
              Navigator.of(context).maybePop();
            }
          },
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            margin: EdgeInsets.all(SizeConfig.size15),
            padding: EdgeInsets.all(SizeConfig.size15),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Form(
              key: widget.controller.formKeyStep1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Product Name
                      CommonTextField(
                          textEditController:
                              widget.controller.productNameController,
                          hintText: AppStrings.productDescription,
                          title: AppStrings.productName,
                          validator: ValidationMethod().validateProductName,
                          showLabel: true,
                          maxLength: 360,
                          isCounterVisible: true),
                      SizedBox(height: SizeConfig.size15),

                      /// Brand
                      CommonTextField(
                          textEditController: widget.controller.brandController,
                          hintText: AppStrings.egSamsung,
                          title: AppStrings.brandIfAny,
                          validator: ValidationMethod().validateBrandName,
                          showLabel: true,
                          maxLength: 30,
                          isCounterVisible: true),
                      SizedBox(height: SizeConfig.size15),

                      /// Tag Keywords
                      _buildTagsSection(widget.controller),
                      SizedBox(height: SizeConfig.size15),

                      /// Product Description
                      CommonTextField(
                          textEditController:
                              widget.controller.productDescriptionController,
                          hintText: AppStrings.hintProductDesc,
                          maxLine: 5,
                          title: AppStrings.productDescription,
                          validator:
                              ValidationMethod().validateProductDescription,
                          maxLength: 600,
                          isCounterVisible: true)
                    ],
                  ),
                  SizedBox(height: SizeConfig.size30),
                  CustomBtn(
                    title: AppStrings.save,
                    onTap: () => Get.back(),
                    bgColor: AppColors.primaryColor,
                    textColor: AppColors.white,
                    height: SizeConfig.size40,
                    radius: 10.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection(ManufacturerProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.addTagsKeywords,
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: Row(
            children: [
              Image.asset("assets/icons/tag_icon.png"),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: TextField(
                  controller: controller.tagsController,
                  onChanged: (_) => controller.update(["addIcon"]),
                  decoration: InputDecoration(
                    hintText: AppStrings.tagKeyword.tr,
                    hintStyle: TextStyle(
                      color: AppColors.grey9B,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              GetBuilder<ManufacturerProductController>(
                id: "addIcon",
                builder: (_) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: controller.tagsController.text.isNotEmpty
                        ? InkWell(
                            key: const ValueKey("add"),
                            onTap: () {
                              controller.addTag();
                              controller.update(["addIcon"]);
                              unFocus();
                            },
                            child: LocalAssets(
                              imagePath: AppIconAssets.addBlueIcon,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey("empty")),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppColors.lightBlue,
                  labelStyle: TextStyle(
                      fontSize: SizeConfig.size14, color: Colors.black87),
                  deleteIcon: const Icon(Icons.close,
                      size: 20, color: AppColors.mainTextColor),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(8.0)),
                  onDeleted: () => controller.removeTag(tag),
                  labelPadding: const EdgeInsets.only(left: 12),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ))
      ],
    );
  }
}
