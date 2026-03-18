import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/food/controller/food_entry_controller.dart';
import 'package:BlueEra/features/me/food/controller/food_service_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/food/model/food_category_res_model.dart';

class FoodEntryAiScreen extends StatefulWidget {
  final int? createMissingProductIndex;

  const FoodEntryAiScreen({
    super.key,
    this.createMissingProductIndex,
  });

  @override
  State<FoodEntryAiScreen> createState() => _FoodEntryAiScreenState();
}

class _FoodEntryAiScreenState extends State<FoodEntryAiScreen> {
  final FoodEntryController controller = getOrPut(() => FoodEntryController());
  final vc = Get.find<FoodServiceController>();

  @override
  void initState() {
    super.initState();

   // Wait for the frame to be ready before updating the controller list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vc.foodNestedCateList.isNotEmpty) {
        controller.foodCateList.assignAll(vc.foodNestedCateList);
        debugPrint("Categories assigned: ${controller.foodCateList.length}");
      } else {
        debugPrint("Warning: vc.foodSubCateList is empty at post-frame.");
      }
    });  }

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
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedFile==null ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
                            width: 2,
                          ),
                        ),
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
                                child: selectedFile == null
                                    ? const Center(
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                )
                                    : null,
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
              _buildCategorySection(),
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
                      ? () {
                    if (controller.isFormValid.value) {
                      // 1. Image Validation
                      if (controller.foodSearchImages.isEmpty || controller.foodSearchImages[0] == null) {
                        commonSnackBar(message: "Please upload a food image to proceed.");
                        return;
                      }

                      // 2. Determine the deepest selected category
                      final lastCategory = controller.selectedLevel2.value ?? controller.selectedLevel1.value;

                      // 3. Check if the selected category has further sub-categories (children)
                      // If it has children, it means the user hasn't finished selecting the "last" category.
                      bool isSelectionComplete = lastCategory != null &&
                          (lastCategory.children == null || lastCategory.children!.isEmpty);

                      if (!isSelectionComplete) {
                        commonSnackBar(
                          message: "Please select a specific sub-category/item type before generating.",
                        );
                        _showCategoryPicker(); // Automatically open the picker for them
                        return;
                      }

                      // 4. Cooking Method Validation
                      if(controller.selectedCookingMethods.isEmpty){
                        commonSnackBar(
                          message: "Please select a cooking method.",
                        );
                        return;
                      }

                      vc.selectedSubFoodTypeIDCat.value = lastCategory.sId ?? '';

                      Map<String, dynamic> reqParams = {
                        "name": controller.foodNameController.text,
                        "foodType": controller.selectedFoodType.value,
                        "cookingMethod": controller.selectedCookingMethods,
                        "category": lastCategory.sId
                      };

                      controller.onGenerate(
                          reqParams: reqParams,
                          createMissingProductIndex: widget.createMissingProductIndex
                      );
                    }


                      }
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

  Widget _buildCategorySection() {
    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Obx(() {
          bool hasSelection = controller.selectedLevel0.value != null;

          return Row(
            children: [
              Expanded(
                child: hasSelection
                    ? _buildSelectionPath()
                    : CustomText("Choose Category", color: Colors.grey[400]),
              ),
              const Icon(
                  Icons.keyboard_arrow_down_outlined,
                  size: 18,
                  color: AppColors.secondaryTextColor),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSelectionPath() {
    // Collect non-null names into a list
    List<String> path = [
      if (controller.selectedLevel0.value != null) controller.selectedLevel0.value!.name!,
      if (controller.selectedLevel1.value != null) controller.selectedLevel1.value!.name!,
      if (controller.selectedLevel2.value != null) controller.selectedLevel2.value!.name!,
    ];

    return Wrap(
      spacing: 4, // Horizontal space between items
      runSpacing: 4, // Vertical space between lines
      crossAxisAlignment: WrapCrossAlignment.center,
      children: path.asMap().entries.map((entry) {
        bool isLast = entry.key == path.length - 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLast ? AppColors.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: CustomText(
                entry.value,
                fontSize: 11,
                color: isLast ? AppColors.primaryColor : AppColors.secondaryTextColor,
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (!isLast)
              const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        );
      }).toList(),
    );
  }

  void _showCategoryPicker() {
    RxList<dynamic> currentDisplayList = <dynamic>[].obs;
    currentDisplayList.assignAll(controller.foodCateList);

    Get.bottomSheet(
      isScrollControlled: true,
      Obx(() => Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInteractiveSheetHeader(currentDisplayList),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: currentDisplayList.length,
                itemBuilder: (context, index) {
                  final item = currentDisplayList[index];
                  final bool hasChildren = (item.children != null && item.children.isNotEmpty);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                    title: CustomText(item.name ?? ""),
                    trailing: hasChildren ? const Icon(Icons.chevron_right, size: 18) : null,
                    onTap: () {
                      if (item.level == 0) {
                        controller.selectedLevel0.value = item;
                        controller.selectedLevel1.value = null;
                        controller.selectedLevel2.value = null;
                        currentDisplayList.assignAll(item.children!);
                      } else if (item.level == 1) {
                        controller.selectedLevel1.value = item;
                        controller.selectedLevel2.value = null;
                        if (hasChildren) {
                          currentDisplayList.assignAll(item.children!);
                        } else {
                          Get.back();
                        }
                      } else {
                        controller.selectedLevel2.value = item;
                        Get.back();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildInteractiveSheetHeader(RxList<dynamic> currentList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText("Select Category", fontWeight: FontWeight.bold, fontSize: 16),
            IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
          ],
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // STEP 0: ALL
            _pathStep("All", () {
              controller.selectedLevel0.value = null;
              controller.selectedLevel1.value = null;
              controller.selectedLevel2.value = null;
              currentList.assignAll(controller.foodCateList);
            }, controller.selectedLevel0.value == null),

            // STEP 1: Level 0
            if (controller.selectedLevel0.value != null) ...[
              const Icon(Icons.chevron_right, size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedLevel0.value!.name!, () {
                controller.selectedLevel1.value = null;
                controller.selectedLevel2.value = null;
                currentList.assignAll(controller.selectedLevel0.value!.children!);
              }, controller.selectedLevel1.value == null),
            ],

            // STEP 2: Level 1
            if (controller.selectedLevel1.value != null) ...[
              const Icon(Icons.chevron_right, size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedLevel1.value!.name!, () {
                controller.selectedLevel2.value = null;
                currentList.assignAll(controller.selectedLevel1.value!.children!);
              }, controller.selectedLevel2.value == null),
            ],

            // STEP 3: Level 2 (Optional: showing current selection final leaf)
            if (controller.selectedLevel2.value != null) ...[
              const Icon(Icons.chevron_right, size: 14, color: AppColors.primaryColor),
              _pathStep(controller.selectedLevel2.value!.name!, () {}, true),
            ],
          ],
        ),
        SizedBox(height: 5),
        CommonHorizontalDivider(
          color: AppColors.greyE5,
          height: 0.5,
        )
      ],
    );
  }

  Widget _pathStep(String label, VoidCallback onTap, bool isCurrent) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: CustomText(
          label,
          fontSize: 12,
          color: isCurrent ? AppColors.primaryColor : AppColors.secondaryTextColor,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
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
