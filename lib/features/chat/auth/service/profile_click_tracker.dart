import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/features/chat/auth/repo/profile_click_repo.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';

/// Records "user visited a business/individual profile" events to the
/// `be_user_service` profile-visit endpoint via [ProfileClickRepo] / the
/// shared [ApiBaseHelper] (auth header + base URL come from there).
///
/// Mirrors [ChatClickTracker]: calls are fire-and-forget — never awaited,
/// never surface errors, never retry on failure. The POST carries no body;
/// the server records the visit from the path id + auth context alone.
/// [source] / [metadata] are accepted for call-site parity with
/// [ChatClickTracker] but are not sent.
class ProfileClickTracker {
  static final ProfileClickRepo _repo = ProfileClickRepo();

  static void track({
    required String userId,
    ChatClickSource source = ChatClickSource.other,
    Map<String, dynamic>? metadata,
  }) {
    log('track() called → userId="$userId", source=${source.apiValue}',
        name: 'ProfileVisit');

    final id = userId.trim();
    if (id.isEmpty) {
      log('SKIPPED → empty userId, not calling the API', name: 'ProfileVisit');
      return;
    }

    log('firing POST recordProfileVisit → id=$id', name: 'ProfileVisit');
    unawaited(
      _repo.recordProfileVisit(userId: id).then((res) {
        log('response → isSuccess=${res.isSuccess}, '
            'status=${res.response?.statusCode}, message=${res.message}',
            name: 'ProfileVisit');
      }).catchError((Object e, StackTrace s) {
        log('ERROR → $e', name: 'ProfileVisit', error: e, stackTrace: s);
      }),
    );
  }
}
