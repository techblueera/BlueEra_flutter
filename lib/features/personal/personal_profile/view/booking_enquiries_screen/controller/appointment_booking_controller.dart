import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:get/get.dart';

import '../model/appointment_booking_model.dart';
import '../model/availability_model.dart';
import '../model/calendar_model.dart';
import '../repo/booking_repo.dart';

/// A customer booking an appointment with a channel from one of its videos:
/// the channel's open dates, fee and time slots, and the booking itself.
/// Registered by AppointmentBookingBinding on the booking screen's route.
class AppointmentBookingController extends GetxController {
  AppointmentBookingController(
      {required BookingRepo repo,
      required this.channelId,
      required this.videoId})
      : _repo = repo;

  final BookingRepo _repo;
  final String channelId;
  final String videoId;

  final calendarData = Rxn<CalendarResponse>();
  final availableDates = <DateTime>[].obs;
  final charges = ''.obs;
  final isLoadingCalendar = false.obs;
  final availabilityDetails = Rxn<AvailabilityData>();
  final isBooking = false.obs;

  bool get isAvailabilitySet => calendarData.value?.data?.isNotEmpty ?? false;

  @override
  void onInit() {
    super.onInit();
    loadAvailability();
  }

  /// Loads the channel's open dates, then its schedule and fee.
  Future<void> loadAvailability() async {
    try {
      isLoadingCalendar.value = true;

      final response =
          await _repo.getavailableCalender(channelId: channelId, params: {});
      if (response.isSuccess && response.response?.data != null) {
        try {
          final calendarResponse =
              CalendarResponse.fromJson(response.response!.data);
          calendarData.value = calendarResponse;
          if (calendarResponse.fee != null) {
            charges.value = calendarResponse.fee!;
          }
          _setAvailableDates(calendarResponse.data);
        } catch (e) {
          logs("Error parsing calendar response: $e");
        }
      } else {
        logs("Failed to fetch calendar: ${response.message}");
      }

      // The schedule (for time slots) and the fee come from the channel's
      // availability, not the calendar.
      try {
        final availabilityRes = await _repo.getUserAvailability(
            id: channelId, queryParams: {ApiKeys.type: 'channel'});
        if (availabilityRes.isSuccess &&
            availabilityRes.response?.data != null) {
          final availability =
              AvailabilityResponse.fromJson(availabilityRes.response!.data);
          final fee = availability.data?.fee?.toString() ?? '';
          if (fee.isNotEmpty) charges.value = fee;
          availabilityDetails.value = availability.data;
        } else {
          logs("Availability fetch failed or empty: ${availabilityRes.message}");
        }
      } catch (e) {
        logs("Error fetching availability details: $e");
      }
    } catch (e) {
      logs("Error fetching calendar: $e");
    } finally {
      isLoadingCalendar.value = false;
    }
  }

  void _setAvailableDates(List<String>? dates) {
    if (dates == null) return;
    availableDates.clear();
    for (final dateString in dates) {
      final date = DateTime.tryParse(dateString);
      if (date != null) availableDates.add(date);
    }
  }

  /// The bookable slots on [date], cut from the day's open hours into
  /// appointment-length pieces ("HH:mm - HH:mm").
  List<String> getAvailableTimeSlotsForDate(DateTime date) {
    final details = availabilityDetails.value;
    final schedule = details?.schedule;
    if (details == null || schedule == null || schedule.isEmpty) return [];

    const dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final dayName = dayNames[date.weekday - 1];

    final scheduleForDay = schedule
        .where((s) =>
            (s.day?.toLowerCase() ?? '') == dayName && (s.isOpen ?? false))
        .toList();
    final slotMinutes = details.durationInMinutes ?? 60;
    final slots = <String>[];

    for (final sch in scheduleForDay) {
      for (final ts in sch.timeSlots ?? []) {
        final start = _tryParseHHmm(ts.startTime);
        final end = _tryParseHHmm(ts.endTime);
        if (start == null || end == null) continue;

        var cursor = start;
        while (cursor.isBefore(end)) {
          final next = cursor.add(Duration(minutes: slotMinutes));
          if (next.isAfter(end)) break;
          slots.add('${_formatHHmm(cursor)} - ${_formatHHmm(next)}');
          cursor = next;
        }
      }
    }
    return slots;
  }

  /// Books [at] for [customer]. Returns true when the booking was made.
  Future<bool> book(
      {required DateTime at, required CustomerDetails customer}) async {
    if (isBooking.value) return false;
    isBooking.value = true;
    try {
      final response = await _repo.postAppointment(bodyRequest: {
        ApiKeys.serviceProvider_channelId: channelId,
        ApiKeys.videoId: videoId,
        ApiKeys.bookingTime: "$at",
        ApiKeys.customerDetails: customer.toJson(),
      });
      if (!response.isSuccess) {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      commonSnackBar(message: response.message ?? AppStrings.success);
      return true;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      isBooking.value = false;
    }
  }

  DateTime? _tryParseHHmm(String? hhmm) {
    final raw = hhmm?.trim().toUpperCase() ?? '';
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (raw.contains('PM') && hour != 12) hour += 12;
    if (raw.contains('AM') && hour == 12) hour = 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatHHmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
