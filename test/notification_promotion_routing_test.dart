import 'package:BlueEra/core/services/notification_tracking_service.dart';
import 'package:BlueEra/features/common/notification/model/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers FLUTTER_NOTIFICATION_ROUTING_GUIDE.md §5 and §6.
///
/// The guide's central warning is that the SAME notification reaches the app
/// through two producers that disagree on casing — the FCM push writes
/// `deepLink` / `broadcastId`, the stored inbox row writes `deep_link` /
/// `broadcast_id`. A reader that handles only one casing routes the banner
/// correctly and dead-ends the inbox row, which is exactly the bug these pin.
void main() {
  group('deepLinkOf reads every producer', () {
    test('the FCM push casing', () {
      expect(
        NotificationTracking.deepLinkOf({'deepLink': 'https://beapp.in/app/jobs'}),
        'https://beapp.in/app/jobs',
      );
    });

    test('the stored inbox casing', () {
      expect(
        NotificationTracking.deepLinkOf({'deep_link': 'https://beapp.in/app/jobs'}),
        'https://beapp.in/app/jobs',
      );
    });

    test('the pre-normalisation spellings still route', () {
      // `deepLink` used to be emitted only for video notifications; an
      // engagement theme carried its destination as `link`/`url`. A queued push
      // composed before normalisation landed must not dead-end.
      expect(NotificationTracking.deepLinkOf({'link': '/app/jobs'}), '/app/jobs');
      expect(NotificationTracking.deepLinkOf({'url': '/app/jobs'}), '/app/jobs');
    });

    test('absent or blank is null, not an empty string', () {
      // The caller branches on null to mean "nudge only — land on the hub".
      // An empty string would be parsed as a URI and routed to nowhere.
      expect(NotificationTracking.deepLinkOf({}), isNull);
      expect(NotificationTracking.deepLinkOf({'deepLink': ''}), isNull);
      expect(NotificationTracking.deepLinkOf({'deepLink': '   '}), isNull);
    });

    test('camelCase wins when a payload carries both', () {
      expect(
        NotificationTracking.deepLinkOf({
          'deepLink': '/app/jobs',
          'deep_link': '/app/videos',
        }),
        '/app/jobs',
      );
    });

    test('a per-operation PREFIXED key is still found', () {
      // The routing guide §5 says stored rows carry `deep_link`, but the only
      // captured sample of a stored row in the repo (video promo guide §7)
      // shows `video_deep_link`. Unresolved with the backend, so the reader
      // must not depend on the answer.
      expect(
        NotificationTracking.deepLinkOf({
          'video_deep_link': 'https://beapp.in/app/video/68f0',
        }),
        'https://beapp.in/app/video/68f0',
      );
      expect(
        NotificationTracking.deepLinkOf({'promotion_deep_link': '/app/jobs'}),
        '/app/jobs',
      );
      expect(
        NotificationTracking.deepLinkOf({'promoDeepLink': '/app/jobs'}),
        '/app/jobs',
      );
    });

    test('an exact key still wins over a prefixed one', () {
      expect(
        NotificationTracking.deepLinkOf({
          'video_deep_link': '/app/video/1',
          'deepLink': '/app/jobs',
        }),
        '/app/jobs',
      );
    });

    test('unrelated keys are never mistaken for a destination', () {
      expect(
        NotificationTracking.deepLinkOf({
          'deep_link_saved_at': '',
          'title': 'Naye jobs aaye hain',
          'broadcastId': 'abc',
        }),
        isNull,
      );
    });
  });

  group('campaignIdOf reads every producer', () {
    test('both casings and the bulk variant', () {
      expect(NotificationTracking.campaignIdOf({'broadcastId': 'abc'}), 'abc');
      expect(NotificationTracking.campaignIdOf({'broadcast_id': 'abc'}), 'abc');
      expect(
        NotificationTracking.campaignIdOf({'bulkNotificationId': 'abc'}),
        'abc',
      );
    });

    test('a transactional push has no campaign, and that is not an error', () {
      // `report()` returns early on null — an order update or chat message has
      // nothing to attribute.
      expect(NotificationTracking.campaignIdOf({}), isNull);
      expect(NotificationTracking.campaignIdOf({'broadcastId': ''}), isNull);
    });
  });

  group('the guide\'s example engagement push (§2)', () {
    final push = <String, dynamic>{
      'operation': 'admin_promotion',
      'title': 'Naye jobs aaye hain 💼',
      'body': 'Aapke area mein kuch acche openings hain — dekh lo.',
      'imageUrl': '',
      'style': 'bigText',
      'channelId': 'announcements',
      'deepLink': 'https://beapp.in/app/jobs',
      'broadcastId': '6aa4f1b2c3d4e5f607182930',
    };

    test('routes to the link, and is attributable to its campaign', () {
      expect(NotificationTracking.deepLinkOf(push), 'https://beapp.in/app/jobs');
      expect(
        NotificationTracking.campaignIdOf(push),
        '6aa4f1b2c3d4e5f607182930',
      );
      // FCM data is always strings — the destination must survive Uri parsing.
      final uri = Uri.tryParse(NotificationTracking.deepLinkOf(push)!);
      expect(uri, isNotNull);
      expect(uri!.path, '/app/jobs');
    });

    test('a malformed link is caught rather than thrown', () {
      // `Uri.parse` on this throws; the handler uses `tryParse` so a bad link
      // falls back to the hub instead of taking the cold-start path down.
      expect(NotificationTracking.deepLinkOf({'deepLink': 'http://['}), isNotNull);
      expect(Uri.tryParse('http://['), isNull);
    });
  });

  group('inbox Metadata parses what the row needs', () {
    test('the stored snake_case shape', () {
      final meta = Metadata.fromJson({
        'deep_link': 'https://beapp.in/app/jobs',
        'broadcast_id': '6aa4f1b2c3d4e5f607182930',
        'image_url': 'https://cdn.example/promo.jpg',
        'originalOperation': 'admin_promotion',
        'title': 'Naye jobs aaye hain',
      });

      expect(meta.deepLink, 'https://beapp.in/app/jobs');
      expect(meta.broadcastId, '6aa4f1b2c3d4e5f607182930');
      expect(meta.imageUrl, 'https://cdn.example/promo.jpg');
    });

    test('the camelCase shape, for a row mirrored straight from a push', () {
      final meta = Metadata.fromJson({
        'deepLink': 'https://beapp.in/app/jobs',
        'broadcastId': 'abc',
        'imageUrl': 'https://cdn.example/promo.jpg',
      });

      expect(meta.deepLink, 'https://beapp.in/app/jobs');
      expect(meta.broadcastId, 'abc');
      expect(meta.imageUrl, 'https://cdn.example/promo.jpg');
    });

    test('round-trips through toJson so the cache keeps the destination', () {
      // The inbox caches rows; a field dropped from toJson would route on a
      // fresh fetch and dead-end after a restart.
      final meta = Metadata.fromJson({
        'deep_link': 'https://beapp.in/app/jobs',
        'broadcast_id': 'abc',
        'image_url': 'https://cdn.example/promo.jpg',
      });
      final revived = Metadata.fromJson(meta.toJson());

      expect(revived.deepLink, 'https://beapp.in/app/jobs');
      expect(revived.broadcastId, 'abc');
      expect(revived.imageUrl, 'https://cdn.example/promo.jpg');
    });

    test('the row and its push resolve to the SAME destination', () {
      // The guide's whole point: one resolver, two producers.
      const destination = 'https://beapp.in/app/jobs';
      final fromPush = NotificationTracking.deepLinkOf({
        'deepLink': destination,
        'broadcastId': 'abc',
      });
      final row = Metadata.fromJson({
        'deep_link': destination,
        'broadcast_id': 'abc',
      });
      final fromRow = NotificationTracking.deepLinkOf(row.toJson());

      expect(fromRow, fromPush);
      expect(
        NotificationTracking.campaignIdOf(row.toJson()),
        NotificationTracking.campaignIdOf({'broadcastId': 'abc'}),
      );
    });

    test('a PREFIXED stored key survives parse → toJson → read', () {
      // The failure this guards is quiet: `toJson()` emits only fields the
      // model knows, so a spelling it did not recognise at `fromJson` is gone
      // before any reader downstream sees it. The row would then dead-end on
      // the list it was tapped from, with nothing in the log.
      final meta = Metadata.fromJson({
        'video_deep_link': 'https://beapp.in/app/video/68f0',
        'broadcast_id': 'abc',
      });
      expect(meta.deepLink, 'https://beapp.in/app/video/68f0');
      expect(
        NotificationTracking.deepLinkOf(meta.toJson()),
        'https://beapp.in/app/video/68f0',
      );
    });

    test('a nudge row with no destination yields null', () {
      final meta = Metadata.fromJson({'title': 'Open the app'});
      expect(meta.deepLink, isNull);
      expect(NotificationTracking.deepLinkOf(meta.toJson()), isNull);
    });
  });
}
