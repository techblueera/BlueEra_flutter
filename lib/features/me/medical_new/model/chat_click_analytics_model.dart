/// Models for the centralized chat-click analytics endpoint.
///
/// Endpoint: GET /business/:businessId/chat-clicks
/// Reference: lib/docs/CHAT_CLICK_ANALYTICS_INTEGRATION_GUIDE.md
class ChatClickAnalyticsResponse {
  final bool success;
  final ChatClickAnalyticsMeta? meta;
  final ChatClickAnalyticsData data;

  ChatClickAnalyticsResponse({
    required this.success,
    this.meta,
    required this.data,
  });

  factory ChatClickAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return ChatClickAnalyticsResponse(
      success: json['success'] == true,
      meta: json['meta'] is Map<String, dynamic>
          ? ChatClickAnalyticsMeta.fromJson(json['meta'])
          : null,
      data: ChatClickAnalyticsData.fromJson(
        rawData is Map<String, dynamic> ? rawData : <String, dynamic>{},
      ),
    );
  }
}

class ChatClickAnalyticsMeta {
  final String? businessId;
  final String? format;
  final String? granularity;
  final ChatClickRangeMeta? range;
  final DateTime? generatedAt;

  ChatClickAnalyticsMeta({
    this.businessId,
    this.format,
    this.granularity,
    this.range,
    this.generatedAt,
  });

  factory ChatClickAnalyticsMeta.fromJson(Map<String, dynamic> json) {
    return ChatClickAnalyticsMeta(
      businessId: json['businessId']?.toString(),
      format: json['format']?.toString(),
      granularity: json['granularity']?.toString(),
      range: json['range'] is Map<String, dynamic>
          ? ChatClickRangeMeta.fromJson(json['range'])
          : null,
      generatedAt: _parseDate(json['generated_at']),
    );
  }
}

class ChatClickRangeMeta {
  final String? preset;
  final String? tz;
  final DateTime? from;
  final DateTime? to;

  ChatClickRangeMeta({this.preset, this.tz, this.from, this.to});

  factory ChatClickRangeMeta.fromJson(Map<String, dynamic> json) {
    return ChatClickRangeMeta(
      preset: json['preset']?.toString(),
      tz: json['tz']?.toString(),
      from: _parseDate(json['from'] ?? json['fromIso']),
      to: _parseDate(json['to'] ?? json['toIso']),
    );
  }
}

/// Aggregated container that mirrors `format=full` but is also resilient to
/// partial responses (single-format calls or the legacy lifetime aggregate).
class ChatClickAnalyticsData {
  final ChatClickSummary summary;
  final ChatClickTimeseries? timeseries;
  final ChatClickComparison? comparison;

  ChatClickAnalyticsData({
    required this.summary,
    this.timeseries,
    this.comparison,
  });

  factory ChatClickAnalyticsData.fromJson(Map<String, dynamic> json) {
    final summarySrc =
        json['summary'] is Map<String, dynamic> ? json['summary'] : json;
    final tsSrc = json['timeseries'];
    final compSrc = json['comparison'];

    return ChatClickAnalyticsData(
      summary:
          ChatClickSummary.fromJson(summarySrc as Map<String, dynamic>? ?? {}),
      timeseries: tsSrc is Map<String, dynamic>
          ? ChatClickTimeseries.fromJson(tsSrc)
          : null,
      comparison: compSrc is Map<String, dynamic>
          ? ChatClickComparison.fromJson(compSrc)
          : null,
    );
  }
}

class ChatClickSummary {
  final int totalClicks;
  final int uniqueUsers;
  final double averageClicksPerUser;
  final DateTime? firstClickedAt;
  final DateTime? lastClickedAt;

  ChatClickSummary({
    required this.totalClicks,
    required this.uniqueUsers,
    required this.averageClicksPerUser,
    this.firstClickedAt,
    this.lastClickedAt,
  });

  factory ChatClickSummary.fromJson(Map<String, dynamic> json) {
    return ChatClickSummary(
      totalClicks: _parseInt(json['total_clicks']),
      uniqueUsers: _parseInt(json['unique_users']),
      averageClicksPerUser: _parseDouble(json['average_clicks_per_user']),
      firstClickedAt: _parseDate(json['first_clicked_at']),
      lastClickedAt: _parseDate(json['last_clicked_at']),
    );
  }
}

class ChatClickTimeseries {
  final String? granularity;
  final List<ChatClickSeriesPoint> series;
  final int totalClicks;
  final int totalUniqueUsers;

  ChatClickTimeseries({
    this.granularity,
    required this.series,
    required this.totalClicks,
    required this.totalUniqueUsers,
  });

  factory ChatClickTimeseries.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'];
    final List<ChatClickSeriesPoint> points = rawSeries is List
        ? rawSeries
            .whereType<Map<String, dynamic>>()
            .map(ChatClickSeriesPoint.fromJson)
            .toList()
        : <ChatClickSeriesPoint>[];

    final totals =
        json['totals'] is Map<String, dynamic> ? json['totals'] : const {};
    return ChatClickTimeseries(
      granularity: json['granularity']?.toString(),
      series: points,
      totalClicks: _parseInt(totals['clicks']),
      totalUniqueUsers: _parseInt(totals['unique_users']),
    );
  }
}

class ChatClickSeriesPoint {
  final DateTime? bucket;
  final int clicks;
  final int uniqueUsers;

  ChatClickSeriesPoint({
    required this.bucket,
    required this.clicks,
    required this.uniqueUsers,
  });

  factory ChatClickSeriesPoint.fromJson(Map<String, dynamic> json) {
    return ChatClickSeriesPoint(
      bucket: _parseDate(json['bucket']),
      clicks: _parseInt(json['clicks']),
      uniqueUsers: _parseInt(json['unique_users']),
    );
  }
}

class ChatClickComparison {
  final ChatClickSummary current;
  final ChatClickSummary previous;
  final double clicksPct;
  final double uniqueUsersPct;

  ChatClickComparison({
    required this.current,
    required this.previous,
    required this.clicksPct,
    required this.uniqueUsersPct,
  });

  factory ChatClickComparison.fromJson(Map<String, dynamic> json) {
    final delta =
        json['delta'] is Map<String, dynamic> ? json['delta'] : const {};
    final current = json['current'] is Map<String, dynamic>
        ? ChatClickSummary.fromJson(json['current'])
        : ChatClickSummary.fromJson(const {});
    final previous = json['previous'] is Map<String, dynamic>
        ? ChatClickSummary.fromJson(json['previous'])
        : ChatClickSummary.fromJson(const {});
    return ChatClickComparison(
      current: current,
      previous: previous,
      clicksPct: _parseDouble(delta['clicks_pct']),
      uniqueUsersPct: _parseDouble(delta['unique_users_pct']),
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
