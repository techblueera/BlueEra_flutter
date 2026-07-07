import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// A single broadcast / system notification rendered inside the in-app
/// "BlueEra" chat thread (profile updates, admin announcements, etc.).
class BlueEraNotificationItem {
  final String title;
  final String body;
  final String operation;
  final int timeMillis;

  /// Image URLs attached to a broadcast (e.g. admin_broadcast with photos),
  /// rendered like a chat image+text message. Empty for plain text pushes.
  final List<String> images;
  bool read;

  BlueEraNotificationItem({
    required this.title,
    required this.body,
    required this.operation,
    required this.timeMillis,
    this.images = const [],
    this.read = false,
  });

  bool get hasImages => images.isNotEmpty;

  static bool _isVideo(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv');
  }

  /// Preview text shown as the chat-list row's "last message".
  String get preview {
    if (body.trim().isNotEmpty) return body.trim();
    if (images.isNotEmpty) {
      return _isVideo(images.first) ? '🎥 Video' : '📷 Photo';
    }
    return title.trim();
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'operation': operation,
        'timeMillis': timeMillis,
        'images': images,
        'read': read,
      };

  factory BlueEraNotificationItem.fromMap(Map<String, dynamic> map) =>
      BlueEraNotificationItem(
        title: (map['title'] ?? '').toString(),
        body: (map['body'] ?? '').toString(),
        operation: (map['operation'] ?? '').toString(),
        timeMillis: (map['timeMillis'] is int)
            ? map['timeMillis'] as int
            : int.tryParse('${map['timeMillis']}') ?? 0,
        images: (map['images'] is List)
            ? (map['images'] as List)
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList()
            : const [],
        read: map['read'] == true,
      );
}

/// Persists incoming FCM broadcast/system notifications and exposes them as a
/// reactive list so a single pinned "BlueEra" row in the personal chat list —
/// and the [BlueEraNotificationScreen] it opens — stay in sync.
///
/// Backed by a plain Hive box (list of JSON strings), so no adapter/codegen is
/// needed. Capture happens from [AppNotificationHandler] whenever a non-chat,
/// non-call push is received in the foreground or tapped from the background.
class BlueEraNotificationController extends GetxController {
  static const String _boxName = 'blueera_notifications';
  static const String _itemsKey = 'items';
  static const int _maxItems = 300;

  /// Newest-first list of stored notifications.
  final RxList<BlueEraNotificationItem> messages =
      <BlueEraNotificationItem>[].obs;

  Box? _box;

  /// Lazily-registered singleton accessor so the notification handler can
  /// capture pushes even before the chat UI has been opened.
  static BlueEraNotificationController get to =>
      Get.isRegistered<BlueEraNotificationController>()
          ? Get.find<BlueEraNotificationController>()
          : Get.put(BlueEraNotificationController(), permanent: true);

  /// Number of unread notifications — drives the row's unread badge.
  int get unreadCount => messages.where((m) => !m.read).length;

  /// Newest notification, if any — drives the row's preview + time.
  BlueEraNotificationItem? get latest =>
      messages.isEmpty ? null : messages.first;

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
                return BlueEraNotificationItem.fromMap(
                    Map<String, dynamic>.from(jsonDecode(e.toString())));
              } catch (_) {
                return null;
              }
            })
            .whereType<BlueEraNotificationItem>()
            .toList();
        loaded.sort((a, b) => b.timeMillis.compareTo(a.timeMillis));
        messages.assignAll(loaded);
      }
    } catch (_) {
      // Best-effort — a storage failure just means an empty thread this run.
    }
  }

  /// Append a freshly-received notification. De-duplicates a burst of the same
  /// push (e.g. foreground render + a later tap) by ignoring an identical
  /// title/body/operation that arrives within a few seconds of the last one.
  Future<void> addNotification({
    required String title,
    required String body,
    required String operation,
    List<String>? images,
    int? timeMillis,
  }) async {
    final now = timeMillis ?? _nowMillis();
    final imgs = images ?? const <String>[];
    if (title.trim().isEmpty && body.trim().isEmpty && imgs.isEmpty) return;

    final key = '$operation|$title|$body|${imgs.join(',')}';
    final recent = messages.isNotEmpty ? messages.first : null;
    if (recent != null &&
        '${recent.operation}|${recent.title}|${recent.body}|${recent.images.join(',')}' ==
            key &&
        (now - recent.timeMillis).abs() < 5000) {
      return;
    }

    messages.insert(
      0,
      BlueEraNotificationItem(
        title: title,
        body: body,
        operation: operation,
        timeMillis: now,
        images: imgs,
        read: false,
      ),
    );
    if (messages.length > _maxItems) {
      messages.removeRange(_maxItems, messages.length);
    }
    await _persist();
  }

  /// Mark the whole thread as read — called when the user opens the screen.
  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    for (final m in messages) {
      m.read = true;
    }
    messages.refresh();
    await _persist();
  }

  /// Clear the entire thread.
  Future<void> clearAll() async {
    messages.clear();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      _box ??= Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      final encoded = messages.map((m) => jsonEncode(m.toMap())).toList();
      await _box?.put(_itemsKey, encoded);
    } catch (_) {}
  }

  // DateTime.now() is available in the app isolate (unlike workflow scripts).
  int _nowMillis() => DateTime.now().millisecondsSinceEpoch;
}
