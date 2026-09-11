import 'dart:convert';

import 'package:BlueEra/core/services/app_notification.dart';
import 'package:BlueEra/core/services/notification/pending_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the two pure decisions behind an `admin_video_promo` tap
/// (FLUTTER_VIDEO_PROMO_NOTIFICATION_GUIDE.md §3, §5, §7). Everything else in
/// that flow navigates or fetches, so it is covered on-device; these are the
/// branches that silently open nothing when they get it wrong.
///
/// The casing split is the whole reason this file exists: the FCM push writes
/// `videoId`, the stored inbox row writes `metadata.video_id`, and a tap can
/// arrive through either.
void main() {
  group('videoIdFromNotification', () {
    test('reads the camelCase key the FCM push sends', () {
      expect(
        AppNotificationHandler.videoIdFromNotification({
          'operation': 'admin_video_promo',
          'videoId': '68f0a1b2c3d4e5f60718293a',
        }),
        '68f0a1b2c3d4e5f60718293a',
      );
    });

    test('reads the snake_case key the stored inbox row sends', () {
      expect(
        AppNotificationHandler.videoIdFromNotification({
          'video_id': '68f0a1b2c3d4e5f60718293a',
        }),
        '68f0a1b2c3d4e5f60718293a',
      );
    });

    test('reads it out of nested metadata', () {
      expect(
        AppNotificationHandler.videoIdFromNotification({
          'metadata': {'video_id': '68f0a1b2c3d4e5f60718293a'},
        }),
        '68f0a1b2c3d4e5f60718293a',
      );
    });

    test('digs into the payload JSON string when nothing is flat', () {
      expect(
        AppNotificationHandler.videoIdFromNotification({
          'payload': jsonEncode({
            'metadata': {'video_id': '68f0a1b2c3d4e5f60718293a'},
          }),
        }),
        '68f0a1b2c3d4e5f60718293a',
      );
    });

    test('a flat key wins over one buried in the payload', () {
      expect(
        AppNotificationHandler.videoIdFromNotification({
          'videoId': 'flat',
          'payload': jsonEncode({'videoId': 'nested'}),
        }),
        'flat',
      );
    });

    test('trims whitespace — every FCM data value arrives as a string', () {
      expect(
        AppNotificationHandler.videoIdFromNotification(
            {'videoId': '  68f0a1b2c3d4e5f60718293a  '}),
        '68f0a1b2c3d4e5f60718293a',
      );
    });

    // Null rather than '' so the caller can fall back to the hub instead of
    // firing a fetch against an empty id.
    test('a promo naming no video returns null, not an empty string', () {
      expect(
        AppNotificationHandler.videoIdFromNotification(
            {'operation': 'admin_video_promo'}),
        isNull,
      );
    });

    test('the literal string "null" is not an id', () {
      expect(
        AppNotificationHandler.videoIdFromNotification({'videoId': 'null'}),
        isNull,
      );
    });

    test('a payload that will not decode simply carries no id', () {
      expect(
        AppNotificationHandler.videoIdFromNotification(
            {'payload': 'not json at all'}),
        isNull,
      );
    });
  });

  group('PendingDeepLink for a video promo', () {
    test('targets the reel player, not the notification hub', () {
      expect(
        PendingDeepLink.deriveTarget('admin_video_promo'),
        DeepLinkTarget.reel,
      );
    });

    // The player fetches over HTTP; making a cold-start promo tap pay for a
    // chat-socket handshake it never uses would be pure latency.
    test('does not ask the cold-start boot for a chat socket', () {
      final link = PendingDeepLink.fromData({
        'operation': 'admin_video_promo',
        'videoId': '68f0a1b2c3d4e5f60718293a',
      });
      expect(link!.needsSocket, isFalse);
    });

    test('records the video as the entity id', () {
      final link = PendingDeepLink.fromData({
        'operation': 'admin_video_promo',
        'videoId': '68f0a1b2c3d4e5f60718293a',
      });
      expect(link!.entityId, '68f0a1b2c3d4e5f60718293a');
    });
  });
}
