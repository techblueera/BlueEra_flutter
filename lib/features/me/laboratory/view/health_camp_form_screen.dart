import 'dart:io';

import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/health_camp_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_check_box.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthCampFormScreen extends StatefulWidget {
  final HealthCamp? existing;

  const HealthCampFormScreen({super.key, this.existing});

  @override
  State<HealthCampFormScreen> createState() => _HealthCampFormScreenState();
}

class _HealthCampFormScreenState extends State<HealthCampFormScreen> {
  late final HealthCampController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<HealthCampController>()) {
      controller = Get.put(HealthCampController(), permanent: true);
    } else {
      controller = Get.find<HealthCampController>();
    }
    controller.preloadForm(widget.existing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.existing == null
              ? AppStrings.createHealthCamp.tr
              : AppStrings.editHealthCamp.tr),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextField(
                textEditController: controller.typeController,
                title: AppStrings.activityType.tr,
                hintText: AppStrings.egFreeHealthCheckup.tr,
                onChange: (val) {
                  controller.activityType.value = val;
                  controller.validateForm();
                },
              ),
              SizedBox(height: SizeConfig.size16),
              CommonTextField(
                textEditController: controller.descController,
                title: AppStrings.description.tr,
                hintText: AppStrings.describeTheCamp.tr,
                maxLine: 4,
                onChange: (val) => controller.validateForm(),
              ),
              SizedBox(height: SizeConfig.size16),
              CommonTextField(
                textEditController: controller.sqFootController,
                title: AppStrings.sqFoot.tr,
                hintText: "E.g. 200",
                keyBoardType: TextInputType.number,
                onChange: (val) => controller.validateForm(),
              ),
              SizedBox(height: SizeConfig.size16),
              Row(
                children: [

                  Expanded(
                    child: CommonTextField(
                      textEditController: controller.priceController,
                      title: AppStrings.price.tr,
                      hintText: "E.g. 499",
                      keyBoardType: TextInputType.number,
                      onChange: (val) => controller.validateForm(),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CommonTextField(
                      textEditController: controller.discountPriceController,
                      title: AppStrings.discountPrice.tr,
                      hintText: "E.g. 399",
                      keyBoardType: TextInputType.number,
                      onChange: (val) => controller.validateForm(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size16),
              CustomText(AppStrings.startDate.tr,
                  fontSize: 12, fontWeight: FontWeight.w400),
              SizedBox(height: SizeConfig.size8),
              Obx(() => NewDatePicker(
                    selectedDay: controller.startDay.value,
                    selectedMonth: controller.startMonth.value,
                    selectedYear: controller.startYear.value,
                    isFutureYear: true,
                    onDayChanged: (v) {
                      controller.startDay.value = v!;
                      controller.validateForm();
                    },
                    onMonthChanged: (v) {
                      controller.startMonth.value = v!;
                      controller.validateForm();
                    },
                    onYearChanged: (v) {
                      controller.startYear.value = v!;
                      controller.validateForm();
                    },
                  )),
              SizedBox(height: SizeConfig.size16),
              CustomText(AppStrings.endDate.tr, fontSize: 12, fontWeight: FontWeight.w400),
              SizedBox(height: SizeConfig.size8),
              Obx(() => NewDatePicker(
                    selectedDay: controller.endDay.value,
                    selectedMonth: controller.endMonth.value,
                    selectedYear: controller.endYear.value,
                    isFutureYear: true,
                    onDayChanged: (v) {
                      controller.endDay.value = v!;
                      controller.validateForm();
                    },
                    onMonthChanged: (v) {
                      controller.endMonth.value = v!;
                      controller.validateForm();
                    },
                    onYearChanged: (v) {
                      controller.endYear.value = v!;
                      controller.validateForm();
                    },
                  )),
              SizedBox(height: SizeConfig.size16),
              _buildSingleTimeDropdown(AppStrings.startTime.tr, controller.selectedTime),
              SizedBox(height: SizeConfig.size16),
              CommonLocationSearchField(
                controller: controller.searchController,
                hintText: "E.g. Happy Health Club...",
                isShowLeading: false,
                title: "Search Your Location On Google",
                onSelected: (placeId, lat, lng, address) async {
                  controller.searchController.text = address;
                  //
                  try {
                    final detailsResponse = await PlaceRepo()
                        .getCompletePlaceDetails(placeId: placeId);
                    final detailsData = detailsResponse.response?.data;
                    final placeDetails =
                    PlaceDetailsResponse.fromJson(detailsData);
                    // controller.lat.value=placeDetails.result?.geometry?.location?.lat??0.0;
                    // controller.lng.value=placeDetails.result?.geometry?.location?.lng??0.0;
                    // logs(
                    //     "placeDetails.result?.website ${placeDetails.result?.website}");
                  } catch (e) {
                    print("Error fetching place details: $e");
                  }
                  //
                  // validateAiSchoolForm();
                  // setstate(() {});
                },
              ),

              SizedBox(height: SizeConfig.size16),
              _buildImageUploadSection(),
              SizedBox(height: SizeConfig.size16),
              _buildTestCategorySection(),
              SizedBox(height: SizeConfig.size20),
              Obx(() => CustomBtn(
                    title: widget.existing == null ? AppStrings.create.tr : AppStrings.update.tr,
                    isValidate: controller.isValid.value,
                    isLoading: controller.isLoading.value,
                    onTap: controller.isValid.value
                        ? () async {
                            bool ok;
                            if (widget.existing == null) {
                              ok = await controller.createCamp();
                            } else {
                              ok =
                                  await controller.updateCamp(widget.existing!);
                            }
                            if (ok) Get.back();
                          }
                        : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              AppStrings.campImages.tr,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            Obx(() => CustomText(
                  "${controller.selectedImages.length}/${controller.maxImages}",
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyA5,
                )),
          ],
        ),
        SizedBox(height: SizeConfig.size8),
        Obx(() => Wrap(
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size8,
              children: [
                ...List.generate(controller.selectedImages.length, (index) {
                  return _buildImageTile(controller.selectedImages[index], index);
                }),
                if (controller.selectedImages.length < controller.maxImages)
                  _buildAddImageTile(),
              ],
            )),
        SizedBox(height: SizeConfig.size4),
        Obx(() => controller.selectedImages.isEmpty
            ? CustomText(
                AppStrings.minOneImageRequired.tr,
                fontSize: 10,
                color: AppColors.red,
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildImageTile(File imageFile, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            imageFile,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => controller.removeImage(index),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: () async {
        final remaining =
            controller.maxImages - controller.selectedImages.length;
        if (remaining <= 0) return;
        final paths = await SelectProductImageDialog.showLogoDialog(
          context,
          AppStrings.addImages.tr,
          maxImages: remaining,
        );
        if (paths != null && paths.isNotEmpty) {
          controller.addImages(paths);
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyE5, width: 1),
        ),
        child: const Icon(
          Icons.add_a_photo_outlined,
          color: AppColors.greyA5,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTestCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.testOffers.tr,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        SizedBox(height: SizeConfig.size8),
        GestureDetector(
          onTap: () => _showTestCategoryBottomSheet(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(width: 1, color: AppColors.greyE5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => controller.selectedTestCategories.isEmpty
                      ? CustomText(
                          AppStrings.selectCategory.tr,
                          fontSize: 12,
                          color: AppColors.greyA5,
                        )
                      : CustomText(
                          controller.selectedTestCategories.take(1).join(", "),
                          fontSize: 12,
                          maxLines: 2,
                        )),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size8),
        Obx(() => Wrap(
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size4,
              children: controller.selectedTestCategories
                  .map((cat) => Chip(
                        label: CustomText(cat, fontSize: 11),
                        deleteIcon:
                            const Icon(Icons.close, size: 14),
                        onDeleted: () =>
                            controller.toggleTestCategory(cat),
                        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  void _showTestCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(SizeConfig.size16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.selectCategory.tr,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: CustomText(
                          AppStrings.done.tr,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...controller.testCategoryOptions.map((category) {
                  return Obx(() {
                    final isSelected =
                        controller.selectedTestCategories.contains(category);
                    return InkWell(
                      onTap: () => controller.toggleTestCategory(category),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16,
                          vertical: SizeConfig.size12,
                        ),
                        child: Row(
                          children: [
                            CustomCheckBox(
                              isChecked: isSelected,
                              onChanged: () =>
                                  controller.toggleTestCategory(category),
                              size: 22,
                              borderColor: AppColors.greyE5,
                            ),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(
                              child: CustomText(
                                category,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                }),
                SizedBox(height: SizeConfig.size20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleTimeDropdown(String label, RxString selectedValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontSize: 12, fontWeight: FontWeight.w400),
        const SizedBox(height: 8),
        Obx(() => SizedBox(
              width: double.infinity,
              child: _buildDropdown(controller.timeSlots, selectedValue.value,
                  (val) {
                selectedValue.value = val!;
                controller.validateForm();
              }),
            )),
      ],
    );
  }

  Widget _buildDropdown(
      List<String> items, String currentValue, Function(String?) onChanged) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: AppColors.greyE5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : null,
          hint: CustomText(AppStrings.selectStartTime.tr),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.mainTextColor,
          ),
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: AppConstants.OpenSans,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: CustomText(
                value,
                fontSize: 12,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
