import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_management_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagementFormScreen extends StatefulWidget {
  const ManagementFormScreen({super.key});

  @override
  State<ManagementFormScreen> createState() => _ManagementFormScreenState();
}

class _ManagementFormScreenState extends State<ManagementFormScreen> {
  late final HospitalManagementController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HospitalManagementController>();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: controller.editingMember == null ? AppStrings.addedMembers : AppStrings.editMembers,
        isLeading: true,
        isShadowShow: true,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonCardWidget(
                cardMargin: 0,
                child: Column(
                  children: [
                    _buildImageSection(),
                    SizedBox(height: SizeConfig.size15),
                    CommonTextField(
                      title: AppStrings.fullName,
                      textEditController: controller.nameController,
                      isValidate: true,
                      validator: (v)=> ValidationMethod.validateName(v),
                      onChange: (_) => controller.validate(),
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CommonTextField(
                      title: AppStrings.position,
                      textEditController: controller.positionController,
                      isValidate: true,
                      validator: (v)=> ValidationMethod.validatePosition(v),
                      onChange: (_) => controller.validate(),
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CommonTextField(
                      title:AppStrings.education,
                      textEditController: controller.educationController,
                      isValidate: true,
                      validator: (v)=> ValidationMethod.validateEducation(v),
                      onChange: (_) => controller.validate(),
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CommonTextField(
                      title: AppStrings.description,
                      maxLine: 5,
                      textEditController: controller.descriptionController,
                      isValidate: true,
                      validator: (v)=> ValidationMethod.validateDescription(v),
                      onChange: (_) => controller.validate(),
                    ),
                    SizedBox(height: SizeConfig.size15),
                    CustomBtn(
                      title: controller.editingMember == null ? AppStrings.save : AppStrings.update,
                      width: double.infinity,
                      height: SizeConfig.size45,
                      isLoading: controller.isSaving.value,
                      isValidate: controller.isFormValid.value,
                      onTap: () {
                        if (controller.isFormValid.value) {
                          controller.save();
                        } else {
                          // This triggers inline validation in fields.
                          // If those fields are not visible, show a snackbar.
                          if (!((controller.selectedImage.value != null) || controller.initialImageUrl.isNotEmpty)) {
                            commonSnackBar(message: 'Please upload a photo');
                          } else {
                             commonSnackBar(message: AppStrings.hospitalCtrlAllFieldsRequiredValid.tr);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildImageSection() {
    if (controller.selectedImage.value != null) {
      return CommonImageUploadTile(
        imageFile: controller.selectedImage,
        onImageRemove: () {
          controller.selectedImage.value = null;
          controller.validate();
        },
        title: '',
        context: context,
      );
    } else if (controller.initialImageUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              controller.initialImageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: CircleAvatar(
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  controller.initialImageUrl = "";
                  controller.validate();
                  setState(() {});
                },
              ),
            ),
          )
        ],
      );
    }
    return CommonImageUploadTile(
      title:AppStrings.uploadPhotos,
      context: context,
      onImageSelected: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
        if (path != null) {
          controller.selectedImage.value = File(path);
          controller.validate();
        }
      },
      imageFile: controller.selectedImage,
    );
  }
}
