import 'dart:convert';

import 'package:BlueEra/features/common/Discover/model/nearby_sections_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses the REAL `map-service/api/nearby/discover` response, trimmed to the
/// shapes that matter but otherwise copied verbatim from a live Jodhpur
/// response — including the awkward bits: an empty `image_url`, a null
/// `sub_category`, a `distance` of exactly 0, and a category whose `count`
/// exceeds the `items` the server actually sent.
///
/// The rails read BUSINESSES out of a category grouping, and every one of
/// those hops (`data` → section → `categories` → `items` → `category`) is a
/// place a rename would silently produce an empty rail rather than an error.
/// That is what this pins.
const String _payload = '''
{
  "success": true,
  "data": {
    "shops_near_me": {
      "title": "Shops near me",
      "count": 5,
      "categories": [
        {
          "rank": 1,
          "id": "6a088aebcc4c93f8e56649b0",
          "name": "General Store",
          "type": "Grocery",
          "image_url": "https://cdn/category-images/grocery/general-store.png",
          "count": 3,
          "nearest_km": 0,
          "items": [
            {
              "id": "6a69ea205a834390875cac77",
              "name": "highway dhaba",
              "dp": "https://cdn/business/logo/dhaba.png",
              "logo": "https://cdn/business/logo/dhaba.png",
              "type": "Grocery",
              "business_type": "shop",
              "account_type": "BUSINESS",
              "user_id": "6a68a3aaaa9aff51cf99312f",
              "user": {
                "id": "6a68a3aaaa9aff51cf99312f",
                "name": "highway dhaba",
                "profile_image": "https://cdn/business/logo/dhaba.png",
                "account_type": "BUSINESS"
              },
              "category": {
                "id": "6a088aebcc4c93f8e56649b0",
                "name": "General Store",
                "type": "Grocery",
                "image_url": "https://cdn/category-images/grocery/general-store.png"
              },
              "sub_category": { "id": "sub1", "name": "Mini Supermarket" },
              "distance": 0,
              "avg_rating": 0,
              "total_ratings": 0,
              "address": "Balaji Rd, Jodhpur, Rajasthan 342003, India",
              "is_verified": false,
              "business_location": { "lat": 26.2751203, "lon": 72.9972837 }
            },
            {
              "id": "6a447815e4356208b42e8aec",
              "name": "Instamart",
              "dp": "https://cdn/business/logo/instamart.png",
              "logo": "https://cdn/business/logo/instamart.png",
              "type": "Grocery",
              "business_type": "shop",
              "account_type": "BUSINESS",
              "user_id": "6a447786e4356208b42e872c",
              "user": { "id": "6a447786e4356208b42e872c", "name": "Instamart", "profile_image": "https://cdn/x.png", "account_type": "BUSINESS" },
              "category": { "id": "6a088aebcc4c93f8e56649b0", "name": "General Store", "type": "Grocery", "image_url": "https://cdn/y.png" },
              "sub_category": { "id": "sub2", "name": "Supermarket" },
              "distance": 1.19,
              "avg_rating": 0,
              "total_ratings": 0,
              "address": "Cazri Rd, Jodhpur, Rajasthan 342003, India",
              "is_verified": false,
              "business_location": { "lat": 26.2649843, "lon": 72.9935645 }
            }
          ]
        },
        {
          "rank": 2,
          "id": "6a082",
          "name": "Manufacturing Grocery And Stationary",
          "type": "Manufacturing",
          "image_url": "",
          "count": 1,
          "nearest_km": 0,
          "items": [
            {
              "id": "6a82faedd9540f42dbd801a1",
              "name": "food industryy",
              "dp": "",
              "logo": "",
              "type": "Manufacturing",
              "business_type": "shop",
              "account_type": "BUSINESS",
              "user_id": "6a82fa2ed9540f42dbd7fba0",
              "user": { "id": "6a82fa2ed9540f42dbd7fba0", "name": "food industryy", "profile_image": "https://cdn/owner/fallback.png", "account_type": "BUSINESS" },
              "category": { "id": "6a082", "name": "Manufacturing Grocery And Stationary", "type": "Manufacturing", "image_url": "" },
              "sub_category": null,
              "distance": 0,
              "avg_rating": 0,
              "total_ratings": 0,
              "address": "Baldev Nagar, Jodhpur, Rajasthan, 342003, India",
              "is_verified": false,
              "business_location": { "lat": 26.2751406, "lon": 72.9972606 }
            }
          ]
        }
      ]
    },
    "services_near_me": {
      "title": "Services Near me",
      "count": 2,
      "categories": [
        {
          "rank": 2,
          "id": "6a097ecb74b33a0af6fb02d9",
          "name": "Beauty Fitness Personal Care",
          "type": "Service",
          "image_url": "https://cdn/category-images/service/beauty.png",
          "count": 1,
          "nearest_km": 4.69,
          "items": [
            {
              "id": "6a4b85eb7865ff86a67d5cee",
              "name": "ishaan makeovers",
              "dp": "https://cdn/business/logo/ishaan.png",
              "logo": "https://cdn/business/logo/ishaan.png",
              "type": "Service",
              "business_type": "service",
              "account_type": "BUSINESS",
              "user_id": "6a4b84ef7865ff86a67d5971",
              "user": { "id": "6a4b84ef7865ff86a67d5971", "name": "ishaan makeovers", "profile_image": "https://cdn/z.png", "account_type": "BUSINESS" },
              "category": { "id": "6a097ecb74b33a0af6fb02d9", "name": "Beauty Fitness Personal Care", "type": "Service", "image_url": "https://cdn/w.png" },
              "sub_category": { "id": "sub9", "name": "Beauty Parlour" },
              "distance": 4.69,
              "avg_rating": 4.33,
              "total_ratings": 9,
              "address": "Paota, Jodhpur, Rajasthan 342006, India",
              "is_verified": false,
              "business_location": { "lat": 26.3004868, "lon": 73.0348978 }
            }
          ]
        }
      ]
    },
    "recent_visited": { "title": "Recent visited store", "count": 0, "items": [] }
  },
  "meta": {
    "lat": 26.2751352, "lng": 72.9972389, "radius": 5, "per_section": 5,
    "counts": { "shop_categories": 5, "service_categories": 2, "recent": 0, "nearby_businesses": 16 },
    "degraded": [], "took_ms": 25
  }
}
''';

NearbySectionsResult _parse() => NearbySectionsResult.fromJson(
    jsonDecode(_payload) as Map<String, dynamic>);

void main() {
  group('sections', () {
    test('both rails and the empty recent section parse', () {
      final r = _parse();

      expect(r.shops.length, 2);
      expect(r.services.length, 1);
      // count 0 with an empty items array is a real, valid answer — not a
      // parse failure, and not a reason to treat the payload as broken.
      expect(r.recentVisited, isEmpty);
      expect(r.isEmpty, isFalse);
    });

    test("the server's own titles win over the local fallbacks", () {
      final r = _parse();
      // Note the lowercase 'n' and 'm' — these are rendered verbatim, so a
      // local title would visibly disagree with the backend.
      expect(r.shopsTitle, 'Shops near me');
      expect(r.servicesTitle, 'Services Near me');
      expect(r.recentTitle, 'Recent visited store');
    });

    test('radius comes off meta, and nothing is degraded', () {
      final r = _parse();
      expect(r.radiusKm, 5);
      expect(r.degraded, isEmpty);
    });
  });

  group('categories', () {
    test('carry their vertical, and an empty image_url is tolerated', () {
      final r = _parse();
      expect(r.shops.first.type, 'Grocery');
      expect(r.shops[1].type, 'Manufacturing');
      expect(r.shops[1].imageUrl, '');
    });

    test('count is the radius total, NOT items.length', () {
      // The server caps items per category (`meta.per_section`), so a category
      // can legitimately say "3 nearby" while sending 2. Reading count as the
      // list length would under-report every dense category.
      final r = _parse();
      expect(r.shops.first.count, 3);
      expect(r.shops.first.items.length, 2);
    });
  });

  group('businesses', () {
    test('carry the fields the rail draws', () {
      final item = _parse().shops.first.items.first;

      expect(item.name, 'highway dhaba');
      expect(item.categoryName, 'General Store');
      expect(item.displayImage, 'https://cdn/business/logo/dhaba.png');
      expect(item.subCategoryName, 'Mini Supermarket');
    });

    test('business id and owner id are DIFFERENT and both survive', () {
      // They are distinct records; routing needs both, and conflating them
      // opens the wrong profile.
      final item = _parse().shops.first.items.first;
      expect(item.id, '6a69ea205a834390875cac77');
      expect(item.userId, '6a68a3aaaa9aff51cf99312f');
      expect(item.id, isNot(item.userId));
    });

    test('carry what routing needs', () {
      final shop = _parse().shops.first.items.first;
      expect(shop.type, 'Grocery');
      expect(shop.businessType, 'shop');
      expect(shop.accountType, 'BUSINESS');

      final service = _parse().services.first.items.first;
      expect(service.type, 'Service');
      expect(service.businessType, 'service');
    });

    test('a null sub_category is empty, not a crash', () {
      final item = _parse().shops[1].items.first;
      expect(item.subCategoryName, '');
    });

    test('image falls back dp → logo → owner avatar', () {
      // "food industryy" has neither dp nor logo; the owner's avatar is all
      // there is, and it beats rendering a broken image.
      final item = _parse().shops[1].items.first;
      expect(item.dp, '');
      expect(item.logo, '');
      expect(item.displayImage, 'https://cdn/owner/fallback.png');
    });

    test('a distance of exactly 0 is preserved', () {
      // 0 means "at your coordinates", not "unknown" — dropping it is what
      // left the sub-line blank on the closest shop.
      expect(_parse().shops.first.items.first.distance, 0);
    });

    test('ratings parse as numbers, including a fractional average', () {
      final item = _parse().services.first.items.first;
      expect(item.avgRating, 4.33);
      expect(item.totalRatings, 9);
    });
  });

  group('flatten', () {
    test('yields every business, in category-rank order', () {
      final businesses = flattenNearbyBusinesses(_parse().shops);
      expect(businesses.map((b) => b.name).toList(), [
        'highway dhaba',
        'Instamart',
        'food industryy',
      ]);
    });

    test('de-dupes a business listed under two categories', () {
      final r = _parse();
      // Same category object twice — every id repeats.
      final doubled = [r.shops.first, r.shops.first];
      expect(flattenNearbyBusinesses(doubled).length,
          r.shops.first.items.length);
    });
  });

  group('defensive parsing', () {
    test('a payload with no data section is empty, not an exception', () {
      final r = NearbySectionsResult.fromJson({'success': true});
      expect(r.isEmpty, isTrue);
      expect(r.shops, isEmpty);
      // Falls back to the local wording rather than rendering a blank heading.
      expect(r.shopsTitle, 'Shops Near Me');
    });

    test('a category with no items array yields no businesses', () {
      final r = NearbySectionsResult.fromJson({
        'data': {
          'shops_near_me': {
            'categories': [
              {'rank': 1, 'id': 'x', 'name': 'X'}
            ]
          }
        }
      });
      expect(r.shops.single.items, isEmpty);
      expect(flattenNearbyBusinesses(r.shops), isEmpty);
    });

    test('numbers arriving as strings still parse', () {
      // Different services produce this payload; the numeric fields have
      // shipped as strings before.
      final r = NearbySectionsResult.fromJson({
        'data': {
          'shops_near_me': {
            'categories': [
              {
                'rank': '1',
                'count': '7',
                'nearest_km': '2.5',
                'items': [
                  {'id': 'a', 'distance': '1.5', 'total_ratings': '4'}
                ]
              }
            ]
          }
        }
      });
      final category = r.shops.single;
      expect(category.rank, 1);
      expect(category.count, 7);
      expect(category.nearestKm, 2.5);
      expect(category.items.single.distance, 1.5);
      expect(category.items.single.totalRatings, 4);
    });
  });
}
