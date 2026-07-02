import 'dart:developer';

import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/coin/model/earn_coin_models.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/coin/repo/earn_coin_repo.dart';
import 'package:get/get.dart';

/// Drives the Coin Wallet card + the 5-tab "View Details" screen.
/// Read-only except [redeem]. Contract: docs/backend/FLUTTER-MASTER-GUIDE.md.
class EarnCoinController extends GetxController {
  final EarnCoinRepo _repo = EarnCoinRepo();

  // ── Balance (coin chip + Coin Wallet card + details header) ──────────
  final Rxn<CoinBalance> balance = Rxn<CoinBalance>();
  final RxBool balanceLoading = false.obs;

  Future<void> fetchBalance() async {
    // Guard against duplicate in-flight calls (e.g. the coin chip and the
    // Coin Wallet card both requesting on the same frame).
    if (balanceLoading.value) return;
    balanceLoading.value = true;
    try {
      final res = await _repo.getBalance();
      final data = res.data;
      if (res.isSuccess && data is Map) {
        balance.value = CoinBalance.fromJson(data.cast<String, dynamic>());
      }
    } catch (e, s) {
      log('fetchBalance error: $e\n$s');
    } finally {
      balanceLoading.value = false;
    }
  }

  // ── Dashboard tab ────────────────────────────────────────────────────
  final Rxn<EarnDashboard> dashboard = Rxn<EarnDashboard>();
  final RxBool dashboardLoading = false.obs;

  Future<void> fetchDashboard() async {
    dashboardLoading.value = true;
    try {
      final res = await _repo.getDashboard();
      final data = res.data;
      if (res.isSuccess && data is Map) {
        dashboard.value = EarnDashboard.fromJson(data.cast<String, dynamic>());
        // The dashboard payload carries a fresh balance too — keep the header
        // and Coin Wallet card in sync without a second call.
        balance.value = dashboard.value!.balance;
      }
    } catch (e, s) {
      log('fetchDashboard error: $e\n$s');
    } finally {
      dashboardLoading.value = false;
    }
  }

  // ── Tasks tab ────────────────────────────────────────────────────────
  final Rxn<TaskSummary> taskSummary = Rxn<TaskSummary>();
  final RxList<EarnTask> tasks = <EarnTask>[].obs;
  final RxBool tasksLoading = false.obs;

  Future<void> fetchTasks() async {
    tasksLoading.value = true;
    try {
      final res = await _repo.getTasks();
      final data = res.data;
      if (res.isSuccess && data is Map) {
        final map = data.cast<String, dynamic>();
        taskSummary.value = TaskSummary.fromJson(
            (map['summary'] as Map?)?.cast<String, dynamic>() ?? const {});
        tasks.value = ((map['tasks'] as List?) ?? const [])
            .map((e) => EarnTask.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      }
    } catch (e, s) {
      log('fetchTasks error: $e\n$s');
    } finally {
      tasksLoading.value = false;
    }
  }

  // ── History tab (cursor paginated) ───────────────────────────────────
  final RxList<EarnHistoryItem> history = <EarnHistoryItem>[].obs;
  final RxBool historyLoading = false.obs;
  final RxBool historyLoadingMore = false.obs;
  final RxBool historyHasMore = true.obs;
  String? _historyCursor;

  Future<void> fetchHistory({bool refresh = false}) async {
    if (refresh) {
      _historyCursor = null;
      historyHasMore.value = true;
    }
    historyLoading.value = true;
    try {
      final res = await _repo.getHistory();
      if (res.isSuccess && res.data is List) {
        history.value = (res.data as List)
            .map((e) =>
                EarnHistoryItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        _applyHistoryPagination(res.getExtraData('pagination'));
      }
    } catch (e, s) {
      log('fetchHistory error: $e\n$s');
    } finally {
      historyLoading.value = false;
    }
  }

  Future<void> loadMoreHistory() async {
    if (historyLoadingMore.value ||
        historyLoading.value ||
        !historyHasMore.value ||
        _historyCursor == null) {
      return;
    }
    historyLoadingMore.value = true;
    try {
      final res = await _repo.getHistory(cursor: _historyCursor);
      if (res.isSuccess && res.data is List) {
        history.addAll((res.data as List)
            .map((e) =>
                EarnHistoryItem.fromJson((e as Map).cast<String, dynamic>())));
        _applyHistoryPagination(res.getExtraData('pagination'));
      }
    } catch (e, s) {
      log('loadMoreHistory error: $e\n$s');
    } finally {
      historyLoadingMore.value = false;
    }
  }

  void _applyHistoryPagination(dynamic pagination) {
    if (pagination is Map) {
      _historyCursor = pagination['nextCursor']?.toString();
      historyHasMore.value = pagination['hasMore'] == true;
    } else {
      historyHasMore.value = false;
    }
  }

  // ── Rank tab ─────────────────────────────────────────────────────────
  final Rxn<Leaderboard> leaderboard = Rxn<Leaderboard>();
  final RxBool leaderboardLoading = false.obs;

  Future<void> fetchLeaderboard() async {
    leaderboardLoading.value = true;
    try {
      final res = await _repo.getLeaderboard();
      final data = res.data;
      if (res.isSuccess && data is Map) {
        leaderboard.value = Leaderboard.fromJson(data.cast<String, dynamic>());
      }
    } catch (e, s) {
      log('fetchLeaderboard error: $e\n$s');
    } finally {
      leaderboardLoading.value = false;
    }
  }

  // ── Streak tab ───────────────────────────────────────────────────────
  final Rxn<Streak> streak = Rxn<Streak>();
  final RxBool streakLoading = false.obs;

  Future<void> fetchStreak() async {
    streakLoading.value = true;
    try {
      final res = await _repo.getStreak();
      final data = res.data;
      if (res.isSuccess && data is Map) {
        streak.value = Streak.fromJson(data.cast<String, dynamic>());
      }
    } catch (e, s) {
      log('fetchStreak error: $e\n$s');
    } finally {
      streakLoading.value = false;
    }
  }

  // ── Redeem (coins → ₹) ───────────────────────────────────────────────
  final RxBool redeeming = false.obs;

  /// Returns true on success. Enforces the ≥5000 / multiple-of-100 rules
  /// client-side for instant feedback before hitting the server.
  Future<bool> redeem(int coins) async {
    final min = balance.value?.minRedeemCoins ?? 5000;
    if (coins < min) {
      commonSnackBar(message: 'Redeem at least $min coins.');
      return false;
    }
    if (coins % 100 != 0) {
      commonSnackBar(message: 'Coins must be a multiple of 100.');
      return false;
    }
    redeeming.value = true;
    try {
      final res = await _repo.redeem(coins: coins);
      if (res.isSuccess) {
        commonSnackBar(message: res.message?.toString() ?? 'Redeemed');
        await fetchBalance();
        return true;
      }
      commonSnackBar(message: res.message?.toString() ?? 'Redeem failed');
      return false;
    } catch (e, s) {
      log('redeem error: $e\n$s');
      commonSnackBar(message: 'Redeem failed. Try again.');
      return false;
    } finally {
      redeeming.value = false;
    }
  }
}
