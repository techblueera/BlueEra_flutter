/// Rider earnings + performance dashboard payload.
///
/// Contract: `GET rider-service/riders/statistics?period=today|week|month`.
/// Every field is optional and defaults to zero — a rider who has never taken a
/// trip, and a backend that has not shipped a section yet, both render as an
/// honest zero rather than crashing the tab.
///
/// See `docs/backend/RIDER_STATISTICS_API_GUIDE.md` for the full contract.
class RiderStatisticsModel {
  final String period;

  /// The window the numbers cover, as the backend computed it in the rider's
  /// timezone. Shown under the period tabs so "this week" is never ambiguous.
  final RiderStatsRange range;

  final RiderEarningsStats earnings;
  final RiderTripStats trips;
  final RiderPerformanceStats performance;

  /// One entry per day in the selected period, oldest first. Drives the trend
  /// chart; empty means "no chart", never a flat line of zeros.
  final List<RiderTrendPoint> trend;

  final RiderPayoutStats payouts;

  /// Which fields the backend cannot source yet. Drives card visibility — see
  /// [RiderStatsMeta].
  final RiderStatsMeta meta;

  const RiderStatisticsModel({
    this.period = 'today',
    this.range = const RiderStatsRange(),
    this.earnings = const RiderEarningsStats(),
    this.trips = const RiderTripStats(),
    this.performance = const RiderPerformanceStats(),
    this.trend = const [],
    this.payouts = const RiderPayoutStats(),
    this.meta = const RiderStatsMeta(),
  });

  factory RiderStatisticsModel.fromJson(Map<String, dynamic> json) {
    final trendRaw = json['trend'];
    return RiderStatisticsModel(
      period: json['period']?.toString() ?? 'today',
      range: RiderStatsRange.fromJson(_map(json['range'])),
      earnings: RiderEarningsStats.fromJson(_map(json['earnings'])),
      trips: RiderTripStats.fromJson(_map(json['trips'])),
      performance: RiderPerformanceStats.fromJson(_map(json['performance'])),
      trend: trendRaw is List
          ? trendRaw
              .whereType<Map>()
              .map((e) => RiderTrendPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      payouts: RiderPayoutStats.fromJson(_map(json['payouts'])),
      meta: RiderStatsMeta.fromJson(_map(json['_meta'])),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  /// True when there is genuinely nothing to show — used to pick the empty
  /// state over a grid of zeros.
  bool get isEmpty =>
      earnings.total == 0 && trips.completed == 0 && trips.onlineMinutes == 0;
}

/// The window the numbers cover — `range.from` / `range.to`, ISO-8601 with the
/// rider's local UTC offset (`2026-08-03T00:00:00+05:30`).
///
/// Held as plain calendar dates, not instants. See [_calendarDate] for why that
/// is the only correct reading of these two strings.
class RiderStatsRange {
  final DateTime? from;
  final DateTime? to;

  const RiderStatsRange({this.from, this.to});

  factory RiderStatsRange.fromJson(Map<String, dynamic> json) {
    return RiderStatsRange(
      from: _calendarDate(json['from']),
      to: _calendarDate(json['to']),
    );
  }

  /// Both ends present, so the header has something to show. A backend that
  /// omits `range` renders no line rather than a half one.
  bool get isComplete => from != null && to != null;

  /// Takes the DATE PART of the string and reads it as a plain local date.
  ///
  /// `DateTime.parse("2026-08-03T00:00:00+05:30")` is correct but not what we
  /// want: it returns the equivalent UTC *instant* (02 Aug 18:30Z), whose
  /// `.day` is **2**, so a week starting Monday the 3rd would print as starting
  /// Sunday the 2nd. `.toLocal()` fixes that only for devices in the rider's
  /// timezone and re-breaks it for anyone travelling.
  ///
  /// The backend already computed these boundaries in the rider's timezone
  /// (guide §1), so the calendar date it wrote down IS the answer — no
  /// conversion should happen on this side at all.
  static DateTime? _calendarDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.split('T').first);
  }
}

/// `data._meta` — the backend telling us which numbers it cannot source yet.
///
/// `be_rider_service` returns the FULL contract shape whether or not it can fill
/// it, so a zero on its own is ambiguous: it means either "this rider earned
/// nothing in tips" or "there is no tips ledger at all". `unavailable` is what
/// separates the two, and the view gates on it rather than on the value.
///
/// The payoff is that nothing here needs shipping again. The day the settlement
/// service starts feeding real payouts, the backend drops those paths from the
/// list and the cards light up on their own. See
/// docs/backend/RIDER_STATISTICS_FLUTTER_GUIDE.md §2 and §10.
///
/// Paths are dotted and exact: `earnings.tips`, `trips.onlineMinutes`,
/// `payouts.pending`, …
class RiderStatsMeta {
  final List<String> unavailable;

  const RiderStatsMeta({this.unavailable = const []});

  factory RiderStatsMeta.fromJson(Map<String, dynamic> json) {
    final raw = json['unavailable'];
    return RiderStatsMeta(
      unavailable: raw is List
          ? raw.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }

  /// True when the backend really provides [path].
  ///
  /// Defaults to TRUE for an unknown path, and an absent `_meta` therefore
  /// means "everything is real". That is the right default: a backend that has
  /// stopped flagging gaps is a backend that has filled them, and the failure
  /// mode is showing an honest zero rather than silently hiding a card the
  /// rider is owed.
  bool has(String path) => !unavailable.contains(path);
}

/// What the rider made, and where it came from. [total] is authoritative: it is
/// what the backend says was earned, NOT a sum the app recomputes — the parts
/// are for explanation only and may not add up exactly (rounding, adjustments).
class RiderEarningsStats {
  final String currency;
  final double total;
  final double tripFare;
  final double incentives;
  final double tips;

  /// Commission / platform fee already taken out of [total].
  final double deductions;

  const RiderEarningsStats({
    this.currency = 'INR',
    this.total = 0,
    this.tripFare = 0,
    this.incentives = 0,
    this.tips = 0,
    this.deductions = 0,
  });

  factory RiderEarningsStats.fromJson(Map<String, dynamic> json) {
    return RiderEarningsStats(
      currency: json['currency']?.toString() ?? 'INR',
      total: _toDouble(json['total']),
      tripFare: _toDouble(json['tripFare']),
      incentives: _toDouble(json['incentives']),
      tips: _toDouble(json['tips']),
      deductions: _toDouble(json['deductions']),
    );
  }
}

class RiderTripStats {
  final int completed;
  final int cancelledByRider;
  final int cancelledByCustomer;
  final double distanceKm;
  final int onlineMinutes;

  const RiderTripStats({
    this.completed = 0,
    this.cancelledByRider = 0,
    this.cancelledByCustomer = 0,
    this.distanceKm = 0,
    this.onlineMinutes = 0,
  });

  factory RiderTripStats.fromJson(Map<String, dynamic> json) {
    return RiderTripStats(
      completed: _toInt(json['completed']),
      cancelledByRider: _toInt(json['cancelledByRider']),
      cancelledByCustomer: _toInt(json['cancelledByCustomer']),
      distanceKm: _toDouble(json['distanceKm']),
      onlineMinutes: _toInt(json['onlineMinutes']),
    );
  }

  int get cancelledTotal => cancelledByRider + cancelledByCustomer;
}

/// The numbers a rider is measured on. Rates are PERCENTAGES (0–100) — the
/// guide is explicit about that, because 0–1 fractions here would silently
/// render every rider at 1%.
class RiderPerformanceStats {
  final double acceptanceRate;
  final double cancellationRate;
  final double completionRate;
  final double rating;
  final int ratingCount;

  const RiderPerformanceStats({
    this.acceptanceRate = 0,
    this.cancellationRate = 0,
    this.completionRate = 0,
    this.rating = 0,
    this.ratingCount = 0,
  });

  factory RiderPerformanceStats.fromJson(Map<String, dynamic> json) {
    return RiderPerformanceStats(
      acceptanceRate: _toDouble(json['acceptanceRate']),
      cancellationRate: _toDouble(json['cancellationRate']),
      completionRate: _toDouble(json['completionRate']),
      rating: _toDouble(json['rating']),
      ratingCount: _toInt(json['ratingCount']),
    );
  }

  /// Whether the backend sent a rating at all — a rider with no ratings yet
  /// must not be shown a 0.0 out of 5.
  bool get hasRating => ratingCount > 0 && rating > 0;
}

class RiderTrendPoint {
  /// `yyyy-MM-dd`, the bucket's local date.
  final String date;
  final double earnings;
  final int trips;

  const RiderTrendPoint({
    required this.date,
    this.earnings = 0,
    this.trips = 0,
  });

  factory RiderTrendPoint.fromJson(Map<String, dynamic> json) {
    return RiderTrendPoint(
      date: json['date']?.toString() ?? '',
      earnings: _toDouble(json['earnings']),
      trips: _toInt(json['trips']),
    );
  }

  /// Single-letter-ish weekday for the axis (`Mon`), or the raw string when the
  /// date can't be parsed — the chart never shows an empty tick.
  ///
  /// Only meaningful for a window of a week or less. A month brings the same
  /// weekday round four or five times, so the chart uses [dayLabel] there.
  String get shortLabel {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(parsed.weekday - 1).clamp(0, 6)];
  }

  /// Day of the month (`1`, `14`, `31`), for windows long enough that weekday
  /// names repeat.
  String get dayLabel {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.day}';
  }

  /// `14 Aug` — used where a bare weekday or day number would be ambiguous out
  /// of the axis's context, like the "best day" caption under the chart.
  String get mediumLabel {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${parsed.day} ${months[(parsed.month - 1).clamp(0, 11)]}';
  }
}

class RiderPayoutStats {
  final double pending;
  final double lastAmount;
  final String? lastPaidAt;

  const RiderPayoutStats({
    this.pending = 0,
    this.lastAmount = 0,
    this.lastPaidAt,
  });

  factory RiderPayoutStats.fromJson(Map<String, dynamic> json) {
    return RiderPayoutStats(
      pending: _toDouble(json['pending']),
      lastAmount: _toDouble(json['lastAmount']),
      lastPaidAt: json['lastPaidAt']?.toString(),
    );
  }

  bool get hasAny => pending > 0 || lastAmount > 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _toInt(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
