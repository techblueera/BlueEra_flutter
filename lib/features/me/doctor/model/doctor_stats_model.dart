/// `GET hospital-service/doctors/me/stats` — the doctor's booking analytics.
///
/// All four status counts are always present, even when `0`. An all-zero
/// response is a success, not an empty state.
class DoctorStats {
  final int pending;
  final int accepted;
  final int declined;
  final int cancelled;
  final int total;

  /// Accepted appointments dated today or later.
  final int upcomingAccepted;
  final int certificateCount;

  const DoctorStats({
    this.pending = 0,
    this.accepted = 0,
    this.declined = 0,
    this.cancelled = 0,
    this.total = 0,
    this.upcomingAccepted = 0,
    this.certificateCount = 0,
  });

  factory DoctorStats.fromJson(Map<String, dynamic> json) {
    final appointments = (json['appointments'] is Map)
        ? Map<String, dynamic>.from(json['appointments'] as Map)
        : const <String, dynamic>{};
    int parse(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return DoctorStats(
      pending: parse(appointments['pending']),
      accepted: parse(appointments['accepted']),
      declined: parse(appointments['declined']),
      cancelled: parse(appointments['cancelled']),
      total: parse(appointments['total']),
      upcomingAccepted: parse(json['upcomingAccepted']),
      certificateCount: parse(json['certificateCount']),
    );
  }
}
