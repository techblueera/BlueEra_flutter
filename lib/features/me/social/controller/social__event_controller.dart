import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialEventController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final titleController = TextEditingController();
  final venueController = TextEditingController();
  final eventTypeController = TextEditingController();
  final linkController = TextEditingController();
  final fromTimeController = TextEditingController();
  final toTimeController = TextEditingController();
  var lat = 0.0.obs;
  var lng = 0.0.obs;
  // Date Selection Observables
  var startDay = 0.obs, startMonth = 0.obs, startYear = 0.obs;
  var endDay = 0.obs, endMonth = 0.obs, endYear = 0.obs;

  // Button State
  var isFormValid = false.obs;
   List<String> timeSlots = [];

  @override
  void onInit() {
    super.onInit();
    timeSlots = generateTimeSlots(15); // 15-minute intervals
    // Add listeners to all text controllers
    titleController.addListener(validateForm);
    venueController.addListener(validateForm);
    eventTypeController.addListener(validateForm);
    linkController.addListener(validateForm);
    fromTimeController.addListener(validateForm);
    toTimeController.addListener(validateForm);
  }

  void validateForm() {
    bool isDatesFilled = startDay!=0 && startMonth!=0 && startYear!=0 &&
        endDay!=0 && endMonth!=0 && endYear!=0;

    bool isTextFilled = titleController.text.trim().isNotEmpty &&
        venueController.text.trim().isNotEmpty &&
        eventTypeController.text.trim().isNotEmpty &&
        fromTimeController.text.trim().isNotEmpty &&
        toTimeController.text.trim().isNotEmpty &&
        linkController.text.trim().isNotEmpty;

    isFormValid.value = isDatesFilled && isTextFilled;
  }


// Observables for selection
  var selectedFromTime = "09:00 AM".obs;
  var selectedToTime = "10:00 AM".obs;
  List<String> generateTimeSlots(int stepMinutes) {
    List<String> slots = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int min = 0; min < 60; min += stepMinutes) {
        final h = hour == 0 || hour == 12 ? 12 : hour % 12;
        final period = hour < 12 ? "AM" : "PM";
        final m = min.toString().padLeft(2, '0');
        slots.add("${h.toString().padLeft(2, '0')}:$m $period");
      }
    }
    return slots;
  }
  void saveEvent() {
    // Logic for API call
    commonSnackBar(message: "Success Event scheduled successfully");
  }
}