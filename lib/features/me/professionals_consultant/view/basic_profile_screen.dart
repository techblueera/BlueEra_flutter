import 'dart:io';

import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BasicProfileScreen extends StatefulWidget {
  BasicProfileScreen({super.key});

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  final controller = Get.find<AiProfessionalsController>();

  @override
  void initState() {
    controller.clearBasicProfile();
    BasicDetails? basicDetails =
        controller.getProfessionalServiceRes?.value.data?.basicDetails;
    controller.selectedImage.value =
        File(basicDetails?.profilePhotoUrl ?? "");
    controller.nameController.text = basicDetails?.fullName ?? "";
    controller.titleController.text =
        basicDetails?.professionalTitle ?? "";
    controller.taglineController.text =
        basicDetails?.shortTagline ?? "";
    controller.locationController.text = basicDetails?.location ?? "";
    controller.selectedLanguage.value =
        basicDetails?.languagesSpoken?.firstOrNull ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.basicProfile.tr),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size14),
          child: Column(
            children: [
              // --- Profile Photo ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _sectionIcon(Icons.camera_alt_outlined,
                          AppStrings.proConsultProfilePhoto.tr, AppStrings.proConsultUploadProfessionalPhoto.tr),
                      const SizedBox(height: 16),
                      Center(
                        child: Obx(() => CommonProfileImage(
                              imagePath:
                                  controller.selectedImage.value?.path ??
                                      "",
                              dialogTitle: AppStrings.proConsultUploadPicture.tr,
                              onImageUpdate: (path) {
                                controller.selectedImage.value =
                                    File(path);
                                controller.isImageEdit.value = true;
                              },
                              isOwnProfile: true,
                              showProfileBorder: true,
                              borderColor: AppColors.primaryColor,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size14),

              // --- Personal Details ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionIcon(Icons.person_outline,
                          AppStrings.personalDetails.tr, AppStrings.proConsultYourNameAndTitle.tr),
                      const SizedBox(height: 16),
                      CommonTextField(
                        title: AppStrings.fullName,
                        textEditController: controller.nameController,
                        hintText: AppStrings.proConsultEgRajeshKumar.tr,
                      ),
                      const SizedBox(height: 16),
                      CommonTextField(
                        title: AppStrings.proConsultProfessionalTitle.tr,
                        textEditController:
                            controller.titleController,
                        hintText: AppStrings.proConsultEgFinanceTaxConsultant.tr,
                      ),
                      const SizedBox(height: 16),
                      CommonTextField(
                        title: AppStrings.proConsultShortTagline.tr,
                        textEditController:
                            controller.taglineController,
                        hintText:
                            AppStrings.proConsultEgTaxComplianceExpert.tr,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size14),

              // --- Location & Language ---
              CommonCardWidget(
                padding: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionIcon(Icons.location_on_outlined,
                          AppStrings.proConsultLocationLanguage.tr, AppStrings.proConsultWhereBased.tr),
                      const SizedBox(height: 16),
                      CommonLocationSearchField(
                        controller: controller.locationController,
                        title: AppStrings.location,
                        isShowLeading: false,
                        onSelected:
                            (placeId, lat, lng, address) async {
                          controller.locationController.text = address;
                          try {
                            final detailsResponse = await PlaceRepo()
                                .getCompletePlaceDetails(
                                    placeId: placeId);
                            final detailsData =
                                detailsResponse.response?.data;
                            final placeDetails =
                                PlaceDetailsResponse.fromJson(
                                    detailsData);
                            controller.selectedLat = placeDetails
                                    .result
                                    ?.geometry
                                    ?.location
                                    ?.lat ??
                                0.0;
                            controller.selectedLng = placeDetails
                                    .result
                                    ?.geometry
                                    ?.location
                                    ?.lng ??
                                0.0;
                          } catch (e) {
                            debugPrint(
                                "Error fetching place details: $e");
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomText(AppStrings.proConsultLanguagesSpoken.tr,
                          color: AppColors.mainTextColor),
                      const SizedBox(height: 10),
                      Obx(() => CommonDropdownDialog<String>(
                            title: AppStrings.selectLanguage.tr,
                            hintText: AppStrings.proConsultEgEnglish.tr,
                            items: controller.indianLanguages,
                            selectedValue: controller
                                    .selectedLanguage.value.isEmpty
                                ? null
                                : controller.selectedLanguage.value,
                            displayValue: (lang) => lang,
                            onChanged: (value) =>
                                controller.onLanguageChanged(value),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- Save ---
              Obx(() => CustomBtn(
                    title: AppStrings.save.tr,
                    isValidate: controller.isBasicValid.value,
                    onTap: controller.isBasicValid.value
                        ? () => controller.saveProfile()
                        : null,
                  )),
              SizedBox(height: SizeConfig.size20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionIcon(
      IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(icon, color: AppColors.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(title,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.medium),
              const SizedBox(height: 2),
              CustomText(subtitle,
                  color: AppColors.secondaryTextColor,
                  fontSize: SizeConfig.small),
            ],
          ),
        ),
      ],
    );
  }
}
