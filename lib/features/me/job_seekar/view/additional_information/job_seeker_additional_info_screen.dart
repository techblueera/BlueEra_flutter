import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/resume/controller/additional_info_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_document_picker.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobSeekerAdditionalInfoFormScreen extends StatefulWidget {
  final bool isEdit;
  final String? infoId;
  JobSeekerAdditionalInfoFormScreen({Key? key, this.isEdit = false, this.infoId})
      : super(key: key);

  @override
  State<JobSeekerAdditionalInfoFormScreen> createState() => _JobSeekerAdditionalInfoFormScreenState();
}

class _JobSeekerAdditionalInfoFormScreenState extends State<JobSeekerAdditionalInfoFormScreen> {
  // final AdditionalInfoController controller = Get.find();
  final controller = getOrPut(() => AdditionalInfoController());

  @override
  void initState() {
    super.initState();

    controller.titleController.addListener(() {
      setState(() {}); // update UI for isValid changes
    });
    controller.infoController.addListener(() {
      setState(() {});
    });

    if (widget.isEdit && widget.infoId != null) {
      final item = controller.additionalInfoList
          .firstWhereOrNull((e) => e['_id'] == widget.infoId);
      if (item != null) controller.fillForm(item);
    } else {
      controller.clearForm();
    }
  }

  bool isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;
    try {
      final date = DateTime(year, month, day);
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      return !date.isAfter(todayDateOnly); // Prevent future dates
    } catch (_) {
      return false;
    }
  }

  bool get isValid {
    if (controller.titleController.text.trim().isEmpty) return false;
    if (controller.infoController.text.trim().isEmpty) return false;
    if (controller.isAddDate.value) {
      if (!isValidDate(controller.selectedDay, controller.selectedMonth,
          controller.selectedYear)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
            title: widget.isEdit
                ? AppStrings.editAdditionalInfo.tr
                : AppStrings.addAdditionalInformation.tr),
        body: Padding(
          padding: EdgeInsets.all(SizeConfig.paddingS),
          child: CommonCardWidget(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.paddingXS),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      CommonTextField(
                        title: AppStrings.title.tr,
                        textEditController: controller.titleController,
                        hintText: AppStrings.langExample.tr,
                      ),
                      SizedBox(height: SizeConfig.size18),

                      // Additional Description (maps to 'info')
                      CustomText(AppStrings.additionalDescription.tr),
                      SizedBox(height: SizeConfig.size10),
                      CommonTextField(
                        hintText:AppStrings.describeThisInfo.tr,
                        textEditController: controller.infoController,
                        maxLine: 5,
                        maxLength: 200,
                      ),
                      SizedBox(height: SizeConfig.size20),

                      Obx(() => controller.isAddDate.value
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      AppStrings.date.tr,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.isAddDate.value = false;
                                        controller.selectedDay = null;
                                        controller.selectedMonth = null;
                                        controller.selectedYear = null;
                                        setState(() {});
                                      },

                                      child: CustomText(
                                        AppStrings.remove.tr,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size10),
                                NewDatePicker(
                                  selectedDay: controller.selectedDay,
                                  selectedMonth: controller.selectedMonth,
                                  selectedYear: controller.selectedYear,
                                  onDayChanged: (day) => setState(
                                      () => controller.selectedDay = day),
                                  onMonthChanged: (month) => setState(
                                      () => controller.selectedMonth = month),
                                  onYearChanged: (year) => setState(
                                      () => controller.selectedYear = year),
                                ),
                                SizedBox(height: SizeConfig.size15),
                              ],
                            )
                          : InkWell(
                              onTap: () => controller.isAddDate.value = true,
                              child: Row(
                                children: [
                                  LocalAssets(
                                      imagePath: AppIconAssets.addBlueIcon),
                                  SizedBox(width: SizeConfig.size4),
                                  CustomText(
                                    AppStrings.addDate.tr,
                                    color: AppColors.primaryColor,
                                    fontSize: SizeConfig.large,
                                  ),
                                ],
                              ),
                            )),
                      SizedBox(height: SizeConfig.size15),

                      // Add Photo Toggle and Document Picker
                      Obx(() => controller.isAddPhoto.value
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      AppStrings.photo.tr,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.selectedImagePath = null;
                                        controller.isAddPhoto.value = false;
                                        setState(
                                            () {}); // update UI for picker hide
                                      },
                                      child: CustomText(
                                        AppStrings.remove.tr,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size10),
                                CommonDocumentPicker(
                                  imagePath: controller.selectedImagePath,
                                  onClear: () {
                                    controller.selectedImagePath = null;
                                    setState(() {}); // update picker UI
                                  },
                                  onSelect: (context) async {
                                    controller.selectedImagePath =
                                        await SelectProfilePictureDialog
                                            .showLogoDialog(
                                                context,
                                            AppStrings
                                                    .uploadYourDocumentPhoto.tr);
                                    setState(() {}); // update picker UI
                                  },
                                ),
                                SizedBox(height: SizeConfig.size15),
                              ],
                            )
                          : InkWell(
                              onTap: () => controller.isAddPhoto.value = true,
                              child: Row(
                                children: [
                                  LocalAssets(
                                      imagePath: AppIconAssets.addBlueIcon),
                                  SizedBox(width: SizeConfig.size4),
                                  CustomText(
                                    AppStrings.addPhoto.tr,
                                    color: AppColors.primaryColor,
                                    fontSize: SizeConfig.large,
                                  ),
                                ],
                              ),
                            )),
                      SizedBox(height: SizeConfig.size15),

                      Obx(() => controller.isAddMoreTextBox.value
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      AppStrings.moreDetails.tr,
                                      fontSize: SizeConfig.medium,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.moreTextController.clear();
                                        controller.isAddMoreTextBox.value =
                                            false;
                                        setState(() {});
                                      },
                                      child: CustomText(
                                        AppStrings.remove.tr,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: SizeConfig.size10),
                                CommonTextField(
                                  hintText: AppStrings.moreDetails.tr,
                                  textEditController:
                                      controller.moreTextController,
                                  maxLine: 3,
                                ),
                                SizedBox(height: SizeConfig.size15),
                              ],
                            )
                          : InkWell(
                              onTap: () =>
                                  controller.isAddMoreTextBox.value = true,
                              child: Row(
                                children: [
                                  LocalAssets(
                                      imagePath: AppIconAssets.addBlueIcon),
                                  SizedBox(width: SizeConfig.size4),
                                  CustomText(
                                    AppStrings.addMoreTextBox.tr,
                                    color: AppColors.primaryColor,
                                    fontSize: SizeConfig.large,
                                  ),
                                ],
                              ),
                            )),
                      SizedBox(height: SizeConfig.size22),

                      // Save / Update Button
                      CustomBtn(
                        title: widget.isEdit ? AppStrings.update.tr : AppStrings.save.tr,
                        isValidate: isValid,
                        onTap: isValid
                            ? () async {
                                Map<String, dynamic>? date;
                                if (controller.isAddDate.value &&
                                    controller.selectedDay != null &&
                                    controller.selectedMonth != null &&
                                    controller.selectedYear != null) {
                                  date = {
                                    'date': controller.selectedDay,
                                    'month': controller.selectedMonth,
                                    'year': controller.selectedYear,
                                  };
                                } else {
                                  date = null;
                                }

                                final additionalDesc = controller
                                        .isAddMoreTextBox.value
                                    ? controller.moreTextController.text.trim()
                                    : ''; // empty string to clear

                                final imagePath = controller.isAddPhoto.value
                                    ? controller.selectedImagePath ?? ''
                                    : ''; // empty string or null

                                final inputParams = {
                                  'title':
                                      controller.titleController.text.trim(),
                                  'info': controller.infoController.text.trim(),
                                  'additionalDesc': additionalDesc,
                                };

                                if (widget.isEdit && widget.infoId != null) {
                                  await controller.updateAdditionalInfo(
                                    widget.infoId!,
                                    inputParams,
                                    // photoPath: imagePath,
                                    date: date,
                                  );
                                } else {
                                  await controller.addAdditionalInfo(
                                    inputParams,
                                    photoPath: imagePath,
                                    date: date,
                                  );
                                }
                                Navigator.pop(context);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
