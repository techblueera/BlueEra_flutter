import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/constants/shared_preference_utils.dart';
import '../model/bookmarked_media.dart';

/// Local (device-only) bookmarks for chat images/videos. Persisted as a JSON
/// list via secure storage, keyed by [_storageKey]. Registered lazily the
/// first time a bookmark action or the Bookmarks screen is used.
class BookmarkController extends GetxController {
  static const _storageKey = 'chat_bookmarked_media_v1';

  /// Most-recent-first list of bookmarked media.
  final RxList<BookmarkedMedia> bookmarks = <BookmarkedMedia>[].obs;

  /// Fetch the singleton, registering it on first use.
  static BookmarkController get to => Get.isRegistered<BookmarkController>()
      ? Get.find<BookmarkController>()
      : Get.put(BookmarkController(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await SharedPreferenceUtils.getSecureValue(_storageKey);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          bookmarks.assignAll(decoded
              .whereType<Map>()
              .map((e) => BookmarkedMedia.fromJson(Map<String, dynamic>.from(e)))
              .toList());
        }
      }
    } catch (_) {
      // Corrupt payload — start clean rather than crash.
    }
  }

  Future<void> _persist() async {
    await SharedPreferenceUtils.setSecureValue(
      _storageKey,
      jsonEncode(bookmarks.map((e) => e.toJson()).toList()),
    );
  }

  bool isBookmarked(String url) => bookmarks.any((b) => b.url == url);

  /// Adds or removes [media]; returns true if it is now bookmarked.
  Future<bool> toggle(BookmarkedMedia media) async {
    final idx = bookmarks.indexWhere((b) => b.url == media.url);
    final bool added;
    if (idx >= 0) {
      bookmarks.removeAt(idx);
      added = false;
    } else {
      bookmarks.insert(0, media);
      added = true;
    }
    await _persist();
    return added;
  }

  Future<void> remove(String url) async {
    bookmarks.removeWhere((b) => b.url == url);
    await _persist();
  }

  /// Bookmarks grouped by conversation, preserving recency order within each
  /// group. Used by the Bookmarks screen to show media per person/chat.
  Map<String, List<BookmarkedMedia>> get groupedByConversation {
    final map = <String, List<BookmarkedMedia>>{};
    for (final b in bookmarks) {
      map.putIfAbsent(b.conversationId, () => <BookmarkedMedia>[]).add(b);
    }
    return map;
  }
}
