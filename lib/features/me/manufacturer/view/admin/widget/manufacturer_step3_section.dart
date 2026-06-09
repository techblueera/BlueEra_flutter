import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/manufacturer/controller/manufacturer_product_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManufacturerStep3Section extends StatefulWidget {
  final ManufacturerProductController controller;
  const ManufacturerStep3Section({super.key, required this.controller});

  @override
  State<ManufacturerStep3Section> createState() =>
      _ManufacturerStep3SectionState();
}

class _ManufacturerStep3SectionState extends State<ManufacturerStep3Section> {
  late List<TextEditingController> tempUserGuideLineControllers;
  late TextEditingController tempProductWarrantyController;
  late TextEditingController tempProductExpiryDurationController;

  @override
  void initState() {
    super.initState();

    // 🔹 Copy old values into local variables
    tempUserGuideLineControllers = widget.controller.userGuideLineControllers
        .map((c) => TextEditingController(text: c.text))
        .toList();

    tempProductWarrantyController = TextEditingController(
        text: widget.controller.productWarrantyController.text);
    tempProductExpiryDurationController = TextEditingController(
        text: widget.controller.productExpiryDurationController.text);
  }

  // 🔹 Restore old values if user cancels
  void _restoreOldValues() {
    widget.controller.featureControllers.clear();
    for (final c in tempUserGuideLineControllers) {
      widget.controller.userGuideLineControllers
          .add(TextEditingController(text: c.text));
    }

    widget.controller.productWarrantyController.text =
        tempProductWarrantyController.text;
    widget.controller.productExpiryDurationController.text =
        tempProductExpiryDurationController.text;
  }

  Future<bool> _handleBackPress(BuildContext context) async {
    bool shouldPop = false;

    await showCommonDialog(
      context: context,
      text: AppStrings.changesWillBeLost,
      confirmText: AppStrings.confirm,
      cancelText: AppStrings.cancel,
      confirmCallback: () {
        _restoreOldValues();
        Get.close(2);
        shouldPop = true;
      },
      cancelCallback: () {
        Navigator.of(context).pop(false);
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
        final shouldPop = await _handleBackPress(context);
        if (shouldPop) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.pricingWarranty,
          onBackTap: () async {
            final shouldPop = await _handleBackPress(context);
            if (shouldPop) {
              Navigator.of(context).maybePop();
            }
          },
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size15),
          child: CustomFormCard(
            child: Form(
              key: widget.controller.formKeyStep3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Warranty
                  CommonTextField(
                    textEditController:
                        widget.controller.productWarrantyController,
                    title: AppStrings.productWarranty,
                    hintText: AppStrings.eg1Year,
                    keyBoardType: TextInputType.number,
                    validator: ValidationMethod().validateProductWarranty,
                    showLabel: true,
                  ),
                  SizedBox(height: SizeConfig.size16),

                  /// Expiry Date
                  CommonTextField(
                    textEditController:
                        widget.controller.productExpiryDurationController,
                    title: AppStrings.addExpiryDateOptional,
                    hintText: AppStrings.eg1Year,
                    keyBoardType: TextInputType.text,
                    validator: ValidationMethod().validateProductExpiration,
                    showLabel: true,
                  ),
                  SizedBox(height: SizeConfig.size16),

                  /// Guidelines
                  _buildUserGuideLines(),
                  SizedBox(height: SizeConfig.size30),

                  // Bottom Buttons
                  PositiveCustomBtn(
                    onTap: () => Get.back(),
                    title: AppStrings.save,
                    bgColor: AppColors.primaryColor,
                    borderColor: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserGuideLines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.addProductGuideLine,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size16),
        Obx(() => Column(
              children: List.generate(
                  widget.controller.featureControllers.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: SizeConfig.size16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CommonTextField(
                          title: '${AppStrings.userGuide} ${i + 1}',
                          hintText: AppStrings.hintUserGuide,
                          textEditController:
                              widget.controller.featureControllers[i],
                          maxLine: 2,
                          validator: (value) =>
                              ValidationMethod().validateUserGuideLine(value, i),
                          maxLength: 140,
                          isCounterVisible: true,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size8),
                      if (widget.controller.featureControllers.length > 1)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.controller.removeFeature(i),
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
                        ),
                    ],
                  ),
                );
              }),
            )),
        SizedBox(height: SizeConfig.size16),
        GestureDetector(
          onTap: widget.controller.addFeature,
          child: Row(
            children: [
              LocalAssets(imagePath: AppIconAssets.addBlueIcon),
              SizedBox(width: SizeConfig.size10),
              CustomText(AppStrings.addMoreUserGuideLine,
                  color: AppColors.primaryColor),
            ],
          ),
        ),
      ],
    );
  }
}
