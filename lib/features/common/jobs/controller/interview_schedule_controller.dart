import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/jobs/repo/job_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InterviewScheduleController extends GetxController {
  // Observable variables for form fields
  var venue = ''.obs;
  var onlineMeetingLink = ''.obs;

  // Date variables
  var selectedDay = RxnInt();
  var selectedMonth = RxnInt();
  var selectedYear = RxnInt();

  // Time variables - Start Time
  var startHour = RxnInt();
  var startMinute = RxnInt();
  var startPeriod = RxnString();

  // Time variables - End Time
  var endHour = RxnInt();
  var endMinute = RxnInt();
  var endPeriod = RxnString();

  // For backward compatibility
  var startTimeController = TextEditingController().obs;
  var endTimeController = TextEditingController().obs;
  Rx<TextEditingController> feedbackController = TextEditingController().obs;

  // Loading state
  var isLoading = false.obs;
  Rx<CommunicationMode?> communicationMode = Rx<CommunicationMode?>(null);

  // Mode options
  Rx<ApiResponse> scheduleInterviewResponse =
      ApiResponse.initial('Initial').obs;

  // Validation
  bool get isFormValid {
    if (communicationMode.value?.displayName == 'Online') {
      return selectedDay.value != null &&
          selectedMonth.value != null &&
          selectedYear.value != null &&
          startHour.value != null &&
          startMinute.value != null &&
          startPeriod.value != null &&
          endHour.value != null &&
          endMinute.value != null &&
          endPeriod.value != null &&
          onlineMeetingLink.value.isNotEmpty;
    } else {
      return selectedDay.value != null &&
          selectedMonth.value != null &&
          selectedYear.value != null &&
          startHour.value != null &&
          startMinute.value != null &&
          startPeriod.value != null &&
          endHour.value != null &&
          endMinute.value != null &&
          endPeriod.value != null &&
          venue.value.isNotEmpty;
    }
  }

  // Reset form
  void resetForm() {
    communicationMode.value = null;
    venue.value = '';
    onlineMeetingLink.value = '';
    selectedDay.value = null;
    selectedMonth.value = null;
    selectedYear.value = null;
    startHour.value = null;
    startMinute.value = null;
    startPeriod.value = null;
    endHour.value = null;
    endMinute.value = null;
    endPeriod.value = null;
    startTimeController.value.text = '';
    endTimeController.value.text = '';
  }

  // Update time controllers when dropdown values change
  void updateStartTimeController() {
    if (startHour.value != null &&
        startMinute.value != null &&
        startPeriod.value != null) {
      final formattedTime =
          '${startHour.value.toString().padLeft(2, '0')}:${startMinute.value.toString().padLeft(2, '0')} ${startPeriod.value}';
      startTimeController.value.text = formattedTime;
    }
  }

  void updateEndTimeController() {
    if (endHour.value != null &&
        endMinute.value != null &&
        endPeriod.value != null) {
      final formattedTime =
          '${endHour.value.toString().padLeft(2, '0')}:${endMinute.value.toString().padLeft(2, '0')} ${endPeriod.value}';
      endTimeController.value.text = formattedTime;
    }
  }

  Future<void> scheduleInterviewController(
      {required List<String>? applicationId,
      String? rescheduleId,
      required bool? isReschedule}) async {
    try {
      if (!isFormValid) {
        commonSnackBar(message: "Fill this form");
        return;
      }
      // Update time controllers before API call
      updateStartTimeController();
      updateEndTimeController();

      scheduleInterviewResponse.value = ApiResponse.initial('Initial');

      // Format date as YYYY-MM-DD
      final formattedDate =
          '${selectedYear.value}-${selectedMonth.value.toString().padLeft(2, '0')}-${selectedDay.value.toString().padLeft(2, '0')}';

      // Prepare request parameters
      final Map<String, dynamic> params = {
        if ((isReschedule==true)) "interviewIds": applicationId,
        if ((isReschedule == false)) "applicationIds": applicationId,
        "mode": communicationMode.value?.displayName,
        "scheduledDate": formattedDate,
        "startTime": startTimeController.value.text,
        "endTime": endTimeController.value.text,
      };

      // Add venue or online meeting link based on mode
      if (communicationMode.value?.displayName == 'Online') {
        params["onlineMeetingLink"] = onlineMeetingLink.value;
      } else {
        params["venue"] = venue.value;
      }

      if (isReschedule ?? false) {
        params["reasonForReschedule"] = feedbackController.value.text;
      }

      ResponseModel responseModel = (isReschedule ?? false)
          ? await JobRepo().rescheduleInterViewRepo(
              reqParam: params,
            )
          : await JobRepo().scheduleInterViewRepo(reqParam: params);
      if (responseModel.isSuccess) {
        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
        scheduleInterviewResponse.value = ApiResponse.complete(responseModel);
      } else {
        scheduleInterviewResponse.value = ApiResponse.error('error');

        commonSnackBar(
            message: responseModel.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      logs("ERRO ${e}");
      scheduleInterviewResponse.value = ApiResponse.error('error');
    }
  }
}
