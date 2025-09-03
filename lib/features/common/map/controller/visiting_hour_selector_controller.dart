import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VisitingHoursSelectorController extends GetxController {
  final RxMap<String, bool> visitingHours = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  }.obs;
  
  final RxMap<String, TimeOfDay> startTimes = <String, TimeOfDay>{}.obs;
  final RxMap<String, TimeOfDay> endTimes = <String, TimeOfDay>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    for (var day in visitingHours.keys) {
      startTimes[day] = const TimeOfDay(hour: 10, minute: 0);
      endTimes[day] = const TimeOfDay(hour: 23, minute: 0);
    }
  }
  
  void toggleDayStatus(String day, bool value) {
    visitingHours[day] = value;
  }
  
  void updateStartTime(String day, TimeOfDay newTime) {
    startTimes[day] = newTime;
  }
  
  void updateEndTime(String day, TimeOfDay newTime) {
    endTimes[day] = newTime;
  }
  
  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }
  
  List<String> generateTimeList() {
    List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final h = hour.toString().padLeft(2, '0');
        final m = minute.toString().padLeft(2, '0');
        times.add("$h:$m");
      }
    }
    return times;
  }
}