import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/chat/auth/model/symbol_details_model.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the symbol video length (`media_duration`).
/// The payload is lifted verbatim from
/// docs/backend/FLUTTER_SYMBOL_VIDEO_DURATION_INTEGRATION.md so these fail
/// loudly if the client drifts from the documented contract.
void main() {
  group('SymbolFeedItem.media_duration (guide "Response")', () {
    final json = {
      '_id': '60d0fe4f5311236168a109ca',
      'user_id': '60d0fe4f5311236168a109cb',
      'type': 'video',
      'content':
          'https://my-bucket.s3.ap-south-1.amazonaws.com/uploads/1758209730553-71cde5e0.mp4',
      'media_duration': 27.5,
      'caption': 'Sunset drive',
      'expires_at': '2026-07-17T10:30:00.000Z',
      'visibility': 'public',
      'likes_count': 0,
      'comments_count': 0,
      'seen_count': 0,
      'created_at': '2026-07-16T10:30:00.000Z',
    };

    test('parses the documented fractional value', () {
      final item = SymbolFeedItem.fromJson(json);
      expect(item.mediaDuration, 27.5);
      expect(item.hasKnownDuration, isTrue);
    });

    test('accepts an int as well as a double', () {
      final item = SymbolFeedItem.fromJson({...json, 'media_duration': 27});
      expect(item.mediaDuration, 27.0);
    });

    test('a legacy symbol without the field reads as 0, not null', () {
      final item = SymbolFeedItem.fromJson({...json}..remove('media_duration'));
      expect(item.mediaDuration, 0);
      expect(item.hasKnownDuration, isFalse);
    });

    test('an explicit null reads as 0', () {
      final item = SymbolFeedItem.fromJson({...json, 'media_duration': null});
      expect(item.mediaDuration, 0);
    });

    test('a photo symbol carries no duration', () {
      final item = SymbolFeedItem.fromJson({
        ...json,
        'type': 'photo',
        'media_duration': 0,
      });
      expect(item.hasKnownDuration, isFalse);
    });
  });

  group('SymbolDetailsModel.media_duration', () {
    test('parses the field on the single-symbol read path', () {
      final model = SymbolDetailsModel.fromJson({
        '_id': '60d0fe4f5311236168a109ca',
        'type': 'video',
        'media_duration': 27.5,
      });
      expect(model.mediaDuration, 27.5);
    });

    test('round-trips through toJson under the documented key', () {
      final model = SymbolDetailsModel(type: 'video', mediaDuration: 27.5);
      expect(model.toJson()['media_duration'], 27.5);
    });
  });

  group('formatMediaDuration (guide "Testing Checklist")', () {
    test('a clip over a minute formats as minutes:seconds, not raw seconds', () {
      expect(formatMediaDuration(83), '01:23');
    });

    test('rounds to the nearest second rather than truncating', () {
      expect(formatMediaDuration(27.9), '00:28');
    });

    test('a sub-second clip does not display as 00:00', () {
      expect(formatMediaDuration(0.4), isNot('00:00'));
      expect(formatMediaDuration(0.4), '00:01');
    });

    test('an unknown length still reads as 00:00', () {
      expect(formatMediaDuration(0), '00:00');
    });
  });
}
