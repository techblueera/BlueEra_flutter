import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_history_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalHistoryScreen extends StatefulWidget {
  const HospitalHistoryScreen({super.key});

  @override
  State<HospitalHistoryScreen> createState() => _HospitalHistoryScreenState();
}

class _HospitalHistoryScreenState extends State<HospitalHistoryScreen> {
  final HospitalHistoryController controller =
      Get.put(HospitalHistoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.history),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          final data = controller.data.value;
          final isExistingRecord = data != null && (data.id?.isNotEmpty ?? false);
          final submitLabel =
              isExistingRecord ? AppStrings.update : AppStrings.submit;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.whiteE5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonCardWidget(
                  cardMargin: 0,
                  padding: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 5,
                    ),
                    child: AiDescriptionField(
                      label: AppStrings.hospitalHistoryTitle,
                      hintText: AppStrings.hospitalHistorySubtitle,
                      controller: controller.historyController,
                      rxValue: RxString(controller.historyController.text),
                      aiType: "Hospital history",
                      aiData: const {},
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                CustomText(AppStrings.uploadPhotos),
                SizedBox(height: SizeConfig.size10),
                _buildImageSection(),
                SizedBox(height: SizeConfig.size30),
                CustomBtn(
                  onTap: controller.saveOrUpdate,
                  title: submitLabel,
                  isValidate: controller.isFormValid.value,
                ),
              ],
            ),
          );
        }),
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
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
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
