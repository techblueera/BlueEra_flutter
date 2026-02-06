import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialActivityController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final titleController = TextEditingController();
  final venueController = TextEditingController();
  final typeController = TextEditingController();
  final linkController = TextEditingController();
  final descriptionController = TextEditingController();
  final roleController = TextEditingController();
  final organizerController = TextEditingController();
  final impactController = TextEditingController();
  var lat = 0.0.obs;
  var lng = 0.0.obs;
  // Date/Time Observables
  var startDay = 0.obs, startMonth = 0.obs, startYear = 0.obs;
  var endDay = 0.obs, endMonth = 0.obs, endYear = 0.obs;

  // Single List Time Selection
  var selectedFromTime = "09:00 AM".obs;
  var selectedToTime = "10:00 AM".obs;
  List<String> timeSlots = [];

  var isFormValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    timeSlots = _generateTimeSlots(15);

    // Add listeners to trigger validation
    titleController.addListener(validateForm);
    venueController.addListener(validateForm);
    typeController.addListener(validateForm);
    linkController.addListener(validateForm);
    descriptionController.addListener(validateForm);
  }

  List<String> _generateTimeSlots(int step) {
    List<String> slots = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int min = 0; min < 60; min += step) {
        final h = hour == 0 || hour == 12 ? 12 : hour % 12;
        final period = hour < 12 ? "AM" : "PM";
        slots.add("${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period");
      }
    }
    return slots;
  }

  void validateForm() {
    // Basic requirement check: Title, Venue/Location, and Date selection
    bool hasText = titleController.text.isNotEmpty && venueController.text.isNotEmpty;
    bool hasDates = startDay!=0 && startMonth!=0 && startYear!=0;

    isFormValid.value = hasText && hasDates;
  }
}