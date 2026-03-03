import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/social/controller/social_feed_controller.dart';
import 'package:BlueEra/features/me/social/model/social_activity_feed_res_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddSocialFeedScreen extends StatefulWidget {
  final bool isEdit;
  final SocialActivityFeedData? departmentData;

  const AddSocialFeedScreen(
      {super.key, this.isEdit = false, this.departmentData});

  @override
  State<AddSocialFeedScreen> createState() => _AddSocialFeedScreenState();
}

class _AddSocialFeedScreenState extends State<AddSocialFeedScreen> {
  final controller = Get.find<SocialFeedController>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  @override
  void initState() {
    controller.selectedImages.clear();
    controller.networkImages.clear();
    controller.deptName.value = "";
    if (widget.isEdit && widget.departmentData != null) {
      controller.initEditData(widget.departmentData ?? SocialActivityFeedData());
      nameCtrl.text = controller.deptName.value;
      descCtrl.text = controller.description.value;
    } else {}
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.isEdit ? AppStrings.editActivityFeed.tr :AppStrings.addActivityFeed.tr),
      body: CommonCardWidget(
        child: SafeArea(
          child: SingleChildScrollView(
            // padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildImagePicker(),
                SizedBox(height: 20),
                CommonTextField(
                  textEditController: nameCtrl,
                  title: AppStrings.title,
                  onChange: (v) {
                    controller.deptName.value = v;
                    controller.validateForm(isEdit: widget.isEdit);
                  },
                ),
                SizedBox(height: SizeConfig.paddingM),

                Obx(() {
                  return AiDescriptionField(
                    label: AppStrings.description,
                    hintText: "Share your feed...",
                    controller: descCtrl,
                    rxValue: controller.description,
                    aiType: "Activity Feed",
                    aiData: {"title": controller.deptName.value},
                    onChanged: (val) {
                      controller.validateForm(isEdit: widget.isEdit);
                    },
                  );
                }),


                SizedBox(height: 40),
                Obx(() =>
                    CustomBtn(
                      title:
                      widget.isEdit ? AppStrings.update.tr : AppStrings.add.tr,
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
