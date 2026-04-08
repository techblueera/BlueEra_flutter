import 'dart:io';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_opd_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';

class OpdDoctorFormScreen extends StatefulWidget {
  final String departmentId;
  final String? hospitalId;
  const OpdDoctorFormScreen({super.key, required this.departmentId, this.hospitalId});

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
    SizeConfig.init(context);
    return Scaffold(
      appBar: CommonBackAppBar(title:  AppStrings.addEditOpdDoctor,),
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
                  CommonTextField(
                    title: AppStrings.fullName,
                    textEditController: controller.nameController,
                    hintText: AppStrings.egRahulSharma,
                    onChange: (_) => controller.validate(),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  CommonTextField(
                    title:  AppStrings.education,
                    textEditController: controller.educationController,
                    hintText: AppStrings.hospitalViewEducationOptional.tr,
                    onChange: (_) => controller.validate(),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  CommonTextField(
                    title:  AppStrings.position,
                    textEditController: controller.positionController,
                    hintText: AppStrings.hospitalViewPositionHint.tr,
                    onChange: (_) => controller.validate(),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  CommonTextField(
                    title: AppStrings.fees,
                    textEditController: controller.feesController,
                    hintText:  AppStrings.fees,
                    keyBoardType: TextInputType.number,
                    onChange: (_) => controller.validate(),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  CommonTextField(
                    title:  AppStrings.timing,
                    textEditController: controller.timingController,
                    hintText: AppStrings.hospitalViewTimingHint.tr,
                    onChange: (_) => controller.validate(),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  CommonTextField(
                    title:  AppStrings.description,
                    textEditController: controller.descriptionController,
                    hintText: AppStrings.description.tr,
                    maxLine: 4,
                    onChange: (_) => controller.validate(),
                  ),
                  SizedBox(height: SizeConfig.size20),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: CustomBtn(
                          isValidate:controller.isFormValid.value  ,
                          title: controller.editing == null ?  AppStrings.save :  AppStrings.update,
                          onTap: controller.isFormValid.value ? controller.save : null,
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
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
      title:  AppStrings.uploadPhotos,
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
