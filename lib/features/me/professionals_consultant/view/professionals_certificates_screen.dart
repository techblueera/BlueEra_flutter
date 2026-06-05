import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_certificates_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_service_photo_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_service_gallery/professionals_service_category_details_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_service_gallery/upload_professionals_service_photos_screen.dart';
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

class ProfessionalsCertificatesScreen extends StatelessWidget {
  ProfessionalsCertificatesScreen({super.key});

  final aiController = Get.find<AiProfessionalsController>();
  final certController = Get.put(ProfessionalsCertificatesController());
  final controller = Get.put(ProfessionalsServicePhotoPhotoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.proConsultGalleryCertifications.tr),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size8),
        child: Column(
          children: [
            CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(AppStrings.certificateAwards.tr,
                          fontWeight: FontWeight.w600),
                      InkWell(
                        onTap: () {
                          certController.openForCreate();
                          _openAddEditSheet(context, false);
                        },
                        child: CustomText(
                          "+ ${AppStrings.addMore.tr}",
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size15),
                  Obx(() {
                    return _buildCertificatesGrid();
                  }),
                ],
              ),
            ),
            Obx(() {
              return CommonCardWidget(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                            "${AppStrings.proConsultUploadImagesPrefix.tr} (${controller.propertyPhotosList.length}/20)",
                            fontWeight: FontWeight.w600),
                        if (controller.propertyPhotosList.length < 20)
                          InkWell(
                            onTap: () {
                              Get.to(UploadProfessionalsServicePhotosScreen());
                            },
                            child: CustomText(
                              "+ ${AppStrings.addMore.tr}",
                              color: AppColors.primaryColor,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size15),
                    ProfessionalsServiceCategoryDetailsScreen(),
                  ],
                ),
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesGrid() {
    final data = aiController.getProfessionalServiceRes?.value.data;
    final items = data?.certificates ?? [];

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 260, // Height of the card area
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: 0),
        itemBuilder: (context, index) {
          final cert = items[index];
          return GestureDetector(
            onTap: () {
              certController.openForEdit(cert);
              _openAddEditSheet(context, true);
            },
            // onLongPress: () => _showDeleteDialog(cert), // Abstracted for clarity
            child: Container(
              width: 240, // Width as per design aspect ratio
              margin: EdgeInsets.only(right: SizeConfig.size12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // 1. Background Image
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: cert.fileKey ?? "",
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) => Image.asset(
                            'assets/images/placeholder.png',
                            fit: BoxFit.cover),
                      ),
                    ),

                    // 2. Gradient Overlay for Text Readability
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

                    // 3. Text Content Overlaid at the Bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.all(SizeConfig.size12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              cert.title ?? AppStrings.certificateName.tr,
                              color: Colors.white,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.bold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: SizeConfig.size4),
                            CustomText(
                              cert.description ?? AppStrings.proConsultDescriptionGoesHere.tr,
                              color: Colors.white,
                              fontSize: SizeConfig.small,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
      ),
    );
  }

  void _openAddEditSheet(BuildContext context, bool isEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SizeConfig.size14,
                  right: SizeConfig.size14,
                  top: SizeConfig.size14,
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      SizeConfig.size14,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(AppStrings.proConsultAddMoreCertAndAwards.tr,
                              fontWeight: FontWeight.w600),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size12),
                      _documentTypeDropdown(),
                      SizedBox(height: SizeConfig.size12),
                      CommonTextField(
                        title: AppStrings.title.tr,
                        textEditController: certController.titleController,
                        hintText: AppStrings.proConsultEgCertificateName.tr,
                        onChange: (val) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: SizeConfig.size12),
                      CommonTextField(
                        title: AppStrings.proConsultIssuedBy.tr,
                        textEditController: certController.issuedByController,
                        hintText: AppStrings.proConsultEgAuthority.tr,
                        onChange: (val) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: SizeConfig.size12),
                      // _issueDatePicker(context),
                      ///DOB selection
                      CustomText(
                        AppStrings.proConsultIssuedDate.tr,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                      NewDatePicker(
                        selectedDay: certController.selectedDay,
                        selectedMonth: certController.selectedMonth,
                        selectedYear: certController.selectedYear,
                        isAgeValidation15: false,
                        onDayChanged: (value) {
                          setState(() {
                            certController.selectedDay = value;
                          });
                        },
                        onMonthChanged: (value) {
                          setState(() {
                            certController.selectedMonth = value;
                          });
                        },
                        onYearChanged: (value) {
                          setState(() {
                            certController.selectedYear = value;
                          });
                        },
                      ),
                      SizedBox(height: SizeConfig.size12),
                      if (!isEdit) ...[
                        _filePicker(),
                        SizedBox(height: SizeConfig.size12),
                      ],
                      // CommonTextField(
                      //   title: "Description",
                      //   textEditController:
                      //       certController.descriptionController,
                      //   hintText: "Add a brief description",
                      //   maxLine: 4,
                      // ),
                      Obx(() {
                        return AiDescriptionField(
                          label: AppStrings.description.tr,
                          hintText: AppStrings.proConsultTellUsMoreOrganization.tr,
                          controller: certController.descriptionController,
                          rxValue: certController.description,
                          // Your RX variable from the controller
                          aiType: "Awards & Certificate",
                          aiData: {
                            "docType": certController.documentType.value,
                            "title": certController.titleController.text,
                            "issuedBy": certController.issuedByController.text,
                          },
                        );
                      }),
                      SizedBox(height: SizeConfig.size20),
                      Obx(() => CustomBtn(
                            title: isEdit ? AppStrings.update.tr : AppStrings.save.tr,
                            isValidate: !(certController.isSaving.value),
                            onTap: certController.isSaving.value
                                ? null
                                : () async {
                                    if (await certController.save()) {
                                      Get.back(result: true);
                                    }
                                  },
                          )),
                      SizedBox(height: SizeConfig.size20),
                      CustomBtn(
                        title: AppStrings.delete.tr,
                        onTap: () async {
                          await showCommonDialog(
                              context: context,
                              text:
                                  AppStrings.proConsultAreYouSureDeleteCert.tr,
                              confirmCallback: () async {
                                Get.back();
                                await certController
                                    .deleteCertificateController(
                                        certiId: certController
                                                .editingCertificateId.value ??
                                            "");
                              },
                              cancelCallback: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              confirmText: AppStrings.yes.tr,
                              cancelText: AppStrings.no.tr);
                          // Get.back();
                        },
                        bgColor: AppColors.red00,
                      ),
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

  Widget _documentTypeDropdown() {
    // Internal values kept as-is for backend; UI labels are localized.
    final types = ["Award", "Certificate", "License", "Other"];
    final labels = {
      "Award": AppStrings.award.tr,
      "Certificate": AppStrings.certificate.tr,
      "License": AppStrings.proConsultLicense.tr,
      "Other": AppStrings.other.tr,
    };
    return Obx(() => DropdownButtonFormField<String>(
          value: certController.documentType.value,
          items: types
              .map((e) => DropdownMenuItem(value: e, child: Text(labels[e] ?? e)))
              .toList(),
          onChanged: (val) {
            if (val != null) certController.documentType.value = val;
          },
          decoration: InputDecoration(
            labelText: AppStrings.proConsultDocumentType.tr,
            border: const OutlineInputBorder(),
          ),
        ));
  }

  Widget _filePicker() {
    return Obx(() {
      final file = certController.selectedFile.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(AppStrings.proConsultUploadFile.tr),
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final x = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (x != null) {
                    certController.selectedFile.value = File(x.path);
                    certController.isImageEdit.value = true;
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: CustomText(AppStrings.proConsultJpgPng.tr),
                // label: const Text("PDF / JPG / PNG"),
              ),
              SizedBox(width: SizeConfig.size12),
              if (file != null)
                Expanded(
                  child: CustomText(
                    file.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      );
    });

    /*  return Column(
      children: [
        CustomText(
          "Upload Doc ",
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w400,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(() {
          return (certController.docUploadName.value == "")
              ? Row(
            children: [
              Expanded(child: _buildImageSection()),
              SizedBox(width: SizeConfig.size10),
              Expanded(child: ProfessionalPdfPreviewWidget()),
            ],
          )
              : Row(
            children: [
              if (certController.docUploadName.value == "photo")
                Expanded(child: _buildImageSection()),
              SizedBox(width: SizeConfig.size10),
              if (certController.docUploadName.value == "pdf")
                Expanded(
                    child: (widget.isEdit)
                        ? Column(
                      children: [
                        IgnorePointer(
                          ignoring: true,
                          child: Container(
                            height: 150, // Preview Height
                            decoration: BoxDecoration(
                              border:
                              Border.all(color: Colors.black12),
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SfPdfViewer.network(
                              widget.studentItem?.uploadPhoto ?? "",
                              canShowPaginationDialog:
                              false, // Clean preview look
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              certController
                                  .noticeImageFile.value = null;
                              certController
                                  .initialNoticeImageUrl = "";
                              certController
                                  .docUploadName.value = "";
                            },
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            label: const CustomText("Remove",
                                color: Colors.red),
                          ),
                        ),
                      ],
                    )
                        : ProfessionalPdfPreviewWidget()),
            ],
          );
        }),
      ],
    );*/
  }
}
