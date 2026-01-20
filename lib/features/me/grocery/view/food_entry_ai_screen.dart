import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/me/grocery/controller/food_entry_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/food_service_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/food/model/food_category_res_model.dart';

class FoodEntryScreen extends StatefulWidget {
  final FoodCategoryData foodCategoryData;

  const FoodEntryScreen({super.key, required this.foodCategoryData});

  @override
  State<FoodEntryScreen> createState() => _FoodEntryScreenState();
}

class _FoodEntryScreenState extends State<FoodEntryScreen> {
  final FoodEntryController controller = Get.put(FoodEntryController());
  final controllerFoodService = Get.find<FoodServiceController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.categoryList.value = widget.foodCategoryData.children ?? [];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Food",
      ),
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
              Obx(() => Wrap(
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
              Obx(() => Wrap(
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
              const CustomText("Food Category", fontWeight: FontWeight.bold),

              const SizedBox(height: 10),

              // 4. Food Category Input
              Obx(() => CommonDropdown<Children>(
                    // Use the observable list from controller
                    items: controller.categoryList,

                    // Find the currently selected object based on the stored ID
                    selectedValue: controller.selectedCategoryId.value.isEmpty
                        ? null
                        : controller.categoryList.firstWhereOrNull((item) =>
                            item.id == controller.selectedCategoryId.value),

                    hintText: "Select Category",

                    // This tells the dropdown what text to show to the user
                    displayValue: (item) => item.name ?? "",

                    onChanged: (Children? val) {
                      if (val != null) {
                        controllerFoodService.selectedSubFoodTypeIDCat.value =
                            val.id ?? "";

                        controller.selectedCategoryId.value = val.id ?? "";
                        controller.foodCategoryController.text = val.name ?? "";
                        debugPrint("Selected Key: ${val.key}");
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  )),

              const SizedBox(height: 30),

              // 5. Generate Button
              Obx(() {
                return CustomBtn(
                  onTap: controller.isFormValid.value
                      ? controller.onGenerate
                      : null,
                  title: AppStrings.generate,
                  isValidate: controller.isFormValid.value,
                );
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
            activeColor: AppColors.primaryColor,
          ),
          CustomText(label, fontSize: 13),
        ],
      ),
    );
  }
}
