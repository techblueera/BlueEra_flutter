import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/feed/widget/feed_business_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_product_card.dart';
import 'package:BlueEra/features/common/feed/widget/feed_video_card.dart';
import 'package:BlueEra/features/common/reel/widget/auto_video_playback_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Render tests for the `/feed` item types that previously fell through to an
/// empty box. These assert the cards actually paint their content — parsing
/// alone doesn't prove the item reaches the screen.
void main() {
  setUp(() {
    Get.reset();
    // Fire visibility callbacks at end-of-frame. VisibilityDetectorController is
    // a process-wide singleton driven by one internal timer, so a non-zero
    // interval both leaves that timer pending at teardown AND batches every
    // later test's callbacks behind it.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(Get.reset);

  /// A FeedVideoCard creates the shared [SimplePriorityVideoManager], which
  /// starts a 4s warmup timer in onInit. flutter_test fails a test whose timers
  /// outlive the widget tree, and tearDown runs *after* that check — so every
  /// test that renders a video card must release the manager itself.
  ///
  /// Must be `Get.delete`, not `Get.reset`: reset only clears the registry,
  /// while delete runs onClose, which is what cancels the timer.
  void releaseVideoManager() {
    if (Get.isRegistered<SimplePriorityVideoManager>()) {
      Get.delete<SimplePriorityVideoManager>(force: true);
    }
  }

  /// Pumps [child] with SizeConfig initialised, as the real app does at startup.
  Future<void> pumpCard(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          SizeConfig.init(context);
          return SingleChildScrollView(child: child);
        }),
      ),
    ));
    await tester.pump();
  }

  group('FeedBusinessCard', () {
    testWidgets('renders name, category, rating, count and address',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'biz_123',
        'type': 'business',
        'name': 'Cafe Aroma',
        'category': 'Restaurant',
        'description': 'Cozy coffee shop',
        'location': {
          'address': '123 Main St',
          'city_state_pincode': 'Delhi, DL 110001',
        },
        'avg_rating': 4.5,
        'total_ratings': 120,
      });

      await pumpCard(tester, FeedBusinessCard(post: post));

      expect(find.text('Cafe Aroma'), findsOneWidget);
      expect(find.text('Restaurant'), findsOneWidget);
      expect(find.text('Cozy coffee shop'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(120)'), findsOneWidget);
      expect(find.text('123 Main St, Delhi, DL 110001'), findsOneWidget);
    });

    testWidgets('renders a sparse business without throwing', (tester) async {
      // Guide §4.1/§4.5: fields are nullable — render defensively.
      final post = Post.fromJson({'_id': 'b1', 'type': 'business'});
      await pumpCard(tester, FeedBusinessCard(post: post));

      expect(tester.takeException(), isNull);
      expect(find.text('Business'), findsOneWidget); // name fallback
    });

    testWidgets('hides the rating chip when unrated', (tester) async {
      final post = Post.fromJson({
        '_id': 'b1',
        'type': 'business',
        'name': 'New Place',
        'avg_rating': 0,
        'total_ratings': 0,
      });
      await pumpCard(tester, FeedBusinessCard(post: post));

      expect(find.text('New Place'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });

  group('FeedProductCard', () {
    testWidgets('renders brand, name, price, rating, store and returns',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'prod_123',
        'type': 'product',
        'name': 'Wireless Headphones',
        'price': 2999,
        'currency': 'INR',
        'brand': 'Acme',
        'store': {'name': 'Acme Store'},
        'rating': 4.2,
        'is_returnable': true,
        'return_period_days': 7,
        'product_type': 'Product',
      });

      await pumpCard(tester, FeedProductCard(post: post));

      expect(find.text('ACME'), findsOneWidget);
      expect(find.text('Wireless Headphones'), findsOneWidget);
      expect(find.text('₹2999'), findsOneWidget);
      expect(find.text('4.2'), findsOneWidget);
      expect(find.text('Acme Store'), findsOneWidget);
      expect(find.text('7-day returns'), findsOneWidget);
      expect(find.text('Product'), findsOneWidget); // badge
    });

    testWidgets('a Service shows the Service badge and no returns chip',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'p1',
        'type': 'product',
        'name': 'Deep Clean',
        'price': 499,
        'currency': 'INR',
        'product_type': 'Service',
        'is_returnable': true,
        'return_period_days': 7,
      });

      await pumpCard(tester, FeedProductCard(post: post));

      expect(find.text('Service'), findsOneWidget);
      expect(find.text('₹499'), findsOneWidget);
      expect(find.text('7-day returns'), findsNothing);
    });

    testWidgets('renders a priceless, imageless product without throwing',
        (tester) async {
      final post = Post.fromJson({'_id': 'p1', 'type': 'product'});
      await pumpCard(tester, FeedProductCard(post: post));

      expect(tester.takeException(), isNull);
      expect(find.text('Product'), findsWidgets); // badge + name fallback
    });
  });

  group('FeedVideoCard', () {
    testWidgets('short_video shows the Short badge, title, views, duration',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'video_123',
        'type': 'short_video',
        'title': 'My Reel',
        'video_url': 'https://cdn.example/video.mp4',
        'duration': 30,
        'live': false,
        'views_count': 1000,
        'channel': {'_id': 'c1', 'name': 'My Channel'},
      });

      await pumpCard(tester, FeedVideoCard(post: post));

      expect(find.text('Short'), findsOneWidget);
      expect(find.text('My Reel'), findsOneWidget);
      expect(find.text('My Channel'), findsOneWidget);
      expect(find.text('0:30'), findsOneWidget);
      // Views go through the app's shared formatter (1000 -> "1k").
      expect(find.text('1k'), findsOneWidget);
      releaseVideoManager();
    });

    testWidgets('long_video shows the Video badge and h:mm:ss duration',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'v2',
        'type': 'long_video',
        'title': 'Long Talk',
        'video_url': 'https://cdn.example/v.mp4',
        'duration': 3725, // 1h 02m 05s
        'views_count': 10,
      });

      await pumpCard(tester, FeedVideoCard(post: post));

      expect(find.text('Video'), findsOneWidget);
      expect(find.text('1:02:05'), findsOneWidget);
      releaseVideoManager();
    });

    testWidgets('a live video shows LIVE and hides the duration chip',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'v3',
        'type': 'long_video',
        'title': 'Live Now',
        'video_url': 'https://cdn.example/v.mp4',
        'duration': 30,
        'live': true,
      });

      await pumpCard(tester, FeedVideoCard(post: post));

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Video'), findsNothing);
      expect(find.text('0:30'), findsNothing);
      releaseVideoManager();
    });

    testWidgets('falls back to the author when the video has no channel',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'v4',
        'type': 'short_video',
        'video_url': 'https://cdn.example/v.mp4',
        'user': {'_id': 'u1', 'name': 'Jane Doe'},
      });

      await pumpCard(tester, FeedVideoCard(post: post));
      expect(find.text('Jane Doe'), findsOneWidget);
      releaseVideoManager();
    });
  });

  group('FeedVideoCard autoplay', () {
    // These stop short of flushing the manager's 4s warmup, so it records the
    // playback candidate without ever reaching VideoPlayerController — the
    // video platform has no implementation under flutter_test.

    testWidgets('an on-screen video registers itself for autoplay',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'v1',
        'type': 'short_video',
        'video_url': 'https://cdn.example/v.mp4',
      });

      await pumpCard(tester, FeedVideoCard(post: post));
      final manager = Get.find<SimplePriorityVideoManager>();

      expect(manager.visibleVideos.containsKey('v1'), isTrue,
          reason: 'card must register with the shared manager to autoplay');
      expect(manager.videoUrls['v1'], 'https://cdn.example/v.mp4');
      releaseVideoManager();
    });

    testWidgets('a video with no playable source never registers',
        (tester) async {
      // Registering a sourceless item would let it win the priority slot and
      // starve a real video, since the manager would fail to init an empty URL.
      final post = Post.fromJson({'_id': 'v2', 'type': 'short_video'});

      await pumpCard(tester, FeedVideoCard(post: post));
      final manager = Get.find<SimplePriorityVideoManager>();

      expect(manager.visibleVideos.containsKey('v2'), isFalse);
      releaseVideoManager();
    });

    testWidgets('a scrolled-away video releases its autoplay slot',
        (tester) async {
      final post = Post.fromJson({
        '_id': 'v3',
        'type': 'short_video',
        'video_url': 'https://cdn.example/v.mp4',
      });

      await pumpCard(tester, FeedVideoCard(post: post));
      final manager = Get.find<SimplePriorityVideoManager>();
      expect(manager.visibleVideos.containsKey('v3'), isTrue);

      // Dispose the card, as a ListView does when it scrolls out of cache.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();

      expect(manager.visibleVideos.containsKey('v3'), isFalse,
          reason: 'a disposed card must not keep holding the priority slot');
      releaseVideoManager();
    });

    testWidgets('only one video plays at a time across the feed',
        (tester) async {
      // Two video cards on screen must share one manager (and therefore one
      // controller) — that is what stops two videos playing over each other.
      final a = Post.fromJson({
        '_id': 'a',
        'type': 'short_video',
        'video_url': 'https://cdn.example/a.mp4',
      });
      final b = Post.fromJson({
        '_id': 'b',
        'type': 'long_video',
        'video_url': 'https://cdn.example/b.mp4',
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            SizeConfig.init(context);
            return ListView(
              children: [FeedVideoCard(post: a), FeedVideoCard(post: b)],
            );
          }),
        ),
      ));
      await tester.pump();

      final manager = Get.find<SimplePriorityVideoManager>();
      // Both registered as candidates, but the manager owns a single controller
      // and a single currentIndex, so at most one can be playing.
      expect(manager.videoUrls.containsKey('a'), isTrue);
      expect(manager.currentIndex.value, -1); // nothing playing pre-warmup
      releaseVideoManager();
    });
  });
}
