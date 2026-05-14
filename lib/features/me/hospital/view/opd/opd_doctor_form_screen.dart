import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_opd_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OpdDoctorFormScreen extends StatefulWidget {
  final String departmentId;
  final String? hospitalId;

  const OpdDoctorFormScreen({
    super.key,
    required this.departmentId,
    this.hospitalId,
  });

  @override
  State<OpdDoctorFormScreen> createState() => _OpdDoctorFormScreenState();
}

class _OpdDoctorFormScreenState extends State<OpdDoctorFormScreen> {
  late final HospitalOpdController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HospitalOpdController>();
    controller.departmentIdArg = widget.departmentId;
    controller.hospitalIdArg = widget.hospitalId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.addEditOpdDoctor),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonCardWidget(
              child: Column(
                children: [
                  _buildImageSection(),
                  SizedBox(height: SizeConfig.size12),
                  _textField(
                    title: AppStrings.fullName,
                    textController: controller.nameController,
                    hint: AppStrings.egRahulSharma,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _textField(
                    title: AppStrings.education,
                    textController: controller.educationController,
                    hint: AppStrings.hospitalViewEducationOptional.tr,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _textField(
                    title: AppStrings.position,
                    textController: controller.positionController,
                    hint: AppStrings.hospitalViewPositionHint.tr,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _textField(
                    title: AppStrings.fees,
                    textController: controller.feesController,
                    hint: AppStrings.fees,
                    keyBoardType: TextInputType.number,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _textField(
                    title: AppStrings.timing,
                    textController: controller.timingController,
                    hint: AppStrings.hospitalViewTimingHint.tr,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _textField(
                    title: AppStrings.description,
                    textController: controller.descriptionController,
                    hint: AppStrings.description.tr,
                    maxLine: 4,
                  ),
                  SizedBox(height: SizeConfig.size20),
                  Obx(() {
                    final isValid = controller.isFormValid.value;
                    final isEditing = controller.editing != null;
                    return SizedBox(
                      width: double.infinity,
                      child: CustomBtn(
                        isValidate: isValid,
                        title: isEditing ? AppStrings.update : AppStrings.save,
                        onTap: isValid ? controller.save : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required String title,
    required TextEditingController textController,
    required String hint,
    TextInputType? keyBoardType,
    int? maxLine,
  }) {
    return CommonTextField(
      title: title,
      textEditController: textController,
      hintText: hint,
      keyBoardType: keyBoardType,
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
