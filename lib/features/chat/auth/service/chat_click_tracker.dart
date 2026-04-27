import 'dart:async';
import 'dart:io' show Platform;

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_click_repo.dart';
import 'package:flutter/foundation.dart';

/// Funnel-analysis dimension. Sent as `source` in the chat-click payload —
/// validated server-side against an allow-list (unknown values silently
/// fall back to "other"), so it is safe to extend.
enum ChatClickSource {
  mapCard,
  mapList,
  storeDetail,
  searchResult,
  feed,
  deepLink,
  other,
}

extension ChatClickSourceX on ChatClickSource {
  String get apiValue {
    switch (this) {
      case ChatClickSource.mapCard:
        return 'map_card';
      case ChatClickSource.mapList:
        return 'map_list';
      case ChatClickSource.storeDetail:
        return 'store_detail';
      case ChatClickSource.searchResult:
        return 'search_result';
      case ChatClickSource.feed:
        return 'feed';
      case ChatClickSource.deepLink:
        return 'deep_link';
      case ChatClickSource.other:
        return 'other';
    }
  }
}

/// Records "user tapped Chat on a business surface" events to the
/// `be_user_service` chat-click endpoint via [ChatClickRepo] / the shared
/// [ApiBaseHelper] (auth header + base URL come from there).
///
/// Calls are fire-and-forget per the integration guide: never awaited,
/// never surface errors, never retry on failure.
class ChatClickTracker {
  static final ChatClickRepo _repo = ChatClickRepo();

  static String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }

  static void track({
    required String businessId,
    ChatClickSource source = ChatClickSource.other,
    Map<String, dynamic>? metadata,
  }) {
    final id = businessId.trim();
    if (id.isEmpty) return;

    final body = <String, dynamic>{
      'source': source.apiValue,
      'platform': _platform(),
      if (metadata != null) 'metadata': metadata,
    };

    unawaited(
      _repo
          .recordChatClick(businessId: id, body: body)
          .catchError((_) => ResponseModel()),
    );
  }
}
