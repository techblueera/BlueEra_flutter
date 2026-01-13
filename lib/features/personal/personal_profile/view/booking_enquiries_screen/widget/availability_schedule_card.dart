import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class AvailabilityScheduleCard extends StatelessWidget {
  final AvailabilityData data;

  const AvailabilityScheduleCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Process Data Locally (Decoupled from Controller)
    final Map<String, bool> visitingHours = {};
    final Map<String, TimeOfDay> startTimes = {};
    final Map<String, TimeOfDay> endTimes = {};

    final schedule = data.schedule ?? [];

    for (final sch in schedule) {
      final apiDay = (sch.day ?? '').toLowerCase();
      final uiDay = _mapApiDayToUiDay(apiDay);
      if (uiDay == null) continue;

      visitingHours[uiDay] = sch.isOpen ?? false;

      final firstSlot = (sch.timeSlots ?? []).isNotEmpty ? sch.timeSlots!.first : null;

      if (firstSlot != null) {
        final start = _parseTimeOfDay(firstSlot.startTime);
        final end = _parseTimeOfDay(firstSlot.endTime);

        if (start != null) startTimes[uiDay] = start;
        if (end != null) endTimes[uiDay] = end;
      }
    }

    // 2. Filter Open Days
    final openDays = visitingHours.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // 3. Handle Empty Case
    if (openDays.isEmpty) {
      return CustomText(
        AppStrings.noVisitingDaysSelected, // Ensure this string exists or use raw string
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
      );
    }

    // 4. Build List
    return Container(
      padding: EdgeInsets.all(SizeConfig.size12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 1.2),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: openDays.map((day) {
          // Use the local maps, not the controller!
          final start = _formatTime(context, startTimes[day]);
          final end = _formatTime(context, endTimes[day]);

          return Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
            child: Row(
              children: [
                // Day Name
                CustomText(
                  day,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
                const Spacer(),

                // "Open" Label
                CustomText(
                  "Open",
                  fontSize: SizeConfig.large,
                  color: AppColors.green7F,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(width: SizeConfig.size8),

                // Time Range
                CustomText(
                  "$start - $end",
                  fontSize: SizeConfig.medium,
                  color: AppColors.grey9A,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- PRIVATE HELPERS (Keep logic self-contained) ---

  String? _mapApiDayToUiDay(String apiDay) {
    const map = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };
    return map[apiDay.toLowerCase()];
  }

  TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null || !timeString.contains(":")) return null;
    try {
      final parts = timeString.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  String _formatTime(BuildContext context, TimeOfDay? time) {
    if (time == null) return "--:--";
    // Uses Flutter's native localization for AM/PM
    return time.format(context);
  }
}