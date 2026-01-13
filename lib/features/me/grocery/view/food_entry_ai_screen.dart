import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/grocery/controller/food_entry_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodEntryScreen extends StatelessWidget {
  final FoodEntryController controller = Get.put(FoodEntryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Food",),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Food Name Input
              CommonTextField(
                textEditController: controller.foodNameController,
                title: "Food Name",
                hintText: "E.g. Paneer Butter Masala....",
              ),
              const SizedBox(height: 20),

              // 2. Food Type Radio Group
              const CustomText("Food Type", fontWeight: FontWeight.bold),
              Obx(() =>
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildRadioButton("Veg", controller.selectedFoodType),
                      _buildRadioButton("Non-Veg", controller.selectedFoodType),
                      _buildRadioButton("Vigan", controller.selectedFoodType),
                      _buildRadioButton(
                          "Dairy/Sweet", controller.selectedFoodType),
                    ],
                  )),
              const SizedBox(height: 20),

              // 3. Cooking Method Radio Group
              const CustomText("Cooking Method", fontWeight: FontWeight.bold),
              Obx(() =>
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildRadioButton(
                          "Cold Mix", controller.selectedCookingMethod),
                      _buildRadioButton(
                          "Boiled", controller.selectedCookingMethod),
                      _buildRadioButton(
                          "Oil Fried", controller.selectedCookingMethod),
                      _buildRadioButton(
                          "Deshi Ghee", controller.selectedCookingMethod),
                      _buildRadioButton(
                          "Oil + Ghee Mix", controller.selectedCookingMethod),
                      _buildRadioButton(
                          "Vegetable Ghee", controller.selectedCookingMethod),

                    ],
                  )),
              const SizedBox(height: 20),

              // 4. Food Category Input
              CommonTextField(
                textEditController: controller.foodCategoryController,
                title: "Food Category",
                hintText: "E.g. Breakfast > South Indian",
              ),
              const SizedBox(height: 30),

              // 5. Generate Button
              Obx(() {
                return CustomBtn(onTap: controller.isFormValid.value
                    ? controller.onGenerate
                    : null,
                  title: AppStrings.generate,
                  isValidate: controller.isFormValid.value,);
              })

            ],
          ),
        ),
      ),
    );
  }

  // Helper to build a custom Radio with Label
  Widget _buildRadioButton(String label, RxString selectedValue) {
    return InkWell(
      onTap: () => selectedValue.value = label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: label,
            groupValue: selectedValue.value,
            onChanged: (value) => selectedValue.value = value!,
            activeColor:AppColors.primaryColor,
          ),
          CustomText(label, fontSize: 13),
        ],
      ),
    );
  }
}