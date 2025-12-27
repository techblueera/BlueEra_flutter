import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_multiple_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/about_us_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMoreDepartmentScreen extends StatelessWidget {
  AddMoreDepartmentScreen({super.key});

  final aboutUsController = Get.find<AboutUsController>();

  final multipleImageSectionController =
  Get.put(CommonMultipleImageSectionController());
  final departmentNameEditController = TextEditingController();
  final hodEditController = TextEditingController();
  final staffEditController = TextEditingController();
  final descriptionEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    departmentNameEditController.addListener(_runValidation);
    hodEditController.addListener(_runValidation);
    staffEditController.addListener(_runValidation);
    descriptionEditController.addListener(_runValidation);
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add More Departments",
        isShadowShow: false,
      ),
      body: SafeArea(
        child: CommonCardWidget(
          child: SingleChildScrollView(
            child: Column(
              children: [
                GetBuilder<CommonMultipleImageSectionController>(
                  id: CommonMultipleImageSectionController.addMoreDepartment,
                  builder: (ctrl) =>
                      CommonMultipleImageUploadSection(
                        title: AppStrings.uploadImages,
                        maxImages: aboutUsController.maxDepartmentImageUpload,
                        images: aboutUsController.addMoreImages,
                        onAddImage: () async {
                          await multipleImageSectionController.addImages(
                              label: AppStrings.uploadImages,
                              imageList: aboutUsController.addMoreImages,
                              updateId: CommonMultipleImageSectionController
                                  .addMoreDepartment,
                              maxUploadImages:
                              aboutUsController.maxDepartmentImageUpload);
                          _runValidation(); // Validate after adding image

                        },
                        onRemoveImage: (index) async {
                          multipleImageSectionController.removeImageAt(
                            imageList: aboutUsController.addMoreImages,
                            index: index,
                            updateId: CommonMultipleImageSectionController
                                .addMoreDepartment,
                          );
                          _runValidation(); // Validate after adding image
                        },
                      ),
                ),
                CommonTextField(
                  textEditController: departmentNameEditController,
                  hintText: "E.g. Geography Department",
                  title: "Department Name",
                  onChange: (_) => _runValidation(),

                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: hodEditController,
                  hintText: "E.g. Ramesh Bhagat",
                  title: "HOD Name",
                  // onChange is another way to trigger validation
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: staffEditController,
                  hintText: "E.g. Suresh Kumar",
                  title: "Staff Names",
                  // onChange is another way to trigger validation
                  onChange: (_) => _runValidation(),
                ),
                SizedBox(height: SizeConfig.paddingM),
                CommonTextField(
                  textEditController: descriptionEditController,
                  title: AppStrings.description,
                  hintText:
                  "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                  maxLine: 5,
                  maxLength: 1000,

                  isValidate: false,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChange: (value) {
                    String newVal = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                    aboutUsController.departmentDescriptionText.value = newVal;
                    _runValidation();
                  },
                ),
                SizedBox(height: SizeConfig.paddingXSL),

                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() =>
                      CustomText(
                        "${aboutUsController.departmentDescriptionText.value
                            .length}/1000",
                        color: Colors.grey,
                        fontSize: 12,
                      )),
                ),
                SizedBox(height: SizeConfig.paddingM),

                // THE BUTTON
                Obx(() =>
                    CustomBtn(
                      // Logic: If not valid, onTap is null (disables button)
                      onTap: aboutUsController.isFormValid.value
                          ? () {
                        /* Your Submit Logic */
                      }
                          : null,
                      title: AppStrings.add,
                      // Pass the validation state to change button color/opacity
                      isValidate: aboutUsController.isFormValid.value,
                    )),
                SizedBox(height: SizeConfig.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper to trigger validation
  void _runValidation() {
    aboutUsController.validateForm(
      deptName: departmentNameEditController.text,
      hodName: hodEditController.text,
      staffNames: staffEditController.text,
      description: descriptionEditController.text,
      images: aboutUsController.addMoreImages,
    );
  }
}
