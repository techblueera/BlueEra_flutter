import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';

class FoodUploadScreen extends StatefulWidget {
  final ProductServiceProviderType providerType;
  final EarnWithBlueEraServiceTypes? serviceSubType;
  final String? category;

  FoodUploadScreen({Key? key, required this.providerType, this.serviceSubType, this.category}) : super(key: key);

  @override
  State<FoodUploadScreen> createState() => _FoodUploadScreenState();
}

class _FoodUploadScreenState extends State<FoodUploadScreen> {
  final FoodUploadController controller = getOrPut(() => FoodUploadController());

  @override
  void initState() {
    super.initState();

    if (widget.providerType == ProductServiceProviderType.user &&
        widget.category != null) {
      final category = widget.category!;
      controller.selectedFoodType1.value = category;

      // find index of category in list
      final index = controller.foodType1Options.indexOf(category);
      if (index != -1) {
        controller.selectedFoodType1Index.value = index;
      }

      controller.isCategoryLocked = true;
    } else {
      controller.isCategoryLocked = false;
    }
  }


  @override
  void dispose() {
    log('done, now deleted');
    Get.delete<FoodUploadController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.food,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: SizeConfig.size15,
          ),
          child: CommonCardWidget(
            cardMargin: 0.0,
            child: Obx(()=> AbsorbPointer(
              absorbing: controller.isGenerateFoodLoading.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload Images Section
                  _buildUploadImagesSection(context),

                  SizedBox(height: SizeConfig.size20),

                  // Food Name Field
                  _buildTextField(
                    label: AppStrings.foodName,
                    hint: AppStrings.egPaneerButterMasala,
                    inputController: controller.foodNameController,
                    filedName: 'food_name',
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Food Type 1 Selection
                  AbsorbPointer(
                    absorbing: controller.isCategoryLocked,
                    child: _buildTabSection(
                      title: AppStrings.foodType1,
                      tabs: controller.foodType1Options,
                      selectedIndex: controller.selectedFoodType1Index,
                      onTabSelected: (index, value) {
                          controller.selectedFoodType1.value = value;
                          controller.selectedFoodType1Index.value = index;
                      },
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Food Type 2 Selection
                  _buildTabSection(
                    title: AppStrings.foodType2,
                    tabs: controller.foodType2Options,
                    selectedIndex: controller.selectedFoodType2Index,
                    onTabSelected: (index, value) {
                      controller.selectedFoodType2.value = value;
                    },
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Cooking Method Selection
                  _buildTabSection(
                    title: AppStrings.cookingMethod,
                    tabs: controller.cookingMethodOptions,
                    selectedIndex: controller.selectedCookingMethodIndex,
                    onTabSelected: (index, value) {
                      controller.selectedCookingMethod.value = value;
                    },
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // Item Nature Selection
                  _buildTabSection(
                    title: AppStrings.itemNature,
                    tabs: controller.itemNatureOptions,
                    selectedIndex: controller.selectedItemNatureIndex,
                    onTabSelected: (index, value) {
                      controller.selectedItemNature.value = value;
                    },
                  ),
                  SizedBox(height: SizeConfig.size20),

                  // City Name Field (Optional)
                  _buildTextField(
                    label: AppStrings.cityNameOptional,
                    hint: AppStrings.egDurgapur,
                    inputController: controller.cityNameController,
                    filedName: '',
                  ),
                  SizedBox(height: SizeConfig.size30),

                  // Generate Button
                  _buildGenerateButton(),

                  SizedBox(height: SizeConfig.size10),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadImagesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.uploadImages,
          fontSize: SizeConfig.large,
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() => GestureDetector(
          onTap: () async {
            final String? selected =
            await SelectProfilePictureDialog.showLogoDialog(
              context,
              AppStrings.selectPhoto.tr,
            );
            if ((selected?.isNotEmpty ?? false) && selected != null) {
              controller.selectedImage.value = File(selected);
            }
          },
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: controller.selectedImage.value != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                controller.selectedImage.value!,
                fit: BoxFit.cover,
              ),
            )
                : Icon(
              Icons.add_photo_alternate,
              size: 40,
              color: Colors.grey[500],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTextField({
    required String filedName,
    required String label,
    required String hint,
    required TextEditingController inputController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: SizeConfig.large,
        ),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: inputController,
          hintText: hint,
          onChange: (value) {
            if (filedName == "food_name") {
              controller.foodName.value = value;
            }
          },
        ),
      ],
    );
  }

  /// 🔹 Reusable HorizontalTabSelector Section
  Widget _buildTabSection({
    required String title,
    required List<String> tabs,
    required RxInt selectedIndex,
    required Function(int, String) onTabSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: SizeConfig.large,
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() => HorizontalTabSelector(
          tabs: tabs,
          selectedIndex: selectedIndex.value,
          isFilterIconShow: false,
          onTabSelected: (index, value) {
            selectedIndex.value = index;
            onTabSelected(index, value);
          },
          labelBuilder: (label) => label,
        )),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Obx(() {
      return CustomBtn(
          isValidate: (controller.selectedImage.value != null &&
              controller.foodName.value.isNotEmpty),
          onTap: (controller.selectedImage.value != null &&
              controller.foodNameController.text.isNotEmpty)
              ? () {
            if (controller.selectedImage.value != null &&
                controller.foodNameController.text.isNotEmpty) {
              controller.generateFood(
                  providerType: widget.providerType,
                  serviceSubType: widget.serviceSubType
              );
            }
          }
              : null,
          title: controller.isGenerateFoodLoading.value
              ? null
              : AppStrings.generate,
        isLoading: controller.isGenerateFoodLoading.value,
      );
    });
  }
}