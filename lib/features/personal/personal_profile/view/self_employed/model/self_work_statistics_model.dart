/// Statistics payload for a SELF_EMPLOYED **skilled worker** — electrician,
/// plumber, carpenter, painter, tutor, gardener, AC technician, and the rest of
/// the trades that live under the `selfWork` earn-service profile.
///
/// Contract: `GET earn-service/self-work/statistics?period=today|week|month`.
/// See `docs/backend/SELF_WORK_STATISTICS_API_GUIDE.md` for the full contract,
/// including how every rate below is defined.
///
/// Parsing rules that the whole file obeys:
///  * Every field is optional and defaults to zero / empty. A worker who has
///    never taken a job, and a backend that has not shipped a section yet, both
///    render as an honest zero instead of crashing the tab.
///  * All rates are **percentages (0–100)**, never 0–1 fractions.
///  * All money is in **major units** (rupees), never paise.
class SelfWorkStatisticsModel {
  /// Echo of the requested window — `today` | `week` | `month`.
  final String period;

  /// The worker's trade, e.g. `ELECTRICIAN`. Drives the benchmark copy
  /// ("vs other electricians near you"); empty is fine, the UI falls back to a
  /// generic label.
  final String profession;

  final SelfWorkEarningsStats earnings;
  final SelfWorkJobStats jobs;
  final SelfWorkEnquiryFunnel funnel;

  /// One entry per day in the window, oldest first. Drives the trend chart;
  /// fewer than two points means "no chart", never a flat line of zeros.
  final List<SelfWorkTrendPoint> trend;

  /// Revenue split across the services the worker actually lists on their
  /// Service tab. Already sorted by the backend, highest earning first.
  final List<SelfWorkServiceBreakdown> topServices;

  final SelfWorkReputationStats reputation;
  final SelfWorkAvailabilityStats availability;
  final SelfWorkReachStats reach;
  final SelfWorkBenchmark benchmark;

  const SelfWorkStatisticsModel({
    this.period = 'week',
    this.profession = '',
    this.earnings = const SelfWorkEarningsStats(),
    this.jobs = const SelfWorkJobStats(),
    this.funnel = const SelfWorkEnquiryFunnel(),
    this.trend = const [],
    this.topServices = const [],
    this.reputation = const SelfWorkReputationStats(),
    this.availability = const SelfWorkAvailabilityStats(),
    this.reach = const SelfWorkReachStats(),
    this.benchmark = const SelfWorkBenchmark(),
  });

  factory SelfWorkStatisticsModel.fromJson(Map<String, dynamic> json) {
    return SelfWorkStatisticsModel(
      period: json['period']?.toString() ?? 'week',
      profession: json['profession']?.toString() ?? '',
      earnings: SelfWorkEarningsStats.fromJson(_map(json['earnings'])),
      jobs: SelfWorkJobStats.fromJson(_map(json['jobs'])),
      funnel: SelfWorkEnquiryFunnel.fromJson(_map(json['funnel'])),
      trend: _list(json['trend'], SelfWorkTrendPoint.fromJson),
      topServices:
          _list(json['topServices'], SelfWorkServiceBreakdown.fromJson),
      reputation: SelfWorkReputationStats.fromJson(_map(json['reputation'])),
      availability:
          SelfWorkAvailabilityStats.fromJson(_map(json['availability'])),
      reach: SelfWorkReachStats.fromJson(_map(json['reach'])),
      benchmark: SelfWorkBenchmark.fromJson(_map(json['benchmark'])),
    );
  }

  /// True when there is genuinely nothing worth drawing — picks the empty state
  /// over a wall of zeros. Reach counts as activity: a worker who was found but
  /// not hired still has something to learn from this tab.
  bool get isEmpty =>
      earnings.total == 0 &&
      jobs.completed == 0 &&
      funnel.received == 0 &&
      reach.profileViews == 0;

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static List<T> _list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// What the worker made, and how much of it is actually in hand.
///
/// [total] is authoritative — it is what the backend says was billed, NOT a sum
/// the app recomputes. [collected] + [pending] are the explanation and may not
/// add up exactly (write-offs, adjustments, part payments).
class SelfWorkEarningsStats {
  final String currency;

  /// Billed across completed jobs in the window.
  final double total;

  /// Of [total], what the worker has actually been paid.
  final double collected;

  /// Of [total], what is still owed by customers.
  final double pending;

  /// Backend-computed average ticket. Not `total / completed` — cancelled and
  /// part-billed jobs make that division wrong.
  final double averageJobValue;

  /// Largest single job in the window. Workers use this as their own ceiling.
  final double highestJobValue;

  /// Same window, previous period (last week vs this week). Drives the
  /// up/down delta chip; `0` renders no chip rather than a fake +100%.
  final double previousPeriodTotal;

  const SelfWorkEarningsStats({
    this.currency = 'INR',
    this.total = 0,
    this.collected = 0,
    this.pending = 0,
    this.averageJobValue = 0,
    this.highestJobValue = 0,
    this.previousPeriodTotal = 0,
  });

  factory SelfWorkEarningsStats.fromJson(Map<String, dynamic> json) {
    return SelfWorkEarningsStats(
      currency: json['currency']?.toString() ?? 'INR',
      total: _toDouble(json['total']),
      collected: _toDouble(json['collected']),
      pending: _toDouble(json['pending']),
      averageJobValue: _toDouble(json['averageJobValue']),
      highestJobValue: _toDouble(json['highestJobValue']),
      previousPeriodTotal: _toDouble(json['previousPeriodTotal']),
    );
  }

  /// Percent change vs the previous window, or null when there is no baseline
  /// to compare against (first ever period → no delta, not "+100%").
  double? get changePercent {
    if (previousPeriodTotal <= 0) return null;
    return ((total - previousPeriodTotal) / previousPeriodTotal) * 100;
  }
}

/// The work behind the money.
class SelfWorkJobStats {
  final int completed;

  /// Accepted and not finished yet — the worker's current load.
  final int inProgress;

  final int cancelledByWorker;
  final int cancelledByCustomer;

  /// Jobs from a customer who had already hired this worker before. The single
  /// strongest signal of a healthy trade business.
  final int repeatCustomers;

  /// Time actually spent on jobs (not time online — that is availability).
  final int workedMinutes;

  const SelfWorkJobStats({
    this.completed = 0,
    this.inProgress = 0,
    this.cancelledByWorker = 0,
    this.cancelledByCustomer = 0,
    this.repeatCustomers = 0,
    this.workedMinutes = 0,
  });

  factory SelfWorkJobStats.fromJson(Map<String, dynamic> json) {
    return SelfWorkJobStats(
      completed: _toInt(json['completed']),
      inProgress: _toInt(json['inProgress']),
      cancelledByWorker: _toInt(json['cancelledByWorker']),
      cancelledByCustomer: _toInt(json['cancelledByCustomer']),
      repeatCustomers: _toInt(json['repeatCustomers']),
      workedMinutes: _toInt(json['workedMinutes']),
    );
  }

  int get cancelledTotal => cancelledByWorker + cancelledByCustomer;

  /// Share of completed jobs that came from a returning customer.
  double get repeatRate =>
      completed <= 0 ? 0 : (repeatCustomers / completed) * 100;
}

/// Enquiry → job funnel. This is the section a tradesperson actually acts on:
/// it separates "nobody is calling me" from "people call and I lose them".
class SelfWorkEnquiryFunnel {
  /// Enquiries that reached the worker in the window.
  final int received;

  /// Of [received], how many the worker replied to at all.
  final int responded;

  /// Of [responded], how many got a price quoted.
  final int quoted;

  /// Of [quoted], how many became an accepted job.
  final int converted;

  /// Median (not mean) minutes from enquiry to first reply. Median because one
  /// forgotten enquiry sitting unread for three days would wreck a mean and
  /// tell the worker nothing about their normal behaviour.
  final int medianResponseMinutes;

  /// Enquiries that expired with no reply at all — the money left on the table.
  final int missed;

  const SelfWorkEnquiryFunnel({
    this.received = 0,
    this.responded = 0,
    this.quoted = 0,
    this.converted = 0,
    this.medianResponseMinutes = 0,
    this.missed = 0,
  });

  factory SelfWorkEnquiryFunnel.fromJson(Map<String, dynamic> json) {
    return SelfWorkEnquiryFunnel(
      received: _toInt(json['received']),
      responded: _toInt(json['responded']),
      quoted: _toInt(json['quoted']),
      converted: _toInt(json['converted']),
      medianResponseMinutes: _toInt(json['medianResponseMinutes']),
      missed: _toInt(json['missed']),
    );
  }

  /// Replied / received.
  double get responseRate => received <= 0 ? 0 : (responded / received) * 100;

  /// Won / received — the headline number of this section.
  double get conversionRate => received <= 0 ? 0 : (converted / received) * 100;

  bool get hasAny => received > 0;
}

class SelfWorkTrendPoint {
  /// `yyyy-MM-dd`, the bucket's LOCAL date.
  final String date;
  final double earnings;
  final int jobs;

  const SelfWorkTrendPoint({
    required this.date,
    this.earnings = 0,
    this.jobs = 0,
  });

  factory SelfWorkTrendPoint.fromJson(Map<String, dynamic> json) {
    return SelfWorkTrendPoint(
      date: json['date']?.toString() ?? '',
      earnings: _toDouble(json['earnings']),
      jobs: _toInt(json['jobs']),
    );
  }

  /// Weekday tick for the axis, or the raw string when the date won't parse —
  /// the chart never shows an empty label.
  String get shortLabel {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(parsed.weekday - 1).clamp(0, 6)];
  }
}

/// One row of the "which of my services actually pay" breakdown. [name] must be
/// a string the worker recognises from their own Service tab (a `serviceType` /
/// `serviceOffered` entry), not an internal id.
class SelfWorkServiceBreakdown {
  final String name;
  final int jobs;
  final double earnings;

  /// Share of the window's revenue, 0–100. Sent by the backend rather than
  /// derived here because the list is truncated to the top few — a share
  /// computed over the shown rows would read as 100% of the wrong total.
  final double sharePercent;

  const SelfWorkServiceBreakdown({
    this.name = '',
    this.jobs = 0,
    this.earnings = 0,
    this.sharePercent = 0,
  });

  factory SelfWorkServiceBreakdown.fromJson(Map<String, dynamic> json) {
    return SelfWorkServiceBreakdown(
      name: json['name']?.toString() ?? '',
      jobs: _toInt(json['jobs']),
      earnings: _toDouble(json['earnings']),
      sharePercent: _toDouble(json['sharePercent']),
    );
  }
}

/// What customers say afterwards — the thing that gates every future job.
class SelfWorkReputationStats {
  final double rating;
  final int ratingCount;

  /// Counts for 5★ … 1★, in that order. Length is normalised to 5 by the
  /// parser so the bar list can index it without checking.
  final List<int> distribution;

  /// Jobs finished within the promised window, as a percentage.
  final double onTimeRate;

  /// Reviews left unanswered — a nudge, not a score.
  final int unansweredReviews;

  const SelfWorkReputationStats({
    this.rating = 0,
    this.ratingCount = 0,
    this.distribution = const [0, 0, 0, 0, 0],
    this.onTimeRate = 0,
    this.unansweredReviews = 0,
  });

  factory SelfWorkReputationStats.fromJson(Map<String, dynamic> json) {
    final raw = json['distribution'];
    final parsed = raw is List
        ? raw.map(_toInt).toList()
        : const <int>[];
    // Normalise to exactly five buckets (5★ first) whatever the backend sends.
    final five = List<int>.filled(5, 0);
    for (var i = 0; i < parsed.length && i < 5; i++) {
      five[i] = parsed[i];
    }
    return SelfWorkReputationStats(
      rating: _toDouble(json['rating']),
      ratingCount: _toInt(json['ratingCount']),
      distribution: five,
      onTimeRate: _toDouble(json['onTimeRate']),
      unansweredReviews: _toInt(json['unansweredReviews']),
    );
  }

  /// A worker with no ratings yet must never be shown "0.0 out of 5".
  bool get hasRating => ratingCount > 0 && rating > 0;

  /// Largest bucket, used to scale the distribution bars.
  int get maxBucket =>
      distribution.isEmpty ? 0 : distribution.reduce((a, b) => a > b ? a : b);
}

/// Being reachable is half the job for a trade. This is the "were you actually
/// open for business" section, driven by the same go-live the Service tab uses.
class SelfWorkAvailabilityStats {
  /// Minutes spent live (accepting work) in the window.
  final int liveMinutes;

  /// Days with at least one live minute.
  final int daysLive;

  /// Days in the window — the denominator for [coverageRate].
  final int daysInPeriod;

  /// Accepted / offered jobs, as a percentage.
  final double acceptanceRate;

  const SelfWorkAvailabilityStats({
    this.liveMinutes = 0,
    this.daysLive = 0,
    this.daysInPeriod = 0,
    this.acceptanceRate = 0,
  });

  factory SelfWorkAvailabilityStats.fromJson(Map<String, dynamic> json) {
    return SelfWorkAvailabilityStats(
      liveMinutes: _toInt(json['liveMinutes']),
      daysLive: _toInt(json['daysLive']),
      daysInPeriod: _toInt(json['daysInPeriod']),
      acceptanceRate: _toDouble(json['acceptanceRate']),
    );
  }

  /// Share of the window's days the worker was available at all.
  double get coverageRate =>
      daysInPeriod <= 0 ? 0 : (daysLive / daysInPeriod) * 100;

  bool get hasAny => liveMinutes > 0 || daysLive > 0;
}

/// Top of the funnel — how many people saw the worker before anyone enquired.
class SelfWorkReachStats {
  final int profileViews;

  /// Times the worker appeared in a Discover / search result list.
  final int searchImpressions;

  final int callTaps;
  final int chatTaps;
  final int directionTaps;

  const SelfWorkReachStats({
    this.profileViews = 0,
    this.searchImpressions = 0,
    this.callTaps = 0,
    this.chatTaps = 0,
    this.directionTaps = 0,
  });

  factory SelfWorkReachStats.fromJson(Map<String, dynamic> json) {
    return SelfWorkReachStats(
      profileViews: _toInt(json['profileViews']),
      searchImpressions: _toInt(json['searchImpressions']),
      callTaps: _toInt(json['callTaps']),
      chatTaps: _toInt(json['chatTaps']),
      directionTaps: _toInt(json['directionTaps']),
    );
  }

  int get contactTaps => callTaps + chatTaps + directionTaps;

  /// Of the people who saw the listing, how many reached out.
  double get contactRate =>
      profileViews <= 0 ? 0 : (contactTaps / profileViews) * 100;

  bool get hasAny => profileViews > 0 || searchImpressions > 0;
}

/// The worker against their own trade in their own area — the "industry level"
/// view. Percentiles are 0–100 and mean "you are above this share of your
/// peers", so higher is always better, including for response time (the backend
/// inverts that one before sending it).
class SelfWorkBenchmark {
  /// Human label for the peer group, e.g. `Electricians in Indore`. The app
  /// does NOT build this string — pluralisation and locale live server-side.
  final String peerGroupLabel;

  /// How many peers the comparison is drawn from. Below the backend's minimum
  /// the whole section is suppressed via [isReliable].
  final int peerCount;

  final double earningsPercentile;
  final double ratingPercentile;
  final double responsePercentile;

  /// Peer medians, for the "you 4.6 · them 4.2" comparison rows.
  final double peerMedianEarnings;
  final double peerMedianRating;
  final int peerMedianResponseMinutes;

  const SelfWorkBenchmark({
    this.peerGroupLabel = '',
    this.peerCount = 0,
    this.earningsPercentile = 0,
    this.ratingPercentile = 0,
    this.responsePercentile = 0,
    this.peerMedianEarnings = 0,
    this.peerMedianRating = 0,
    this.peerMedianResponseMinutes = 0,
  });

  factory SelfWorkBenchmark.fromJson(Map<String, dynamic> json) {
    return SelfWorkBenchmark(
      peerGroupLabel: json['peerGroupLabel']?.toString() ?? '',
      peerCount: _toInt(json['peerCount']),
      earningsPercentile: _toDouble(json['earningsPercentile']),
      ratingPercentile: _toDouble(json['ratingPercentile']),
      responsePercentile: _toDouble(json['responsePercentile']),
      peerMedianEarnings: _toDouble(json['peerMedianEarnings']),
      peerMedianRating: _toDouble(json['peerMedianRating']),
      peerMedianResponseMinutes: _toInt(json['peerMedianResponseMinutes']),
    );
  }

  /// A comparison against three other electricians is noise, not insight, and
  /// in a thin market it also leaks individual behaviour. The backend enforces
  /// the same floor; this is the client's second line of defence.
  static const int minimumPeers = 5;

  bool get isReliable => peerCount >= minimumPeers;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _toInt(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
