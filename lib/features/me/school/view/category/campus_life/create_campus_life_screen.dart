import 'package:BlueEra/core/api/model/campus_life_categories_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/campus_life_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateCampusLifeScreen extends StatefulWidget {
  const CreateCampusLifeScreen({super.key});

  @override
  State<CreateCampusLifeScreen> createState() => _CreateCampusLifeScreenState();
}

class _CreateCampusLifeScreenState extends State<CreateCampusLifeScreen> {
  final controller = Get.find<CampusLifeController>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller.isFormValid.value=false;
    controller.selectedCategory.value = null;
    controller.selectedSubCategory.value = null;
    controller.imageFiles.clear();
    controller.imageCaptions.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Add Campus Life"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Category Dropdown
            CustomText(
              "Select category",
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            Obx(() => CommonDropdownDialog<CampusLifeCategoriesData>(
                  title: "Select Category",
                  hintText: "E.g. Transportation",
                  items: controller.categoryList,
                  selectedValue: controller.selectedCategory.value,
                  displayValue: (cat) => cat.name ?? "",
                  onChanged: (value) => controller.onCategoryChanged(value),
                )),

            SizedBox(height: 16),
            CustomText(
              "Select Subcategory",
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.paddingXSL),
            // 2. Subcategory Dropdown (Reactive)
            Obx(() => CommonDropdownDialog<SubCategories>(
                  title: "Select Sub-Category",
                  hintText: controller.selectedCategory.value == null
                      ? "Please select a category first"
                      : "E.g. Bus Service",
                  items: controller.availableSubCategories,
                  selectedValue: controller.selectedSubCategory.value,
                  displayValue: (sub) => sub.name ?? "",
                  onChanged: (value) => controller.onSubCategoryChanged(value),
                )),
            SizedBox(height: 20),

            CustomText(
              "Select Images (Min 1, Max 6)",
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.paddingXSL),

            // Multiple Image Display
            Obx(() => Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.imageFiles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == controller.imageFiles.length) {
                        // Add Button
                        return index < 6
                            ? _buildAddButton(context)
                            : SizedBox();
                      }

                      return _buildImageTile(index);
                    },
                  ),
                )),

            SizedBox(height: 20),
            // Example of Caption Field for each image (Optional)
            Obx(() => Column(
                  children:
                      List.generate(controller.imageFiles.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CommonTextField(
                        textEditController: controller.imageCaptions[index],
                        title: "Caption for Image ${index + 1}",
                        hintText: "Enter caption...",
                        onChange: (val){
                          controller.textFiledChanged();
                        },
                      ),
                    );
                  }),
                )),

            SizedBox(height: 30),
            Obx(() => CustomBtn(
                  isLoading: controller.isLoading.value,
                  onTap: controller.isFormValid.value
                      ? controller.submitCampusData
                      : null,
                  title: "Save Campus Life",
                  isValidate: controller.isFormValid.value,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
        if (path != null) controller.addImage(path);
      },
      child: Container(
        width: 100,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.primaryColor, style: BorderStyle.solid),
        ),
        child: Icon(Icons.add_a_photo, color: AppColors.primaryColor),
      ),
    );
  }

  Widget _buildImageTile(int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: FileImage(controller.imageFiles[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 10,
          child: GestureDetector(
            onTap: () => controller.removeImage(index),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
