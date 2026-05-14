import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_ipd_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IpdWardFormScreen extends StatefulWidget {
  final String departmentId;
  final String? hospitalId;

  const IpdWardFormScreen({
    super.key,
    required this.departmentId,
    this.hospitalId,
  });

  @override
  State<IpdWardFormScreen> createState() => _IpdWardFormScreenState();
}

class _IpdWardFormScreenState extends State<IpdWardFormScreen> {
  late final HospitalIpdController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalIpdController());
    controller.departmentIdArg = widget.departmentId;
    controller.hospitalIdArg = widget.hospitalId;
    controller.selectedImage.value = null;
  }

  /// Called from every text field's `onChange`. The `setState` is needed
  /// because the `AiDescriptionField` below reads non-Rx text from
  /// `nameController` and `bedCountController` into its `aiData` map; a
  /// rebuild is required to refresh that snapshot on each keystroke.
  void _onFieldChange() {
    controller.validate();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.editingWard != null;

    return Scaffold(
      appBar: CommonBackAppBar(
        title: isEditing ? AppStrings.editIpd : AppStrings.addIpd,
      ),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!isEditing) ...[
                _buildImageSection(context),
                SizedBox(height: SizeConfig.size20),
              ],
              _textField(
                title: AppStrings.bedName,
                textController: controller.nameController,
                hint: AppStrings.fullName,
              ),
              SizedBox(height: SizeConfig.size10),
              _textField(
                title: AppStrings.bedCount,
                textController: controller.bedCountController,
                hint: "4",
                keyBoardType: TextInputType.number,
              ),
              SizedBox(height: SizeConfig.size10),
              _textField(
                title: AppStrings.price,
                textController: controller.feesController,
                hint: "Rs 500/-",
                keyBoardType: TextInputType.number,
              ),
              SizedBox(height: SizeConfig.size10),
              AiDescriptionField(
                label: AppStrings.hospital_ipd_title,
                hintText: AppStrings.hospital_ipd_subtitle,
                controller: controller.historyController,
                rxValue: RxString(controller.historyController.text),
                aiType: "Hospital IPD (In-Patient Departments / Wards)",
                aiData: {
                  'bed_count': controller.bedCountController.text,
                  'bed_name': controller.nameController.text,
                },
              ),
              SizedBox(height: SizeConfig.size30),
              Obx(() {
                final isValid = controller.isFormValid.value;
                final isSaving = controller.isSaving.value;
                return CustomBtn(
                  isValidate: isValid,
                  title: isSaving
                      ? AppStrings.saving
                      : (isEditing ? AppStrings.update : AppStrings.add),
                  onTap: isValid ? controller.saveOrUpdate : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required String title,
    required TextEditingController textController,
    required String hint,
    TextInputType? keyBoardType,
  }) {
    return CommonTextField(
      title: title,
      textEditController: textController,
      hintText: hint,
      keyBoardType: keyBoardType,
      onChange: (_) => _onFieldChange(),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Obx(() {
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
    });
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
