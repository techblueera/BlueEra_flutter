/// Models for the **sectioned** `nearby-discover` response.
///
/// The endpoint now answers three ready-made sections instead of raw store
/// buckets:
///
/// ```
/// data.shops_near_me    { title, count, categories: [ … ] }
/// data.services_near_me { title, count, categories: [ … ] }
/// data.recent_visited   { title, count, items:      [ … ] }
/// ```
///
/// **The categories are a GROUPING; the businesses under them are what the
/// rails draw.** Each entry in `categories` carries an `items` array of real
/// shops — name, `dp`, its own `category`, and a `type` naming the vertical.
/// The category itself supplies the ORDER (its `rank`) and the heading data
/// (`count`, `nearest_km`), not a tile.
///
/// `recent_visited` is per-business directly, with no category wrapper.
///
/// Everything is defensively parsed: a missing section, a null field or a
/// string where a number was expected yields an empty list or a zero rather
/// than throwing. A parse failure here would take out the whole Discover
/// landing, and the backend is free to add sections this file does not know.
library;

/// Flattens categories → the businesses under them, in category-`rank` order
/// and the server's order within each.
///
/// Deliberately does NOT re-sort by distance: the backend ranks the categories
/// and orders the shops inside them, and flattening is not licence to throw
/// that away.
///
/// De-duplicated by business id — a shop listed under two categories would
/// otherwise appear twice in one rail, which reads as a data fault. The FIRST
/// occurrence wins, so it keeps its highest-ranked category's position.
List<NearbySectionItem> flattenNearbyBusinesses(
    List<NearbySectionCategory> categories) {
  final seen = <String>{};
  final out = <NearbySectionItem>[];
  for (final category in categories) {
    for (final item in category.items) {
      if (item.id.isNotEmpty && !seen.add(item.id)) continue;
      out.add(item);
    }
  }
  return out;
}

/// One nearby BUSINESS, nested under its category in either rail.
///
/// This is what the rails actually draw — the shop's own photo, its real name
/// and the category under it. The category is the grouping the server sends
/// them in, not the thing displayed.
class NearbySectionItem {
  const NearbySectionItem({
    required this.id,
    required this.name,
    required this.dp,
    required this.logo,
    required this.type,
    required this.businessType,
    required this.accountType,
    required this.userId,
    required this.ownerProfileImage,
    required this.categoryId,
    required this.categoryName,
    required this.subCategoryName,
    required this.distance,
    required this.avgRating,
    required this.totalRatings,
    required this.address,
    required this.isVerified,
  });

  /// The BUSINESS id — distinct from [userId], which is the owner's. They are
  /// equal for some accounts and different for others, so neither substitutes
  /// for the other.
  final String id;

  /// The business's real name, e.g. "highway dhaba".
  final String name;

  /// Display picture. Preferred over [logo]: the payload sends both and `dp`
  /// is the one the backend keeps current.
  final String dp;
  final String logo;

  /// The VERTICAL — `Grocery` / `Service` / `Product` / … This is the field
  /// that finally makes per-tile routing possible; without it a tap could only
  /// open the generic nearby list.
  final String type;

  /// `shop` | `service`.
  final String businessType;

  /// The OWNER's account type — `BUSINESS` / `INDIVIDUAL`.
  final String accountType;

  /// The owner's user id, and their avatar as a last-resort image.
  final String userId;
  final String ownerProfileImage;

  final String categoryId;
  final String categoryName;

  /// The SPECIFIC store type — "Mini Supermarket", "Beauty Parlour". More
  /// precise than [categoryName], and empty when the backend sends
  /// `sub_category: null`. Parsed but not drawn: the design puts the CATEGORY
  /// under the business name. One-line switch in the rail if that changes.
  final String subCategoryName;

  final double distance;
  final double avgRating;
  final int totalRatings;
  final String address;
  final bool isVerified;

  /// The image to draw, in the order the payload is worth trusting:
  /// the business's own display picture, then its logo, then the owner's
  /// avatar. Empty when the business has no artwork at all — the tile then
  /// falls back to a glyph rather than a broken image.
  String get displayImage {
    for (final candidate in [dp, logo, ownerProfileImage]) {
      if (candidate.trim().isNotEmpty) return candidate.trim();
    }
    return '';
  }

  factory NearbySectionItem.fromJson(Map json, {Map? parentCategory}) {
    // `category` is per-item, but fall back to the enclosing category so a row
    // that omits it still shows the group it was sent under rather than blank.
    final cat = json['category'] is Map ? json['category'] as Map : parentCategory;
    final user = json['user'] is Map ? json['user'] as Map : null;
    return NearbySectionItem(
      id: _str(json['id']),
      name: _str(json['name']),
      dp: _str(json['dp']),
      logo: _str(json['logo']),
      type: _str(json['type']),
      businessType: _str(json['business_type']),
      accountType: _str(json['account_type']),
      userId: _str(json['user_id']),
      ownerProfileImage: user == null ? '' : _str(user['profile_image']),
      categoryId: cat == null ? '' : _str(cat['id']),
      categoryName: cat == null ? '' : _str(cat['name']),
      // Legitimately null on some businesses — `_str` turns that into ''.
      subCategoryName: json['sub_category'] is Map
          ? _str((json['sub_category'] as Map)['name'])
          : '',
      distance: _double(json['distance']),
      avgRating: _double(json['avg_rating']),
      totalRatings: _int(json['total_ratings']),
      address: _str(json['address']),
      isVerified: json['is_verified'] == true,
    );
  }
}

/// One category group in "Shops Near Me" / "Services Near Me", and the
/// businesses the server nested under it.
class NearbySectionCategory {
  const NearbySectionCategory({
    required this.rank,
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.count,
    required this.nearestKm,
    required this.items,
  });

  /// Server-assigned display order. Honoured as-is — the backend ranks these
  /// and re-sorting client-side would throw that away.
  final int rank;

  final String id;
  final String name;

  /// The vertical this category belongs to — `Grocery`, `Service`, …
  final String type;

  final String imageUrl;

  /// How many businesses of this category are within the searched radius.
  /// May exceed `items.length`, which the server caps per category.
  final int count;

  /// Distance to the closest one, in km.
  final double nearestKm;

  /// The businesses themselves — what the rails draw.
  final List<NearbySectionItem> items;

  factory NearbySectionCategory.fromJson(Map json) {
    final rawItems = json['items'];
    return NearbySectionCategory(
      rank: _int(json['rank']),
      id: _str(json['id']),
      name: _str(json['name']),
      type: _str(json['type']),
      imageUrl: _str(json['image_url']),
      count: _int(json['count']),
      nearestKm: _double(json['nearest_km']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => NearbySectionItem.fromJson(e, parentCategory: json))
              .toList()
          : const [],
    );
  }
}

/// One business in "Recent Visited Stores".
class NearbyVisitedStore {
  const NearbyVisitedStore({
    required this.rank,
    required this.id,
    required this.businessName,
    required this.logo,
    required this.categoryId,
    required this.categoryName,
    required this.distance,
    required this.chatClickCount,
    required this.chatUniqueUsers,
    required this.lastClickedAt,
  });

  final int rank;
  final String id;
  final String businessName;
  final String logo;

  /// Flattened from the nested `category` object — the row only ever shows the
  /// name, and the id is kept for routing.
  final String categoryId;
  final String categoryName;

  /// Kilometres from the user.
  final double distance;

  /// Engagement counters. Not drawn today; parsed because they are the reason
  /// this section is ordered the way it is, and dropping them here would mean
  /// re-deriving the shape to use them later.
  final int chatClickCount;
  final int chatUniqueUsers;

  /// When this user last opened the store. Null when unparseable — the row
  /// then simply shows no timestamp rather than a wrong one.
  final DateTime? lastClickedAt;

  factory NearbyVisitedStore.fromJson(Map json) {
    final cat = json['category'];
    return NearbyVisitedStore(
      rank: _int(json['rank']),
      id: _str(json['id']),
      businessName: _str(json['business_name']),
      logo: _str(json['logo']),
      categoryId: (cat is Map) ? _str(cat['id']) : '',
      categoryName: (cat is Map) ? _str(cat['name']) : '',
      distance: _double(json['distance']),
      chatClickCount: _int(json['chat_click_count']),
      chatUniqueUsers: _int(json['chat_unique_users']),
      lastClickedAt: _date(json['last_clicked_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'id': id,
        'business_name': businessName,
        'logo': logo,
        'category': {'id': categoryId, 'name': categoryName},
        'distance': distance,
        'chat_click_count': chatClickCount,
        'chat_unique_users': chatUniqueUsers,
        'last_clicked_at': lastClickedAt?.toIso8601String(),
      };
}

/// The whole sectioned payload.
class NearbySectionsResult {
  const NearbySectionsResult({
    required this.shops,
    required this.services,
    required this.recentVisited,
    required this.shopsTitle,
    required this.servicesTitle,
    required this.recentTitle,
    required this.degraded,
    required this.radiusKm,
  });

  final List<NearbySectionCategory> shops;
  final List<NearbySectionCategory> services;
  final List<NearbyVisitedStore> recentVisited;

  /// Section headings as the SERVER words them. Used in preference to a
  /// hard-coded string so a backend rename reaches the UI without a release —
  /// the local wording is only the fallback for an older payload.
  final String shopsTitle;
  final String servicesTitle;
  final String recentTitle;

  /// `meta.degraded` — slices that failed upstream. An empty section is only
  /// honestly "nothing nearby" when its slice is NOT in here.
  final List<String> degraded;

  /// The radius the backend actually searched (km). Read back rather than
  /// assumed: the server is free to answer on a radius other than requested.
  final double radiusKm;

  bool get isEmpty =>
      shops.isEmpty && services.isEmpty && recentVisited.isEmpty;

  factory NearbySectionsResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];

    List<NearbySectionCategory> categories(String key) {
      final section = (data is Map) ? data[key] : null;
      final list = (section is Map) ? section['categories'] : null;
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map(NearbySectionCategory.fromJson)
          .toList()
        // The server ranks these; sorting by that rank makes the order
        // explicit rather than relying on JSON array order surviving the
        // round-trip through Hive.
        ..sort((a, b) => a.rank.compareTo(b.rank));
    }

    String title(String key, String fallback) {
      final section = (data is Map) ? data[key] : null;
      final t = (section is Map) ? _str(section['title']) : '';
      return t.isEmpty ? fallback : t;
    }

    final visitedSection = (data is Map) ? data['recent_visited'] : null;
    final visitedItems =
        (visitedSection is Map) ? visitedSection['items'] : null;

    return NearbySectionsResult(
      shops: categories('shops_near_me'),
      services: categories('services_near_me'),
      recentVisited: (visitedItems is List)
          ? (visitedItems
              .whereType<Map>()
              .map(NearbyVisitedStore.fromJson)
              .toList()
            ..sort((a, b) => a.rank.compareTo(b.rank)))
          : const [],
      shopsTitle: title('shops_near_me', 'Shops Near Me'),
      servicesTitle: title('services_near_me', 'Services Near Me'),
      recentTitle: title('recent_visited', 'Recent Visited Stores'),
      degraded: (meta is Map && meta['degraded'] is List)
          ? (meta['degraded'] as List).map((e) => e.toString()).toList()
          : const [],
      radiusKm: (meta is Map) ? _double(meta['radius']) : 0,
    );
  }
}

// ── Coercion helpers ────────────────────────────────────────────────────────
//
// The payload mixes numeric and string forms for the same field depending on
// which service produced it, so nothing is cast directly.

String _str(dynamic v) => v?.toString() ?? '';

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _double(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

DateTime? _date(dynamic v) {
  final raw = v?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}
