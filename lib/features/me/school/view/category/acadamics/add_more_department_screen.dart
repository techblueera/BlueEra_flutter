import 'dart:io';
import 'package:BlueEra/core/api/model/department_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/school/controller/department_controller.dart';
import 'package:BlueEra/features/me/school/view/common_ai_genereted_button.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMoreDepartmentScreen extends StatefulWidget {
  final bool isEdit;
  final DepartmentData? departmentData;

  const AddMoreDepartmentScreen(
      {super.key, this.isEdit = false, this.departmentData});

  @override
  State<AddMoreDepartmentScreen> createState() =>
      _AddMoreDepartmentScreenState();
}

class _AddMoreDepartmentScreenState extends State<AddMoreDepartmentScreen> {
  final controller = Get.find<DepartmentController>();
  final nameCtrl = TextEditingController();
  final hodCtrl = TextEditingController();
  final staffCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  @override
  void initState() {
    controller.selectedImages.clear();
    controller.networkImages.clear();
    controller.hodName.value="";
    controller.staffNames.value="";
    controller.deptName.value="";
    if (widget.isEdit && widget.departmentData != null) {
      controller.initEditData(widget.departmentData ?? DepartmentData());
      nameCtrl.text = controller.deptName.value;
      hodCtrl.text = controller.hodName.value;
      staffCtrl.text = controller.staffNames.value;
      descCtrl.text = controller.description.value;
    } else {}
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.isEdit ?AppStrings.editDepartment.tr: AppStrings.addDepartment.tr),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildImagePicker(),
              SizedBox(height: 20),
              CommonTextField(
                textEditController: nameCtrl,
                title: AppStrings.departmentName,
                onChange: (v) {
                  controller.deptName.value = v;
                  controller.validateForm(isEdit: widget.isEdit);
                },
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: hodCtrl,
                title: AppStrings.hodName,
                onChange: (v) {
                  controller.hodName.value = v;
                  controller.validateForm(isEdit: widget.isEdit);
                },
              ),
              SizedBox(height: SizeConfig.paddingM),
              CommonTextField(
                textEditController: staffCtrl,
                title:AppStrings.staffNamesHint,
                onChange: (v) {
                  controller.staffNames.value = v;
                  controller.validateForm(isEdit: widget.isEdit);
                },
              ),
              SizedBox(height: SizeConfig.paddingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    AppStrings.description,
                  ),
                  // The Reusable AI Widget
                  Obx(() {
                    return AIGeneratorButton(
                      type: "Department",
                      data: {
                        "department_name": controller.deptName.value,
                        "hod_name": controller.hodName.value
                      },
                      onSelected: (generatedText) {
                        descCtrl.text = generatedText;
                        controller.description.value = generatedText;
                        controller.validateForm(isEdit: widget.isEdit);
                      },
                    );
                  }),
                ],
              ),
              CommonTextField(
                textEditController: descCtrl,
                title: "",
                hintText:
                "Hello Everyone @India User Now I am Using https://blueera.ai It’s Amazing, I suggest to Join Me.",
                maxLine: 5,
                maxLength: 1000,
                isValidate: false,
                keyBoardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChange: (value) {
                  String newVal = value.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                  controller.description.value = newVal;
                  controller.validateForm(isEdit: widget.isEdit);
                },
              ),
              SizedBox(height: SizeConfig.paddingXSL),
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() =>
                    CustomText(
                      "${controller.description.value.length}/1000",
                      color: Colors.grey,
                      fontSize: 12,
                    )),
              ),
              SizedBox(height: SizeConfig.paddingM),
              SizedBox(height: 40),
              Obx(() =>
                  CustomBtn(
                    title:
                    widget.isEdit ?AppStrings.updateDepartment.tr :AppStrings.addDepartment.tr,
                    isValidate: controller.isFormValid.value &&
                        !controller.isUploading.value,
                    onTap: controller.isFormValid.value
                        ? () =>
                        controller.submitDepartment(
                            isEdit: widget.isEdit,
                            deptId: widget.departmentData?.id ?? "")
                        : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Obx(() =>
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  AppStrings.uploadImages,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                )),
            SizedBox(height: SizeConfig.paddingXSL),
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                // 1. Show Network Images (Edit Mode)
                ...controller.networkImages
                    .map((url) => _imageTile(url, isNetwork: true)),
                // 2. Show Locally Picked Images
                ...controller.selectedImages
                    .map((file) => _imageTile(file.path, isNetwork: false)),
                // 3. Add Button
                if ((controller.networkImages.length +
                    controller.selectedImages.length) <
                    5)
                  GestureDetector(
                    onTap: () async {
                      // Pick image logic and add to controller.selectedImages
                      final selectedPath =
                      await CommonImageUploadTile.pickImage(
                          context: context);
                      controller.selectedImages.add(File(selectedPath ?? ""));

                      controller.validateForm(isEdit: widget.isEdit);
                    },
                    child: Container(
                        height: 80,
                        width: 80,
                        margin: EdgeInsets.only(top: 4, left: 10),
                        decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primaryColor)),
                        child: Icon(Icons.add)),
                  )
              ],
            ),
          ],
        ));
  }

  Widget _imageTile(String path, {required bool isNetwork}) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.all(5),
          height: 80,
          width: 80,
          decoration:
          BoxDecoration(border: Border.all(color: AppColors.primaryColor)),
          child: isNetwork
              ? Image.network(path, fit: BoxFit.cover)
              : Image.file(File(path), fit: BoxFit.cover),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: InkWell(
            onTap: () {
              isNetwork
                  ? controller.networkImages.remove(path)
                  : controller.selectedImages
                  .removeWhere((element) => element.path == path);
              controller.validateForm(isEdit: widget.isEdit);
            },
            child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 12, color: Colors.white)),
          ),
        )
      ],
    );
  }
}
