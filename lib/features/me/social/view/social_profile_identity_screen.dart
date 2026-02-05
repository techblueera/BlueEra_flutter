import 'package:BlueEra/features/me/social/controller/profile_identity_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialProfileIdentityScreen extends StatelessWidget {
  final controller = Get.put(ProfileIdentityController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Profile Identity",
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
                      label: "Short Bio",
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
                      label: "Your Journey",
                      hintText: "Share your experience...",
                      controller: controller.journeyController,
                      rxValue: controller.journeyRx,
                      aiType: "Journey",
                      aiData: {"name": "User Name"},
                    ),
                    const SizedBox(height: 20),

                    // Location Search Field
                    const Text("Location",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    CommonLocationSearchField(
                      controller: controller.locationController,
                      hintText: "E.g. Lucknow, Uttar Pradesh...",
                      isShowLeading: false,
                      title: "Search Your Profile On Google",
                      onSelected: (placeId, lat, lng, address) async {
                        controller.locationController.text = address;
                        controller.lat.value = lat;
                        controller.lng.value = lng;
                        // Basic trigger for validation logic if needed
                      },
                    ),

                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add Family Background"),
                    ),

                    const SizedBox(height: 30),

                    // Responsive Save Button
                    Obx(() {
                      return CustomBtn(
                        onTap: controller.isFormValid.value
                            ? () => controller.validateAndSave()
                            : null,
                        isValidate:controller.isFormValid.value ,
                        title: controller.isEditMode.value ? "Update" : "Save",
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
