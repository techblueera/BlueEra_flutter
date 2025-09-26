import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_product_via_ai_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../listing_form_screen_controller.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Step3Section extends StatefulWidget {
  final AddProductViaAiController controller;
  const Step3Section({super.key, required this.controller});

  @override
  State<Step3Section> createState() => _Step3SectionState();
}

class _Step3SectionState extends State<Step3Section> {
  late List<TextEditingController> tempUserGuideLineControllers;
  late TextEditingController tempMrpController;
  late TextEditingController tempProductWarrantyController;
  late TextEditingController tempProductExpiryDurationController;

  @override
  void initState() {
    super.initState();

    // 🔹 Copy old values into local variables
    tempUserGuideLineControllers = widget.controller.userGuideLineControllers
        .map((c) => TextEditingController(text: c.text))
        .toList();

    tempMrpController = TextEditingController(text: widget.controller.mrpController.text);
    tempProductWarrantyController = TextEditingController(text: widget.controller.productWarrantyController.text);
    tempProductExpiryDurationController = TextEditingController(text: widget.controller.productExpiryDurationController.text);

  }

  // 🔹 Restore old values if user cancels
  void _restoreOldValues() {
    widget.controller.featureControllers.clear();
    for (final c in tempUserGuideLineControllers) {
      widget.controller.userGuideLineControllers.add(TextEditingController(text: c.text));
    }

    widget.controller.mrpController.text = tempMrpController.text;
    widget.controller.productWarrantyController.text = tempProductWarrantyController.text;
    widget.controller.productExpiryDurationController.text = tempProductExpiryDurationController.text;

  }

  Future<bool> _handleBackPress(BuildContext context) async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your changes will be lost if you go back.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _restoreOldValues();
              Get.close(2);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (shouldPop ?? false) {
      _restoreOldValues();
      return true;
    }
    return false;
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
        backgroundColor: AppColors.whiteF3,
        appBar: CommonBackAppBar(
          title: 'Pricing & Warranty',
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
                  // Product Name
                  // CommonTextField(
                  //   textEditController: controller.productNameController,
                  //   hintText: 'E.g. Wireless Earbuds Boat Airdopes 161',
                  //   title: "Product Name",
                  //   validator: controller.validateProductName,
                  //   showLabel: true,
                  // ),
                  // SizedBox(height: SizeConfig.size16),
                  // CommonTextField(
                  //   textEditController: controller.productNameController,
                  //   hintText: 'E.g. TSH-RED-s-0001',
                  //   title: "Product SKU Number (Optional)",
                  //   validator: controller.validateProductName,
                  //   showLabel: true,
                  // ),
                  // SizedBox(height: SizeConfig.size16),
                  // CommonTextField(
                  //   textEditController: controller.productNameController,
                  //   hintText: 'E.g. 1554367',
                  //   title: "Product Id Number",
                  //   validator: controller.validateProductName,
                  //   showLabel: true,
                  // ),

                  // SizedBox(height: SizeConfig.size16),
                  // CustomText("Category folder"),
                  // SizedBox(height: SizeConfig.size16),
                  // Container(
                  //   width: double.infinity,
                  //   height: 44,
                  //   decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(10),
                  //       border: Border.all(
                  //           color: AppColors.secondaryTextColor.withOpacity(0.2))),
                  //   padding: EdgeInsets.all(8),
                  //   child: CustomText(
                  //     "Choose Category Folder",
                  //     color: AppColors.secondaryTextColor,
                  //   ),
                  // ),
                  // SizedBox(height: SizeConfig.size16),
                  // // Brand
                  // CommonTextField(
                  //   textEditController: controller.brandController,
                  //   title: 'Brand',
                  //   hintText: 'E.g. Boat',
                  //   validator: controller.validateBrand,
                  //   showLabel: true,
                  // ),
                  // SizedBox(height: SizeConfig.size16),

                  /// MRP
                  CommonTextField(
                    textEditController: widget.controller.mrpController,
                    title: 'MRP (Original Price with GST)',
                    hintText: 'E.g. ₹1499',
                    keyBoardType: TextInputType.number,
                    validator: widget.controller.validateMRP,
                    showLabel: true,
                  ),
                  SizedBox(height: SizeConfig.size16),

                  // /// Selling Price
                  // CommonTextField(
                  //   textEditController: controller.sellingPriceController,
                  //   title: 'Selling Price (RS.)',
                  //   hintText: 'E.g. ₹500',
                  //   keyBoardType: TextInputType.number,
                  //   validator: controller.validateSellingPrice,
                  //   showLabel: true,
                  // ),
                  // SizedBox(height: SizeConfig.size16),

                  // /// Available Stock
                  // CommonTextField(
                  //   textEditController: controller.availableStockController,
                  //   title: 'Available Stock',
                  //   hintText: 'E.g. Text',
                  //   keyBoardType: TextInputType.number,
                  //   validator: controller.validateAvailableStock,
                  //   showLabel: true,
                  // ),
                  // SizedBox(height: SizeConfig.size16),


                  /// Warranty
                  // CommonTextField(
                  //   title: "Product Warranty",
                  //   hintText: "Eg. 1 Years",
                  //   textEditController: controller.warrantyController,
                  // ),

                  CommonTextField(
                    textEditController: widget.controller.productWarrantyController,
                    title: 'Product Warranty',
                    hintText: 'E.g. 1 year',
                    keyBoardType: TextInputType.number,
                    validator: widget.controller.validateProductWarranty,
                    showLabel: true,
                  ),

                  // _buildProductWarrantySection(),

                  SizedBox(height: SizeConfig.size16),


                  /// Expiry Date
                  CommonTextField(
                    textEditController: widget.controller.productExpiryDurationController,
                    title: 'Add Expiry Date (Optional)',
                    hintText: 'E.g. 1 year',
                    keyBoardType: TextInputType.number,
                    validator: widget.controller.validateProductExpiration,
                    showLabel: true,
                  ),

                  // _buildExpiryDateSection(widget.controller),

                  // Non-returnable Toggle
                  // _buildNonReturnableSection(controller),

                  SizedBox(height: SizeConfig.size16),

                  /// Guidelines
                  _buildUserGuideLines(),
                  // CommonTextField(
                  //     title: "User Guideline",
                  //     hintText: "Lorem ipsum dolor sit amit, adisping...",
                  //     textEditController: controller.guidelineController,
                  //     maxLine: 5,
                  //     validator: controller.validateUserGuidance,
                  //     maxLength: 600,
                  //     isCounterVisible: true
                  //   ),

                  SizedBox(height: SizeConfig.size30),

                  // Bottom Buttons
                  PositiveCustomBtn(
                    onTap: ()=> Get.back(),
                    // onTap: widget.controller.onNext,
                    title: 'Save',
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

  _buildProductWarrantySection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CustomText(
          //   "Product Warranty",
          //   fontSize: SizeConfig.medium,
          //   color: AppColors.black,
          // ),
          // SizedBox(height: SizeConfig.size8),

          CommonTextField(
            textEditController: widget.controller.productWarrantyController,
            title: 'Product Warranty',
            hintText: 'E.g. 1 year',
            keyBoardType: TextInputType.number,
            validator: widget.controller.validateProductWarranty,
            showLabel: true,
          ),

          // // Dropdowns Row
          // Row(
          //   children: [
          //     // Duration Type Dropdown
          //     Expanded(
          //       flex: 1,
          //       child: Obx(() => Container(
          //         padding: EdgeInsets.symmetric(
          //           horizontal: SizeConfig.size16,
          //           vertical: SizeConfig.size10,
          //         ),
          //         decoration: BoxDecoration(
          //             color: Colors.white,
          //             borderRadius: BorderRadius.circular(8),
          //             border: Border.all(color: AppColors.greyE5),
          //             boxShadow: [AppShadows.textFieldShadow]
          //         ),
          //         child: DropdownButtonHideUnderline(
          //           child: DropdownButton<String>(
          //             isDense: true,
          //             value: controller.selectedProductDuration.value,
          //             padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          //             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          //             style: TextStyle(
          //               color: Colors.black87,
          //               fontSize: 16,
          //             ),
          //             items: controller.durationTypes.map((String duration) {
          //               return DropdownMenuItem<String>(
          //                 value: duration,
          //                 child: Text(duration),
          //               );
          //             }).take(4).toList(),
          //             onChanged: (String? newValue) {
          //               if (newValue != null) {
          //                 controller.onProductDurationChanged(newValue);
          //               }
          //             },
          //           ),
          //         ),
          //       )),
          //     ),
          //
          //     SizedBox(width: 12),
          //
          //     // Value Dropdown
          //     Expanded(
          //       flex: 1,
          //       child: Obx(() => Container(
          //         padding: EdgeInsets.symmetric(
          //           horizontal: SizeConfig.size16,
          //           vertical: SizeConfig.size10,
          //         ),
          //         decoration: BoxDecoration(
          //             color: Colors.white,
          //             borderRadius: BorderRadius.circular(8),
          //             border: Border.all(color: AppColors.greyE5),
          //             boxShadow: [AppShadows.textFieldShadow]
          //         ),
          //         child: DropdownButtonHideUnderline(
          //           child: DropdownButton<num>(
          //             isDense: true,
          //             value: controller.selectedProductValue.value,
          //             padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          //             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          //             style: TextStyle(
          //               color: Colors.black87,
          //               fontSize: 16,
          //             ),
          //             items: controller.productValueRange.map((num value) {
          //               return DropdownMenuItem<num>(
          //                 value: value,
          //                 child: Text(
          //                   value % 1 == 0 ? value.toInt().toString() : value.toString(),
          //                 ),
          //               );
          //             }).toList(),
          //             onChanged: (num? newValue) {
          //               if (newValue != null) {
          //                 controller.onProductValueChanged(newValue);
          //               }
          //             },
          //           ),
          //         ),
          //       )),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

   Widget _buildExpiryDateSection(AddProductViaAiController controller) {
     return Container(
      constraints: const BoxConstraints(minHeight: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonTextField(
            textEditController: controller.productExpiryDurationController,
            title: 'Add Expiry Date (Optional)',
            hintText: 'E.g. 1 year',
            keyBoardType: TextInputType.number,
            validator: controller.validateProductExpiration,
            showLabel: true,
          ),

          // CustomText(
          //   'Add Expiry Date (Optional)',
          //   fontSize: SizeConfig.medium,
          //   color: AppColors.black,
          // ),
          // SizedBox(height: SizeConfig.size8),
          //
          // // Dropdowns Row
          // Row(
          //   children: [
          //     // Duration Type Dropdown
          //     Expanded(
          //       flex: 1,
          //       child: Obx(() => Container(
          //         padding: EdgeInsets.symmetric(
          //           horizontal: SizeConfig.size16,
          //           vertical: SizeConfig.size10,
          //         ),
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(8),
          //           border: Border.all(color: AppColors.greyE5),
          //           boxShadow: [AppShadows.textFieldShadow]
          //         ),
          //         child: DropdownButtonHideUnderline(
          //           child: DropdownButton<String>(
          //             isDense: true,
          //             value: controller.selectedExpiryDuration.value,
          //             padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          //             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          //             style: TextStyle(
          //               color: Colors.black87,
          //               fontSize: 16,
          //             ),
          //             items: controller.durationTypes.map((String duration) {
          //               return DropdownMenuItem<String>(
          //                 value: duration,
          //                 child: Text(duration),
          //               );
          //             }).toList(),
          //             onChanged: (String? newValue) {
          //               if (newValue != null) {
          //                 controller.onDurationChanged(newValue);
          //               }
          //             },
          //           ),
          //         ),
          //       )),
          //     ),
          //
          //     SizedBox(width: 12),
          //
          //     // Value Dropdown
          //     Expanded(
          //       flex: 1,
          //       child: Obx(() => Container(
          //         padding: EdgeInsets.symmetric(
          //           horizontal: SizeConfig.size16,
          //           vertical: SizeConfig.size10,
          //         ),
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(8),
          //             border: Border.all(color: AppColors.greyE5),
          //             boxShadow: [AppShadows.textFieldShadow]
          //         ),
          //         child: DropdownButtonHideUnderline(
          //           child: DropdownButton<num>(
          //             isDense: true,
          //             value: controller.selectedExpiryValue.value,
          //             padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          //             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          //             style: TextStyle(
          //               color: Colors.black87,
          //               fontSize: 16,
          //             ),
          //             items: controller.expiryValueRange.map((num value) {
          //               return DropdownMenuItem<num>(
          //                 value: value,
          //                 child: Text(
          //                   value % 1 == 0 ? value.toInt().toString() : value.toString()
          //                 ),
          //               );
          //             }).toList(),
          //             onChanged: controller.selectedExpiryDuration.value == 'Life Time'
          //                 ? null // Disable dropdown for Life Time
          //                 : (num? newValue) {
          //               if (newValue != null) {
          //                 controller.onValueChanged(newValue);
          //               }
          //             },
          //           ),
          //         ),
          //       )),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildUserGuideLines(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Add Product GuideLine',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size16),
        Obx(() => Column(
          children:
          List.generate(widget.controller.featureControllers.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CommonTextField(
                      title: 'User Guide ${i + 1}',
                      hintText: 'E.g. Vorem ipsum dolor sit amet,',
                      textEditController: widget.controller.featureControllers[i],
                      maxLine: 2,
                      validator: (value)=> widget.controller.validateUserGuideLine(value, i),
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
              CustomText("Add More User GuideLine", color: AppColors.primaryColor),
            ],
          ),
        ),

      ],
    );
  }

}
