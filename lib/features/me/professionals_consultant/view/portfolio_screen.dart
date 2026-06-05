import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/portfolio_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/portfolio_project_card_widget.dart';
import 'package:BlueEra/features/me/school/view/widget/add_more_icon_button.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PortfolioScreen extends StatelessWidget {
  PortfolioScreen({super.key});

  final aiController = Get.find<AiProfessionalsController>();
  final portfolioController = Get.put(PortfolioProfessionalsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.proConsultPortfolioCaseStudies.tr),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0, top: 10),
          child: AddMoreIconButton(
            onTapEvent: () {
              portfolioController.openForCreate();
              _openAddEditSheet(context, false);
            },
          ),
        ),
      ),
      body: Obx(() {
        if (aiController
                .getProfessionalServiceRes?.value.data?.portfolio?.isNotEmpty ??
            false) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return PortfolioProjectCardWidget(
                project: aiController.getProfessionalServiceRes?.value.data
                        ?.portfolio?[index] ??
                    ProfessionalPortfolio(),
              );
            },
            itemCount: aiController
                .getProfessionalServiceRes?.value.data?.portfolio?.length,
          );
        }
        return Center(child: CustomText(AppStrings.na.tr));
      }),
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
                          CustomText(AppStrings.addMore.tr, fontWeight: FontWeight.w600),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),

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
                            selectedValue: portfolioController
                                    .selectedCategory.value.isEmpty
                                ? null
                                : portfolioController.selectedCategory.value,
                            displayValue: (mode) => mode,
                            onChanged: (value) {
                              if (value != null)
                                portfolioController.selectedCategory.value =
                                    value;
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
                      if (!isEdit) ...[
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
                      ],
                      Obx(() {
                        return AiDescriptionField(
                          label: AppStrings.description,
                          hintText:
                              AppStrings.tellUsMoreAboutProject.tr,
                          controller: portfolioController.descriptionController,
                          rxValue: portfolioController.description,
                          // Your RX variable from the controller
                          aiType: "Portfolio,Case Studies",
                          aiData: {
                            "category":
                                portfolioController.selectedCategory.value,
                            "title": portfolioController.titleController.text
                          },
                        );
                      }),
                      SizedBox(height: SizeConfig.size20),
                      Obx(() => CustomBtn(
                            title: isEdit ? AppStrings.update.tr : AppStrings.save.tr,
                            isValidate: !(portfolioController.isSaving.value),
                            onTap: portfolioController.isSaving.value
                                ? null
                                : () async {
                                    if (isEdit == false &&
                                        portfolioController
                                                .selectedFile.value ==
                                            null) {
                                      commonSnackBar(
                                          message:
                                              AppStrings.proConsultUploadImageRequired.tr);
                                      return;
                                    }
                                    await portfolioController.save();
                                    Get.back(result: true);
                                  },
                          )),
                      SizedBox(height: SizeConfig.size20),
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
