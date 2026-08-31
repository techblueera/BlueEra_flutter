import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/job_seekar/controller/job_seeker_portfolio_professionals_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerPortfolioFormScreen extends StatefulWidget {
  const JobSeekerPortfolioFormScreen({super.key});

  @override
  State<JobSeekerPortfolioFormScreen> createState() =>
      _JobSeekerPortfolioFormScreenState();
}

class _JobSeekerPortfolioFormScreenState
    extends State<JobSeekerPortfolioFormScreen> {
  final portfolioController =
      Get.find<JobSeekerPortfolioProfessionalsController>();

  @override
  void initState() {
    // TODO: implement initState
    portfolioController.isSaving.value = false;
    portfolioController.selectedFile.value = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.portfolioProjects.tr,
      ),
      body: SafeArea(
        child: CommonCardWidget(
          child: Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + SizeConfig.size14,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     CustomText("Add More", fontWeight: FontWeight.w600),
                  //     IconButton(
                  //       icon: const Icon(Icons.close),
                  //       onPressed: () => Get.back(),
                  //     ),
                  //   ],
                  // ),

                  CommonTextField(
                    title: AppStrings.projectTitle.tr,
                    textEditController: portfolioController.titleController,
                    hintText: AppStrings.egFinanceTax.tr,
                    onChange: (val) {
                      setState(() {});
                    },
                  ),

                  SizedBox(height: SizeConfig.size12),
                  CustomText(AppStrings.consultationMode.tr,
                      color: AppColors.mainTextColor),
                  const SizedBox(height: 10),
                  Obx(() => CommonDropdownDialog<String>(
                        title: AppStrings.selectMode.tr,
                        hintText: AppStrings.egOnline.tr,
                        items: portfolioController.categoryList,
                        selectedValue:
                            portfolioController.selectedCategory.value.isEmpty
                                ? null
                                : portfolioController.selectedCategory.value,
                        displayValue: (mode) => mode,
                        onChanged: (value) {
                          if (value != null)
                            portfolioController.selectedCategory.value = value;
                        },
                      )),
                  const SizedBox(height: 10),

                  ///DOB selection
                  CustomText(
                    AppStrings.whenWorkCompleted.tr,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  NewDatePicker(
                    selectedDay: portfolioController.selectedDay,
                    selectedMonth: portfolioController.selectedMonth,
                    selectedYear: portfolioController.selectedYear,
                    isAgeValidation15: false,
                    onDayChanged: (value) {
                      setState(() {
                        portfolioController.selectedDay = value;
                      });
                    },
                    onMonthChanged: (value) {
                      setState(() {
                        portfolioController.selectedMonth = value;
                      });
                    },
                    onYearChanged: (value) {
                      setState(() {
                        portfolioController.selectedYear = value;
                      });
                    },
                  ),
                  SizedBox(height: SizeConfig.size12),
                  // if (!isEdit) ...[
                  CustomText(
                    AppStrings.uploadImage.tr,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(
                    height: SizeConfig.size10,
                  ),
                  _buildImageSection(context, setState(() {})),
                  SizedBox(height: SizeConfig.size12),
                  // ],
                  Obx(() {
                    return AiDescriptionField(
                      label: AppStrings.description.tr,
                      hintText: AppStrings.tellUsMoreAboutProject.tr,
                      controller: portfolioController.descriptionController,
                      rxValue: portfolioController.description,
                      // Your RX variable from the controller
                      aiType: "Portfolio,Case Studies",
                      aiData: {
                        "category": portfolioController.selectedCategory.value,
                        "title": portfolioController.titleController.text
                      },
                    );
                  }),
                  SizedBox(height: SizeConfig.size20),
                  Obx(() => CustomBtn(
                        // title: isEdit ? "Update" : "Save",
                        title: AppStrings.save.tr,
                        isValidate: !(portfolioController.isSaving.value),
                        onTap: portfolioController.isSaving.value
                            ? null
                            : () async {
                                // if (isEdit == false &&
                                //     portfolioController
                                //         .selectedFile.value ==
                                //         null) {
                                //   commonSnackBar(
                                //       message:
                                //       "Upload image file is required");
                                //   return;
                                // }
                                await portfolioController.save();
                                Get.back();
                              },
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, void param1) {
    // If user picked a NEW local file
    if (portfolioController.selectedFile.value != null) {
      return CommonImageUploadTile(
        imageFile: portfolioController.selectedFile,
        onImageRemove: () {
          portfolioController.selectedFile.value = null;
          portfolioController.initialNoticeImageUrl = "";
          portfolioController.docUploadName.value = "";
        },
        title: '',
        context: context,
      );
    }
    // If no local file but we have a NETWORK image from API
    else if (portfolioController.initialNoticeImageUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              portfolioController.initialNoticeImageUrl,
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
                  // Clear initial URL to show "Change" happened
                  portfolioController.selectedFile.value = null;

                  portfolioController.initialNoticeImageUrl = "";
                  portfolioController.docUploadName.value = "";

                  // _runValidation();
                  // setState(
                  //         () {}); // Refresh local UI to show upload placeholder
                },
              ),
            ),
          )
        ],
      );
    }
    // Default: Show Upload Placeholder
    return CommonImageUploadTile(
      title: AppStrings.uploadImage.tr,
      context: context,
      onImageSelected: () async {
        final path = await CommonImageUploadTile.pickImage(context: context);
        if (path != null) {
          portfolioController.selectedFile.value = File(path);
          portfolioController.initialNoticeImageUrl = path;
          portfolioController.docUploadName.value = "photo";

          // _runValidation();
        }
      },
      onImageRemove: () {
        // Clear initial URL to show "Change" happened
        portfolioController.selectedFile.value = null;

        portfolioController.initialNoticeImageUrl = "";
        // _runValidation();
        // setState(() {}); //
      },
      imageFile: portfolioController.selectedFile,
    );
  }
}
