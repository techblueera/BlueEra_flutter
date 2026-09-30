import 'dart:async';

import 'package:BlueEra/features/chat/auth/model/symbol_details_model.dart';
import 'package:BlueEra/features/chat/auth/repo/symbol_repo.dart';
import 'package:BlueEra/features/common/notification/model/notification_model.dart';
import 'package:BlueEra/features/common/notification/notification_repo.dart';
import 'package:BlueEra/features/common/notification/service/notification_cache_service.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/debug_log.dart';

/// Drives the notification hub (NotificationScreen): syncs pages from the
/// server into [NotificationCacheService], filters the cached stream by tab and
/// search, and marks read / deletes.
///
/// The list itself lives in the cache (it outlives the screen and absorbs
/// pushes); this only holds what the open screen needs, and is scoped to its
/// route by NotificationBinding.
class NotificationHubController extends GetxController {
  NotificationHubController({
    NotificationListRepo? repo,
    SymbolRepo? symbolRepo,
    NotificationCacheService? cache,
  })  : _repo = repo ?? NotificationListRepo(),
        _symbolRepo = symbolRepo ?? SymbolRepo(),
        cache = cache ?? NotificationCacheService.to;

  final NotificationListRepo _repo;
  final SymbolRepo _symbolRepo;

  /// Local-first store: the list is served from here (Hive-backed) so opening
  /// the hub, switching tabs, marking read and deleting never wait on the API.
  final NotificationCacheService cache;

  /// Stable filter ids (decoupled from the localized tab titles) used for
  /// client-side filtering of the cached "all" stream.
  static const List<String> tabIds = ['All', 'Orders', 'Tags', 'Jobs', 'Posts'];

  final RxInt selectedTab = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSyncing = false.obs;
  final RxBool isLoadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Serve the cache instantly; only touch the network once per app session
    // (or when the cache is empty). Incoming pushes keep the cache fresh in the
    // meantime, so re-opening the hub is a pure local read.
    if (!cache.syncedThisSession || cache.items.isEmpty) {
      syncFirstPage();
    }
  }

  /// Pagination only makes sense on the "All" tab — the filter tabs slice the
  /// already-cached stream client-side, so there are no extra server pages to
  /// pull for them.
  bool get isAllTab => selectedTab.value == 0;

  /// Whether the list should show its pagination footer and fetch more.
  bool get showsMore => isAllTab && cache.hasMore && searchQuery.value.isEmpty;

  bool get canLoadMore => showsMore && !isLoadingMore.value && !isSyncing.value;

  // Call notifications (incoming/missed/cancelled) are delivered under the
  // "chat" notification_type, so they're distinguished by their `type`.
  static bool isCallNotification(NotificationDataList data) {
    const callTypes = {"incoming_call", "missed_call", "call_cancelled"};
    return callTypes.contains(data.type);
  }

  // A chat message notification (personal / group / broadcast) that should be
  // hidden from this list. Calls share the "chat" notification_type but are
  // not messages, so they are excluded from the hide rule.
  static bool isChatMessageNotification(NotificationDataList data) {
    return data.notification_type == "chat" && !isCallNotification(data);
  }

  /// Client-side tab filter over the cached "all" stream.
  static bool _matchesTab(NotificationDataList n, String tabId) {
    final type = (n.notification_type ?? '').toLowerCase();
    switch (tabId) {
      case 'Orders':
        return type == 'orders';
      case 'Tags':
        return type == 'tags';
      case 'Jobs':
        return type == 'jobs';
      case 'Posts':
        return type == 'posts';
      default:
        return true; // "All"
    }
  }

  /// The rows to render: cache filtered by the active tab + search query.
  List<NotificationDataList> get visible {
    final tabId = tabIds[selectedTab.value.clamp(0, tabIds.length - 1)];
    final q = searchQuery.value.toLowerCase().trim();
    return cache.items.where((n) {
      if (isChatMessageNotification(n)) return false;
      if (!_matchesTab(n, tabId)) return false;
      if (q.isEmpty) return true;
      return (n.message ?? '').toLowerCase().contains(q) ||
          (n.metadata?.title ?? '').toLowerCase().contains(q) ||
          (n.metadata?.body ?? '').toLowerCase().contains(q);
    }).toList();
  }

  /// Parse the visible (hub-eligible) items out of a list response. Chat
  /// text/broadcast messages belong to the Chat section and are excluded here.
  List<NotificationDataList> _parseVisible(dynamic data) {
    final list = (data is Map ? data['data'] : null);
    if (list is! List) return [];
    return list
        .map((e) => NotificationDataList.fromJson(e))
        .where((n) => !isChatMessageNotification(n))
        .toList();
  }

  bool _hasNext(dynamic data, int returnedCount) {
    final pg = data is Map ? data['pagination'] : null;
    if (pg is Map && pg['hasNextPage'] is bool)
      return pg['hasNextPage'] as bool;
    return returnedCount >= NotificationCacheService.pageLimit;
  }

  /// Authoritative refresh of page 1 → replaces the cache (keeping any newer
  /// push-only rows). Also the pull-to-refresh handler.
  Future<void> syncFirstPage() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      final response = await _repo.fetchNotificationRepo(
        filterType: "all",
        page: 1,
        limit: NotificationCacheService.pageLimit,
      );
      if (response.isSuccess) {
        final data = response.response!.data;
        final visible = _parseVisible(data);
        await cache.replaceWithServerPage(
          visible,
          hasNext: _hasNext(data, visible.length),
        );
      }
    } catch (e) {
      // Keep whatever is cached — offline / transient failures degrade to the
      // last known list rather than an empty screen.
      debugLog("Notification sync error: $e");
    } finally {
      isSyncing.value = false;
    }
  }

  /// Fetch the next older page on scroll and merge it into the cache.
  Future<void> loadMore() async {
    if (isLoadingMore.value) return;
    isLoadingMore.value = true;
    final nextPage = cache.loadedPages + 1;
    try {
      final response = await _repo.fetchNotificationRepo(
        filterType: "all",
        page: nextPage,
        limit: NotificationCacheService.pageLimit,
      );
      if (response.isSuccess) {
        final data = response.response!.data;
        final visible = _parseVisible(data);
        await cache.appendServerPage(
          visible,
          page: nextPage,
          hasNext: _hasNext(data, visible.length),
        );
      }
    } catch (e) {
      debugLog("Notification load-more error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Optimistic: flip read locally now, sync to the server in the background.
  /// Skips the API for push-only rows (synthetic `local_…` ids the server
  /// doesn't know yet).
  void markRead(String id) {
    cache.markRead(id);
    if (id.isNotEmpty && !id.startsWith('local_')) {
      _repo.notificationReadRepo(notificationId: id);
    }
  }

  /// Clear all — remove from the local cache immediately, then sync the server
  /// in the background (push-only rows never existed server-side).
  Future<void> deleteAll() async {
    await cache.clear();
    // Local state already cleared; a failed server call self-heals on the
    // next successful sync.
    unawaited(_repo.deleteAllNotification().then((_) {}, onError: (_) {}));
  }

  /// Single delete — optimistic local removal, background server delete
  /// (skipped for synthetic push-only ids the server doesn't know). Returns
  /// false when there was nothing to delete.
  Future<bool> deleteOne(String? notifyId) async {
    if (notifyId == null || notifyId.isEmpty) return false;
    await cache.remove(notifyId);
    if (!notifyId.startsWith('local_')) {
      unawaited(_repo
          .deleteNotification(notifyId: notifyId)
          .then((_) {}, onError: (_) {}));
    }
    return true;
  }

  /// The symbol a SYMBOL_CREATED row points at, or null when it can't be
  /// loaded.
  Future<SymbolDetailsModel?> fetchSymbol(String symbolId) async {
    try {
      final response = await _symbolRepo.getSymbolById(symbolId);
      if (!response.isSuccess || response.data == null) return null;
      final responseData = Map<String, dynamic>.from(response.data);
      final symbolJson =
          Map<String, dynamic>.from(responseData['symbol'] ?? {});
      if (responseData['creator'] != null) {
        symbolJson['user'] = responseData['creator'];
      }
      return SymbolDetailsModel.fromJson(symbolJson);
    } catch (_) {
      return null;
    }
  }
}
