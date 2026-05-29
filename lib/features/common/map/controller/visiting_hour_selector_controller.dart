import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VisitingHoursSelectorController extends GetxController {
  final RxMap<String, bool> visitingHours = {
    'Monday':    false,
    'Tuesday':   false,
    'Wednesday': false,
    'Thursday':  false,
    'Friday':    false,
    'Saturday':  false,
    'Sunday':    false,
  }.obs;

  final RxMap<String, TimeOfDay> startTimes = <String, TimeOfDay>{}.obs;
  final RxMap<String, TimeOfDay> endTimes   = <String, TimeOfDay>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ init all days with default times
    for (final day in visitingHours.keys) {
      startTimes[day] = const TimeOfDay(hour: 10, minute: 0);
      endTimes[day]   = const TimeOfDay(hour: 23, minute: 0);
    }
  }

  void toggleDayStatus(String day, bool value) => visitingHours[day] = value;
  void updateStartTime(String day, TimeOfDay t) => startTimes[day] = t;
  void updateEndTime(String day, TimeOfDay t)   => endTimes[day]   = t;

  /// Copy [sourceDay]'s start/end into every other day so the user can
  /// set hours once and reuse them everywhere. Open/closed state is left
  /// alone — only the time slots are propagated.
  void applyTimeToAllDays(String sourceDay) {
    final start = startTimes[sourceDay];
    final end   = endTimes[sourceDay];
    if (start == null || end == null) return;
    for (final day in visitingHours.keys) {
      if (day == sourceDay) continue;
      startTimes[day] = start;
      endTimes[day]   = end;
    }
  }

  // ✅ batch update — called from BookingController
  void syncAll({
    required Map<String, bool>      visitingHours,
    required Map<String, TimeOfDay> startTimes,
    required Map<String, TimeOfDay> endTimes,
  }) {
    this.visitingHours.assignAll(visitingHours);

    // ✅ merge — ensure ALL 7 days have times (fallback for closed days)
    final mergedStart = <String, TimeOfDay>{};
    final mergedEnd   = <String, TimeOfDay>{};

    for (final day in this.visitingHours.keys) {
      mergedStart[day] = startTimes[day] ?? const TimeOfDay(hour: 10, minute: 0);
      mergedEnd[day]   = endTimes[day]   ?? const TimeOfDay(hour: 23, minute: 0);
    }

    this.startTimes..clear()..addAll(mergedStart);
    this.endTimes..clear()..addAll(mergedEnd);
  }

  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt  = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  /// 12-hour label used in dropdowns and read-only displays. The dropdown
  /// still stores `HH:mm` as its value (so the wire format / backend
  /// payload stays unchanged) — only the rendered text is 12-hour.
  String formatTime12(TimeOfDay time) {
    final now = DateTime.now();
    final dt  = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  String to12HourLabel(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return formatTime12(TimeOfDay(hour: h, minute: m));
  }

  List<String> generateTimeList() {
    final times = <String>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        times.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    return times;
  }
}