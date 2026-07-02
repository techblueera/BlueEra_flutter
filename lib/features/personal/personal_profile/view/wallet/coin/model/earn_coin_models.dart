// Data models for the Earn-Coin (gamification) system.
// Contract: docs/backend/FLUTTER-MASTER-GUIDE.md. Every model is null-safe —
// the backend may omit fields for a brand-new user (coins:0, empty lists).

int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

bool _bool(dynamic v) => v == true;

DateTime? _date(dynamic v) =>
    (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;

/// `GET /earn/balance` → coin chip + Coin Wallet card.
class CoinBalance {
  final int coins;
  final int xp;
  final int lifetimeCoins;
  final int redeemedCoins;
  final int level;
  final int coinsPerRupee;
  final int minRedeemCoins;
  final List<String> badges;

  const CoinBalance({
    this.coins = 0,
    this.xp = 0,
    this.lifetimeCoins = 0,
    this.redeemedCoins = 0,
    this.level = 0,
    this.coinsPerRupee = 100,
    this.minRedeemCoins = 5000,
    this.badges = const [],
  });

  factory CoinBalance.fromJson(Map<String, dynamic> j) => CoinBalance(
        coins: _int(j['coins']),
        xp: _int(j['xp']),
        lifetimeCoins: _int(j['lifetimeCoins']),
        redeemedCoins: _int(j['redeemedCoins']),
        level: _int(j['level']),
        coinsPerRupee: _int(j['coins_per_rupee'], 100),
        minRedeemCoins: _int(j['min_redeem_coins'], 5000),
        badges: List<String>.from(j['badges'] ?? const []),
      );

  /// ₹ value of the current coin balance (100 coins → ₹1 by default).
  double get rupeeEquivalent => coinsPerRupee == 0 ? 0 : coins / coinsPerRupee;
}

/// `GET /earn/dashboard` → the whole Dashboard tab in one call.
class EarnDashboard {
  final CoinBalance balance;
  final int streak;

  /// Total active earning days — shown as the Dashboard "Days" stat.
  ///
  /// ⚠️ FRONTEND GAP: `GET /earn/dashboard` does NOT currently return this.
  /// We read `data.streak.days` / `data.activeDays` if present, else fall back
  /// to `longestStreak`, else 0. See docs/backend/EARN-COIN-FRONTEND-GAPS.md.
  final int activeDays;
  final bool checkedInToday;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final List<EarnTask> tasks;
  final List<EarnHistoryItem> recent;

  const EarnDashboard({
    this.balance = const CoinBalance(),
    this.streak = 0,
    this.activeDays = 0,
    this.checkedInToday = false,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.tasks = const [],
    this.recent = const [],
  });

  factory EarnDashboard.fromJson(Map<String, dynamic> j) {
    final streakObj = (j['streak'] as Map?)?.cast<String, dynamic>() ?? const {};
    final summary =
        (j['taskSummary'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EarnDashboard(
      balance: CoinBalance.fromJson(
          (j['balance'] as Map?)?.cast<String, dynamic>() ?? const {}),
      streak: _int(streakObj['streak']),
      // Not in the API yet — best-effort fallbacks (see doc).
      activeDays: _int(streakObj['days'],
          _int(j['activeDays'], _int(streakObj['longestStreak']))),
      checkedInToday: _bool(streakObj['checkedInToday']),
      totalTasks: _int(summary['total']),
      completedTasks: _int(summary['completed']),
      pendingTasks: _int(summary['pending'], _int(j['pendingTasks'])),
      tasks: ((j['tasks'] as List?) ?? const [])
          .map((e) => EarnTask.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      recent: ((j['recent'] as List?) ?? const [])
          .map((e) =>
              EarnHistoryItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// Summary block returned by `GET /earn/tasks`.
class TaskSummary {
  final int total;
  final int completed;
  final int pending;
  final int percent;

  const TaskSummary({
    this.total = 0,
    this.completed = 0,
    this.pending = 0,
    this.percent = 0,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> j) => TaskSummary(
        total: _int(j['total']),
        completed: _int(j['completed']),
        pending: _int(j['pending']),
        percent: _int(j['percent']),
      );
}

/// A single task (Tasks tab + Dashboard pending tasks). Note the coin field is
/// singular `coin` here (history/recent use plural `coins`).
class EarnTask {
  final String id;
  final String title;
  final String eventName;
  final String badge;
  final String cta;
  final int coin;
  final int xp;
  final int progress; // 0–100
  final int taskOrder;
  final bool completed;
  final bool repeatable;

  const EarnTask({
    this.id = '',
    this.title = '',
    this.eventName = '',
    this.badge = '',
    this.cta = '',
    this.coin = 0,
    this.xp = 0,
    this.progress = 0,
    this.taskOrder = 0,
    this.completed = false,
    this.repeatable = false,
  });

  factory EarnTask.fromJson(Map<String, dynamic> j) => EarnTask(
        id: j['id']?.toString() ?? '',
        title: (j['title'] ?? j['event_name'] ?? '').toString(),
        eventName: j['event_name']?.toString() ?? '',
        badge: j['badge']?.toString() ?? '',
        cta: j['cta']?.toString() ?? '',
        coin: _int(j['coin']),
        xp: _int(j['xp']),
        progress: _int(j['progress']),
        taskOrder: _int(j['task_order']),
        completed: _bool(j['completed']),
        repeatable: _bool(j['repeatable']),
      );
}

/// A row in the History tab (and Dashboard "Recent Earning"). Negative [coins]
/// means a debit (redeem/refund).
class EarnHistoryItem {
  final String id;
  final String title;
  final String eventName;
  final String status; // CREDITED / DEBITED
  final String type; // CREDIT / DEBIT
  final int coins;
  final int xp;
  final DateTime? createdAt;

  const EarnHistoryItem({
    this.id = '',
    this.title = '',
    this.eventName = '',
    this.status = '',
    this.type = '',
    this.coins = 0,
    this.xp = 0,
    this.createdAt,
  });

  factory EarnHistoryItem.fromJson(Map<String, dynamic> j) => EarnHistoryItem(
        id: j['id']?.toString() ?? '',
        title: (j['title'] ?? j['event_name'] ?? '').toString(),
        eventName: j['event_name']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        coins: _int(j['coins']),
        xp: _int(j['xp']),
        createdAt: _date(j['createdAt']),
      );

  bool get isDebit => type.toUpperCase() == 'DEBIT' || coins < 0;
}

/// One row in the Rank tab leaderboard.
class LeaderboardEntry {
  final int rank;
  final int coins;
  final int xp;
  final String userId;
  final String name;
  final String avatar;
  final bool isMe;

  const LeaderboardEntry({
    this.rank = 0,
    this.coins = 0,
    this.xp = 0,
    this.userId = '',
    this.name = '',
    this.avatar = '',
    this.isMe = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: _int(j['rank']),
        coins: _int(j['coins']),
        xp: _int(j['xp']),
        userId: j['userId']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        avatar: j['avatar']?.toString() ?? '',
        isMe: _bool(j['isMe']),
      );
}

/// `GET /earn/leaderboard` → the full Rank tab (`entries` + `me`).
class Leaderboard {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? me;

  const Leaderboard({this.entries = const [], this.me});

  factory Leaderboard.fromJson(Map<String, dynamic> j) => Leaderboard(
        entries: ((j['entries'] as List?) ?? const [])
            .map((e) =>
                LeaderboardEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        me: j['me'] is Map
            ? LeaderboardEntry.fromJson((j['me'] as Map).cast<String, dynamic>())
            : null,
      );
}

/// `GET /earn/streak` → the Streak tab.
class Streak {
  final int streak;
  final int longestStreak;
  final bool checkedInToday;
  final DateTime? lastEarnedAt;

  const Streak({
    this.streak = 0,
    this.longestStreak = 0,
    this.checkedInToday = false,
    this.lastEarnedAt,
  });

  factory Streak.fromJson(Map<String, dynamic> j) => Streak(
        streak: _int(j['streak']),
        longestStreak: _int(j['longestStreak']),
        checkedInToday: _bool(j['checkedInToday']),
        lastEarnedAt: _date(j['lastEarnedAt']),
      );
}
