import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/social/controller/social_activity_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialActivityFormScreen extends StatelessWidget {
  final controller = Get.find<SocialActivityController>();

  SocialActivityFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.socialDetails),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Upload ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(AppStrings.uploadPhotos,
                                  fontWeight: FontWeight.w600,
                                  fontSize: SizeConfig.medium),
                              const SizedBox(height: 2),
                              CustomText("Add a photo for this activity",
                                  color: AppColors.secondaryTextColor,
                                  fontSize: SizeConfig.small),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() => _buildImageSection(context)),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Activity Info ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.volunteer_activism,
                              color: AppColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        CustomText("Activity Info",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      textEditController: controller.titleController,
                      title: AppStrings.activityTitle,
                      hintText: "E.g. Free Health Check-up Camp...",
                      onChange: (val) {
                        controller.activityTitle.value = val;
                      },
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      return AiDescriptionField(
                        label: AppStrings.descriptionMessage,
                        hintText:
                            "Free medicines & doctor consultation",
                        controller: controller.descriptionController,
                        rxValue: "".obs,
                        aiType: "Activity",
                        aiData: {
                          "title": controller.activityTitle.value
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    CommonTextField(
                      textEditController: controller.typeController,
                      title: AppStrings.activityType,
                      hintText: "E.g. Health Camp, Education...",
                      onChange: (val) {
                        controller.activityType.value = val;
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Date & Location ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_month,
                              color: AppColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        CustomText("Date & Location",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDateRow(AppStrings.date),
                    const SizedBox(height: 16),
                    CommonLocationSearchField(
                      controller: controller.venueController,
                      hintText: "E.g. Lucknow, Uttar Pradesh...",
                      isShowLeading: false,
                      title: AppStrings.location,
                      onSelected:
                          (placeId, lat, lng, address) async {
                        controller.venueController.text = address;
                        try {
                          final detailsResponse = await PlaceRepo()
                              .getCompletePlaceDetails(
                                  placeId: placeId);
                          final detailsData =
                              detailsResponse.response?.data;
                          final placeDetails =
                              PlaceDetailsResponse.fromJson(
                                  detailsData);
                          controller.lat.value = placeDetails.result
                                  ?.geometry?.location?.lat ??
                              0.0;
                          controller.lng.value = placeDetails.result
                                  ?.geometry?.location?.lng ??
                              0.0;
                        } catch (e) {
                          debugPrint(
                              "Error fetching place details: $e");
                        }
                        controller.validateForm();
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Role & Impact ---
            CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.groups_outlined,
                              color: AppColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        CustomText("Role & Impact",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      textEditController: controller.roleController,
                      title: AppStrings.yourRole,
                      hintText: "E.g. Organizer, Chief Guest...",
                      onChange: (val) {
                        controller.activityRole.value = val;
                      },
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      textEditController:
                          controller.organizerController,
                      title: AppStrings.organizerName,
                      hintText: "E.g. Organization Name...",
                      onChange: (val) {
                        controller.activityOrganizer.value = val;
                      },
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      return AiDescriptionField(
                        label: AppStrings.beneficiariesImpact,
                        hintText:
                            "E.g. 80 villagers / 1.2K Peoples benefited...",
                        controller: controller.impactController,
                        rxValue: "".obs,
                        aiType: "Beneficiaries",
                        maxChars: 140,
                        aiData: {
                          "title": controller.activityTitle.value,
                          "role": controller.activityRole.value,
                          "activityType":
                              controller.activityType.value,
                          "organizer":
                              controller.activityOrganizer.value
                        },
                        onChanged: (_) =>
                            controller.validateForm(),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Save Button ---
            Obx(() {
              return CustomBtn(
                isValidate: controller.isFormValid.value,
                isLoading: controller.isSaving.value,
                onTap: controller.isFormValid.value
                    ? (controller.isSaving.value
                        ? null
                        : controller.save)
                    : null,
                title: AppStrings.save,
              );
            }),
            SizedBox(height: SizeConfig.size20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    if (controller.selectedImage.value != null) {
      return CommonImageUploadTile(
        imageFile: controller.selectedImage,
        onImageRemove: () {
          controller.selectedImage.value = null;
          controller.serverImageUrl.value = null;
          controller.validateForm();
        },
        title: '',
        context: context,
      );
    } else if (controller.serverImageUrl.value != null &&
        controller.serverImageUrl.value!.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              controller.serverImageUrl.value!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: InkWell(
              onTap: () {
                controller.selectedImage.value = null;
                controller.serverImageUrl.value = null;
                controller.validateForm();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return CommonImageUploadTile(
      title: AppStrings.uploadPhotos,
      context: context,
      onImageSelected: () async {
        final path = await CommonImageUploadTile.pickImage(
            context: context);
        if (path != null) {
          controller.selectedImage.value = File(path);
          controller.validateForm();
        }
      },
      onImageRemove: () {
        controller.selectedImage.value = null;
        controller.serverImageUrl.value = null;
        controller.validateForm();
      },
      imageFile: controller.selectedImage,
    );
  }

  Widget _buildDateRow(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label,
            fontSize: 14, fontWeight: FontWeight.w400),
        const SizedBox(height: 8),
        Obx(() => NewDatePicker(
              selectedDay: controller.startDay.value,
              selectedMonth: controller.startMonth.value,
              selectedYear: controller.startYear.value,
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
      ],
    );
  }
}
