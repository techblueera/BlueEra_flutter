import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// In-sheet working-hours editor.
///
/// Structure (kept from the user-approved layout, only the visuals are
/// refined): one row per day; each row is a tinted card with a thin
/// status rail on the left edge, the day's 3-letter name, a switch,
/// and either two time dropdowns (in / out) or a "Closed" chip.
///
/// Visual direction is editorial-professional: tracked uppercase day
/// labels in Open Sans, a soft gradient backdrop instead of a flat
/// alpha tint, white dropdown pills that pop against the row, and a
/// proper "Closed" pill with a status dot instead of bare red text.
class WorkingHoursEditor extends StatelessWidget {
  const WorkingHoursEditor({super.key});

  static const _days = <String>[
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
    final ctrl = getOrPut(() => VisitingHoursSelectorController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _days
          .map((day) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DayRow(day: day, ctrl: ctrl),
              ))
          .toList(),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final VisitingHoursSelectorController ctrl;

  const _DayRow({required this.day, required this.ctrl});

  /// 3-letter uppercase abbreviation used in the day label slot
  /// (e.g. "MON", "TUE"). Keeps the row compact while letting the
  /// tracked-uppercase styling read confidently.
  String get _abbr =>
      day.substring(0, day.length > 3 ? 3 : day.length).toUpperCase();

  @override
  Widget build(BuildContext context) {
    // Per-row Obx — the .obs reads happen inside this build, not in
    // a parent closure, so each row owns its own reactive scope (a
    // single parent Obx would throw "improper use of GetX" because
    // its builder body wouldn't touch any observables directly).
    return Obx(() {
      final isOpen = ctrl.visitingHours[day] ?? false;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.zero,
        // Clip children to the container's rounded decoration —
        // without this, the 3-px status rail on the left poked past
        // the top-left / bottom-left corners of the row.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: isOpen
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.060),
                    AppColors.primaryColor.withValues(alpha: 0.015),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFCFCFE),
                    Color(0xFFF6F7FA),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen
                ? AppColors.primaryColor.withValues(alpha: 0.22)
                : const Color(0xFFE7E9EE),
            width: 0.8,
          ),
          boxShadow: isOpen
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status rail — a 3-px colored bar pinned to the left
              // edge that flips from primary (open) to a hairline
              // grey (closed). Lets the week status read at a
              // glance without a dedicated indicator column.
              _statusRail(isOpen),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      _dayLabel(isOpen),
                      const SizedBox(width: 4),
                      _switch(isOpen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: isOpen
                            ? _openControls()
                            : Align(
                                alignment: Alignment.centerRight,
                                child: _closedChip(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statusRail(bool isOpen) {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.primaryColor
            : const Color(0xFFE7E9EE),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
    );
  }

  /// Tracked uppercase day abbreviation. Closed days lose weight and
  /// color saturation so the active days visually lead.
  Widget _dayLabel(bool isOpen) {
    return SizedBox(
      width: 38,
      child: Text(
        _abbr,
        style: TextStyle(
          fontFamily: AppConstants.OpenSans,
          fontSize: 12.5,
          fontWeight: isOpen ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: 1.6,
          height: 1.0,
          color: isOpen
              ? AppColors.mainTextColor
              : AppColors.secondaryTextColor.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _switch(bool isOpen) {
    return Transform.scale(
      scale: 0.78,
      child: Switch(
        value: isOpen,
        onChanged: (val) => ctrl.toggleDayStatus(day, val),
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primaryColor,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFD8DCE3),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// Two dropdown pills bridged by a primary-colored arrow — the
  /// arrow replaces the original `-` separator because flow (in →
  /// out) reads more deliberately than a hyphen.
  Widget _openControls() {
    return Row(
      children: [
        Expanded(
          child: _DropdownPill(
            ctrl: ctrl,
            current: ctrl.startTimes[day],
            semanticLabel: 'In time',
            onChanged: (t) {
              // Reject in-times that aren't strictly before the
              // current out-time; the dropdown stays controlled by
              // the unchanged controller value so the menu snaps
              // back to the previous selection on its own.
              final end = ctrl.endTimes[day];
              if (end != null && !_isBefore(t, end)) {
                _showRangeError('In time must be before out time');
                return;
              }
              ctrl.updateStartTime(day, t);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.arrow_right_alt_rounded,
            size: 16,
            color: AppColors.primaryColor.withValues(alpha: 0.75),
          ),
        ),
        Expanded(
          child: _DropdownPill(
            ctrl: ctrl,
            current: ctrl.endTimes[day],
            semanticLabel: 'Out time',
            onChanged: (t) {
              final start = ctrl.startTimes[day];
              if (start != null && !_isBefore(start, t)) {
                _showRangeError('Out time must be after in time');
                return;
              }
              ctrl.updateEndTime(day, t);
            },
          ),
        ),
      ],
    );
  }

  static bool _isBefore(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) < (b.hour * 60 + b.minute);

  void _showRangeError(String message) {
    Get.snackbar(
      'Invalid hours',
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      backgroundColor: Colors.white,
      colorText: AppColors.mainTextColor,
      icon: Icon(Icons.error_outline_rounded,
          color: AppColors.primaryColor),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Compact pill that takes over the open-state slot when the day
  /// is off. A 6px status dot anchors the row even when no times
  /// are showing, and the soft red tint keeps the "you've turned
  /// this day off" message gentle instead of alarming.
  Widget _closedChip() {
    const closedRed = Color(0xFFE0394A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: closedRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: closedRed.withValues(alpha: 0.22),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: closedRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'CLOSED',
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: closedRed,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// A refined dropdown styled as a soft white pill that pops against
/// the tinted row backdrop. Material+InkWell isn't useful here
/// because [DropdownButton] paints its own ripple over the menu;
/// instead the pill leans on a subtle shadow + primary-tinted
/// border for depth and a custom chevron for character.
class _DropdownPill extends StatelessWidget {
  final VisitingHoursSelectorController ctrl;
  final TimeOfDay? current;
  final String semanticLabel;
  final ValueChanged<TimeOfDay> onChanged;

  const _DropdownPill({
    required this.ctrl,
    required this.current,
    required this.semanticLabel,
    required this.onChanged,
  });

  TimeOfDay? _parseHHmm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  Widget build(BuildContext context) {
    final items = ctrl.generateTimeList();
    final selected = current != null ? ctrl.formatTime(current!) : null;
    final hasValue = selected != null && items.contains(selected);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.18),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: hasValue ? selected : null,
            isExpanded: true,
            isDense: true,
            menuMaxHeight: 320,
            borderRadius: BorderRadius.circular(12),
            elevation: 8,
            dropdownColor: Colors.white,
            icon: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.expand_more_rounded,
                size: 14,
                color: AppColors.primaryColor,
              ),
            ),
            iconSize: 18,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 12,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
            selectedItemBuilder: (context) => items
                .map((value) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ctrl.to12HourLabel(value),
                        style: TextStyle(
                          fontFamily: AppConstants.OpenSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          letterSpacing: 0.1,
                          height: 1.0,
                        ),
                      ),
                    ))
                .toList(),
            items: items
                .map((value) => DropdownMenuItem<String>(
                      value: value,
                      child: CustomText(
                        ctrl.to12HourLabel(value),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              final t = _parseHHmm(val);
              if (t != null) onChanged(t);
            },
          ),
        ),
      ),
    );
  }
}
