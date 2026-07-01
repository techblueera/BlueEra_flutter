/// The Joining Bounce **progress object** returned (inside `data`) by
/// `enroll`, `activity`, `milestone`, `current`, `my-bounces` and
/// `:id/progress`. Field names match the backend exactly — see
/// `docs/backend/JOINING_BOUNCE_FLUTTER_GUIDE.md` §5.
class JoiningBounceProgress {
  final String? joiningBounceId;
  final String? tagId;
  final String? accountType; // "BUSINESS" | "INDIVIDUAL"
  final String? status; // in_progress | eligible | credited | cancelled | expired
  final bool isActive;
  final int bonusAmount; // paise
  final int bonusInr; // whole rupees, for display
  final String? currency;
  final int progressPercent; // 0–100
  final int completedCount; // e.g. "2 of 9 Completed" → 2
  final int totalCount; //     e.g. "2 of 9 Completed" → 9
  final bool eligible;
  final JoiningBounceRequirements? requirements;
  final int daysActive;
  final num totalHours;
  final int totalTasks;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final List<String> completedMilestones;
  final DateTime? enrolledAt;
  final DateTime? eligibleAt;
  final DateTime? creditedAt;
  final int creditedAmount;

  JoiningBounceProgress({
    this.joiningBounceId,
    this.tagId,
    this.accountType,
    this.status,
    this.isActive = false,
    this.bonusAmount = 0,
    this.bonusInr = 0,
    this.currency,
    this.progressPercent = 0,
    this.completedCount = 0,
    this.totalCount = 0,
    this.eligible = false,
    this.requirements,
    this.daysActive = 0,
    this.totalHours = 0,
    this.totalTasks = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.completedMilestones = const [],
    this.enrolledAt,
    this.eligibleAt,
    this.creditedAt,
    this.creditedAmount = 0,
  });

  factory JoiningBounceProgress.fromJson(Map<String, dynamic> json) {
    return JoiningBounceProgress(
      joiningBounceId: json['joining_bounce_id']?.toString(),
      tagId: json['tag_id']?.toString(),
      accountType: json['account_type']?.toString(),
      status: json['status']?.toString(),
      isActive: json['is_active'] == true,
      bonusAmount: _toInt(json['bonus_amount']),
      bonusInr: _toInt(json['bonus_inr']),
      currency: json['currency']?.toString(),
      progressPercent: _toInt(json['progress_percent']),
      completedCount: _toInt(json['completed_count']),
      totalCount: _toInt(json['total_count']),
      eligible: json['eligible'] == true,
      requirements: json['requirements'] is Map
          ? JoiningBounceRequirements.fromJson(
              Map<String, dynamic>.from(json['requirements']))
          : null,
      daysActive: _toInt(json['days_active']),
      totalHours: (json['total_hours'] is num) ? json['total_hours'] as num : 0,
      totalTasks: _toInt(json['total_tasks']),
      currentStreak: _toInt(json['current_streak']),
      longestStreak: _toInt(json['longest_streak']),
      lastActiveDate: _toDate(json['last_active_date']),
      completedMilestones: (json['completed_milestones'] is List)
          ? List<String>.from(
              (json['completed_milestones'] as List).map((e) => e.toString()))
          : const [],
      enrolledAt: _toDate(json['enrolled_at']),
      eligibleAt: _toDate(json['eligible_at']),
      creditedAt: _toDate(json['credited_at']),
      creditedAmount: _toInt(json['credited_amount']),
    );
  }

  // ── Derived display helpers ─────────────────────────────────────────────

  bool get isBusiness => (accountType ?? '').toUpperCase() == 'BUSINESS';
  bool get isIndividual => (accountType ?? '').toUpperCase() == 'INDIVIDUAL';

  bool get isInProgress => status == 'in_progress';
  bool get isEligible => eligible || status == 'eligible';
  bool get isCredited => status == 'credited';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  /// Human title from the raw `tag_id` (e.g. `GENERAL_STORE` → "General Store").
  String get title {
    final raw = (tagId ?? '').trim();
    if (raw.isEmpty) return 'Joining Bonus';
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// Short status caption shown on the right of the row.
  String get statusLabel {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'eligible':
        return 'Eligible to Claim';
      case 'credited':
        return 'Credited';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      default:
        return status ?? '';
    }
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// `requirements` block — one [JoiningBounceRequirement] per metric plus the
/// named-milestone tracker.
class JoiningBounceRequirements {
  final JoiningBounceRequirement? days;
  final JoiningBounceRequirement? hours;
  final JoiningBounceRequirement? tasks;
  final JoiningBounceRequirement? streak;
  final JoiningBounceMilestones? milestones;

  JoiningBounceRequirements({
    this.days,
    this.hours,
    this.tasks,
    this.streak,
    this.milestones,
  });

  factory JoiningBounceRequirements.fromJson(Map<String, dynamic> json) {
    JoiningBounceRequirement? req(dynamic v) => v is Map
        ? JoiningBounceRequirement.fromJson(Map<String, dynamic>.from(v))
        : null;
    return JoiningBounceRequirements(
      days: req(json['days']),
      hours: req(json['hours']),
      tasks: req(json['tasks']),
      streak: req(json['streak']),
      milestones: json['milestones'] is Map
          ? JoiningBounceMilestones.fromJson(
              Map<String, dynamic>.from(json['milestones']))
          : null,
    );
  }
}

class JoiningBounceRequirement {
  final String? label; // e.g. "Go Live Count (Days)", "Live Hour"
  final String? unit; //  e.g. "Days", "hrs", "Tasks"
  final num required;
  final num current;
  final bool met;

  JoiningBounceRequirement({
    this.label,
    this.unit,
    this.required = 0,
    this.current = 0,
    this.met = false,
  });

  factory JoiningBounceRequirement.fromJson(Map<String, dynamic> json) {
    return JoiningBounceRequirement(
      label: json['label']?.toString(),
      unit: json['unit']?.toString(),
      required: (json['required'] is num) ? json['required'] as num : 0,
      current: (json['current'] is num) ? json['current'] as num : 0,
      met: json['met'] == true,
    );
  }
}

class JoiningBounceMilestones {
  final List<String> required;
  final List<String> completed;
  final List<String> missing;
  final bool met;

  /// Rich per-milestone rows (key/label/current/target/met) — drives the
  /// Joining Bonus task checklist. Preferred over the flat key lists above.
  final List<JoiningBounceMilestoneItem> items;

  JoiningBounceMilestones({
    this.required = const [],
    this.completed = const [],
    this.missing = const [],
    this.met = false,
    this.items = const [],
  });

  factory JoiningBounceMilestones.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic v) => (v is List)
        ? List<String>.from(v.map((e) => e.toString()))
        : const [];
    return JoiningBounceMilestones(
      required: list(json['required']),
      completed: list(json['completed']),
      missing: list(json['missing']),
      met: json['met'] == true,
      items: (json['items'] is List)
          ? (json['items'] as List)
              .whereType<Map>()
              .map((e) => JoiningBounceMilestoneItem.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// One milestone row from `requirements.milestones.items`.
class JoiningBounceMilestoneItem {
  final String key;
  final String label;
  final num current;
  final num target;
  final bool met;

  JoiningBounceMilestoneItem({
    this.key = '',
    this.label = '',
    this.current = 0,
    this.target = 0,
    this.met = false,
  });

  factory JoiningBounceMilestoneItem.fromJson(Map<String, dynamic> json) {
    return JoiningBounceMilestoneItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      current: (json['current'] is num) ? json['current'] as num : 0,
      target: (json['target'] is num) ? json['target'] as num : 0,
      met: json['met'] == true,
    );
  }
}
