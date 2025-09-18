import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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

class Step3Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step3Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      margin: EdgeInsets.all(SizeConfig.size15),
      child: Form(
        key: controller.formKeyStep3,
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
              textEditController: controller.mrpController,
              title: 'MRP (Original Price with GST)',
              hintText: 'E.g. ₹1499',
              keyBoardType: TextInputType.number,
              validator: controller.validateMRP,
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
            _buildProductWarrantySection(),

            SizedBox(height: SizeConfig.size16),


            /// Expiry Date
            _buildExpiryDateSection(controller),

            // Non-returnable Toggle
            // _buildNonReturnableSection(controller),

            SizedBox(height: SizeConfig.size16),

              /// Guidelines
            CommonTextField(
                title: "User Guideline",
                hintText: "Lorem ipsum dolor sit amit, adisping...",
                textEditController: controller.guidelineController,
                maxLine: 5,
                validator: controller.validateUserGuidance,
                maxLength: 600,
                isCounterVisible: true
              ),

            SizedBox(height: SizeConfig.size30),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: controller.saveAsDraft,
                    title: 'Save as draft',
                    bgColor: AppColors.white,
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: controller.onNext,
                    title: 'Next',
                    bgColor: AppColors.primaryColor,
                    borderColor: AppColors.primaryColor,
                  ),
                ),
              ],
            )

          ],
        ),
      ),
    );

  }

  _buildProductWarrantySection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "Product Warranty",
            fontSize: SizeConfig.medium,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size8),

          // Dropdowns Row
          Row(
            children: [
              // Duration Type Dropdown
              Expanded(
                flex: 1,
                child: Obx(() => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyE5),
                      boxShadow: [AppShadows.textFieldShadow]
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      value: controller.selectedProductDuration.value,
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      items: controller.durationTypes.map((String duration) {
                        return DropdownMenuItem<String>(
                          value: duration,
                          child: Text(duration),
                        );
                      }).take(4).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.onProductDurationChanged(newValue);
                        }
                      },
                    ),
                  ),
                )),
              ),

              SizedBox(width: 12),

              // Value Dropdown
              Expanded(
                flex: 1,
                child: Obx(() => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyE5),
                      boxShadow: [AppShadows.textFieldShadow]
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<num>(
                      isDense: true,
                      value: controller.selectedProductValue.value,
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      items: controller.productValueRange.map((num value) {
                        return DropdownMenuItem<num>(
                          value: value,
                          child: Text(
                            value % 1 == 0 ? value.toInt().toString() : value.toString(),
                          ),
                        );
                      }).toList(),
                      onChanged: (num? newValue) {
                        if (newValue != null) {
                          controller.onProductValueChanged(newValue);
                        }
                      },
                    ),
                  ),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

   Widget _buildExpiryDateSection(ManualListingScreenController controller) {
     return Container(
      constraints: const BoxConstraints(minHeight: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            'Add Expiry Date (Optional)',
            fontSize: SizeConfig.medium,
            color: AppColors.black,
          ),
          SizedBox(height: SizeConfig.size8),

          // Dropdowns Row
          Row(
            children: [
              // Duration Type Dropdown
              Expanded(
                flex: 1,
                child: Obx(() => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.greyE5),
                    boxShadow: [AppShadows.textFieldShadow]
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      value: controller.selectedDuration.value,
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      items: controller.durationTypes.map((String duration) {
                        return DropdownMenuItem<String>(
                          value: duration,
                          child: Text(duration),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.onDurationChanged(newValue);
                        }
                      },
                    ),
                  ),
                )),
              ),

              SizedBox(width: 12),

              // Value Dropdown
              Expanded(
                flex: 1,
                child: Obx(() => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyE5),
                      boxShadow: [AppShadows.textFieldShadow]
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<num>(
                      isDense: true,
                      value: controller.selectedValue.value,
                      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      items: controller.valueRange.map((num value) {
                        return DropdownMenuItem<num>(
                          value: value,
                          child: Text(
                            value % 1 == 0 ? value.toInt().toString() : value.toString()
                          ),
                        );
                      }).toList(),
                      onChanged: controller.selectedDuration.value == 'Life Time'
                          ? null // Disable dropdown for Life Time
                          : (num? newValue) {
                        if (newValue != null) {
                          controller.onValueChanged(newValue);
                        }
                      },
                    ),
                  ),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNonReturnableSection(ManualListingScreenController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          'This is a non-returnable product',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
        Obx(() => CustomSwitch(
              containerHeight: 25,
              containerWidth: 50,
              value: controller.isNonReturnable.value,
              onChanged: (value) => controller.toggleNonReturnable(),
            )),
      ],
    );
  }




}
