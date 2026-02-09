import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_certificates_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/professionals_service_photo_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_service_gallery/professionals_service_category_details_screen.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_service_gallery/upload_professionals_service_photos_screen.dart';
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
      appBar: CommonBackAppBar(title: "Certifications"),
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
                      CustomText("Certificate",
                          fontWeight: FontWeight.w600),
                      InkWell(
                        onTap: () {
                          certController.openForCreate();
                          _openAddEditSheet(context, false);
                        },
                        child: const CustomText(
                          "+ Add More",
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
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesGrid() {
    final items = certController.socialCertificationDataList ?? [];

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 260, // Height of the card area
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.symmetric(horizontal: 0),
        itemBuilder: (context, index) {
          SocialCertificationData cert = items[index];
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
                        imageUrl: cert.fileUrl ?? "",
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) => Image.asset(
                            AppImageAssets.noImageFound,
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
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.8),
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
                              cert.title ?? "Certificate Name",
                              color: Colors.white,
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.bold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: SizeConfig.size4),
                            CustomText(
                              cert.description ?? "Description goes here...",
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
                          CustomText("Add More Certificate",
                              fontWeight: FontWeight.w600),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size12),
                      // _documentTypeDropdown(),
                      // SizedBox(height: SizeConfig.size12),
                      CommonTextField(
                        title: "Title",
                        textEditController: certController.titleController,
                        hintText: "E.g. Certificate Name",
                        onChange: (val) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: SizeConfig.size12),
                      // CommonTextField(
                      //   title: "Issued By",
                      //   textEditController: certController.issuedByController,
                      //   hintText: "E.g. Authority / Organization",
                      //   onChange: (val) {
                      //     setState(() {});
                      //   },
                      // ),
                      // SizedBox(height: SizeConfig.size12),
                      // _issueDatePicker(context),
                      ///DOB selection
                      CustomText(
                        'Issued Date',
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
                      AiDescriptionField(
                        label: AppStrings.description,
                        hintText: "Tell us more about the organization...",
                        controller: certController.descriptionController,
                        rxValue: certController.description,
                        // Your RX variable from the controller
                        aiType: "Certificate",
                        aiData: {
                          // "docType": certController.documentType.value,
                          "title": certController.titleController.text,
                          // "issuedBy": certController.issuedByController.text,
                        },
                      ),
                      SizedBox(height: SizeConfig.size20),
                      Obx(() => CustomBtn(
                            title: isEdit ? "Update" : "Save",
                            isValidate: !(certController.isSaving.value),
                            onTap: certController.isSaving.value
                                ? null
                                : () async {
                                    if (isEdit == false &&
                                        certController.selectedFile.value ==
                                            null) {
                                      commonSnackBar(
                                          message:
                                              "Upload image file is required");
                                      return;
                                    }
                                    await certController.save();
                                    Get.back();
                                  },
                          )),
                      if(isEdit)...[
                        SizedBox(height: SizeConfig.size20),
                        CustomBtn(
                          title: "Delete",
                          onTap: () async {
                            await showCommonDialog(
                                context: context,
                                text:
                                'Are you sure you want to delete this certificate ?',
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
                                confirmText: AppStrings.yes,
                                cancelText: AppStrings.no);
                            // Get.back();
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

  Widget _documentTypeDropdown() {
    final types = ["Award", "Certificate", "License", "Other"];
    return Obx(() => DropdownButtonFormField<String>(
          value: certController.documentType.value,
          items: types
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            if (val != null) certController.documentType.value = val;
          },
          decoration: const InputDecoration(
            labelText: "Document Type",
            border: OutlineInputBorder(),
          ),
        ));
  }

  Widget _filePicker() {
    return Obx(() {
      final file = certController.selectedFile.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText("Upload File"),
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
                label: const CustomText("JPG / PNG"),
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
