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

/// Hotel weekly-hours capture — hotel equivalent of [LabAvailabilityScreen].
/// Owners declare when the hotel front desk is open, either Daily (same hours
/// every day) or Weekly (per-day toggle + per-day open/close), and the
/// assembled 7-day [Schedule] is persisted via the caller-supplied [onSave].
/// The card in the overview tab opens this and calls the shared business
/// availability endpoint; on success the screen pops back `true` so the
/// caller can refresh.
///
/// Kept as its own file (rather than reusing the lab screen) so the copy —
/// appbar title, header, subtitle — stays hotel-flavoured without a shared
/// abstraction. The mechanics are otherwise identical.
class HotelAvailabilityScreen extends StatefulWidget {
  /// Optional previously-saved schedule used to pre-fill the form.
  final List<Schedule>? initialSchedule;

  /// Persists the assembled 7-day [Schedule]. Returns `null` on success,
  /// otherwise an error message to surface as a snackbar.
  final Future<String?> Function(List<Schedule> schedule) onSave;

  const HotelAvailabilityScreen({
    super.key,
    this.initialSchedule,
    required this.onSave,
  });

  @override
  State<HotelAvailabilityScreen> createState() =>
      _HotelAvailabilityScreenState();
}

class _HotelAvailabilityScreenState extends State<HotelAvailabilityScreen> {
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

  TimeOfDay _dailyOpen = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _dailyClose = const TimeOfDay(hour: 21, minute: 0);

  late final Map<String, _DayHours> _weekly;

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
      appBar: const CommonBackAppBar(title: 'Hotel Availability'),
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
                      'Set Your Hotel Timings',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size4),
                    CustomText(
                      'Choose when your hotel is open',
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

  // Time field: the chosen time in 24-hour (railway) form, tapped to open a
  // list of 30-minute steps from 00:00 → 23:30.
  //
  // The list opens in a SHEET rather than living in a `DropdownButton`, and
  // that is a performance fix, not a style change. A DropdownButton builds
  // every one of its items up front — and lays them all out in a hidden stack
  // to size itself — so every field here built all 48 options before the screen
  // could show anything, each an Icon plus a [CustomText] (which runs a `.tr`
  // lookup per build). That is what made the hours editor take seconds to open.
  // Now the closed field is a label, and the 48 rows are built lazily, for one
  // field, only when tapped. Same fix as `ShopAvailabilityScreen`.
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
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _pickTime(label: label, current: time, onChanged: onChanged),
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.greyE5, width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: CustomText(
                    _hhmm(_snap(time)),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The 30-minute options, as a lazily-built list. Opens scrolled to the
  /// current value so the common edit — a step or two either side — is right
  /// under the thumb instead of 20 rows away.
  Future<void> _pickTime({
    required String label,
    required TimeOfDay current,
    required ValueChanged<TimeOfDay> onChanged,
  }) async {
    const rowHeight = 48.0;
    final snapped = _snap(current);
    final selected = _timeOptions.indexWhere(
      (t) => t.hour == snapped.hour && t.minute == snapped.minute,
    );

    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: SizeConfig.size12),
              CustomText(
                label,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size8),
              Container(height: 1, color: AppColors.greyE5),
              SizedBox(
                // Capped so the sheet is a list to scroll, not a full-screen
                // takeover for a two-tap edit.
                height: rowHeight * 7,
                child: ListView.builder(
                  itemExtent: rowHeight,
                  controller: ScrollController(
                    // Three rows of context above the current value.
                    initialScrollOffset:
                        selected <= 3 ? 0 : (selected - 3) * rowHeight,
                  ),
                  itemCount: _timeOptions.length,
                  itemBuilder: (_, i) {
                    final option = _timeOptions[i];
                    final isSelected = i == selected;
                    return InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(option),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size16),
                        color: isSelected
                            ? AppColors.primaryColor.withValues(alpha: 0.08)
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.secondaryTextColor,
                            ),
                            SizedBox(width: SizeConfig.size8),
                            CustomText(
                              _hhmm(option),
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.mainTextColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: SizeConfig.size8),
            ],
          ),
        );
      },
    );

    if (picked != null) onChanged(picked);
  }

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

  static final List<TimeOfDay> _timeOptions = [
    for (int m = 0; m < 24 * 60; m += 30)
      TimeOfDay(hour: m ~/ 60, minute: m % 60),
  ];

  TimeOfDay _snap(TimeOfDay t) {
    final total = t.hour * 60 + t.minute;
    final snapped = (((total + 15) ~/ 30) * 30) % (24 * 60);
    return TimeOfDay(hour: snapped ~/ 60, minute: snapped % 60);
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay? _parse(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

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
