import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

/// Renders a weekly schedule the same way [_buildTimingsSection] /
/// [_buildTimingsGrid] do on `professionals_service_screen.dart`:
/// when there is no schedule yet we show a gradient-tinted empty-state
/// CTA (the whole card is the call-to-action), and when there is one
/// we show every day of the week with the open time-range in green or
/// "Closed" in red. This keeps the working-hours surface visually
/// consistent across the consultant + self-employed flows.
class AvailabilityScheduleCard extends StatelessWidget {
  final List<Schedule> schedule;

  /// Fired from the empty-state CTA. When omitted the empty card still
  /// renders, but without the "Add" pill — useful in read-only contexts
  /// where the parent decides what tapping the card means.
  final VoidCallback? onAdd;

  const AvailabilityScheduleCard({
    super.key,
    required this.schedule,
    this.onAdd,
  });

  static const _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    if (schedule.isEmpty) return _buildEmptyState();

    final Map<String, _DayEntry> byDay = {};
    for (final sch in schedule) {
      final uiDay = _mapApiDayToUiDay((sch.day ?? '').toLowerCase());
      if (uiDay == null) continue;
      final slot =
          (sch.timeSlots ?? []).isNotEmpty ? sch.timeSlots!.first : null;
      byDay[uiDay] = _DayEntry(
        isOpen: sch.isOpen ?? false,
        start: _parseTimeOfDay(slot?.startTime),
        end: _parseTimeOfDay(slot?.endTime),
      );
    }

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
        children: _allDays.map((day) {
          final entry = byDay[day];
          final isOpen = entry?.isOpen ?? false;
          final text = isOpen
              ? "${_formatTime(entry?.start)} - ${_formatTime(entry?.end)}"
              : "Closed";
          return Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  day,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                ),
                CustomText(
                  text,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: isOpen ? Colors.green : Colors.red,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.07),
                AppColors.primaryColor.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 22,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Set your working hours',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Tell clients when you're available so bookings come at the right time.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }
}

class _DayEntry {
  final bool isOpen;
  final TimeOfDay? start;
  final TimeOfDay? end;

  _DayEntry({required this.isOpen, this.start, this.end});
}
