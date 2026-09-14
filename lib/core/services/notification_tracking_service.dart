import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/constants/common_methods.dart';

/// Campaign engagement reporting, plus the two field readers every caller needs.
///
/// ## Why the readers live here
///
/// The same notification reaches the app through two producers that disagree on
/// casing: the FCM push writes `deepLink` / `broadcastId`, the stored inbox row
/// writes `deep_link` / `broadcast_id`. Both readers accept either, in one
/// place, so a push tap and an inbox tap can never resolve a payload
/// differently — which is the whole point of routing them through one resolver.
class NotificationTracking extends BaseService {
  NotificationTracking._();

  static final NotificationTracking _instance = NotificationTracking._();

  /// The destination a notification points at, or null when it is just a nudge
  /// to open the app.
  ///
  /// `deepLink` is the backend's normalised field — it already folds in
  /// `link` / `url` / `deep_link` / the video link from every producer — but the
  /// older spellings are still read so a queued push composed before that
  /// normalisation landed still routes.
  ///
  /// ## The prefixed fallback is not paranoia
  ///
  /// The two backend guides disagree about the STORED (inbox) shape.
  /// `FLUTTER_NOTIFICATION_ROUTING_GUIDE.md` §5 says the row carries
  /// `deep_link`; the only captured sample of a stored row anywhere in the repo
  /// — `FLUTTER_VIDEO_PROMO_NOTIFICATION_GUIDE.md` §7 — shows
  /// **`video_deep_link`**, a per-operation prefix. Nobody has confirmed which
  /// an `admin_promotion` row actually writes (see
  /// `docs/backend/OPEN_BACKEND_QUESTIONS.md`).
  ///
  /// So rather than bet on one, any key whose name ENDS in `deep_link` /
  /// `deeplink` is accepted after the exact matches fail. That makes the reader
  /// correct under either answer, and under a third spelling nobody has
  /// mentioned yet — which is the difference between a promo row that opens the
  /// jobs screen and one that silently dead-ends on the list it was tapped
  /// from. The exact keys are still tried first, so a payload carrying both
  /// resolves to the canonical one.
  static String? deepLinkOf(Map<String, dynamic> data) {
    final exact = (data['deepLink'] ??
            data['deep_link'] ??
            data['link'] ??
            data['url'] ??
            '')
        .toString()
        .trim();
    if (exact.isNotEmpty) return exact;

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase().replaceAll('_', '');
      if (!key.endsWith('deeplink')) continue;
      final value = (entry.value ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// The campaign a notification belongs to, or null for a transactional push
  /// (an order update, a chat message) that has no campaign to report against.
  static String? campaignIdOf(Map<String, dynamic> data) {
    final v = (data['broadcastId'] ??
            data['broadcast_id'] ??
            data['bulkNotificationId'] ??
            data['bulk_notification_id'] ??
            '')
        .toString()
        .trim();
    return v.isEmpty ? null : v;
  }

  /// Reports engagement with a campaign notification.
  ///
  /// **Fire-and-forget by design.** Call it with `unawaited(...)`: analytics
  /// must never delay the screen the user asked for, and must never surface an
  /// error to them. The endpoint is idempotent, so there is nothing to guard
  /// against on repeat taps.
  ///
  /// [kind] is `open` (the tap), `click` (an action button) or `convert` (the
  /// destination was actually reached). `open` and `convert` differ more than
  /// they look: a tap that lands on a dead screen still counts as an open, and
  /// the gap between the two is the clearest signal that a destination is
  /// broken.
  ///
  /// A payload with no campaign id returns immediately — that is the normal
  /// case for every transactional notification in the app, not an error.
  static Future<void> report(
    Map<String, dynamic> data, {
    String kind = 'open',
    String? actionId,
    bool? fromColdStart,
  }) async {
    final campaignId = campaignIdOf(data);
    if (campaignId == null) return;

    try {
      await ApiBaseHelper().postHTTP(
        _instance.notificationTrackApi,
        params: <String, dynamic>{
          'campaignId': campaignId,
          'kind': kind,
          'operation': (data['operation'] ?? data['originalOperation'] ?? '')
              .toString(),
          if (actionId != null) 'actionId': actionId,
          'platform': Platform.isIOS ? 'ios' : 'android',
          if (fromColdStart != null) 'fromColdStart': fromColdStart,
        },
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
    } catch (e) {
      // Swallowed on purpose — a lost analytics ping is not worth a snackbar,
      // and this runs on the path to a screen the user is waiting for. Logged
      // so a systematically failing endpoint is still visible.
      logs('notification tracking ($kind) failed: $e');
    }
  }
}
