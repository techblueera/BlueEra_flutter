import 'dart:convert';

import 'package:BlueEra/features/common/notification/model/notification_model.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Local-first cache for the notification-hub list (`NotificationScreen`).
///
/// Backed by a plain Hive box holding a `List` of JSON strings — the same
/// adapter-free pattern used by `BlueEraNotificationController`. Each entry is a
/// [NotificationDataList] round-tripped through its existing `toJson`/`fromJson`.
///
/// Goals (see notification_screen.dart):
///  * Load the list once per app session from the server, then serve it from
///    here so opening the hub, switching filter tabs, marking read, and
///    deleting never block on the network.
///  * Absorb newly-arrived FCM pushes immediately via [upsertFromPush] so the
///    hub reflects them without an API round-trip.
///
/// Reconciliation: push-inserted rows get a synthetic `local_…` id (the push
/// payload carries no server `_id`). On the next authoritative server sync
/// ([replaceWithServerPage]) those local rows are dropped once the server has
/// caught up (only rows strictly newer than the newest server row survive).
class NotificationCacheService extends GetxController {
  static const String _boxName = 'notification_hub_cache';
  static const String _itemsKey = 'items';

  /// Hard cap so a long-lived install can't grow the box without bound. Matches
  /// the BlueEra thread's cap order-of-magnitude.
  static const int _maxItems = 500;

  /// Server page size requested by the hub. Used to decide `hasMore` when the
  /// response omits explicit pagination flags.
  static const int pageLimit = 20;

  /// Prefix marking a row synthesised from a push (no server `_id` yet).
  static const String _localIdPrefix = 'local_';

  /// Newest-first list of cached notifications (hub-visible only).
  final RxList<NotificationDataList> items = <NotificationDataList>[].obs;

  /// Highest server page number currently merged in (0 = none yet).
  int loadedPages = 0;

  /// Whether the server has more (older) pages beyond what's cached.
  bool hasMore = true;

  /// True once a server sync has completed this app run — lets the screen skip
  /// the network on subsequent opens and serve the cache directly.
  bool syncedThisSession = false;

  Box? _box;

  /// Lazily-registered singleton so the FCM handler can push into the cache
  /// even before the hub UI has ever been opened.
  static NotificationCacheService get to =>
      Get.isRegistered<NotificationCacheService>()
          ? Get.find<NotificationCacheService>()
          : Get.put(NotificationCacheService(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      final raw = _box?.get(_itemsKey);
      if (raw is List) {
        final loaded = raw
            .map((e) {
              try {
                return NotificationDataList.fromJson(
                    Map<String, dynamic>.from(jsonDecode(e.toString())));
              } catch (_) {
                return null;
              }
            })
            .whereType<NotificationDataList>()
            .toList();
        _sortDesc(loaded);
        items.assignAll(loaded);
      }
    } catch (_) {
      // Best-effort — a storage failure just means an empty hub this run.
    }
  }

  /// Replace the cache with an authoritative first page from the server. Any
  /// push-inserted (`local_…`) rows strictly newer than the newest server row
  /// are preserved (the server hasn't surfaced them yet); the rest are dropped
  /// since the server list now supersedes them.
  Future<void> replaceWithServerPage(
    List<NotificationDataList> server, {
    required bool hasNext,
  }) async {
    final int newestServer = server.isEmpty
        ? 0
        : server.map(_millis).fold<int>(0, (a, b) => b > a ? b : a);
    final keptLocal = items
        .where((e) =>
            (e.sId ?? '').startsWith(_localIdPrefix) && _millis(e) > newestServer)
        .toList();

    final merged = _dedupById([...server, ...keptLocal]);
    _sortDesc(merged);
    items.assignAll(merged);

    loadedPages = 1;
    hasMore = hasNext;
    syncedThisSession = true;
    _trim();
    await _persist();
  }

  /// Merge an older page (page > 1) fetched on scroll.
  Future<void> appendServerPage(
    List<NotificationDataList> server, {
    required int page,
    required bool hasNext,
  }) async {
    final merged = _dedupById([...items, ...server]);
    _sortDesc(merged);
    items.assignAll(merged);

    loadedPages = page;
    hasMore = hasNext;
    _trim();
    await _persist();
  }

  /// Insert a notification synthesised from an FCM push. Deduped/positioned by
  /// time; carries a synthetic id so a later server sync can reconcile it.
  Future<void> upsertFromPush({
    required String operation,
    required String title,
    required String body,
    List<String> images = const [],
    String senderName = '',
    String senderImage = '',
  }) async {
    if (title.trim().isEmpty && body.trim().isEmpty) return;
    final now = DateTime.now();
    final item = NotificationDataList(
      sId: '$_localIdPrefix${now.millisecondsSinceEpoch}',
      type: operation,
      status: 'UNREAD',
      createdAt: now.toIso8601String(),
      message: body.trim().isNotEmpty ? body : title,
      metadata: Metadata(
        title: title,
        body: body,
        message: body,
        senderName: senderName,
        originalOperation: operation,
      ),
      senderProfile: (senderName.isNotEmpty || senderImage.isNotEmpty)
          ? SenderProfile(name: senderName, profileImage: senderImage)
          : null,
    );
    await upsert(item);
  }

  /// Add or replace a single row (matched by server `_id`).
  Future<void> upsert(NotificationDataList item) async {
    final id = item.sId ?? '';
    if (id.isNotEmpty) items.removeWhere((e) => e.sId == id);
    items.add(item);
    _sortDesc(items);
    _trim();
    await _persist();
  }

  /// Flip a row to READ locally (optimistic — the API call is fired separately).
  Future<void> markRead(String id) async {
    final i = items.indexWhere((e) => e.sId == id);
    if (i == -1 || items[i].status == 'READ') return;
    items[i].status = 'READ';
    items.refresh();
    await _persist();
  }

  /// Remove a single row locally (optimistic delete).
  Future<void> remove(String id) async {
    final before = items.length;
    items.removeWhere((e) => e.sId == id);
    if (items.length != before) await _persist();
  }

  /// Clear every cached row (optimistic clear-all).
  Future<void> clear() async {
    items.clear();
    hasMore = false;
    loadedPages = 0;
    await _persist();
  }

  // ---- helpers -------------------------------------------------------------

  int _millis(NotificationDataList n) {
    final s = n.createdAt;
    if (s == null || s.isEmpty) return 0;
    return DateTime.tryParse(s)?.millisecondsSinceEpoch ?? 0;
  }

  void _sortDesc(List<NotificationDataList> l) =>
      l.sort((a, b) => _millis(b).compareTo(_millis(a)));

  /// Keep the first occurrence of each server `_id`; rows without an id (should
  /// not happen) are all kept.
  List<NotificationDataList> _dedupById(List<NotificationDataList> l) {
    final seen = <String>{};
    final out = <NotificationDataList>[];
    for (final n in l) {
      final id = n.sId ?? '';
      if (id.isEmpty) {
        out.add(n);
        continue;
      }
      if (seen.add(id)) out.add(n);
    }
    return out;
  }

  void _trim() {
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }
  }

  Future<void> _persist() async {
    try {
      _box ??= Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      final encoded = items.map((m) => jsonEncode(m.toJson())).toList();
      await _box?.put(_itemsKey, encoded);
    } catch (_) {}
  }
}
