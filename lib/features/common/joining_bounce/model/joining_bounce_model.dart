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
  });

  factory JoiningBounce.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return JoiningBounce(
      joiningBounceId: (json['joining_bounce_id'] ?? '').toString(),
      tagId: json['tag_id']?.toString(),
      accountType: json['account_type']?.toString(),
      status: (json['status'] ?? 'none').toString(),
      eligible: json['eligible'] == true,
      progressPercent: asInt(json['progress_percent']),
      bonusInr: asInt(json['bonus_inr']),
      showCard: json['show_card'] is bool ? json['show_card'] as bool : null,
      isClaimed: json['is_claimed'] is bool ? json['is_claimed'] as bool : null,
    );
  }

  bool get isCredited => status == 'credited';

  /// Whether the claim popup should be surfaced at all. Honours the profile's
  /// `show_card`/`is_claimed` when present; otherwise derives from `status`.
  bool get shouldShow {
    if ((isClaimed ?? false) || isCredited) return false;
    if (showCard != null) return showCard!;
    return status == 'in_progress' || status == 'eligible';
  }
}
