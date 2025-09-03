import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/jobs/controller/interview_schedule_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:BlueEra/widgets/time_selection_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showInterviewScheduleDialog(BuildContext context,
    {required List<String> applicationId,
    required VoidCallback callBack,
    required String interviewId,
    bool? isReschedule}) {
  // Initialize controller
  final InterviewScheduleController controller =
      Get.put(InterviewScheduleController());

  controller.resetForm();
  showDialog(
    context: context,
    builder: (_) {
      return SafeArea(
        child: Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Obx(() => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              (isReschedule ?? false)
                                  ? "Reschedule Interview"
                                  : "Schedule Interview",
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.close),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Mode selection
                        const CustomText(
                          "Mode",
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        CommonDropdown<CommunicationMode?>(
                          items: CommunicationMode.values,
                          selectedValue: controller.communicationMode.value,
                          hintText: "Select Mode",
                          displayValue: (profession) =>
                              profession?.displayName ?? "",
                          onChanged: (value) {
                            controller.communicationMode.value =
                                value ?? CommunicationMode.IN_PERSON;
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select your Mode';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Venue or Online Meeting Link based on mode
                        if (controller.communicationMode.value?.displayName !=
                            'Online') ...[
                          CommonTextField(
                            title: "Other",
                            hintText: "Enter details (if other)",
                            isValidate: false,
                            onChange: (value) => controller.venue.value = value,
                          ),
                        ] else ...[
                          CommonTextField(
                            title: "Online Meeting Link",
                            hintText:
                                "Enter meeting link (e.g., Zoom, Google Meet)",
                            isValidate: false,
                            onChange: (value) =>
                                controller.onlineMeetingLink.value = value,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Date selection
                        const CustomText(
                          "Date",
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        NewDatePicker(
                          selectedDay: controller.selectedDay.value,
                          selectedMonth: controller.selectedMonth.value,
                          selectedYear: controller.selectedYear.value,
                          onDayChanged: (value) =>
                              controller.selectedDay.value = value,
                          onMonthChanged: (value) =>
                              controller.selectedMonth.value = value,
                          onYearChanged: (value) =>
                              controller.selectedYear.value = value,
                          isFutureYear: true,
                        ),
                        const SizedBox(height: 16),

                        // Start Time selection with dropdowns
                        const CustomText(
                          "Start Time",
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        TimeSelectionDropdown(
                          selectedHour: controller.startHour.value,
                          selectedMinute: controller.startMinute.value,
                          selectedPeriod: controller.startPeriod.value,
                          onHourChanged: (value) {
                            controller.startHour.value = value;
                            controller.updateStartTimeController();
                          },
                          onMinuteChanged: (value) {
                            controller.startMinute.value = value;
                            controller.updateStartTimeController();
                          },
                          onPeriodChanged: (value) {
                            controller.startPeriod.value = value;
                            controller.updateStartTimeController();
                          },
                        ),
                        const SizedBox(height: 16),

                        // End Time selection with dropdowns
                        const CustomText(
                          "End Time",
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        TimeSelectionDropdown(
                          selectedHour: controller.endHour.value,
                          selectedMinute: controller.endMinute.value,
                          selectedPeriod: controller.endPeriod.value,
                          onHourChanged: (value) {
                            controller.endHour.value = value;
                            controller.updateEndTimeController();
                          },
                          onMinuteChanged: (value) {
                            controller.endMinute.value = value;
                            controller.updateEndTimeController();
                          },
                          onPeriodChanged: (value) {
                            controller.endPeriod.value = value;
                            controller.updateEndTimeController();
                          },
                        ),
                        if (isReschedule == true) ...[
                          const SizedBox(height: 10),

                          // Text field
                          CommonTextField(
                            title: "Reason(Optional)",
                            textEditController:
                                controller.feedbackController.value,
                            maxLine: 4,
                            maxLength: 200,
                            hintText: "Brief reason (if any)",
                            isValidate: false,
                            onChange: (value) {
                              controller.feedbackController.value.text = value;
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 4),
                          // Character count
                          Align(
                            alignment: Alignment.centerRight,
                            child: CustomText(
                                "${controller.feedbackController.value.text.length}/200",
                                fontSize: 12,
                                color: Colors.grey),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Schedule button
                        CustomBtn(
                          isValidate: controller.isFormValid,
                          title: "Schedule",
                          // isLoading: controller.isLoading.value,
                          onTap: controller.isFormValid
                              ? () async {
                                  controller.isLoading.value = true;
                                  await controller.scheduleInterviewController(
                                    applicationId: applicationId, isReschedule: isReschedule,
                                      rescheduleId:interviewId
                                  );
                                  controller.isLoading.value = false;
                                  if (controller.scheduleInterviewResponse.value
                                          .status ==
                                      Status.COMPLETE) {
                                    Navigator.pop(context);
                                    callBack();
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  )),
            );
          }),
        ),
      );
    },
  );
}
