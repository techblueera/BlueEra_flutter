import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/features/me/social/controller/social__event_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialCreateEventScreen extends StatelessWidget {
  final controller = Get.find<SocialEventController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: controller.eventId == null ? "Create Event" : "Update Event",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonTextField(
              textEditController: controller.titleController,
              title: "Event Title",
              hintText: "E.g. Virendra Kishor",
            ),
            const SizedBox(height: 16),

            _buildSectionTitle("Starting Date"),
            _buildDatePicker(isStart: true),
            const SizedBox(height: 16),

            _buildSectionTitle("End Date"),
            _buildDatePicker(isStart: false),
            const SizedBox(height: 16),

            const CustomText("Time", fontWeight: FontWeight.bold),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSingleTimeDropdown(
                      "From", controller.selectedFromTime),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child:
                      _buildSingleTimeDropdown("To", controller.selectedToTime),
                ),
              ],
            ),
            const SizedBox(height: 16),

            CommonLocationSearchField(
              controller: controller.venueController,
              hintText: "E.g. Lucknow, Uttar Pradesh...",
              isShowLeading: false,
              title: "Venue",
              onSelected: (placeId, lat, lng, address) async {
                controller.venueController.text = address;
                try {
                  final detailsResponse = await PlaceRepo()
                      .getCompletePlaceDetails(placeId: placeId);
                  final detailsData = detailsResponse.response?.data;
                  final placeDetails =
                      PlaceDetailsResponse.fromJson(detailsData);
                  controller.lat.value =
                      placeDetails.result?.geometry?.location?.lat ?? 0.0;
                  controller.lng.value =
                      placeDetails.result?.geometry?.location?.lng ?? 0.0;
                } catch (e) {
                  print("Error fetching place details: $e");
                }
              },
            ),
            const SizedBox(height: 16),

            CommonTextField(
              textEditController: controller.eventTypeController,
              title: "Event Type",
              hintText: "E.g. Meeting / Show / Live..",
            ),
            const SizedBox(height: 16),

            HttpsTextField(
              title: "Registration Link",
              controller: controller.linkController,
              hintText: "E.g. https://registrationlink..",
            ),
            const SizedBox(height: 30),

            // REACTIVE BUTTON
            Obx(() => Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : (controller.isFormValid.value
                                ? () => controller.saveEvent()
                                : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.isLoading.value
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : CustomText(
                                controller.eventId == null ? "Save" : "Update",

                                    color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CustomText(title,
          fontWeight: FontWeight.w500, color: Colors.black87),
    );
  }

  Widget _buildDatePicker({required bool isStart}) {
    return Obx(() {
      return NewDatePicker(
        selectedDay:
            isStart ? controller.startDay.value : controller.endDay.value,
        selectedMonth:
            isStart ? controller.startMonth.value : controller.endMonth.value,
        selectedYear:
            isStart ? controller.startYear.value : controller.endYear.value,
        onDayChanged: (val) {
          isStart
              ? controller.startDay.value = val!
              : controller.endDay.value = val!;
          controller.validateForm();
        },
        onMonthChanged: (val) {
          isStart
              ? controller.startMonth.value = val!
              : controller.endMonth.value = val!;
          controller.validateForm();
        },
        onYearChanged: (val) {
          isStart
              ? controller.startYear.value = val!
              : controller.endYear.value = val!;
          controller.validateForm();
        },
      );
    });
  }

  Widget _buildSingleTimeDropdown(String label, RxString selectedValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontSize: 12, fontWeight: FontWeight.w400),
        const SizedBox(height: 8),
        Obx(() => Container(
              width: double.infinity, // Makes it responsive
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
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : null,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.mainTextColor,
          ),
          isDense: true,
          style: TextStyle(
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