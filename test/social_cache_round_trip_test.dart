import 'dart:io';

import 'package:BlueEra/core/services/home_cache_service.dart';
import 'package:BlueEra/core/services/keyed_json_cache.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// The Social section (Feed / Bites / My Post) paints from disk on its first
/// frame and refreshes behind it. That only works if what is written to Hive
/// comes back out as the same objects — and a cache that fails to parse is
/// INVISIBLE: every read is wrapped in a try/catch that reports a plain miss,
/// so a broken round trip looks exactly like an empty cache and the tab simply
/// shows a loader forever, exactly as it did before the cache existed.
///
/// These tests are the tripwire for that. They exercise the real models and the
/// real storage, not stand-ins.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('blueera_cache_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('Post round trip (Feed + My Post caches)', () {
    test('an image post survives toJson -> fromJson with its content intact',
        () {
      final original = Post.fromJson({
        '_id': 'post_1',
        'type': 'image_post',
        'message': 'hello world',
        'createdAt': '2026-07-16T09:58:00.000Z',
        'media': ['https://cdn.example/a.jpg', 'https://cdn.example/b.jpg'],
        'media_types': ['image', 'image'],
        'likes_count': 12,
        'comments_count': 3,
        'isLiked': true,
        'user': {
          '_id': 'u1',
          'name': 'Asha',
          'profile_image': 'https://cdn.example/asha.jpg',
        },
      });

      final restored = Post.fromJson(original.toJson());

      expect(restored.id, 'post_1');
      expect(restored.feedType, 'image_post');
      expect(restored.message, 'hello world');
      expect(restored.media, hasLength(2));
      expect(restored.likesCount, 12);
      expect(restored.isLiked, isTrue);
      // The author has to survive, or every restored card renders anonymous.
      expect(restored.user?.name, 'Asha');
    });

    test('an item_type:"reel" marker post keeps its nested reel payload', () {
      // The regression this guards: `toJson` used to serialise a reel marker
      // through the generic branch, writing a row of nulls — so a cached My Post
      // grid rehydrated its reels as blank tiles.
      final original = Post.fromJson({
        'item_type': 'reel',
        'reel': {
          'id': 'reel_1',
          'videoUrl': 'https://cdn.example/r.mp4',
          'coverUrl': 'https://cdn.example/r.jpg',
          'caption': 'my reel',
          'duration': 30,
          'stats': {'views': 500, 'likes': 40, 'comments': 2, 'shares': 1},
        },
      });

      final restored = Post.fromJson(original.toJson());

      expect(restored.isReel, isTrue);
      expect(restored.id, 'reel_1');
      expect(restored.reel, isNotNull);
      expect(restored.reel!.videoUrl, 'https://cdn.example/r.mp4');
      expect(restored.reel!.coverUrl, 'https://cdn.example/r.jpg');
      expect(restored.reel!.displayText, 'my reel');
      expect(restored.reel!.stats.views, 500);
      expect(restored.reel!.stats.likes, 40);
    });
  });

  group('KeyedJsonCache (Feed + My Post storage)', () {
    const cache = KeyedJsonCache('test_social_box');

    test('getSync serves what save wrote, once the box is open', () async {
      final posts = [
        Post.fromJson({
          '_id': 'p1',
          'type': 'message_post',
          'message': 'first',
          'user': {'_id': 'u1', 'name': 'Asha'},
        }),
        Post.fromJson({
          'item_type': 'reel',
          'reel': {'id': 'r1', 'videoUrl': 'https://cdn.example/r.mp4'},
        }),
      ];

      await cache.ensureOpen();
      await cache.save('user_1', {
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'posts': posts.map((p) => p.toJson()).toList(),
      });

      // The whole point of the sync path: no await, so a screen can call this
      // from initState and have content on its first frame.
      final read = cache.getSync('user_1');

      expect(read, isNotNull, reason: 'sync read must hit an open box');
      final raw = read!['posts'] as List;
      expect(raw, hasLength(2));

      final restored = raw
          .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      expect(restored[0].message, 'first');
      expect(restored[1].isReel, isTrue);
      expect(restored[1].reel!.videoUrl, 'https://cdn.example/r.mp4');
    });

    test('getSync reports a miss rather than throwing on an unopened box', () {
      const closed = KeyedJsonCache('never_opened_box');
      expect(closed.getSync('user_1'), isNull);
    });
  });

  group('HomeCacheService (Bites storage)', () {
    test('shorts survive the write and come back through the sync read',
        () async {
      await HomeCacheService.init();

      final shorts = [
        ShortFeedItem.fromJson({
          'videoId': 'v1',
          'video': {
            '_id': 'v1',
            'type': 'short',
            'title': 'Reel one',
            'videoUrl': 'https://cdn.example/v1.mp4',
            'coverUrl': 'https://cdn.example/v1.jpg',
            'stats': {'views': 10, 'likes': 2, 'comments': 1, 'shares': 0},
          },
          'author': {'id': 'u1', 'name': 'Asha'},
        }),
      ];

      await HomeCacheService().cacheShorts(shorts);
      final restored = HomeCacheService().getCachedShortsSync();

      // The regression this guards: entries used to be stored as raw Hive maps,
      // which read back `Map<dynamic, dynamic>` and blew up every nested
      // `fromJson` cast — so this returned null on every single call and the
      // cache, though written on every fetch, was never once served.
      expect(restored, isNotNull,
          reason: 'a written shorts cache must be readable');
      expect(restored, hasLength(1));
      expect(restored!.first.video?.videoUrl, 'https://cdn.example/v1.mp4');
      expect(restored.first.video?.coverUrl, 'https://cdn.example/v1.jpg');
      expect(restored.first.video?.stats?.views, 10);
      expect(restored.first.author?.name, 'Asha');
    });
  });
}
