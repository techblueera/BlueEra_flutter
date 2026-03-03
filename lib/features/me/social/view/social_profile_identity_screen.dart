import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title:AppStrings.profileIdentity
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: CommonCardWidget(
              padding: 0,
              child: Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Short Bio Field
                    AiDescriptionField(
                      label: AppStrings.shortBio,
                      hintText: "Tell us more about info...",
                      controller: controller.bioController,
                      rxValue: controller.bioRx,
                      aiType: "Short Bio",
                      aiData: {
                        "name": "User Name"
                      }, // Replace with actual user data
                    ),
                    const SizedBox(height: 20),

                    // Your Journey Field
                    AiDescriptionField(
                      label:AppStrings.journey,
                      hintText: "Share your experience...",
                      controller: controller.journeyController,
                      rxValue: controller.journeyRx,
                      aiType: "Journey",
                      aiData: {"name": "User Name"},
                    ),
                    const SizedBox(height: 20),

                    // Location Search Field
                    const CustomText(AppStrings.location,
                     fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    CommonLocationSearchField(
                      controller: controller.locationController,
                      hintText: "E.g. Lucknow, Uttar Pradesh...",
                      isShowLeading: false,
                      title: "Search Your Profile On Google",
                      onSelected: (placeId, lat, lng, address) async {
                        controller.locationController.text = address;

                        try {
                          final detailsResponse = await PlaceRepo()
                              .getCompletePlaceDetails(placeId: placeId);
                          final detailsData = detailsResponse.response?.data;
                          final placeDetails =
                          PlaceDetailsResponse.fromJson(detailsData);
                          controller.lat.value =
                              placeDetails.result?.geometry?.location?.lat ??
                                  0.0;
                          controller.lng.value =
                              placeDetails.result?.geometry?.location?.lng ??
                                  0.0;
                        } catch (e) {
                          print("Error fetching place details: $e");
                        }
                        // Basic trigger for validation logic if needed
                      },
                    ),

                    const SizedBox(height: 10),
                    // TextButton.icon(
                    //   onPressed: () {},
                    //   icon: const Icon(Icons.add, size: 18),
                    //   label: const Text("Add Family Background"),
                    // ),
// 1. The Header / Toggle Button
                    Obx(() {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const CustomText(
                                AppStrings.familyBackground,
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              if (!controller.isAddingBackground.value)
                                TextButton.icon(
                                  onPressed: () {
                                    controller.isAddingBackground.value = true;
                                  },
                                  icon: const Icon(
                                      Icons.add_circle_outline, size: 18),
                                  label: const CustomText(AppStrings.add),
                                )
                              else
                                IconButton(
                                  icon: const Icon(
                                      Icons.close, color: Colors.red, size: 20),
                                  // onPressed: () => setState(() => isAddingBackground = false),
                                  onPressed: () {
                                    controller.isAddingBackground.value = false;
                                  },
                                ),
                            ],
                          ),
                          if (controller.isAddingBackground.value) ...[
                            const SizedBox(height: 10),
                            CommonTextField(
                              textEditController: controller
                                  .familyBackgroundController,
                              title: "",
                              hintText: "Tell us about your family...",
                              maxLine: 5,
                              maxLength: controller.maxChars,
                              isValidate: false,
                              keyBoardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              onChange: (value) {
                                // Logic: Prevent more than 2 consecutive newlines
                                String formatted = value.replaceAll(
                                    RegExp(r'\n{3,}'), '\n\n');
                                if (formatted != value) {
                                  controller.familyBackgroundController.text =
                                      formatted;
                                  controller.familyBackgroundController.selection =
                                      TextSelection.fromPosition(
                                        TextPosition(offset: controller
                                            .familyBackgroundController.text.length),
                                      );
                                }
                                controller.rxValue.value = formatted;
                              },
                            ),
                          ],
                        ],
                      );
                    }),

                    // 2. The Conditional TextField

                    const SizedBox(height: 30),

                    // Responsive Save Button
                    Obx(() {
                      return CustomBtn(
                        onTap: controller.isFormValid.value
                            ? () => controller.validateAndSave()
                            : null,
                        isValidate: controller.isFormValid.value,
                        isLoading: controller.isLoading.value,
                        title: controller.isEditMode.value ? AppStrings.update.tr : AppStrings.save.tr,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
