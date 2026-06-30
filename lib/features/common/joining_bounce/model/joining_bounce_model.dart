/// The joining-bonus "progress payload" — the shape returned by
/// `GET /joining-bounce/current` and embedded as `joining_bounce` in the
/// profile responses. Only the fields the app reads are parsed.
class JoiningBounce {
  final String joiningBounceId;
  final String? tagId;
  final String? accountType;

  /// none | in_progress | eligible | credited | cancelled | expired
  final String status;

  /// true ⇒ the user can Claim now.
  final bool eligible;

  /// 0–100.
  final int progressPercent;

  /// Display amount in rupees.
  final int bonusInr;

  /// Present in the profile-embedded object; null when read from `/current`.
  final bool? showCard;
  final bool? isClaimed;

  /// Whether the user is enrolled in the joining-bonus program.
  final bool? enrolled;

  const JoiningBounce({
    required this.joiningBounceId,
    required this.status,
    required this.eligible,
    required this.progressPercent,
    required this.bonusInr,
    this.tagId,
    this.accountType,
    this.showCard,
    this.isClaimed,
    this.enrolled,
  });

  factory JoiningBounce.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    bool? asBool(dynamic v) => v is bool ? v : null;
    return JoiningBounce(
      joiningBounceId: (json['joining_bounce_id'] ?? '').toString(),
      tagId: json['tag_id']?.toString(),
      accountType: json['account_type']?.toString(),
      status: (json['status'] ?? 'none').toString(),
      eligible: json['eligible'] == true,
      progressPercent: asInt(json['progress_percent']),
      bonusInr: asInt(json['bonus_inr']),
      showCard: asBool(json['show_card']),
      isClaimed: asBool(json['is_claimed']),
      enrolled: asBool(json['enrolled']),
    );
  }

  bool get isCredited => status == 'credited';

  /// Whether the scratch card should be surfaced. Driven solely by the
  /// backend's `show_card` flag — the server already folds in `enrolled`
  /// and not-claimed, so the client never computes its own gate and the two
  /// can never disagree.
  bool get shouldShow => showCard == true;
}
