/// Models for the profile-visit analytics endpoint.
///
/// Endpoint: GET /profile-visit/:userId/profile-visits
/// Example response `data` (format=summary):
///   {
///     "total_visits": 1,
///     "first_visited_at": "...",
///     "last_visited_at": "...",
///     "unique_users": 1,
///     "average_visits_per_user": 1
///   }
///
/// The endpoint currently returns a summary only (no timeseries). An optional
/// `timeseries.series[]` is parsed defensively so the UI's trend chart lights
/// up automatically if a richer (full) format is enabled server-side later.
class ProfileVisitAnalyticsResponse {
  final bool success;
  final ProfileVisitData data;

  ProfileVisitAnalyticsResponse({required this.success, required this.data});

  factory ProfileVisitAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return ProfileVisitAnalyticsResponse(
      success: json['success'] == true,
      data: ProfileVisitData.fromJson(
        raw is Map<String, dynamic> ? raw : const <String, dynamic>{},
      ),
    );
  }
}

class ProfileVisitData {
  final ProfileVisitSummary summary;
  final List<ProfileVisitPoint> series;

  ProfileVisitData({required this.summary, required this.series});

  factory ProfileVisitData.fromJson(Map<String, dynamic> json) {
    // Summary lives at `data` root (summary format) or nested under
    // `data.summary` (full format) — accept either.
    final summarySrc =
        json['summary'] is Map<String, dynamic> ? json['summary'] : json;

    final ts = json['timeseries'];
    final rawSeries = ts is Map<String, dynamic> ? ts['series'] : null;
    final series = rawSeries is List
        ? rawSeries
            .whereType<Map<String, dynamic>>()
            .map(ProfileVisitPoint.fromJson)
            .toList()
        : <ProfileVisitPoint>[];

    return ProfileVisitData(
      summary:
          ProfileVisitSummary.fromJson(summarySrc as Map<String, dynamic>),
      series: series,
    );
  }
}

class ProfileVisitSummary {
  final int totalVisits;
  final int uniqueUsers;
  final double averageVisitsPerUser;
  final DateTime? firstVisitedAt;
  final DateTime? lastVisitedAt;

  ProfileVisitSummary({
    required this.totalVisits,
    required this.uniqueUsers,
    required this.averageVisitsPerUser,
    this.firstVisitedAt,
    this.lastVisitedAt,
  });

  factory ProfileVisitSummary.fromJson(Map<String, dynamic> json) {
    return ProfileVisitSummary(
      totalVisits: _parseInt(json['total_visits']),
      uniqueUsers: _parseInt(json['unique_users']),
      averageVisitsPerUser: _parseDouble(json['average_visits_per_user']),
      firstVisitedAt: _parseDate(json['first_visited_at']),
      lastVisitedAt: _parseDate(json['last_visited_at']),
    );
  }
}

class ProfileVisitPoint {
  final DateTime? bucket;
  final int visits;
  final int uniqueUsers;

  ProfileVisitPoint({
    required this.bucket,
    required this.visits,
    required this.uniqueUsers,
  });

  factory ProfileVisitPoint.fromJson(Map<String, dynamic> json) {
    return ProfileVisitPoint(
      bucket: _parseDate(json['bucket']),
      visits: _parseInt(json['visits']),
      uniqueUsers: _parseInt(json['unique_users']),
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  final str = raw.toString();
  if (str.isEmpty) return null;
  return DateTime.tryParse(str);
}

int _parseInt(dynamic raw) {
  if (raw == null) return 0;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString()) ?? 0;
}

double _parseDouble(dynamic raw) {
  if (raw == null) return 0.0;
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString()) ?? 0.0;
}
