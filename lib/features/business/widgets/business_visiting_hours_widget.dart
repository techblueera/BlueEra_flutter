import 'package:BlueEra/widgets/option_picker_sheet.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// A self-contained visiting hours selector that does NOT use any GetX
/// controller or singleton. All state lives in a plain [ValueNotifier] map
/// passed in from the parent, so every bottom-sheet open gets fresh state.
class BusinessVisitingHoursWidget extends StatelessWidget {
  final ValueNotifier<Map<String, DaySchedule>> schedule;

  const BusinessVisitingHoursWidget({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(width: 1.5, color: AppColors.greyE5),
        color: AppColors.white,
        boxShadow: [AppShadows.textFieldShadow],
      ),
      padding: EdgeInsets.all(SizeConfig.size15),
      child: ValueListenableBuilder<Map<String, DaySchedule>>(
        valueListenable: schedule,
        builder: (_, data, __) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.keys.map((day) {
              final entry = data[day]!;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: CustomText(day, fontSize: SizeConfig.large),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          CustomSwitch(
                            value: entry.isOpen,
                            onChanged: (val) {
                              final updated = Map<String, DaySchedule>.from(data);
                              updated[day] = entry.copyWith(isOpen: val);
                              schedule.value = updated;
                            },
                            containerHeight: SizeConfig.size24,
                            containerWidth: SizeConfig.size50,
                            circleSize: SizeConfig.size18,
                          ),
                          SizedBox(width: SizeConfig.size10),
                          CustomText(
                            entry.isOpen ? "Open" : "Closed",
                            fontSize: SizeConfig.large,
                            color: AppColors.black,
                          ),
                          if (entry.isOpen) ...[
                            SizedBox(width: SizeConfig.size10),
                            _TimeDropdown(
                              value: entry.startTime,
                              onChanged: (t) {
                                final updated = Map<String, DaySchedule>.from(data);
                                updated[day] = entry.copyWith(startTime: t);
                                schedule.value = updated;
                              },
                            ),
                            SizedBox(width: SizeConfig.size3),
                            _TimeDropdown(
                              value: entry.endTime,
                              onChanged: (t) {
                                final updated = Map<String, DaySchedule>.from(data);
                                updated[day] = entry.copyWith(endTime: t);
                                schedule.value = updated;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeDropdown({required this.value, required this.onChanged});

  static final List<String> _timeOptions = _generateTimeList();

  static List<String> _generateTimeList() {
    final times = <String>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        times.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    return times;
  }

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// The chosen time, tapped to pick from the list.
  ///
  /// A sheet, not a `DropdownButton`: the options here are 15-minute steps, so
  /// a DropdownButton per field meant this widget built and laid out
  /// 7 days × 2 fields × 96 options = 1,344 rows before it could paint. See
  /// [showOptionPickerSheet].
  @override
  Widget build(BuildContext context) {
    final selected = _format(value);
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final picked = await showOptionPickerSheet<String>(
          context: context,
          title: 'Select time',
          options: _timeOptions,
          selected: _timeOptions.contains(selected) ? selected : null,
          labelOf: (v) => v,
        );
        if (picked == null) return;
        final parts = picked.split(':');
        onChanged(
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8, vertical: SizeConfig.size6),
        margin: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
        decoration: BoxDecoration(
          color: AppColors.whiteF3,
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomText(
          selected,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w400,
          color: AppColors.grey9A,
        ),
      ),
    );
  }
}

/// Plain data class for a single day's schedule.
class DaySchedule {
  final bool isOpen;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const DaySchedule({
    this.isOpen = false,
    this.startTime = const TimeOfDay(hour: 10, minute: 0),
    this.endTime = const TimeOfDay(hour: 23, minute: 0),
  });

  DaySchedule copyWith({bool? isOpen, TimeOfDay? startTime, TimeOfDay? endTime}) {
    return DaySchedule(
      isOpen: isOpen ?? this.isOpen,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// Helper to create a fresh schedule map, optionally pre-filled.
ValueNotifier<Map<String, DaySchedule>> createFreshSchedule({
  TimeOfDay? openTime,
  TimeOfDay? closeTime,
}) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final map = <String, DaySchedule>{};
  for (final day in days) {
    map[day] = DaySchedule(
      isOpen: openTime != null || closeTime != null,
      startTime: openTime ?? const TimeOfDay(hour: 10, minute: 0),
      endTime: closeTime ?? const TimeOfDay(hour: 23, minute: 0),
    );
  }
  return ValueNotifier(map);
}

/// Build the API payload from the schedule notifier.
List<Map<String, dynamic>> buildVisitingHoursPayload(
    ValueNotifier<Map<String, DaySchedule>> schedule) {
  final List<Map<String, dynamic>> payload = [];
  schedule.value.forEach((day, entry) {
    if (entry.isOpen) {
      final startStr =
          '${entry.startTime.hour.toString().padLeft(2, '0')}:${entry.startTime.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${entry.endTime.hour.toString().padLeft(2, '0')}:${entry.endTime.minute.toString().padLeft(2, '0')}';
      payload.add({
        "day": day,
        "isOpen": true,
        "timeSlots": [
          {"startTime": startStr, "endTime": endStr}
        ],
      });
    }
  });
  return payload;
}

/// Parse a time string (e.g. "09:00", "06:00 PM") into a [TimeOfDay].
TimeOfDay? parseBusinessTime(String? raw) {
  if (raw == null) return null;
  try {
    final upper = raw.trim().toUpperCase();
    final hasMeridian = upper.contains('AM') || upper.contains('PM');
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(upper);
    if (match == null) return null;
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    if (hasMeridian) {
      if (upper.contains('PM') && hour != 12) hour += 12;
      if (upper.contains('AM') && hour == 12) hour = 0;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  } catch (_) {
    return null;
  }
}
