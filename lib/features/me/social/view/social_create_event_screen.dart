import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social__event_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialCreateEventScreen extends StatelessWidget {
  final controller = Get.find<SocialEventController>();

  SocialCreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: controller.eventId == null
            ? AppStrings.createEvent.tr
            : AppStrings.updateEvent.tr,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeConfig.size14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Event Info Section ---
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
                          child: Icon(Icons.event,
                              color: AppColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        CustomText("Event Details",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      textEditController: controller.titleController,
                      title: AppStrings.eventTitle,
                      hintText: "E.g. Annual Meet 2025",
                    ),
                    const SizedBox(height: 16),
                    CommonTextField(
                      textEditController: controller.eventTypeController,
                      title: AppStrings.eventType,
                      hintText: "E.g. Meeting / Show / Live...",
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Date & Time Section ---
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
                          child: Icon(Icons.calendar_today,
                              color: AppColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        CustomText("Date & Time",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomText(AppStrings.startingDate,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainTextColor),
                    const SizedBox(height: 8),
                    _buildDatePicker(isStart: true),
                    const SizedBox(height: 16),
                    CustomText(AppStrings.endDate,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainTextColor),
                    const SizedBox(height: 8),
                    _buildDatePicker(isStart: false),
                    const SizedBox(height: 16),
                    CustomText(AppStrings.time,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainTextColor),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSingleTimeDropdown(
                              AppStrings.from,
                              controller.selectedFromTime),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSingleTimeDropdown(
                              "To", controller.selectedToTime),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size14),

            // --- Venue & Link Section ---
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
                          child: Icon(Icons.location_on_outlined,
                              color: AppColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        CustomText("Venue & Registration",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CommonLocationSearchField(
                      controller: controller.venueController,
                      hintText: "E.g. Lucknow, Uttar Pradesh...",
                      isShowLeading: false,
                      title: AppStrings.venue,
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
                      },
                    ),
                    const SizedBox(height: 16),
                    HttpsTextField(
                      title: AppStrings.registrationLink,
                      controller: controller.linkController,
                      hintText: "E.g. https://registrationlink...",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Save Button ---
            Obx(() => CustomBtn(
                  onTap: controller.isLoading.value
                      ? null
                      : (controller.isFormValid.value
                          ? () => controller.saveEvent()
                          : null),
                  isValidate: controller.isFormValid.value,
                  isLoading: controller.isLoading.value,
                  title: controller.eventId == null
                      ? AppStrings.save.tr
                      : AppStrings.update.tr,
                )),
            SizedBox(height: SizeConfig.size20),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({required bool isStart}) {
    return Obx(() {
      return NewDatePicker(
        selectedDay:
            isStart ? controller.startDay.value : controller.endDay.value,
        selectedMonth: isStart
            ? controller.startMonth.value
            : controller.endMonth.value,
        selectedYear: isStart
            ? controller.startYear.value
            : controller.endYear.value,
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

  Widget _buildSingleTimeDropdown(
      String label, RxString selectedValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label,
            fontSize: 12, fontWeight: FontWeight.w400),
        const SizedBox(height: 8),
        Obx(() => SizedBox(
              width: double.infinity,
              child: _buildDropdown(
                  controller.timeSlots, selectedValue.value, (val) {
                selectedValue.value = val!;
                controller.validateForm();
              }),
            )),
      ],
    );
  }

  Widget _buildDropdown(List<String> items, String currentValue,
      Function(String?) onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : null,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: AppColors.mainTextColor),
          isDense: true,
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppConstants.OpenSans,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: CustomText(value, fontSize: 13),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
