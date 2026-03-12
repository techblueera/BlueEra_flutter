import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_entry_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/food/model/food_category_res_model.dart';

class FoodEntryAiScreen extends StatefulWidget {
  final FoodCategoryData foodCategoryData;

  const FoodEntryAiScreen({super.key, required this.foodCategoryData});

  @override
  State<FoodEntryAiScreen> createState() => _FoodEntryAiScreenState();
}

class _FoodEntryAiScreenState extends State<FoodEntryAiScreen> {
  final FoodEntryController controller = getOrPut(() => FoodEntryController());
  final controllerFoodService = Get.find<FoodServiceController>();

  @override
  void initState() {
    controller.categoryList.value = widget.foodCategoryData.children ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Create Food Item Via AI",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 8.0,
        ),
        child: CustomFormCard(
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Food Uploaded image
              _titleWidget("Upload Images"),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Side: Reactive Image Picker
                  Obx(() {
                    final File? selectedFile = controller.foodSearchImages[0];
                    final String dummyImage = AppImageAssets.foodDummyImage;

                    return GestureDetector(
                      onTap: () => controller.pickImageForIndex(context, 0),
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          children: [
                            // 1. The Image Layer (File or Asset)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: selectedFile != null
                                    ? Image.file(
                                  selectedFile,
                                  fit: BoxFit.cover,
                                )
                                    : Image.asset(
                                  dummyImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // 2. The Dark Overlay + Camera Icon
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: selectedFile == null
                                         ? Colors.black.withValues(alpha: 0.6)
                                         : null,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),

                            // 3. "Tap to Change" label
                            if (selectedFile != null)
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const CustomText(
                                      "Tap to Change",
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),

                  // Right Side: Instructions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "Instruction",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTextColor,
                        ),
                        const SizedBox(height: 6),
                        _buildInstructionItem("1. Use high resolution images"),
                        _buildInstructionItem("2. You can Choose Google Photos, Ai Generated Photo Or Own"),
                        _buildInstructionItem("3. Keep content easily understandable"),
                        _buildInstructionItem("4. Maintain accurate visual information"),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 1. Food Name Input
              CommonTextField(
                textEditController: controller.foodNameController,
                title: "Food Name",
                hintText: "E.g. Paneer Butter Masala....",
              ),
              const SizedBox(height: 16),

              // 2. Food Category
              _titleWidget("Food Category"),
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),

              // 2. Food Type Radio Group
              _titleWidget("Food Type"),
              Obx(() => Wrap(
                    spacing: 8,
                    children: [
                      _buildRadioButton("Veg", controller.selectedFoodType),
                      _buildRadioButton("Non-Veg", controller.selectedFoodType),
                      _buildRadioButton("Vigan", controller.selectedFoodType),
                      _buildRadioButton(
                          "Dairy/Sweet", controller.selectedFoodType),
                    ],
                  )),
              const SizedBox(height: 16),

              // 3. Cooking Method Radio Group
              _buildCookingMethodSection(),

              const SizedBox(height: 20),

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

  Widget _titleWidget(String title){
    return CustomText(
      title,
      fontSize: SizeConfig.small,
      fontWeight: FontWeight.w400,
      color: AppColors.mainTextColor,
    );
  }

  Widget _buildCookingMethodSection() {
    final List<String> methods = [
      "Cold Mix",
      "Deshi Ghee",
      "Boiled",
      "Oil + Ghee Mix",
      "Oil Fried",
      "Vegetable Ghee",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleWidget("Cooking Method"),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: methods.length,
          padding: EdgeInsets.only(top: 8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 6,
          ),
          itemBuilder: (context, index) {
            final String method = methods[index];

            return Obx(() {
              bool isSelected = controller.selectedCookingMethods.contains(method);

              return GestureDetector(
                onTap: () => controller.toggleCookingMethod(method),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: isSelected,
                        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primaryColor; // Background color when CHECKED
                          }
                          return Colors.white; // Background color when UNCHECKED (The fill color you want to change)
                        }),
                        checkColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                        onChanged: (val) => controller.toggleCookingMethod(method),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CustomText(
                      method,
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              );
            });
          },
        )
      ],
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CustomText(
        text,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryTextColor,
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
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primaryColor; // Color when selected (the dot)
              }
              return AppColors.secondaryTextColor; // Color when unselected (the border)
            }),
          ),
          CustomText(label, fontSize: 13),
        ],
      ),
    );
  }
}
