import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/listing_form_screen/listing_form_screen_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
 

class Step4Section extends StatelessWidget {
  final ManualListingScreenController controller;
    Step4Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: SizeConfig.size16),
        CustomFormCard(
          padding: EdgeInsets.all(SizeConfig.size16),
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
              //
              // // Category + Subcategory pickers (single Obx)
              //
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
              SizedBox(height: SizeConfig.size16),
              // MRP
              CommonTextField(
                textEditController: controller.mrpController,
                title: 'MRP (Original Price)',
                hintText: 'E.g. ₹1499',
                keyBoardType: TextInputType.number,
                validator: controller.validateMRP,
                showLabel: true,
              ),
              SizedBox(height: SizeConfig.size16),
              // Selling Price
              CommonTextField(
                textEditController: controller.sellingPriceController,
                title: 'Selling Price',
                hintText: 'E.g. ₹500',
                keyBoardType: TextInputType.number,
                validator: controller.validateSellingPrice,
                showLabel: true,
              ),
              SizedBox(height: SizeConfig.size16),
              // // Available Stock
              // CommonTextField(
              //   textEditController: controller.availableStockController,
              //   title: 'Available Stock',
              //   hintText: 'E.g. Text',
              //   keyBoardType: TextInputType.number,
              //   validator: controller.validateAvailableStock,
              //   showLabel: true,
              // ),
              // SizedBox(height: SizeConfig.size16),
              // Expiry Date
              //
              // // Non-returnable Toggle
              // _buildNonReturnableSection(controller),
              // SizedBox(height: SizeConfig.size16),
              //
              // Warranty
              CommonTextField(
                title: "Product Warranty",
                hintText: "Eg. 1 Years",
                textEditController: controller.warrantyController,
              ),
              SizedBox(height: SizeConfig.size12),
              //
              // Validity duration (unit + value)
              //
              CustomText('Add Expiry Duration (Optional)'),
               SizedBox(height: SizeConfig.size12),
              Obx(() => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildDropdownField(
                          // label: '',
                          hint: 'Select unit',
                          items: controller.validityUnits,
                          validator: (_) => null,
                          onChanged: controller.onValidityUnitChanged,
                          value: controller.validityUnit.value,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size12),

                      //Todo: i want you to map our newly created dropdowns with the value selected in _buildDropdownField
                      // suppose if in _buildDropdownField i choose year then in this field i want to show year Dropdown 
                      Expanded(
                        flex: 1,
                        child: Obx(
                          () {
                            return  _buildValidityValueField(controller.validityUnit.value ?? '');
                          }
                        ),
                      ),
                    ],
                  )),
              SizedBox(height: SizeConfig.size16),
              //  Row(
              //    mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //    children: [
              //      CustomText(
              //        'Add More Details',
              //        fontSize: SizeConfig.medium,
              //       //  fontWeight: FontWeight.bold,
              //        color: AppColors.black,
              //      ),
              //      GestureDetector(
              //        onTap: controller.openMoreDetailsForStep3,
              //        child: Container(
              //          width: 32,
              //          height: 30,
              //          decoration: BoxDecoration(
              //            color: AppColors.primaryColor,
              //            borderRadius: BorderRadius.circular(6),
              //          ),
              //          child: const Icon(
              //            Icons.add,
              //            color: AppColors.white,
              //            size: 20,
              //          ),
              //        ),
              //      ),
              //    ],
              //  ),
              // SizedBox(height: SizeConfig.size8),
              // // Render added details list (shared across steps)
              // Obx(() {
              //   if (controller.moreDetailsStep3.isEmpty) return const SizedBox.shrink();
              //   return Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       // CustomText(
              //       //   'More Details',
              //       //   fontSize: SizeConfig.medium,
              //       //   // fontWeight: FontWeight.w600,
              //       //   color: AppColors.black,
              //       // ),
              //       SizedBox(height: SizeConfig.size4),
              //       ListView.separated(
              //         shrinkWrap: true,
              //         physics: const NeverScrollableScrollPhysics(),
              //         itemCount: controller.moreDetailsStep3.length,
              //         separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size8),
              //         itemBuilder: (context, index) {
              //           final item = controller.moreDetailsStep3[index];
              //           return Container(
              //             decoration: BoxDecoration(
              //               border: Border.all(color: AppColors.secondaryTextColor.withOpacity(0.2)),
              //               borderRadius: BorderRadius.circular(8),
              //             ),
              //             padding: EdgeInsets.all(SizeConfig.size12),
              //             child: Row(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 Expanded(
              //                   child: Column(
              //                     crossAxisAlignment: CrossAxisAlignment.start,
              //                     children: [
              //                       CustomText(
              //                         item['title'] ?? '',
              //                         fontSize: SizeConfig.medium,
              //                         fontWeight: FontWeight.w600,
              //                         color: AppColors.black,
              //                       ),
              //                       SizedBox(height: SizeConfig.size4),
              //                       CustomText(
              //                         item['details'] ?? '',
              //                         color: AppColors.secondaryTextColor,
              //                       ),
              //                     ],
              //                   ),
              //                 ),
              //                 IconButton(
              //                   tooltip: 'Remove',
              //                   icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              //                   onPressed: () => controller.removeMoreDetailAtStep3(index),
              //                 ),
              //               ],
              //             ),
              //           );
              //         },
              //       ),
              //     ],
              //   );
              // }),
              //      SizedBox(height: SizeConfig.size12),
              // // Guidelines
              CommonTextField(
                title: "User Guideline",
                hintText: "Lorem ipsum dolor sit amit, adisping...",
                textEditController: controller.guidelineController,
                maxLine: 3,
              ),
              //
              // SizedBox(height: SizeConfig.size16),
              SizedBox(height: SizeConfig.size20),
              Row(
                children: [
                  // Save as Draft Button
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.primaryColor, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: controller.saveAsDraft,
                          borderRadius: BorderRadius.circular(8),
                          child: const Center(
                            child: CustomText(
                              'Save as draft',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  // Post Product Button
                  Expanded(
                      child: CustomBtn(
                    title: controller.currentStep.value ==
                            ManualListingScreenController.totalSteps
                        ? 'Submit'
                        : 'Next',
                    onTap: controller.onNext,
                    bgColor: AppColors.primaryColor,
                    textColor: AppColors.white,
                    height: 45,
                  )),
                ],
              )
            ],
          ),
        ),
      ],
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
          Obx(() => RestrictedDatePicker(
                selectedDay: controller.selectedDay.value == 0 ? null : controller.selectedDay.value,
                selectedMonth: controller.selectedMonth.value == 0 ? null : controller.selectedMonth.value,
                selectedYear: controller.selectedYear.value == 0 ? null : controller.selectedYear.value,
                onDayChanged: controller.onDayChanged,
                onMonthChanged: controller.onMonthChanged,
                onYearChanged: controller.onYearChanged,
                isFutureYear: true,
              )),
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

  Widget _buildDropdownField({
    // required String label,
    required String hint,
    required List<String> items,
    required String? Function(String?) validator,
    required ValueChanged<String?> onChanged,
    String? value,
  }) {
    final String? effectiveValue = (value != null && items.contains(value)) ? value : null;

    return Container(
      width: SizeConfig.screenWidth,
      decoration: BoxDecoration(
        color: AppColors.white, // White background like CommonTextField
        borderRadius: BorderRadius.circular(12), // Rounded corners like CommonTextField
        boxShadow: [AppShadows.textFieldShadow], // Same shadow as CommonTextField
      ),
      clipBehavior: Clip.antiAlias,
      child: DropdownButtonFormField<String>(
        value: effectiveValue,
        validator: validator,
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingM, // Same padding as CommonTextField
            vertical: SizeConfig.paddingXSL,
          ),
          isDense: true,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.grey9B,
          size: 20,
        ),
        dropdownColor: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        style: TextStyle(
          color: AppColors.black,
          fontSize: SizeConfig.large, // Same font size as CommonTextField
        ),
        menuMaxHeight: 200,
        hint: CustomText(
          hint,
          color: AppColors.secondaryTextColor,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                fontSize: SizeConfig.large, // Match CommonTextField font size
                color: AppColors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper method to get appropriate items list based on validity unit
  List<String> _getValidityValueItems(String validityUnit) {
    switch (validityUnit.toLowerCase()) {
      case 'day':
        return List.generate(31, (index) => ("${index + 1} Day").toString());
      case 'week':
        return ['1 Week', '2 Weeks', '3 Weeks', '4 Weeks'];
      case 'month':
        return List.generate(12, (index) => ("${index + 1} Month").toString());
      case 'year':
        return List.generate(20, (index) => ("${index + 1} Year").toString());
      default:
        return [];
    }
  }

  // Helper method to get appropriate hint text based on validity unit
  String _getValidityValueHint(String validityUnit) {
    switch (validityUnit.toLowerCase()) {
      case 'day':
        return 'Select days';
      case 'week':
        return 'Select weeks';
      case 'month':
        return 'Select months';
      case 'year':
        return 'Select years';
      default:
        return 'Select value';
    }
  }

  // Helper method to get appropriate dropdown based on validity unit
  Widget _buildValidityValueField(String validityUnit) {
    final items = _getValidityValueItems(validityUnit);
    final hint = _getValidityValueHint(validityUnit);
    
    // If no items available, show text field
    if (items.isEmpty) {
      return CommonTextField(
        textEditController: controller.validityValueController,
        hintText: 'e.g. 6',
        keyBoardType: TextInputType.number,
        validator: controller.validateValidityValue,
        showLabel: false,
      );
    }

    // Check if current value is valid for this dropdown type
    final currentValue = controller.validityValueController.text;
    final validValue = items.contains(currentValue) ? currentValue : null;

    return Container(
      width: SizeConfig.screenWidth,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: DropdownButtonFormField<String>(
        value: validValue,
        validator: controller.validateValidityValue,
        onChanged: (value) => controller.validityValueController.text = value ?? '',
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingM,
            vertical: SizeConfig.paddingXSL,
          ),
          isDense: true,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.grey9B,
          size: 20,
        ),
        dropdownColor: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        style: TextStyle(
          color: AppColors.black,
          fontSize: SizeConfig.large,
        ),
        menuMaxHeight: 200,
        hint: CustomText(
          hint,
          color: AppColors.secondaryTextColor,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                fontSize: SizeConfig.large,
                color: AppColors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
