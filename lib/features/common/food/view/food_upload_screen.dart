import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';

class FoodUploadScreen extends StatelessWidget {
  final FoodUploadController controller = Get.put(FoodUploadController());

  FoodUploadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Food",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size20),
            child: CommonCardWidget(
              child: Padding(
                padding: EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload Images Section
                    _buildUploadImagesSection(context),
                    SizedBox(height: SizeConfig.size20),

                    // Food Name Field
                    _buildTextField(
                      label: 'Food Name',
                      hint: 'E.g. Paneer Butter Masala....',
                      inputController: controller.foodNameController,
                      filedName: 'food_name',
                    ),
                    SizedBox(height: SizeConfig.size20),

                    // Food Type 1 Selection
                    _buildFoodTypeSection(
                      title: 'Food Type 1',
                      options: controller.foodType1Options,
                      groupValue: controller.selectedFoodType1,
                    ),
                    SizedBox(height: SizeConfig.size20),

                    // Food Type 2 Selection
                    _buildFoodTypeSection(
                      title: 'Food Type 2',
                      options: controller.foodType2Options,
                      groupValue: controller.selectedFoodType2,
                    ),
                    SizedBox(height: SizeConfig.size20),

                    // Cooking Method Selection
                    _buildCookingMethodSection(),
                    SizedBox(height: SizeConfig.size20),

                    // Item Nature Selection
                    _buildItemNatureSection(),
                    SizedBox(height: SizeConfig.size20),

                    // City Name Field (Optional)
                    _buildTextField(
                      label: 'City Name (Optional)',
                      hint: 'E.g. Durgapur',
                      inputController: controller.cityNameController,
                      filedName: '',
                    ),
                    SizedBox(height: SizeConfig.size30),

                    // Generate Button
                    _buildGenerateButton(),
                    SizedBox(height: SizeConfig.size30),
                  ],
                ),
              ),
            ),
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
          'Upload Images',
          fontSize: SizeConfig.large,
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() => GestureDetector(
              onTap: () async {
                final String? selected =
                    await SelectProfilePictureDialog.showLogoDialog(
                  context,
                  "Select Photo",
                );
                if ((selected?.isNotEmpty ?? false) && selected != null) {
                  controller.selectedImage.value = File(selected);
                } else {
                  commonSnackBar(
                      message: "Something went wrong please try again");
                }
              },
              // onTap: () => controller.showImagePickerDialog(context),
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
          // fontWeight: FontWeight.w500,
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

  Widget _buildFoodTypeSection({
    required String title,
    required List<String> options,
    required RxString groupValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: SizeConfig.large,
          // fontWeight: FontWeight.w500,
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: options.map((option) {
                return Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.9, // adjust size
                        child: Radio<String>(
                          value: option,
                          groupValue: groupValue.value,
                          onChanged: (value) {
                            groupValue.value = value!;
                          },
                          activeColor: AppColors.primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          // removes extra padding
                          visualDensity:
                              VisualDensity.compact, // tighter layout
                        ),
                      ),
                      Flexible(
                          child: Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size5),
                        child: CustomText(option),
                      )),
                      SizedBox(width: SizeConfig.size5),
                    ],
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildCookingMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Cooking Method',
          fontSize: SizeConfig.large,
        ),
        SizedBox(height: SizeConfig.size10),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          children: controller.cookingMethodOptions.map((method) {
            return Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.9, //
                      child: Radio<String>(
                        value: method,
                        groupValue: controller.selectedCookingMethod.value,
                        onChanged: (value) {
                          controller.selectedCookingMethod.value = value!;
                        },
                        activeColor: AppColors.primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        // removes extra padding
                        visualDensity: VisualDensity.compact, // tighter layout
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size5),
                        child: CustomText(
                          method,
                        ),
                      ),
                    ),
                    SizedBox(width: SizeConfig.size5),
                  ],
                ));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildItemNatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Item Nature',
          fontSize: SizeConfig.large,
        ),
        SizedBox(height: SizeConfig.size10),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          children: controller.itemNatureOptions.map((nature) {
            return Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.9,
                      child: Radio<String>(
                        value: nature,
                        groupValue: controller.selectedItemNature.value,
                        onChanged: (value) {
                          controller.selectedItemNature.value = value!;
                        },
                        activeColor: AppColors.primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        // removes extra padding
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Flexible(
                        child: Padding(
                      padding: EdgeInsets.only(left: SizeConfig.size5),
                      child: CustomText(nature),
                    )),
                    SizedBox(width: SizeConfig.size5),
                  ],
                ));
          }).toList(),
        ),
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
                    controller.generateFood();
                  }
                }
              : null,
          title: "Generate");
    });
    /* return SizedBox(
      width: double.infinity,
      height: SizeConfig.size50,
      child: Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : () => controller.generateFood(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: controller.isLoading.value
                ? CircularProgressIndicator(color: Colors.white)
                : CustomText(
                    'Generate',
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
          )),
    );*/
  }
}
