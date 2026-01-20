import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DayTiming {
  String day;
  RxBool isOpen;
  RxString openTime;
  RxString closeTime;

  DayTiming({
    required this.day,
    bool isOpen = false,
    String openTime = "10:00 AM",
    String closeTime = "10:00 PM",
  }) : 
    isOpen = isOpen.obs,
    openTime = openTime.obs,
    closeTime = closeTime.obs;
}

class TimingController extends GetxController {
  var timingList = <DayTiming>[].obs;
  final List<String> timeSlots = [];

  @override
  void onInit() {
    super.onInit();
    _generateTimeSlots();
    // Initialize with data similar to the screenshot
    timingList.addAll([
      DayTiming(day: "Monday", isOpen: true, openTime: "10:00 AM", closeTime: "10:00 PM"),
      DayTiming(day: "Tuesday", isOpen: true, openTime: "10:00 AM", closeTime: "10:00 PM"),
      DayTiming(day: "Wednesday", isOpen: false, openTime: "10:00 AM", closeTime: "10:00 PM"),
      DayTiming(day: "Thursday", isOpen: false, openTime: "10:00 AM", closeTime: "10:00 PM"),
      DayTiming(day: "Friday", isOpen: false, openTime: "10:00 AM", closeTime: "10:00 PM"),
      DayTiming(day: "Saturday", isOpen: false, openTime: "10:00 AM", closeTime: "10:00 PM"),
      DayTiming(day: "Sunday", isOpen: false, openTime: "10:00 AM", closeTime: "10:00 PM"),
    ]);
  }

  void _generateTimeSlots() {
    timeSlots.clear();
    // Generate times from 12:00 AM to 11:30 PM in 30 min intervals
    final periods = ['AM', 'PM'];
    for (var period in periods) {
      for (var hour = 0; hour < 12; hour++) {
        // Handle 12 AM/PM special case
        int displayHour = hour == 0 ? 12 : hour;
        
        for (var min = 0; min < 60; min += 30) {
          String minStr = min.toString().padLeft(2, '0');
          timeSlots.add("$displayHour:$minStr $period");
        }
      }
    }
  }

  void toggleDay(int index, bool value) {
    timingList[index].isOpen.value = value;
  }
  
  void updateTime(int index, String newTime, bool isOpenTime) {
    if (isOpenTime) {
      timingList[index].openTime.value = newTime;
    } else {
      timingList[index].closeTime.value = newTime;
    }
  }
  
  void submit() {
    // Logic to save data
    // For now, just print or show snackbar
    print("Submitting availability...");
    for (var timing in timingList) {
      print("${timing.day}: ${timing.isOpen.value ? 'Open ${timing.openTime.value} - ${timing.closeTime.value}' : 'Closed'}");
    }
    Get.snackbar(
      "Success", 
      "Availability updated successfully",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}
