import 'dart:io';

import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/basic_profile_controller.dart';
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
  final controller = Get.find<ProfileController>();

  @override
  void initState() {
    // TODO: implement initState
    controller.clearBasicProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Basic Profile"),
      // Replace with your standard AppBar
      body: CommonCardWidget(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Image Upload
              const CustomText("Upload Profile Photo",
                  fontWeight: FontWeight.w500),
              const SizedBox(height: 10),
              Center(
                child: Obx(() => CommonProfileImage(
                      imagePath: controller.selectedImage.value?.path ?? "",
                      dialogTitle: "Upload Picture",
                      onImageUpdate: (path) {
                        controller.selectedImage.value = File(path);
                      },
                      isOwnProfile: true,
                      showProfileBorder: true,
                      borderColor: AppColors.primaryColor,
                    )),
              ),

              const SizedBox(height: 24),

              // 2. Full Name
              CommonTextField(
                title: "Full Name",
                textEditController: controller.nameController,
                hintText: "E.g. Virendra Kishor",
              ),
              const SizedBox(height: 16),

              // 3. Professional Title
              CommonTextField(
                title: "Professional Title",
                textEditController: controller.titleController,
                hintText: "E.g. Ramesh Bhagat",
              ),
              const SizedBox(height: 16),

              // 4. Short Tagline
              CommonTextField(
                title: "Short Tagline",
                textEditController: controller.taglineController,
                hintText: "E.g. Tax & Compliance Expert for SMEs....",
              ),
              const SizedBox(height: 16),

              // 5. Location
              CommonLocationSearchField(
                controller: controller.locationController,
                title: "Location",
                isShowLeading: false,
                onSelected: (placeId, lat, lng, address) async {
                  controller.locationController.text = address;
                  // Fetch and auto-fill details
                  try {
                    final detailsResponse = await PlaceRepo()
                        .getCompletePlaceDetails(placeId: placeId);
                    final detailsData = detailsResponse.response?.data;
                    final placeDetails =
                        PlaceDetailsResponse.fromJson(detailsData);
                    controller.selectedLat =
                        placeDetails.result?.geometry?.location?.lat ?? 0.0;
                    controller.selectedLng =
                        placeDetails.result?.geometry?.location?.lng ?? 0.0;
                  } catch (e) {
                    print("Error fetching place details: $e");
                  }
                },
              ),

              const SizedBox(height: 16),

              // 6. Languages Spoken Dropdown
              const CustomText("Languages Spoken",
                  color: AppColors.mainTextColor),
              const SizedBox(height: 10),
              Obx(() => CommonDropdownDialog<String>(
                    title: "Select Language",
                    hintText: "E.g. English",
                    items: controller.indianLanguages,
                    selectedValue: controller.selectedLanguage.value.isEmpty
                        ? null
                        : controller.selectedLanguage.value,
                    displayValue: (lang) => lang,
                    onChanged: (value) => controller.onLanguageChanged(value),
                  )),

              const SizedBox(height: 40),

              // 7. Save Button
              Obx(() => CustomBtn(
                    title: "Save",
                    isValidate: controller.isBasicValid.value,
                    onTap: controller.isBasicValid.value
                        ? () => controller.saveProfile()
                        : null,
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
