import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';

/// Trimmed to the fields the follow flag depends on; mirrors a real
/// `GET /videos/hot/short` item.
const _sample = '''
{
  "success": true,
  "data": [
    {
      "_id": "6a46584016873ade92b422dc",
      "userId": "6a38c94bb7031d0f514e6b2d",
      "type": "short",
      "title": "nature lover",
      "duration": 17,
      "isLiked": false,
      "author": {
        "_id": "6a38c94bb7031d0f514e6b2d",
        "username": "anuradha3187a",
        "account_type": "INDIVIDUAL",
        "name": "Anuradha singh",
        "isVerified": false,
        "followersCount": 0,
        "isFollowing": true
      }
    },
    {
      "_id": "6a46584016873ade92b422dd",
      "type": "short",
      "title": "second",
      "isLiked": true,
      "author": {
        "_id": "6a38c94bb7031d0f514e6b2e",
        "username": "someoneelse",
        "account_type": "INDIVIDUAL",
        "name": "Someone Else",
        "isFollowing": false
      }
    }
  ],
  "pagination": {"page": 1, "limit": 20, "total": 2, "totalPages": 1}
}
''';

void main() {
  test('hot/short carries author.isFollowing into interactions', () {
    final res = VideoResponse.fromHotJson(
        jsonDecode(_sample) as Map<String, dynamic>);
    final items = res.data!.videos!;

    expect(items.length, 2);

    // Followed author → button must read "Following".
    expect(items[0].author?.isFollowing, isTrue);
    expect(items[0].interactions?.isFollowing, isTrue);
    expect(items[0].interactions?.isLiked, isFalse);

    // Not followed → "Follow".
    expect(items[1].author?.isFollowing, isFalse);
    expect(items[1].interactions?.isFollowing, isFalse);
    expect(items[1].interactions?.isLiked, isTrue);
  });

  test('missing author does not crash and defaults to not-following', () {
    final res = VideoResponse.fromHotJson({
      'success': true,
      'data': [
        {'_id': 'x', 'type': 'short'}
      ],
    });
    final item = res.data!.videos!.single;
    expect(item.author, isNull);
    expect(item.interactions?.isFollowing, isFalse);
  });
}
