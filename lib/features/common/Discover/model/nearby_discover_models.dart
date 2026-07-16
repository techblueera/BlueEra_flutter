/// Models for `GET map-service/api/nearby/discover`.
/// See docs/backend/nearby-discover-integration.md.
///
/// This app currently consumes only the **stores** slice (the "Nearest Stores"
/// rail); the services/riders buckets are parsed lazily elsewhere if needed.

double _toDouble(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

int _toInt(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

String _str(dynamic v) => v?.toString() ?? '';

/// One nearby store (an entry inside a category bucket's `items`).
class NearbyStoreCard {
  final String id; // business id
  final String? userId; // merchant user id (null-able per guide)
  final String businessName;
  final String logo; // "" when unset
  final String type; // Grocery | Food | Product
  final String typeOfBusiness;
  final String address;
  final double distance; // km
  final double avgRating;
  final int totalProductCount;
  final int totalCategoryCount;
  final String? subCategoryName;

  /// The parent bucket's category name (e.g. "Kirana Store") — shown under the
  /// store name in the rail.
  final String categoryName;

  /// The parent bucket's category image — used as the avatar fallback when the
  /// store has no `logo`.
  final String categoryImageUrl;

  const NearbyStoreCard({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.logo,
    required this.type,
    required this.typeOfBusiness,
    required this.address,
    required this.distance,
    required this.avgRating,
    required this.totalProductCount,
    required this.totalCategoryCount,
    required this.subCategoryName,
    required this.categoryName,
    required this.categoryImageUrl,
  });

  /// The label shown under the store name — sub-category if present, else the
  /// parent category name (mirrors the reference "Kirana Store / General Store").
  String get displayCategory =>
      (subCategoryName?.trim().isNotEmpty ?? false)
          ? subCategoryName!.trim()
          : categoryName;

  /// The avatar image URL: the store's own `logo` first, then the category
  /// image; empty when neither is available (caller shows a placeholder icon).
  String get displayImage =>
      logo.trim().isNotEmpty ? logo.trim() : categoryImageUrl.trim();

  factory NearbyStoreCard.fromJson(
    Map<String, dynamic> json, {
    required String categoryName,
    required String categoryImageUrl,
  }) {
    final sub = json['sub_category'];
    return NearbyStoreCard(
      id: _str(json['id']),
      userId: json['user_id'] == null ? null : _str(json['user_id']),
      businessName: _str(json['business_name']),
      logo: _str(json['logo']),
      type: _str(json['type']),
      typeOfBusiness: _str(json['type_of_business']),
      address: _str(json['address']),
      distance: _toDouble(json['distance']),
      avgRating: _toDouble(json['avg_rating']),
      totalProductCount: _toInt(json['total_product_count']),
      totalCategoryCount: _toInt(json['total_category_count']),
      subCategoryName: (sub is Map) ? _str(sub['name']) : null,
      categoryName: categoryName,
      categoryImageUrl: categoryImageUrl,
    );
  }
}

/// One nearby worker (an entry inside a `services` or `riders` bucket's
/// `items`). Services are self-employed / professional providers; riders are
/// gig workers (bike / taxi). Show `designation`, never `profession`.
class NearbyWorkerCard {
  final String userId;
  final String name;
  final String username;
  final String profileImage; // "" when unset
  final String designation; // title-cased, display this
  final String profession; // coarse enum (SELF_EMPLOYED / PROFESSIONAL) — routing only
  final double distance; // km
  final bool live; // currently open & pinging (real-time position)
  final String contactNo;

  /// From the parent bucket's `profession` object.
  final String professionName; // e.g. "Electrician"
  final String tagId; // stable key for icons/grouping
  final String profileType; // "Self Employed" | "GigWork"

  const NearbyWorkerCard({
    required this.userId,
    required this.name,
    required this.username,
    required this.profileImage,
    required this.designation,
    required this.profession,
    required this.distance,
    required this.live,
    required this.contactNo,
    required this.professionName,
    required this.tagId,
    required this.profileType,
  });

  /// PROFESSIONAL providers open the consultant view; everything else (self
  /// employed) opens the self-employee view.
  bool get isProfessional => profession.toUpperCase().contains('PROFESSIONAL');

  /// Riders come from the `riders` bucket (`profileType: "GigWork"`).
  bool get isRider => profileType.toLowerCase().contains('gig');

  /// The label under the name — the worker's designation, else the bucket
  /// profession name.
  String get displayLabel =>
      designation.trim().isNotEmpty ? designation.trim() : professionName;

  factory NearbyWorkerCard.fromJson(
    Map<String, dynamic> json, {
    required String professionName,
    required String tagId,
    required String profileType,
  }) {
    return NearbyWorkerCard(
      userId: _str(json['user_id']),
      name: _str(json['name']),
      username: _str(json['username']),
      profileImage: _str(json['profile_image']),
      designation: _str(json['designation']),
      profession: _str(json['profession']),
      distance: _toDouble(json['distance']),
      live: json['live'] == true,
      contactNo: _str(json['contact_no']),
      professionName: professionName,
      tagId: tagId,
      profileType: profileType,
    );
  }
}

/// Parsed nearby-discover response: a flattened nearest-first store list (all
/// types) plus the `services` and `riders` worker lists, and the `degraded`
/// labels so the UI can tell "outage" from "nothing nearby".
class NearbyDiscoverResult {
  final List<NearbyStoreCard> stores;
  final List<NearbyWorkerCard> services;
  final List<NearbyWorkerCard> riders;
  final List<String> degraded;

  const NearbyDiscoverResult({
    required this.stores,
    required this.services,
    required this.riders,
    required this.degraded,
  });

  /// True when the whole stores slice failed upstream (not just "nothing
  /// nearby"). Per-type inventory degradations still return the other types.
  bool get storesDegraded => degraded.contains('businesses');

  /// Flattens **every** store type in `data.stores` (Grocery / Food / Product)
  /// into one nearest-first list. Each card keeps its own `type` so the UI can
  /// route it to the right store-visit screen.
  factory NearbyDiscoverResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final storesObj = (data is Map) ? data['stores'] : null;

    final cards = <NearbyStoreCard>[];
    if (storesObj is Map) {
      for (final buckets in storesObj.values) {
        if (buckets is! List) continue;
        for (final b in buckets) {
          if (b is! Map) continue;
          final cat = b['category'];
          final catName = (cat is Map) ? _str(cat['name']) : '';
          final catImage = (cat is Map) ? _str(cat['image_url']) : '';
          final items = (b['items'] is List) ? b['items'] as List : const [];
          for (final it in items) {
            if (it is! Map) continue;
            cards.add(NearbyStoreCard.fromJson(
              Map<String, dynamic>.from(it),
              categoryName: catName,
              categoryImageUrl: catImage,
            ));
          }
        }
      }
    }
    // Buckets are nearest-first per type, but flattening across types/categories
    // interleaves them; sort so the rail reads strictly nearest-first overall.
    cards.sort((a, b) => a.distance.compareTo(b.distance));

    final services = _parseWorkers((data is Map) ? data['services'] : null);
    final riders = _parseWorkers((data is Map) ? data['riders'] : null);

    final meta = json['meta'];
    final degraded = (meta is Map && meta['degraded'] is List)
        ? (meta['degraded'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return NearbyDiscoverResult(
      stores: cards,
      services: services,
      riders: riders,
      degraded: degraded,
    );
  }

  /// Flattens `services` / `riders` buckets into one worker list. The backend
  /// deliberately orders live workers first within each bucket, so we PRESERVE
  /// bucket order (no distance re-sort — see the guide's §2.4 warning).
  static List<NearbyWorkerCard> _parseWorkers(dynamic bucketsRaw) {
    final out = <NearbyWorkerCard>[];
    if (bucketsRaw is! List) return out;
    for (final b in bucketsRaw) {
      if (b is! Map) continue;
      final prof = b['profession'];
      final pName = (prof is Map) ? _str(prof['name']) : '';
      final tag = (prof is Map) ? _str(prof['tag_id']) : '';
      final pType = (prof is Map) ? _str(prof['profileType']) : '';
      final items = (b['items'] is List) ? b['items'] as List : const [];
      for (final it in items) {
        if (it is! Map) continue;
        out.add(NearbyWorkerCard.fromJson(
          Map<String, dynamic>.from(it),
          professionName: pName,
          tagId: tag,
          profileType: pType,
        ));
      }
    }
    return out;
  }
}
