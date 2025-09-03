import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../listing_form_screen_controller.dart';

class Step1Section extends StatelessWidget {
  final ManualListingScreenController controller;
  const Step1Section({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        CommonTextField(
          textEditController: controller.productNameController,
          hintText: 'E.g. Wireless Earbuds Boat Airdopes 161',
          title: "Product Name",
          validator: controller.validateProductName,
          showLabel: true,
        ),
        SizedBox(height: SizeConfig.size16),
        CommonTextField(
          textEditController: controller.productNameController,
          hintText: 'E.g. TSH-RED-s-0001',
          title: "Product SKU Number (Optional)",
          validator: controller.validateProductName,
          showLabel: true,
        ),
        SizedBox(height: SizeConfig.size16),
        CommonTextField(
          textEditController: controller.productNameController,
          hintText: 'E.g. 1554367',
          title: "Product Id Number",
          validator: controller.validateProductName,
          showLabel: true,
        ),
        SizedBox(height: SizeConfig.size16),
        // Category + Subcategory pickers (single Obx)
        Obx(() {
          return Column(
            children: List.generate(controller.categoryLevels.length, (i) {
              final level = controller.categoryLevels[i];
              final items = level.items.map((e) => e.name).toList();
              return Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size12),
                child: _buildDropdownField(
                  label: i == 0 ? 'Category' : 'Subcategory $i',
                  hint: i == 0 ? 'Select a category' : 'Select a subcategory',
                  items: items,
                  validator: (value) => i == 0 && value == null ? 'Please select a category' : null,
                  onChanged: (val) => controller.onLevelChanged(i, val),
                  value: level.selectedName.isEmpty ? null : level.selectedName,
                ),
              );
            }),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomText(
              "New Category",
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              "+",
              color: AppColors.primaryColor,
              fontSize: SizeConfig.size30,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size16),
        CustomText("Category folder"),
        SizedBox(height: SizeConfig.size16),
        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.secondaryTextColor.withOpacity(0.2))),
          padding: EdgeInsets.all(8),
          child: CustomText(
            "Choose Category Folder",
            color: AppColors.secondaryTextColor,
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        // Brand
        CommonTextField(
          textEditController: controller.brandController,
          title: 'Brand',
          hintText: 'E.g. Boat',
          validator: controller.validateBrand,
          showLabel: true,
        ),
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
          title: 'Selling Price (RS.)',
          hintText: 'E.g. ₹500',
          keyBoardType: TextInputType.number,
          validator: controller.validateSellingPrice,
          showLabel: true,
        ),
        SizedBox(height: SizeConfig.size16),
        // Available Stock
        CommonTextField(
          textEditController: controller.availableStockController,
          title: 'Available Stock',
          hintText: 'E.g. Text',
          keyBoardType: TextInputType.number,
          validator: controller.validateAvailableStock,
          showLabel: true,
        ),
        SizedBox(height: SizeConfig.size16),
        // Expiry Date
        _buildExpiryDateSection(controller),
        SizedBox(height: SizeConfig.size16),
        // Tags
        _buildTagsSection(controller),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required List<String> items,
    required String? Function(String?) validator,
    required void Function(String?) onChanged,
    String? value,
  }) {
    final String? effectiveValue = (value != null && items.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.medium,
          color: AppColors.black,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: effectiveValue,
              validator: validator,
              onChanged: onChanged,
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.grey9B,
                size: 20,
              ),
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              style: TextStyle(
                color: AppColors.black,
                fontSize: SizeConfig.medium,
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
                      fontSize: SizeConfig.medium,
                      color: AppColors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
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

  Widget _buildTagsSection(ManualListingScreenController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Add Tags / Keywords',
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
                  decoration: const InputDecoration(
                    hintText: 'Tag people',
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
              GestureDetector(
                onTap: controller.addTag,
                child: Image.asset("assets/icons/add_icon.png"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
