import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_management_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
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

  void _handleSubmit() {
    if (controller.isFormValid.value) {
      controller.save();
      return;
    }
    // Inline-validation only renders errors inside the text fields. The
    // image-section above has no inline error surface, so surface the
    // "photo required" case via snackbar; otherwise show the generic
    // "all fields required" message.
    final hasImage = controller.selectedImage.value != null ||
        controller.initialImageUrl.isNotEmpty;
    commonSnackBar(
      message: hasImage
          ? AppStrings.hospitalCtrlAllFieldsRequiredValid.tr
          : 'Please upload a photo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.editingMember != null;

    return Scaffold(
      appBar: CommonBackAppBar(
        title: isEditing ? AppStrings.editMembers : AppStrings.addedMembers,
      ),
      body: Obx(() {
        final isChanged = controller.isChanged.value;
        final isValid = controller.isFormValid.value;

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
                    _textField(
                      title: AppStrings.fullName,
                      textController: controller.nameController,
                      validator: ValidationMethod.validateName,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _textField(
                      title: AppStrings.position,
                      textController: controller.positionController,
                      validator: ValidationMethod.validatePosition,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _textField(
                      title: AppStrings.education,
                      textController: controller.educationController,
                      validator: ValidationMethod.validateEducation,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    _textField(
                      title: AppStrings.description,
                      textController: controller.descriptionController,
                      validator: ValidationMethod.validateDescription,
                      maxLine: 5,
                    ),
                    SizedBox(height: SizeConfig.size15),
                    CustomBtn(
                      title: isEditing ? AppStrings.update : AppStrings.save,
                      width: double.infinity,
                      height: SizeConfig.size45,
                      isLoading: controller.isSaving.value,
                      isValidate: isValid && isChanged,
                      onTap: isChanged ? _handleSubmit : null,
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

  Widget _textField({
    required String title,
    required TextEditingController textController,
    required String? Function(String?) validator,
    int? maxLine,
  }) {
    return CommonTextField(
      title: title,
      textEditController: textController,
      isValidate: true,
      validator: validator,
      maxLine: maxLine,
      onChange: (_) => controller.validate(),
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
    }
    if (controller.initialImageUrl.isNotEmpty) {
      return _networkImagePreview(controller.initialImageUrl);
    }
    return CommonImageUploadTile(
      title: AppStrings.uploadPhotos,
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

  Widget _networkImagePreview(String url) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
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
        ),
      ],
    );
  }
}
