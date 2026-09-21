/// The body of `GET /user/account/inactivity/status`.
///
/// This is the inactive-account DATA PURGE, not account deletion: an account
/// left untouched for [thresholdDays] has its content erased while the account
/// itself — phone number, login, wallet balance, active subscription — stays
/// exactly where it was. `/user/account/deletion` is a different flow with its
/// own OTP and is unaffected by any of this.
///
/// See docs/backend/FLUTTER_INACTIVE_USER_DATA_PURGE_GUIDE.md §4.
class InactivityStatusModel {
  const InactivityStatusModel({
    this.success = false,
    this.dataPurged = false,
    this.dataPurgedAt,
    this.purgeCount = 0,
    this.lastActivityAt,
    this.inactiveDays,
    this.thresholdDays,
    this.warningLeadDays,
    this.daysUntilPurge,
    this.showWarning = false,
    this.warningSentAt,
  });

  final bool success;

  /// The account's content has ALREADY been erased. Branch on this to show the
  /// "your data was removed" screen once, then `/acknowledge` it.
  final bool dataPurged;

  final DateTime? dataPurgedAt;

  /// Diagnostics only — one account can be purged more than once over its
  /// lifetime.
  final int purgeCount;

  final DateTime? lastActivityAt;
  final int? inactiveDays;

  /// Display only. Never hardcode 90 — retention policy is server-side config
  /// and can change without an app release.
  final int? thresholdDays;

  /// Display only, same reason as [thresholdDays].
  final int? warningLeadDays;

  /// Copy for the warning banner ("… in N days").
  final int? daysUntilPurge;

  /// The purge is close enough to warn about. Read the flag — do NOT recompute
  /// it from [inactiveDays], or the app and the backend can disagree the day
  /// the retention policy changes.
  final bool showWarning;

  final DateTime? warningSentAt;

  /// Tolerates a non-Map body (a proxy error page, an empty 204) by answering
  /// "nothing to show", which is the only safe default: every caller treats a
  /// false [dataPurged] / [showWarning] as "carry on into the app".
  factory InactivityStatusModel.fromJson(dynamic json) {
    if (json is! Map) return const InactivityStatusModel();
    return InactivityStatusModel(
      success: _bool(json['success']),
      dataPurged: _bool(json['data_purged']),
      dataPurgedAt: _date(json['data_purged_at']),
      purgeCount: _int(json['purge_count']) ?? 0,
      lastActivityAt: _date(json['last_activity_at']),
      inactiveDays: _int(json['inactive_days']),
      thresholdDays: _int(json['threshold_days']),
      warningLeadDays: _int(json['warning_lead_days']),
      daysUntilPurge: _int(json['days_until_purge']),
      showWarning: _bool(json['show_warning']),
      warningSentAt: _date(json['warning_sent_at']),
    );
  }

  /// Booleans have arrived as `true`, `"true"` and `1` from different services
  /// in this backend; all three mean the same thing.
  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v?.toString().toLowerCase() == 'true';
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  static DateTime? _date(dynamic v) {
    final raw = v?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
