import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social_certificates_controller.dart';
import 'package:BlueEra/features/me/social/model/social_certification_res_model.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SocialCertificatesScreen extends StatelessWidget {
  SocialCertificatesScreen({super.key});

  final certController = Get.put(SocialCertificatesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.certifications.tr),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          certController.openForCreate();
          _openAddEditSheet(context, false);
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: CustomText(AppStrings.addMore.tr,
            color: Colors.white,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size14),
        child: Column(
          children: [
            // --- Info Banner ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    AppColors.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primaryColor
                        .withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined,
                      color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      AppStrings.socialCertificatesBanner.tr,
                      color: AppColors.primaryColor,
                      fontSize: SizeConfig.small,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Certificates Grid ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(AppStrings.certifications.tr,
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.medium),
                    SizedBox(height: SizeConfig.size15),
                    Obx(() {
                      final List<SocialCertificationData> items =
                          certController.socialCertificationDataList ??
                              [];
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Icon(Icons.emoji_events_outlined,
                                  size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              CustomText(AppStrings.noDataFound.tr,
                                  color:
                                      AppColors.secondaryTextColor),
                              const SizedBox(height: 4),
                              CustomText(
                                  AppStrings.socialTapAddFirstCertificate.tr,
                                  color: Colors.grey[400],
                                  fontSize: SizeConfig.small),
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      }
                      return _buildCertificatesGrid(
                          context, items);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesGrid(
      BuildContext context, List<SocialCertificationData> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final cert = items[index];
        return GestureDetector(
          onTap: () {
            certController.openForEdit(cert);
            _openAddEditSheet(context, true);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: cert.fileUrl ?? "",
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) =>
                          Image.asset(AppImageAssets.noImageFound,
                              fit: BoxFit.cover),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: const [0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Edit icon
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 14),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding:
                          EdgeInsets.all(SizeConfig.size10),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            cert.title ?? AppStrings.certificate.tr,
                            color: Colors.white,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.bold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (cert.description != null &&
                              cert.description!.isNotEmpty) ...[
                            SizedBox(height: SizeConfig.size4),
                            CustomText(
                              cert.description!,
                              color: Colors.white,
                              fontSize: SizeConfig.small,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAddEditSheet(BuildContext context, bool isEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context,
              void Function(void Function()) setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.size14,
                  right: SizeConfig.size14,
                  top: SizeConfig.size14,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                          SizeConfig.size14,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius:
                                BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            isEdit
                                ? AppStrings.editCertificate.tr
                                : AppStrings.addCertificate.tr,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size12),
                      CommonTextField(
                        title: AppStrings.title.tr,
                        textEditController:
                            certController.titleController,
                        hintText: AppStrings.socialCertificateTitleHint.tr,
                        onChange: (val) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: SizeConfig.size12),
                      CustomText(
                        AppStrings.certificateIssuedBy.tr,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      NewDatePicker(
                        selectedDay:
                            certController.selectedDay,
                        selectedMonth:
                            certController.selectedMonth,
                        selectedYear:
                            certController.selectedYear,
                        isAgeValidation15: false,
                        onDayChanged: (value) {
                          setState(() {
                            certController.selectedDay =
                                value;
                          });
                        },
                        onMonthChanged: (value) {
                          setState(() {
                            certController.selectedMonth =
                                value;
                          });
                        },
                        onYearChanged: (value) {
                          setState(() {
                            certController.selectedYear =
                                value;
                          });
                        },
                      ),
                      SizedBox(height: SizeConfig.size12),
                      if (!isEdit) ...[
                        _filePicker(setState),
                        SizedBox(height: SizeConfig.size12),
                      ],
                      AiDescriptionField(
                        label: AppStrings.description.tr,
                        hintText: AppStrings.socialDescribeAchievementHint.tr,
                        controller:
                            certController.descriptionController,
                        rxValue: certController.description,
                        aiType: "Certificate",
                        aiData: {
                          "title": certController
                              .titleController.text,
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),
                      Obx(() => CustomBtn(
                            title: isEdit
                                ? AppStrings.update.tr
                                : AppStrings.save.tr,
                            isValidate:
                                !(certController.isSaving.value),
                            isLoading:
                                certController.isSaving.value,
                            onTap: certController.isSaving.value
                                ? null
                                : () async {
                                    if (await certController.save()) {
                                      Get.back();
                                    }
                                  },
                          )),
                      if (isEdit) ...[
                        SizedBox(height: SizeConfig.size12),
                        CustomBtn(
                          title: AppStrings.delete.tr,
                          onTap: () async {
                            await showCommonDialog(
                              context: context,
                              text: AppStrings.deleteConfirm.tr,
                              confirmCallback: () async {
                                Get.back();
                                await certController
                                    .deleteCertificateController(
                                  certiId: certController
                                          .editingCertificateId
                                          .value ??
                                      "",
                                );
                              },
                              cancelCallback: () {
                                Navigator.of(context).pop();
                              },
                              confirmText: AppStrings.yes.tr,
                              cancelText: AppStrings.no.tr,
                            );
                          },
                          bgColor: AppColors.red00,
                        ),
                      ],
                      SizedBox(height: SizeConfig.size30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filePicker(void Function(void Function()) setState) {
    return Obx(() {
      final file = certController.selectedFile.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(AppStrings.uploadDocument.tr,
              fontWeight: FontWeight.w500),
          SizedBox(height: SizeConfig.size8),
          InkWell(
            onTap: () async {
              final x = await ImagePicker()
                  .pickImage(source: ImageSource.gallery);
              if (x != null) {
                certController.selectedFile.value =
                    File(x.path);
                certController.isImageEdit.value = true;
                setState(() {});
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.primaryColor,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primaryColor
                    .withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_file,
                      color: AppColors.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  CustomText(
                    file != null
                        ? file.path.split('/').last
                        : "JPG / PNG",
                    color: AppColors.primaryColor,
                    fontSize: SizeConfig.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
