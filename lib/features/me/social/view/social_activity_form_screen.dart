import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/social/controller/social_activity_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialActivityFormScreen extends StatelessWidget {
  final controller = Get.put(SocialActivityController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: "Social Details",),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: CommonCardWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUploadPlaceholder(),
              const SizedBox(height: 16),

              CommonTextField(
                textEditController: controller.titleController,
                title: "Activity Title",
                hintText: "E.g. Free Health Check-up Camp...",
              ),
              const SizedBox(height: 16),

              AiDescriptionField(
                label: "Description of Message",
                hintText: "Free medicines & doctor consultation",
                controller: controller.descriptionController,
                rxValue: "".obs,
                aiType: "Activity",
                aiData: {"title": controller.titleController.text},
              ),
              const SizedBox(height: 16),
              CommonTextField(
                textEditController: controller.typeController,
                title: "Activity type",
                hintText: "E.g. Free Health Check-up Camp...",
              ),
              const SizedBox(height: 16),
              _buildDateRow("Date"),
              const SizedBox(height: 16),


              CommonLocationSearchField(
                controller: controller.venueController,
                hintText: "E.g. Lucknow, Uttar Pradesh...",
                isShowLeading: false,
                title: AppStrings.location,
                onSelected: (placeId, lat, lng, address) async {
                  controller.venueController.text = address;
                  controller.lat.value = lat;
                  controller.lng.value = lng;
                  // Basic trigger for validation logic if needed
                },
              ),
              const SizedBox(height: 16),

              CommonTextField(
                textEditController: controller.roleController,
                title: "Your Role",
                hintText: "E.g. Organizer, Chief Guest...",
              ),
              const SizedBox(height: 30),  CommonTextField(
                textEditController: controller.organizerController,
                title: "Organizer Name",
                hintText: "E.g. Organizer, Chief Guest...",
              ),
              const SizedBox(height: 16),

              AiDescriptionField(
                label: "Beneficiaries/Impact (Forecast)",
                hintText: "E.g. 80 villagers / 1.2K Peoples / 99 KM Are Beneficiaries ....",
                controller: controller.impactController,
                rxValue: "".obs,
                aiType: "Beneficiaries",maxChars: 140,
                aiData: {"title": controller.titleController.text},
              ),
              const SizedBox(height: 30),

              // DYNAMIC BUTTON
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isFormValid.value ? () => print("Submit") : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Continue", style: TextStyle(color: Colors.white)),
                ),
              )),

              // const SizedBox(height: 70),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: Colors.grey),
          SizedBox(width: 8),
          Text("Upload Photos", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontSize: 14, fontWeight: FontWeight.w400),
        const SizedBox(height: 8),
        NewDatePicker(
          selectedDay: controller.startDay.value,
          selectedMonth: controller.startMonth.value,
          selectedYear: controller.startYear.value,
          onDayChanged: (v) { controller.startDay.value = v!; controller.validateForm(); },
          onMonthChanged: (v) { controller.startMonth.value = v!; controller.validateForm(); },
          onYearChanged: (v) { controller.startYear.value = v!; controller.validateForm(); },
        ),
      ],
    );
  }
}