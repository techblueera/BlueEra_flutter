import 'dart:io';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_history_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../widgets/custom_text_cm.dart';

class HospitalHistoryScreen extends StatefulWidget {
  const HospitalHistoryScreen({super.key});

  @override
  State<HospitalHistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HospitalHistoryScreen> {
  late final HospitalHistoryController controller;



  @override
  Widget build(BuildContext context) {
    controller = Get.put(HospitalHistoryController());
    return Scaffold(
      appBar: CommonBackAppBar(title: "History"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          return Column(
            children: [
              Container(
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
                        padding:  EdgeInsets.symmetric(horizontal: 12.0,vertical: 5),
                        child: AiDescriptionField(
                          label: "Describe your hospital history",
                          hintText: "Tell us more about the Hospital history...",
                          controller: controller.historyController,
                          rxValue: RxString(controller.historyController.text),
                          aiType: "Hospital history",
                          aiData: {},
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.size20),
                    CustomText("Upload Photo"),
                    SizedBox(height: SizeConfig.size10),

                    // Image Section: Handles Network vs Local
                    _buildImageSection(),

                    SizedBox(height: SizeConfig.size30),

                    // Submit Button
                    CustomBtn(
                      onTap: controller.isFormValid.value ? () => _handleSubmit() : null,
                      title: AppStrings.submit,
                      isValidate: controller.isFormValid.value,
                    ),
                  ],
                ),
              ),
            ],
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
    else if (controller.initialImageUrl.isNotEmpty) {
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
      title: "Upload Photo",
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

  void _handleSubmit() {
    controller.saveOrUpdate();
  }
}
