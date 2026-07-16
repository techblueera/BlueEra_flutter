import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/home/model/home_feed_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parsing tests for the mixed `/feed` response.
/// Payloads are lifted verbatim from docs/backend/FRONTEND_FEED_INTEGRATION.md
/// so these fail loudly if the client drifts from the documented contract.
void main() {
  group('business item (guide §4.5)', () {
    final json = {
      '_id': 'biz_123',
      'type': 'business',
      'createdAt': '2026-07-16T09:58:00.000Z',
      'name': 'Cafe Aroma',
      'logo': 'https://cdn.../logo.jpg',
      'category': 'Restaurant',
      'description': 'Cozy coffee shop',
      'location': {
        'address': '123 Main St',
        'city_state_pincode': 'Delhi, DL 110001',
        'lat': 28.61,
        'long': 77.21,
      },
      'avg_rating': 4.5,
      'total_ratings': 120,
      'user': {'_id': 'u1', 'name': 'Unknown User', 'business_id': 'biz_owner'},
    };

    test('parses the business payload', () {
      final post = Post.fromJson(json);

      expect(post.feedType, 'business');
      expect(post.business, isNotNull);
      expect(post.business!.name, 'Cafe Aroma');
      expect(post.business!.category, 'Restaurant');
      expect(post.business!.avgRating, 4.5);
      expect(post.business!.totalRatings, 120);
      expect(post.business!.location!.lat, 28.61);
      expect(post.business!.location!.long, 77.21);
      expect(post.business!.location!.displayAddress,
          '123 Main St, Delhi, DL 110001');
      // A business item must not be mistaken for a product.
      expect(post.product, isNull);
    });

    test('object-shaped location does not break the post-level String field',
        () {
      // Regression: `location` is a String on posts but an object on
      // business/video items. A naive cast throws here.
      final post = Post.fromJson(json);
      expect(post.location, '123 Main St');
    });

    test('survives the feed cache toJson/fromJson round-trip', () {
      // FeedController caches the first page via toJson and rehydrates via
      // fromJson — business items must come back intact, not blank.
      final round = Post.fromJson(Post.fromJson(json).toJson());
      expect(round.business, isNotNull);
      expect(round.business!.name, 'Cafe Aroma');
      expect(round.business!.avgRating, 4.5);
      expect(round.business!.location!.displayAddress,
          '123 Main St, Delhi, DL 110001');
    });
  });

  group('product item (guide §4.6)', () {
    final json = {
      '_id': 'prod_123',
      'type': 'product',
      'name': 'Wireless Headphones',
      'price': 2999,
      'currency': 'INR',
      'description': 'Noise cancelling',
      'brand': 'Acme',
      'images': ['https://cdn.../p1.jpg'],
      'video_urls': ['https://cdn.../p1.mp4'],
      'store': {'name': 'Acme Store', 'url': 'https://acme.example'},
      'rating': 4.2,
      'category': 'electronics',
      'warranty': '1 year',
      'is_returnable': true,
      'return_period_days': 7,
      'product_type': 'Product',
    };

    test('parses the product payload', () {
      final post = Post.fromJson(json);

      expect(post.feedType, 'product');
      expect(post.product, isNotNull);
      expect(post.product!.name, 'Wireless Headphones');
      expect(post.product!.brand, 'Acme');
      expect(post.product!.rating, 4.2);
      expect(post.product!.isReturnable, isTrue);
      expect(post.product!.returnPeriodDays, 7);
      expect(post.product!.primaryImage, 'https://cdn.../p1.jpg');
      expect(post.product!.store!.name, 'Acme Store');
      expect(post.product!.isService, isFalse);
      expect(post.business, isNull);
    });

    test('formats price per currency', () {
      expect(Post.fromJson(json).product!.displayPrice, '₹2999');

      expect(
        FeedProduct.fromJson({'price': 49.5, 'currency': 'USD'}).displayPrice,
        '\$49.5',
      );
      expect(
        FeedProduct.fromJson({'price': 10, 'currency': 'EUR'}).displayPrice,
        '€10',
      );
      // An unknown currency must not silently render as rupees.
      expect(
        FeedProduct.fromJson({'price': 10, 'currency': 'GBP'}).displayPrice,
        'GBP 10',
      );
      expect(FeedProduct.fromJson({'currency': 'INR'}).displayPrice, isNull);
    });

    test('identifies a Service', () {
      final service = FeedProduct.fromJson({'product_type': 'Service'});
      expect(service.isService, isTrue);
    });

    test('survives the feed cache round-trip', () {
      final round = Post.fromJson(Post.fromJson(json).toJson());
      expect(round.product, isNotNull);
      expect(round.product!.name, 'Wireless Headphones');
      expect(round.product!.displayPrice, '₹2999');
      expect(round.product!.store!.name, 'Acme Store');
    });
  });

  group('video item (guide §4.4)', () {
    final json = {
      '_id': 'video_123',
      'type': 'short_video',
      'title': 'My Reel',
      'video_url': 'https://cdn.../video.mp4',
      'thumbnail': 'https://cdn.../cover.jpg',
      'duration': 30,
      'live': false,
      'views_count': 1000,
      'location': {'name': 'Delhi', 'lat': 28.6, 'lng': 77.2},
      'channel': {'_id': 'chan_1', 'name': 'My Channel'},
    };

    test('parses a short_video', () {
      final post = Post.fromJson(json);
      expect(post.feedType, 'short_video');
      expect(post.videoUrl, 'https://cdn.../video.mp4');
      expect(post.thumbnail, 'https://cdn.../cover.jpg');
      expect(post.duration, 30);
      expect(post.live, isFalse);
      expect(post.viewsCount, 1000);
      // Object-shaped video location normalises to its display name.
      expect(post.location, 'Delhi');
    });

    test('parses a live long_video', () {
      final post = Post.fromJson({...json, 'type': 'long_video', 'live': true});
      expect(post.feedType, 'long_video');
      expect(post.live, isTrue);
    });
  });

  group('post items (guide §4.2)', () {
    test('detects video media on a post via media_types, not type', () {
      // Guide §6.3: a message_post/image_post can carry an mp4.
      final videoPost = Post.fromJson({
        '_id': 'p1',
        'type': 'image_post',
        'media': ['https://cdn.../1.mp4'],
        'media_types': ['video/mp4'],
      });
      expect(videoPost.hasVideoMedia, isTrue);

      final photoPost = Post.fromJson({
        '_id': 'p2',
        'type': 'image_post',
        'media': ['https://cdn.../1.jpg'],
        'media_types': ['image/jpeg'],
      });
      expect(photoPost.hasVideoMedia, isFalse);

      expect(Post.fromJson({'_id': 'p3'}).hasVideoMedia, isFalse);
    });

    test('String location and `text` body still parse', () {
      final post = Post.fromJson({
        '_id': 'p1',
        'type': 'message_post',
        'text': 'Great day at the beach!',
        'location': 'Goa',
      });
      expect(post.location, 'Goa');
      expect(post.message, 'Great day at the beach!');
    });

    test('`message` wins over `text` when both are present', () {
      final post = Post.fromJson({
        '_id': 'p1',
        'message': 'from message',
        'text': 'from text',
      });
      expect(post.message, 'from message');
    });
  });

  group('unknown / defensive (guide §6.5)', () {
    test('an unknown future type parses without throwing', () {
      final post = Post.fromJson({'_id': 'x1', 'type': 'hologram_post'});
      expect(post.feedType, 'hologram_post');
      expect(post.business, isNull);
      expect(post.product, isNull);
    });

    test('a business item with everything null parses', () {
      final post = Post.fromJson({'_id': 'b1', 'type': 'business'});
      expect(post.business, isNotNull);
      expect(post.business!.name, isNull);
      expect(post.business!.location, isNull);
      expect(post.business!.location?.displayAddress, isNull);
    });

    test('a product with an empty images list has no primary image', () {
      final product = FeedProduct.fromJson({'name': 'x', 'images': []});
      expect(product.primaryImage, isNull);
      expect(product.images, isEmpty);
    });
  });

  group('meta (guide §2, §5)', () {
    test('parses has_more and next_cursor', () {
      final meta = MetaData.fromJson({
        'has_more': true,
        'next_cursor': 'timestamp:1737012345000,postPage:2,videoPage:2',
      });
      expect(meta.has_more, isTrue);
      expect(meta.next_cursor, 'timestamp:1737012345000,postPage:2,videoPage:2');
    });

    test('has_more:false is distinct from an omitted has_more', () {
      // The controller falls back to a count heuristic only when the server
      // omitted the field — an explicit false must stop pagination.
      expect(MetaData.fromJson({'has_more': false}).has_more, isFalse);
      expect(MetaData.fromJson({}).has_more, isNull);
      expect(MetaData.fromJson({}).next_cursor, '');
    });
  });

  group('feed envelope', () {
    test('parses a heterogeneous data list preserving backend order', () {
      // Guide §6.2: render in the order received; never reorder client-side.
      final res = HomeFeedResponse.fromJson({
        'success': true,
        'data': [
          {'_id': '1', 'type': 'message_post'},
          {'_id': '2', 'type': 'business', 'name': 'Cafe'},
          {'_id': '3', 'type': 'short_video'},
          {'_id': '4', 'type': 'product', 'name': 'Thing', 'price': 5},
        ],
        'meta': {'has_more': true, 'next_cursor': 'c1'},
      });

      expect(res.feed.map((e) => e.feedType).toList(),
          ['message_post', 'business', 'short_video', 'product']);
      expect(res.feed[1].business!.name, 'Cafe');
      expect(res.feed[3].product!.name, 'Thing');
      expect(res.metaData!.has_more, isTrue);
    });
  });
}
