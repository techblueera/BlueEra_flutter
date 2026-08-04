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
  final RiderEarningsStats earnings;
  final RiderTripStats trips;
  final RiderPerformanceStats performance;

  /// One entry per day in the selected period, oldest first. Drives the trend
  /// chart; empty means "no chart", never a flat line of zeros.
  final List<RiderTrendPoint> trend;

  final RiderPayoutStats payouts;

  const RiderStatisticsModel({
    this.period = 'today',
    this.earnings = const RiderEarningsStats(),
    this.trips = const RiderTripStats(),
    this.performance = const RiderPerformanceStats(),
    this.trend = const [],
    this.payouts = const RiderPayoutStats(),
  });

  factory RiderStatisticsModel.fromJson(Map<String, dynamic> json) {
    final trendRaw = json['trend'];
    return RiderStatisticsModel(
      period: json['period']?.toString() ?? 'today',
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
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  /// True when there is genuinely nothing to show — used to pick the empty
  /// state over a grid of zeros.
  bool get isEmpty =>
      earnings.total == 0 && trips.completed == 0 && trips.onlineMinutes == 0;
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
  String get shortLabel {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(parsed.weekday - 1).clamp(0, 6)];
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
