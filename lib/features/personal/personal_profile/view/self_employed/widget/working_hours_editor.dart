import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorkingHoursEditor extends StatefulWidget {
  const WorkingHoursEditor({super.key});

  @override
  State<WorkingHoursEditor> createState() => _WorkingHoursEditorState();
}

class _WorkingHoursEditorState extends State<WorkingHoursEditor> {
  // Day labels must match the controller's RxMap keys verbatim — the
  // controller seeds them with the full English names below.
  static const _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Single-letter initials shown on the chip strip. Tue/Thu and
  // Sat/Sun share the same first letter — that's fine; pairing
  // initials with the open/closed dot underneath disambiguates them
  // and keeps the strip compact on narrow phones.
  static const _initials = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final _ctrl = getOrPut(() => VisitingHoursSelectorController());

  /// Index into [_days] of the currently focused day. Local State —
  /// the controller doesn't need to know which day the editor is
  /// showing, only which days are open and at what hours.
  int _focused = 0;

  String get _focusedDay => _days[_focused];

  /// Round-trip helper — converts a "HH:mm" dropdown value back to a
  /// [TimeOfDay] for the controller. Tolerant of malformed input
  /// (returns null) so the dropdown's onChanged is a no-op rather
  /// than a crash if a stray value sneaks in.
  TimeOfDay? _parseHHmm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Copy the focused day's start/end times to every other day that
  /// is already open. Closed days are deliberately left alone so the
  /// shortcut never silently opens days the user didn't ask for.
  void _applyToOtherOpenDays() {
    final src = _focusedDay;
    final start = _ctrl.startTimes[src];
    final end = _ctrl.endTimes[src];
    if (start == null || end == null) return;
    for (final day in _days) {
      if (day == src) continue;
      if (_ctrl.visitingHours[day] ?? false) {
        _ctrl.updateStartTime(day, start);
        _ctrl.updateEndTime(day, end);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final day = _focusedDay;
      final isOpen = _ctrl.visitingHours[day] ?? false;
      final start = _ctrl.startTimes[day];
      final end = _ctrl.endTimes[day];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDayStrip(),
          SizedBox(height: SizeConfig.size12),
          _buildFocusCard(
            dayLabel: day,
            isOpen: isOpen,
            start: start,
            end: end,
          ),
        ],
      );
    });
  }

  // ─── DAY STRIP ───────────────────────────────────────────────
  // Seven equal-width chips. Selected chip gets a primary-filled
  // background + white initial; every day that's marked open wears
  // a small filled dot underneath (or a hollow dot when closed) so
  // the week's status reads in one glance.
  Widget _buildDayStrip() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size6,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE), width: 0.8),
      ),
      child: Row(
        children: List.generate(_days.length, (i) {
          final day = _days[i];
          final open = _ctrl.visitingHours[day] ?? false;
          final selected = _focused == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _focused = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                decoration: BoxDecoration(
                  color:
                      selected ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _initials[i],
                      style: TextStyle(
                        fontFamily: AppConstants.OpenSans,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : AppColors.mainTextColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: open
                            ? (selected
                                ? Colors.white
                                : AppColors.primaryColor)
                            : Colors.transparent,
                        border: open
                            ? null
                            : Border.all(
                                color: AppColors.secondaryTextColor
                                    .withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── FOCUS CARD ──────────────────────────────────────────────
  // The "one day at a time" pane. Header carries the day name and an
  // Open/Off pill; the body is dominated by the oversized HH:mm
  // readout so the user instantly sees what they're declaring; below
  // it, two compact time pills act as tap-to-pick affordances.
  Widget _buildFocusCard({
    required String dayLabel,
    required bool isOpen,
    required TimeOfDay? start,
    required TimeOfDay? end,
  }) {
    // 24-hour HH:mm matches the dropdown option values verbatim, so
    // the hero readout and the dropdown selection stay aligned.
    final startText = start != null ? _ctrl.formatTime(start) : '--:--';
    final endText = end != null ? _ctrl.formatTime(end) : '--:--';
    return Container(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size14,
        SizeConfig.size16,
        SizeConfig.size16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10001120),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — day name + Open/Off pill toggle.
          Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryTextColor,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              _openTogglePill(dayLabel, isOpen),
            ],
          ),
          SizedBox(height: SizeConfig.size16),

          // Hero readout — primary visual anchor. AnimatedSwitcher
          // softly cross-fades between the open time range and the
          // muted "Closed all day" line so toggles don't jolt the
          // layout. Locale-aware time format matches the schedule
          // card display elsewhere in the app.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: isOpen
                ? Row(
                    key: const ValueKey('open'),
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            startText,
                            style: TextStyle(
                              fontFamily: AppConstants.OpenSans,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mainTextColor,
                              letterSpacing: -0.3,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Icon(Icons.arrow_forward_rounded,
                          size: 20, color: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size10),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            endText,
                            style: TextStyle(
                              fontFamily: AppConstants.OpenSans,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mainTextColor,
                              letterSpacing: -0.3,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    key: const ValueKey('closed'),
                    padding:
                        EdgeInsets.symmetric(vertical: SizeConfig.size4),
                    child: Text(
                      'Closed all day',
                      style: TextStyle(
                        fontFamily: AppConstants.OpenSans,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
          ),

          if (isOpen) ...[
            SizedBox(height: SizeConfig.size16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _timeDropdown(
                    label: 'START',
                    selected: start != null ? _ctrl.formatTime(start) : null,
                    isStart: true,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: _timeDropdown(
                    label: 'END',
                    selected: end != null ? _ctrl.formatTime(end) : null,
                    isStart: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            _applyToOthersRow(startText: startText, endText: endText),
          ],
        ],
      ),
    );
  }

  /// Pill-shaped Open/Off toggle. Tapping flips
  /// [VisitingHoursSelectorController.visitingHours] for the focused
  /// day; the rest of the focus card cross-fades to match.
  Widget _openTogglePill(String day, bool isOpen) {
    return GestureDetector(
      onTap: () => _ctrl.toggleDayStatus(day, !isOpen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: isOpen
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOpen
                ? AppColors.primaryColor.withValues(alpha: 0.30)
                : const Color(0xFFE6E8EE),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              isOpen ? 'Open' : 'Off',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOpen
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Tap-to-open dialog picker for start/end time. Items are the 96
  /// quarter-hour "HH:mm" slots [VisitingHoursSelectorController]
  /// ships in [generateTimeList]; the dialog body is a scrollable
  /// ListView, same flow the original visiting-hours selector used.
  Widget _timeDropdown({
    required String label,
    required String? selected,
    required bool isStart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded,
                size: 12, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              label,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size6),
        CommonDropdownDialog<String>(
          items: _ctrl.generateTimeList(),
          selectedValue: selected,
          hintText: isStart ? 'Start' : 'End',
          title: isStart ? 'Start time' : 'End time',
          displayValue: (s) => s,
          onChanged: (val) {
            if (val == null) return;
            final tod = _parseHHmm(val);
            if (tod == null) return;
            if (isStart) {
              _ctrl.updateStartTime(_focusedDay, tod);
            } else {
              _ctrl.updateEndTime(_focusedDay, tod);
            }
          },
        ),
      ],
    );
  }

  /// Soft, optional "apply these hours to other open days" affordance.
  /// Disabled when no other day is open so the affordance never lies
  /// about what it'll do; copy includes the target count so the user
  /// knows exactly how many days will be touched.
  Widget _applyToOthersRow({
    required String startText,
    required String endText,
  }) {
    final src = _focusedDay;
    final otherOpenCount = _days
        .where((d) => d != src && (_ctrl.visitingHours[d] ?? false))
        .length;
    final enabled = otherOpenCount > 0;
    return InkWell(
      onTap: enabled ? _applyToOtherOpenDays : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryColor.withValues(alpha: 0.06)
              : const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? AppColors.primaryColor.withValues(alpha: 0.20)
                : const Color(0xFFE6E8EE),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.repeat_rounded,
                size: 14,
                color: enabled
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                enabled
                    ? 'Apply $startText – $endText to $otherOpenCount other open day${otherOpenCount == 1 ? '' : 's'}'
                    : 'Open another day to apply these hours to it',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
