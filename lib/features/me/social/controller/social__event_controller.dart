import 'package:BlueEra/core/api/model/social_event_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/social/repo/social_profile_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialEventController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final SocialProfileRepo _repo = SocialProfileRepo();

  // Text Controllers
  final titleController = TextEditingController();
  final venueController = TextEditingController();
  final eventTypeController = TextEditingController();
  final linkController = TextEditingController();
  final fromTimeController = TextEditingController();
  final toTimeController = TextEditingController();
  var lat = 0.0.obs;
  var lng = 0.0.obs;
  // Date Selection Observables (legacy - kept for compatibility)
  var startDay = 0.obs, startMonth = 0.obs, startYear = 0.obs;
  var endDay = 0.obs, endMonth = 0.obs, endYear = 0.obs;

  // DateTime observables for date picker
  var selectedStartDate = Rxn<DateTime>();
  var selectedEndDate = Rxn<DateTime>();

  // Button State
  var isFormValid = false.obs;
  List<String> timeSlots = [];
  
  var isLoading = false.obs;
  var isListLoading = false.obs;
  var eventList = <SocialEventData>[].obs;

  String? eventId;
  SocialEventData? eventData;

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
    
    // Fetch events initially
    getEvents();
    
    if (Get.arguments != null && Get.arguments is SocialEventData) {
      initForEdit(Get.arguments);
    }
    
    // Listeners for time selection
    selectedFromTime.listen((val) {
      fromTimeController.text = val;
      validateForm();
    });
    selectedToTime.listen((val) {
      toTimeController.text = val;
      validateForm();
    });
  }

  void initForEdit(SocialEventData event) {
      eventData = event;
      eventId = event.sId;
      titleController.text = event.title ?? "";
      venueController.text = event.venue?.name ?? "";
      eventTypeController.text = event.eventType ?? "";
      linkController.text = event.registrationLink ?? "";
      
      if (event.startDate != null) {
          try {
             DateTime date = DateTime.parse(event.startDate!);
             startDay.value = date.day;
             startMonth.value = date.month;
             startYear.value = date.year;
             selectedStartDate.value = date;
          } catch (_) {}
      }
       if (event.endDate != null) {
          try {
             DateTime date = DateTime.parse(event.endDate!);
             endDay.value = date.day;
             endMonth.value = date.month;
             endYear.value = date.year;
             selectedEndDate.value = date;
          } catch (_) {}
      }
      
      if (event.timing?.from != null) {
          fromTimeController.text = event.timing!.from!;
          selectedFromTime.value = event.timing!.from!;
      }
      if (event.timing?.to != null) {
          toTimeController.text = event.timing!.to!;
          selectedToTime.value = event.timing!.to!;
      }

      if (event.venue?.location?.coordinates != null && event.venue!.location!.coordinates!.length >= 2) {
          lat.value = event.venue?.location?.coordinates?[0].toDouble()??0.0;
          lng.value = event.venue?.location?.coordinates?[1].toDouble()??0.0;
      }
      validateForm();
  }

  void validateForm() {
    bool isDatesFilled = selectedStartDate.value != null &&
        selectedEndDate.value != null;

    bool isTextFilled = titleController.text.trim().isNotEmpty &&
        venueController.text.trim().isNotEmpty &&
        eventTypeController.text.trim().isNotEmpty &&
        fromTimeController.text.trim().isNotEmpty &&
        toTimeController.text.trim().isNotEmpty &&
        linkController.text.trim().isNotEmpty;

    isFormValid.value = isDatesFilled && isTextFilled;
  }

  void setStartDate(DateTime date) {
    selectedStartDate.value = date;
    startDay.value = date.day;
    startMonth.value = date.month;
    startYear.value = date.year;
    // Reset end date if it's before start date
    if (selectedEndDate.value != null &&
        selectedEndDate.value!.isBefore(date)) {
      selectedEndDate.value = null;
      endDay.value = 0;
      endMonth.value = 0;
      endYear.value = 0;
    }
    validateForm();
  }

  void setEndDate(DateTime date) {
    selectedEndDate.value = date;
    endDay.value = date.day;
    endMonth.value = date.month;
    endYear.value = date.year;
    validateForm();
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
  
  Future<void> getEvents() async {
    isListLoading.value = true;
    try {
      final response = await _repo.getEvents();
      if (response.success == true && response.data != null) {
        eventList.value = response.data!;
      } else {
        eventList.clear();
      }
    } catch (e) {
      commonSnackBar(message: "Error fetching events: $e");
    } finally {
      isListLoading.value = false;
    }
  }

  void resetForm() {
    eventId = null;
    eventData = null;
    titleController.clear();
    venueController.clear();
    eventTypeController.clear();
    linkController.clear();
    startDay.value = 0; startMonth.value = 0; startYear.value = 0;
    endDay.value = 0; endMonth.value = 0; endYear.value = 0;
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    fromTimeController.clear();
    toTimeController.clear();
    selectedFromTime.value = "09:00 AM";
    selectedToTime.value = "10:00 AM";
    lat.value = 0.0;
    lng.value = 0.0;
    validateForm();
  }

  Future<void> saveEvent() async {
    if (!isFormValid.value) return;
    isLoading.value = true;
    try {
        final body = {
          "title": titleController.text,
          "startDate": "${startYear.value}-${startMonth.value.toString().padLeft(2, '0')}-${startDay.value.toString().padLeft(2, '0')}",
          "endDate": "${endYear.value}-${endMonth.value.toString().padLeft(2, '0')}-${endDay.value.toString().padLeft(2, '0')}",
          "timing": {
            "from": fromTimeController.text,
            "to": toTimeController.text
          },
          "venue": {
            "name": venueController.text,
            "location": {
              "name": venueController.text,
              "type": "Point",
              "coordinates": [lat.value, lng.value]
            }
          },
          "eventType": eventTypeController.text,
          "registrationLink": linkController.text
        };

        SocialEventModel response;
        if (eventId == null) {
            response = await _repo.createEvent(body);
        } else {
            response = await _repo.updateEvent(eventId!, body);
        }
        
        if (response.success == true) {
            commonSnackBar(message: "Event ${eventId == null ? 'scheduled' : 'updated'} successfully");
            Get.back();
            getEvents(); // Refresh list
        } else {
            commonSnackBar(message: "Failed to ${eventId == null ? 'schedule' : 'update'} event");
        }
    } catch (e) {
        commonSnackBar(message: "Error: $e");
    } finally {
        isLoading.value = false;
    }
  }

  Future<void> deleteEvent() async {
    if (eventId == null) return;
    isLoading.value = true;
    try {
      final response = await _repo.deleteEvent(eventId!);
      if (response.success == true) {
        commonSnackBar(message: "Event deleted successfully");
        Get.back();
        getEvents(); // Refresh list
      } else {
        commonSnackBar(message: "Failed to delete event");
      }
    } catch (e) {
      commonSnackBar(message: "Error deleting event: $e");
    } finally {
      isLoading.value = false;
    }
  }
}