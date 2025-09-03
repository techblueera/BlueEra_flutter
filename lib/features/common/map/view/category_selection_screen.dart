import 'package:BlueEra/core/api/model/category_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_one_controller.dart';
import 'package:BlueEra/features/common/map/controller/category_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CategoryController());
    final addPlaceController = Get.find<AddPlaceStepOneController>();

    return Scaffold(
      bottomNavigationBar: Obx(
        () =>
            controller.isLoading.value || controller.filteredCategories.isEmpty
                ? SizedBox()
                : SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size15,
                          vertical: kToolbarHeight),
                      child: CustomBtn(
                        onTap: controller.validate.value
                            ? () {
                                // Get selected category names
                                List<String> selectedCategoryNames = [];
                                List<String> selectedCategoryIds =
                                    controller.selectedCategoryIds.toList();

                                for (var id in selectedCategoryIds) {
                                  final category = controller.allCategories
                                      .firstWhere((cat) => cat.id == id,
                                          orElse: () => CategoryModel(
                                              id: '',
                                              name: '',
                                              createdAt: '',
                                              updatedAt: '',
                                              v: 0));
                                  if (category.name.isNotEmpty) {
                                    selectedCategoryNames.add(category.name);
                                  }
                                }

                                // Update the category controller text
                                addPlaceController.categoryController.text =
                                    selectedCategoryNames.join(', ');
                                addPlaceController.selectedCategoryIds.value =
                                    selectedCategoryIds;
                                addPlaceController.validateForm();

                                // Navigate back
                                Navigator.pop(context);
                              }
                            : null,
                        title: 'Save',
                        isValidate: controller.validate.value,
                      ),
                    ),
                  ),
      ),
      appBar: CommonBackAppBar(
        isSearch: true,
        controller: controller.searchController,
        onClearCallback: controller.clearSearch,
      ),
      body: SafeArea(
        child: Obx(
          () => controller.isLoading.value
              ? Center(child: CircularProgressIndicator())
              : controller.filteredCategories.isEmpty
                  ? Center(
                      child: EmptyStateWidget(message: "No category found"))
                  : SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.all(SizeConfig.size15),
                      child: Wrap(
                        spacing: 9,
                        runSpacing: 12,
                        children: List.generate(
                            controller.filteredCategories.length, (index) {
                          final category = controller.filteredCategories[index];
                          return Obx(() {
                            final isSelected = controller.selectedCategoryIds
                                .contains(category.id);

                            return GestureDetector(
                              onTap: () =>
                                  controller.toggleCategory(category.id),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: SizeConfig.size10,
                                    horizontal: SizeConfig.size14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomText(
                                      "${isSelected ? "✓" : "+"}",
                                      color: isSelected
                                          ? AppColors.white
                                          : AppColors.black30,
                                      fontSize: SizeConfig.large,
                                    ),
                                    SizedBox(width: SizeConfig.size4),
                                    CustomText(
                                      "${category.name}",
                                      color: isSelected
                                          ? AppColors.white
                                          : AppColors.black30,
                                      fontSize: SizeConfig.medium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                        }),
                      ),
                    ),
        ),
      ),
    );
  }
}
