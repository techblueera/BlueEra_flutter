import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lab weekly-hours capture — the lab equivalent of the grocery
/// [ShopAvailabilityScreen]. Owners declare when the lab is open,
/// either Daily (same hours every day) or Weekly (per-day toggle +
/// per-day open/close), and the assembled 7-day [Schedule] is
/// persisted via the caller-supplied [onSave]. The card in the
/// overview tab opens this and calls the shared business availability
/// endpoint; on success the screen pops back `true` so the caller can
/// refresh.
///
/// Kept as its own file (rather than reusing [ShopAvailabilityScreen])
/// so the copy — appbar title, header, subtitle — stays lab-flavoured
/// without a shared abstraction. The mechanics are otherwise identical.
class LabAvailabilityScreen extends StatefulWidget {
  /// Optional previously-saved schedule used to pre-fill the form.
  final List<Schedule>? initialSchedule;

  /// Persists the assembled 7-day [Schedule]. Returns `null` on success,
  /// otherwise an error message to surface as a snackbar.
  final Future<String?> Function(List<Schedule> schedule) onSave;

  const LabAvailabilityScreen({
    super.key,
    this.initialSchedule,
    required this.onSave,
  });

  @override
  State<LabAvailabilityScreen> createState() => _LabAvailabilityScreenState();
}

class _LabAvailabilityScreenState extends State<LabAvailabilityScreen> {
  // Weekdays in display order — used for both Weekly rows and for fanning
  // the Daily hours across every day on save.
  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // false = Daily (same hours every day), true = Weekly (per-day).
  bool _isWeekly = false;

  // Daily-mode hours applied to every day.
  TimeOfDay _dailyOpen = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _dailyClose = const TimeOfDay(hour: 21, minute: 0);

  // Weekly-mode per-day open flag + hours.
  late final Map<String, _DayHours> _weekly;

  // True while the save request is in flight (drives the button loader).
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weekly = {
      for (final d in _days)
        d: _DayHours(
          isOpen: true,
          open: const TimeOfDay(hour: 9, minute: 0),
          close: const TimeOfDay(hour: 21, minute: 0),
        ),
    };
    _hydrateFromInitial();
  }

  // Pre-fill from a saved schedule. Uniform+all-open opens as Daily; anything
  // else (a closed day or varying hours) opens as Weekly.
  void _hydrateFromInitial() {
    final saved = widget.initialSchedule;
    if (saved == null || saved.isEmpty) return;

    for (final s in saved) {
      final day = s.day;
      if (day == null || !_weekly.containsKey(day)) continue;
      final slot = (s.timeSlots != null && s.timeSlots!.isNotEmpty)
          ? s.timeSlots!.first
          : null;
      _weekly[day] = _DayHours(
        isOpen: s.isOpen ?? true,
        open: _parse(s.shopOpenTime ?? slot?.startTime) ??
            const TimeOfDay(hour: 9, minute: 0),
        close: _parse(s.shopCloseTime ?? slot?.endTime) ??
            const TimeOfDay(hour: 21, minute: 0),
      );
    }

    final allOpen = _weekly.values.every((d) => d.isOpen);
    final first = _weekly.values.first;
    final uniform = _weekly.values
        .every((d) => _eq(d.open, first.open) && _eq(d.close, first.close));
    if (allOpen && uniform) {
      _isWeekly = false;
      _dailyOpen = first.open;
      _dailyClose = first.close;
    } else {
      _isWeekly = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.appBackgroundColor,
      appBar: const CommonBackAppBar(title: 'Lab Availability'),
      // Save lives in the Scaffold's bottom slot rather than as the last child
      // of the body Column — same place on screen, but pinned by the Scaffold
      // and keyboard-aware.
      bottomNavigationBar: _buildSaveBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  14,
                  SizeConfig.size16,
                  14,
                  SizeConfig.size16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Set Your Lab Timings',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      'Choose when your laboratory is open',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(height: SizeConfig.size16),
                    _buildModeToggle(),
                    SizedBox(height: SizeConfig.size16),
                    if (_isWeekly) _buildWeeklyCard() else _buildDailyCard(),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Daily / Weekly segmented toggle ─────────────────────────────
  Widget _buildModeToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const trackPadding = 4.0;
        final pillWidth = (constraints.maxWidth - trackPadding * 2) / 2;
        return Container(
          height: 44,
          padding: const EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: _isWeekly ? pillWidth : 0,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(child: _modeTab(AppStrings.daily.tr, false)),
                    Expanded(child: _modeTab(AppStrings.weekly.tr, true)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modeTab(String label, bool weekly) {
    final selected = _isWeekly == weekly;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isWeekly = weekly),
      child: Center(
        child: CustomText(
          label,
          fontSize: 13.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? Colors.white : AppColors.mainTextColor,
        ),
      ),
    );
  }

  // ── Daily card — one open/close pair applied to every day ───────
  Widget _buildDailyCard() {
    return CustomFormCard(
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.openEveryDay.tr,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          Row(
            children: [
              Expanded(
                child: _timeField(
                  label: AppStrings.openingTime.tr,
                  time: _dailyOpen,
                  onChanged: (t) => setState(() => _dailyOpen = t),
                ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: _timeField(
                  label: AppStrings.closingTime.tr,
                  time: _dailyClose,
                  onChanged: (t) => setState(() => _dailyClose = t),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Weekly card — per-day open toggle + open/close pair ─────────
  Widget _buildWeeklyCard() {
    return CustomFormCard(
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _days.length; i++) ...[
            _buildWeeklyRow(_days[i]),
            if (i != _days.length - 1) ...[
              SizedBox(height: SizeConfig.size12),
              Container(height: 1, color: AppColors.greyE5),
              SizedBox(height: SizeConfig.size12),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyRow(String day) {
    final hours = _weekly[day]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                _dayLabelKey(day).tr,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
            ),
            CustomText(
              hours.isOpen ? AppStrings.open.tr : AppStrings.closed.tr,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hours.isOpen
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
            ),
            SizedBox(width: SizeConfig.size8),
            CustomSwitch(
              value: hours.isOpen,
              containerWidth: 46,
              containerHeight: 26,
              circleSize: 18,
              onChanged: (v) => setState(() => hours.isOpen = v),
            ),
          ],
        ),
        if (hours.isOpen) ...[
          SizedBox(height: SizeConfig.size8),
          Row(
            children: [
              Expanded(
                child: _timeField(
                  label: AppStrings.openingTime.tr,
                  time: hours.open,
                  onChanged: (t) => setState(() => hours.open = t),
                ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: _timeField(
                  label: AppStrings.closingTime.tr,
                  time: hours.close,
                  onChanged: (t) => setState(() => hours.close = t),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Time field rendered as a 24-hour (railway-time) dropdown. Options are
  // generated in 30-minute steps from 00:00 → 23:30 and shown as "HH:mm".
  Widget _timeField({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          label,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
        ),
        SizedBox(height: SizeConfig.size6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TimeOfDay>(
              value: _snap(time),
              isExpanded: true,
              isDense: true,
              borderRadius: BorderRadius.circular(10),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryColor,
              ),
              items: _timeOptions
                  .map(
                    (t) => DropdownMenuItem<TimeOfDay>(
                      value: t,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: SizeConfig.size8),
                          CustomText(
                            _hhmm(t),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (t) {
                if (t != null) onChanged(t);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Save bar pinned at the bottom ───────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        SizeConfig.size12,
        14,
        SizeConfig.size16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: CustomBtn(
        title: AppStrings.save.tr,
        radius: 10,
        bgColor: AppColors.primaryColor,
        isLoading: _isSaving,
        onTap: _onSave,
      ),
    );
  }

  // Validates the timings, assembles the per-day [Schedule] list, persists it
  // through [widget.onSave], then pops back `true`. Daily fans one pair across
  // all seven days; Weekly keeps each day's own hours + open flag. Open days
  // carry explicit HH:MM strings the backend requires; closed days omit them.
  Future<void> _onSave() async {
    final schedule = <Schedule>[];

    if (_isWeekly) {
      final anyOpen = _weekly.values.any((d) => d.isOpen);
      if (!anyOpen) {
        commonSnackBar(message: AppStrings.keepAtLeastOneDayOpen.tr);
        return;
      }
      for (final day in _days) {
        final hours = _weekly[day]!;
        if (hours.isOpen && !_isBefore(hours.open, hours.close)) {
          commonSnackBar(
              message: '${AppStrings.closingTimeMustBeAfterOpening.tr} '
                  '(${_dayLabelKey(day).tr})');
          return;
        }
        schedule.add(
          Schedule(
            day: day,
            isOpen: hours.isOpen,
            shopOpenTime: hours.isOpen ? _hhmm(hours.open) : null,
            shopCloseTime: hours.isOpen ? _hhmm(hours.close) : null,
          ),
        );
      }
    } else {
      if (!_isBefore(_dailyOpen, _dailyClose)) {
        commonSnackBar(message: AppStrings.closingTimeMustBeAfterOpening.tr);
        return;
      }
      for (final day in _days) {
        schedule.add(
          Schedule(
            day: day,
            isOpen: true,
            shopOpenTime: _hhmm(_dailyOpen),
            shopCloseTime: _hhmm(_dailyClose),
          ),
        );
      }
    }

    setState(() => _isSaving = true);
    final err = await widget.onSave(schedule);
    if (!mounted) return;
    if (err != null) {
      setState(() => _isSaving = false);
      commonSnackBar(message: err);
      return;
    }

    Get.back(result: true);
  }

  // ── helpers ─────────────────────────────────────────────────────
  // Selectable 24-hour times in 30-minute steps: 00:00, 00:30 … 23:30.
  static final List<TimeOfDay> _timeOptions = [
    for (int m = 0; m < 24 * 60; m += 30)
      TimeOfDay(hour: m ~/ 60, minute: m % 60),
  ];

  // Snaps an arbitrary time to the nearest 30-minute option so the dropdown
  // always has a matching value (hydrated hours can be off-grid).
  TimeOfDay _snap(TimeOfDay t) {
    final total = t.hour * 60 + t.minute;
    final snapped = (((total + 15) ~/ 30) * 30) % (24 * 60);
    return TimeOfDay(hour: snapped ~/ 60, minute: snapped % 60);
  }

  // "HH:mm" 24-hour serialization for the schedule payload.
  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // Parses a "HH:mm" string back into a TimeOfDay (null on bad input).
  TimeOfDay? _parse(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  // Maps the English weekday data value (kept verbatim in the payload) to
  // its translation key so the UI can show a localized day name.
  String _dayLabelKey(String day) {
    switch (day) {
      case 'Monday':
        return AppStrings.monday;
      case 'Tuesday':
        return AppStrings.tuesday;
      case 'Wednesday':
        return AppStrings.wednesday;
      case 'Thursday':
        return AppStrings.thursday;
      case 'Friday':
        return AppStrings.friday;
      case 'Saturday':
        return AppStrings.saturday;
      case 'Sunday':
        return AppStrings.sunday;
      default:
        return day;
    }
  }

  bool _eq(TimeOfDay a, TimeOfDay b) =>
      a.hour == b.hour && a.minute == b.minute;

  bool _isBefore(TimeOfDay a, TimeOfDay b) =>
      a.hour * 60 + a.minute < b.hour * 60 + b.minute;
}

// Mutable holder for one weekday's open flag + hours in Weekly mode.
class _DayHours {
  bool isOpen;
  TimeOfDay open;
  TimeOfDay close;

  _DayHours({
    required this.isOpen,
    required this.open,
    required this.close,
  });
}
