import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/profile_identity_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialProfileIdentityScreen extends StatelessWidget {
  final controller = Get.put(ProfileIdentityController());

  SocialProfileIdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.profileIdentity),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: controller.formKey,
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.size14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Step Indicator ---
                  _buildStepIndicator(),
                  SizedBox(height: SizeConfig.size20),

                  // --- Short Bio Section ---
                  _buildSectionCard(
                    icon: Icons.person_outline,
                    title: AppStrings.shortBio,
                    subtitle: "Tell people who you are in a few words",
                    child: AiDescriptionField(
                      label: "",
                      hintText: "Tell us about yourself...",
                      controller: controller.bioController,
                      rxValue: controller.bioRx,
                      maxChars: 180,
                      aiType: "Short Bio",
                      aiData: {"name": "User Name"},
                    ),
                  ),
                  SizedBox(height: SizeConfig.size14),

                  // --- Journey Section ---
                  _buildSectionCard(
                    icon: Icons.timeline,
                    title: AppStrings.journey,
                    subtitle: "Share your life journey and experiences",
                    child: AiDescriptionField(
                      label: "",
                      hintText: "Share your journey & experiences...",
                      controller: controller.journeyController,
                      rxValue: controller.journeyRx,
                      aiType: "Journey",
                      aiData: {"name": "User Name"},
                    ),
                  ),
                  SizedBox(height: SizeConfig.size14),

                  // --- Location Section ---
                  _buildSectionCard(
                    icon: Icons.location_on_outlined,
                    title: AppStrings.location,
                    subtitle: "Help people find you on Google",
                    child: CommonLocationSearchField(
                      controller: controller.locationController,
                      hintText: "E.g. Lucknow, Uttar Pradesh...",
                      isShowLeading: false,
                      title: "",
                      onSelected: (placeId, lat, lng, address) async {
                        controller.locationController.text = address;
                        try {
                          final detailsResponse = await PlaceRepo()
                              .getCompletePlaceDetails(placeId: placeId);
                          final detailsData =
                              detailsResponse.response?.data;
                          final placeDetails =
                              PlaceDetailsResponse.fromJson(detailsData);
                          controller.lat.value = placeDetails
                                  .result?.geometry?.location?.lat ??
                              0.0;
                          controller.lng.value = placeDetails
                                  .result?.geometry?.location?.lng ??
                              0.0;
                        } catch (e) {
                          debugPrint("Error fetching place details: $e");
                        }
                      },
                    ),
                  ),
                  SizedBox(height: SizeConfig.size14),

                  // --- Family Background Section ---
                  _buildSectionCard(
                    icon: Icons.family_restroom,
                    title: AppStrings.familyBackground,
                    subtitle: "Share about your family (optional)",
                    child: Obx(() {
                      if (!controller.isAddingBackground.value) {
                        return InkWell(
                          onTap: () =>
                              controller.isAddingBackground.value = true,
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline,
                                    size: 18,
                                    color: AppColors.primaryColor),
                                const SizedBox(width: 8),
                                CustomText(
                                  AppStrings.add,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => controller
                                    .isAddingBackground.value = false,
                                child: Icon(Icons.close,
                                    color: AppColors.red, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CommonTextField(
                            textEditController:
                                controller.familyBackgroundController,
                            title: "",
                            hintText: "Tell us about your family...",
                            maxLine: 5,
                            maxLength: controller.maxChars,
                            isValidate: false,
                            keyBoardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            onChange: (value) {
                              String formatted = value.replaceAll(
                                  RegExp(r'\n{3,}'), '\n\n');
                              if (formatted != value) {
                                controller.familyBackgroundController
                                    .text = formatted;
                                controller.familyBackgroundController
                                        .selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                      offset: controller
                                          .familyBackgroundController
                                          .text
                                          .length),
                                );
                              }
                              controller.rxValue.value = formatted;
                            },
                          ),
                        ],
                      );
                    }),
                  ),
                  SizedBox(height: SizeConfig.size30),

                  // --- Save Button ---
                  Obx(() {
                    return CustomBtn(
                      onTap: controller.isFormValid.value
                          ? () => controller.validateAndSave()
                          : null,
                      isValidate: controller.isFormValid.value,
                      isLoading: controller.isLoading.value,
                      title: controller.isEditMode.value
                          ? AppStrings.update.tr
                          : AppStrings.save.tr,
                    );
                  }),
                  SizedBox(height: SizeConfig.size20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              "Complete your social profile to help people know you better",
              color: AppColors.primaryColor,
              fontSize: SizeConfig.small,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return CommonCardWidget(
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
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      color: AppColors.primaryColor, size: 20),
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
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
