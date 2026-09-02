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

/// Shop availability capture shown right before a Mohalla-Kirana
/// individual grocery seller goes live. The seller declares when their shop is
/// open by setting an open + closing time **per weekday**, plus a per-day
/// open/closed flag.
///
/// Weekly is the only mode. The screen used to also offer a "Daily" mode that
/// fanned one open/close pair across all seven days, but it saved the exact
/// same 7-day payload as Weekly — a second way to enter the same thing, one
/// more state to hydrate into and detect on the way back out. A seller who
/// keeps identical hours all week sets the same two dropdowns seven times,
/// which is the cost of dropping a whole mode.
///
/// On save the screen persists the assembled weekly [Schedule] through the
/// business availability endpoint (`PUT /availability/hours`) and pops back
/// `true`. There is no explicit go-live step: once the hours are saved the
/// shop opens and closes automatically within them (the live state is computed
/// from the schedule + wall clock). A per-day manual override lives in the
/// shop-status sheet, not here.
class ShopAvailabilityScreen extends StatefulWidget {
  /// Optional previously-saved schedule used to pre-fill the form so the
  /// seller edits rather than re-enters their hours.
  final List<Schedule>? initialSchedule;

  /// Persists the assembled 7-day [Schedule]. Returns `null` on success, or an
  /// error message to surface. The host owns the endpoint (business vs
  /// individual), so this screen stays availability-source agnostic.
  final Future<String?> Function(List<Schedule> schedule) onSave;

  const ShopAvailabilityScreen({
    super.key,
    this.initialSchedule,
    required this.onSave,
  });

  @override
  State<ShopAvailabilityScreen> createState() =>
      _ShopAvailabilityScreenState();
}

class _ShopAvailabilityScreenState
    extends State<ShopAvailabilityScreen> {
  // Weekdays in display order — the order of the rows and of the saved
  // schedule.
  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // One editable row per weekday.
  late final Map<String, _DayHours> _weekly;

  // True while the save request is in flight — drives the Save button loader
  // (the availability endpoints no longer show the global progress dialog).
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

  // Pre-fills the rows from a previously-saved schedule when one is passed, so
  // the seller edits their hours rather than re-entering them.
  void _hydrateFromInitial() {
    final saved = widget.initialSchedule;
    if (saved == null || saved.isEmpty) return;

    for (final s in saved) {
      final day = s.day;
      if (day == null || !_weekly.containsKey(day)) continue;
      final slot = (s.timeSlots != null && s.timeSlots!.isNotEmpty)
          ? s.timeSlots!.first
          : null;
      // Prefer the explicit open/close fields; fall back to the mirrored
      // timeSlots for older payloads that predate them.
      _weekly[day] = _DayHours(
        isOpen: s.isOpen ?? true,
        open: _parse(s.shopOpenTime ?? slot?.startTime) ??
            const TimeOfDay(hour: 9, minute: 0),
        close: _parse(s.shopCloseTime ?? slot?.endTime) ??
            const TimeOfDay(hour: 21, minute: 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(title: AppStrings.shopAvailability.tr),
      // Save lives in the Scaffold's bottom slot rather than as the last child
      // of the body Column. Same place on screen, but the Scaffold owns it: it
      // stays pinned without the body needing an Expanded wrapper, and it moves
      // with the keyboard instead of being pushed off by it.
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
                AppStrings.setYourShopTimings.tr,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                AppStrings.shopTimingsSubtitle.tr,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size16),
              _buildWeeklyCard(),
            ],
          ),
        ),
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

  // Time field: the chosen time in 24-hour (railway) form, tapped to open a
  // list of 30-minute steps from 00:00 → 23:30.
  //
  // The list opens in a SHEET rather than living in a `DropdownButton`, and
  // that is a performance fix, not a style change. A DropdownButton builds
  // every one of its items up front — and lays them all out in a hidden stack
  // to size itself — so this screen was building 7 days × 2 fields × 48 options
  // = 672 rows before it could show anything, each an Icon plus a [CustomText]
  // (which runs a `.tr` lookup per build). That is what made the screen take
  // seconds to appear when the Go-Live tap pushed it. Now the closed field is a
  // label, and the 48 rows are built lazily, for one field, only when tapped.
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

  // ── Save bar pinned at the bottom ───────────────────────────────
  //
  // The [SafeArea] is INSIDE the decorated container, not around it: it insets
  // the button by the gesture bar / home indicator so the tap target clears it,
  // while the bar's white fill and top shadow still run to the physical bottom
  // edge instead of leaving a strip of page background under them.
  Widget _buildSaveBar() {
    return Container(
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            SizeConfig.size12,
            14,
            SizeConfig.size16,
          ),
          child: CustomBtn(
            title: AppStrings.save.tr,
            radius: 10,
            bgColor: AppColors.primaryColor,
            isLoading: _isSaving,
            onTap: _onSave,
          ),
        ),
      ),
    );
  }

  // Validates the timings, assembles the per-day [Schedule] list and persists
  // it through the business availability endpoint. Every weekday is sent, each
  // with its own hours and open flag; open days carry explicit
  // shopOpenTime/shopCloseTime (HH:MM) as the backend requires, closed days
  // omit the times. On full success the screen pops back `true` so the caller
  // can reflect the live state.
  Future<void> _onSave() async {
    final schedule = <Schedule>[];

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

    // Persist the weekly schedule via the host (business or individual
    // endpoint). No explicit go-live step: once hours are saved the shop opens
    // and closes automatically within them. A 402 (deposit unpaid) comes back
    // as an error message and is surfaced as a snackbar.
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
