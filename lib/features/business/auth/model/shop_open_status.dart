import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';

/// Effective, right-now open/closed state of a business, derived purely from
/// the weekly [Schedule] + an optional TODAY override + the current wall-clock
/// time. This is what drives the schedule-driven auto open/close: the shop
/// flips ON at its scheduled open time and OFF at its close time with no
/// manual action, and a same-day override (open/close for today only) beats
/// the weekly hours until it auto-reverts tomorrow.
///
/// Pure value type — no I/O. Compute it with [ShopOpenStatus.compute] from the
/// availability the profile already returns, and recompute on a minute timer so
/// the toggle crosses open/close boundaries live.
class ShopOpenStatus {
  /// Open right now (day is open AND current time is within the open window).
  final bool isOpenNow;

  /// Whether the shop is open *at all* today (day-level), override-aware.
  /// A shop can be `openTodayAtAll` but not `isOpenNow` when the clock is
  /// before the open time or after the close time.
  final bool openTodayAtAll;

  /// A same-day override is currently in effect (today's hours were manually
  /// changed and will auto-revert to the weekly schedule tomorrow).
  final bool hasOverrideToday;

  /// Effective open time for today ("HH:mm"), when open today; else null.
  final String? openTime;

  /// Effective close time for today ("HH:mm"), when open today; else null.
  final String? closeTime;

  const ShopOpenStatus({
    required this.isOpenNow,
    required this.openTodayAtAll,
    required this.hasOverrideToday,
    this.openTime,
    this.closeTime,
  });

  const ShopOpenStatus.closed()
      : isOpenNow = false,
        openTodayAtAll = false,
        hasOverrideToday = false,
        openTime = null,
        closeTime = null;

  /// Full-name weekday values used verbatim in the schedule payload.
  static const List<String> _weekdayNames = [
    'Monday', // DateTime.monday == 1
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday', // DateTime.sunday == 7
  ];

  static String weekdayName(DateTime d) => _weekdayNames[d.weekday - 1];

  /// `YYYY-MM-DD` key for the given day (used to match today's override).
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Pick the override that applies to [now] (matching dateKey), if any.
  /// Stale overrides (from a previous day) are ignored — they auto-revert.
  static SpecialOverrides? overrideForToday(
    List<SpecialOverrides>? overrides,
    DateTime now,
  ) {
    if (overrides == null || overrides.isEmpty) return null;
    final key = dateKey(now);
    for (final o in overrides) {
      if (o.dateKey == key || o.date == key) return o;
    }
    return null;
  }

  /// Compute the effective open state for [now] from the weekly [schedule] and
  /// an optional [todayOverride]. The override — when present — replaces the
  /// weekly row for the day entirely (open-all-day when force-opened, closed
  /// when force-closed).
  static ShopOpenStatus compute({
    required List<Schedule>? schedule,
    SpecialOverrides? todayOverride,
    required DateTime now,
  }) {
    final dayName = weekdayName(now);

    Schedule? row;
    if (schedule != null) {
      for (final s in schedule) {
        if (s.day == dayName) {
          row = s;
          break;
        }
      }
    }

    final bool overrideActive = todayOverride != null;
    final bool dayOpen = overrideActive
        ? (todayOverride.isOpen ?? false)
        : (row?.isOpen ?? false);
    final String? open =
        overrideActive ? todayOverride.shopOpenTime : row?.shopOpenTime;
    final String? close =
        overrideActive ? todayOverride.shopCloseTime : row?.shopCloseTime;

    if (!dayOpen) {
      return ShopOpenStatus(
        isOpenNow: false,
        openTodayAtAll: false,
        hasOverrideToday: overrideActive,
        openTime: null,
        closeTime: null,
      );
    }

    final int? openMin = _toMinutes(open);
    final int? closeMin = _toMinutes(close);
    final int nowMin = now.hour * 60 + now.minute;

    // With valid bounds, open only inside [open, close). Missing bounds (older
    // payloads that only stored the open flag) fall back to "open all day".
    final bool openNow = (openMin == null || closeMin == null)
        ? true
        : (nowMin >= openMin && nowMin < closeMin);

    return ShopOpenStatus(
      isOpenNow: openNow,
      openTodayAtAll: true,
      hasOverrideToday: overrideActive,
      openTime: open,
      closeTime: close,
    );
  }

  /// Parse "HH:mm" → minutes-since-midnight (null on bad input).
  static int? _toMinutes(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
