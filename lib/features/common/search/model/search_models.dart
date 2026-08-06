import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:get/get_utils/get_utils.dart';

/// Models for the global hybrid search service
/// (`search-service/*`, see docs/backend/FLUTTER_INTEGRATION_SEARCH.md).
///
/// Parsing is defensive: the search API returns fields at the top level of the
/// response (no `data` envelope), so these are built from the raw response map.

class SearchResultItem {
  final String id;
  final String entityType;
  final String? sourceId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? deepLink;
  final String? brand;
  final String? category;
  final num? price;
  final String? currency;
  final String? city;

  /// Postal code of a location-scoped offer. The backend attaches it to
  /// grocery/health variants (a `city` + `pincode` pair marks the offer's
  /// serviceable area); null for entities that aren't location-scoped.
  final String? pincode;

  /// Display address, already de-duplicated and joined by the backend —
  /// "Rajpur Road, Dehradun, Uttarakhand, 248001". Render as-is.
  ///
  /// Omitted (never null) for catalogue rows — a packet of atta has no address,
  /// while the shop that sells it does, and both can appear in one list. Render
  /// it per row, never as a fixed slot.
  final String? address;

  /// Straight-line metres from the searcher. Only present when `lat`/`lng` were
  /// sent AND the row carries coordinates.
  final int? distanceMeters;

  /// The same distance pre-formatted by the backend — "840 m", "2.4 km".
  final String? distanceText;

  /// Coordinates from the GeoJSON `location` (which is `[lng, lat]` — longitude
  /// first). Null when the entity has no point.
  final double? lat;
  final double? lng;

  /// Free-form tags. For `post` results these are the hashtags; empty for
  /// entity types that don't carry them.
  final List<String> tags;

  final double? score;

  /// Seller/business id, when the backend attaches one to the result (grocery
  /// products may). Used to group the item under its store in the cart; falls
  /// back to the product id when absent.
  final String? businessId;

  /// Owner **user** id of a shop/business result, when the index carries one.
  ///
  /// NOT interchangeable with [businessId]: a store profile is fetched by the
  /// business `_id`, while its inventory is fetched by the owner's user id, and
  /// several screens (e.g. `VisitGroceryStoreScreen`) need both. Parsed
  /// separately — and defensively — so a result that does carry an owner id
  /// hands over the right one instead of the store id twice.
  final String? ownerUserId;

  // ── Optional merchandising fields (Flipkart-style listing card) ──────
  // The search backend does not send these yet; they parse defensively so the
  // richer product card lights up the moment the API includes them, and each
  // element stays hidden until then. Keys accept a couple of common aliases.
  final num? mrp; // original / struck-through price
  final num? offerPrice; // best price incl. bank offer (the "WOW!" line)
  final int? discountPercentRaw; // explicit discount %, if the API sends one
  final double? rating; // 0..5
  final int? ratingCount;
  final bool sponsored;
  final bool assured;
  final String? stockLabel; // e.g. "Only few left"
  final String? deliveryBy; // e.g. "8th Jul"
  final String? warranty; // e.g. "1 year warranty by realme"

  /// How many products the shop/business carries. Only shops send it — a
  /// catalogue row never does — so the listing card renders the badge per row
  /// instead of reserving a fixed slot for it.
  final int? productCount;

  SearchResultItem({
    required this.id,
    required this.entityType,
    required this.title,
    this.sourceId,
    this.subtitle,
    this.imageUrl,
    this.deepLink,
    this.brand,
    this.category,
    this.price,
    this.currency,
    this.city,
    this.pincode,
    this.address,
    this.distanceMeters,
    this.distanceText,
    this.lat,
    this.lng,
    this.tags = const [],
    this.score,
    this.businessId,
    this.ownerUserId,
    this.mrp,
    this.offerPrice,
    this.discountPercentRaw,
    this.rating,
    this.ratingCount,
    this.sponsored = false,
    this.assured = false,
    this.stockLabel,
    this.deliveryBy,
    this.warranty,
    this.productCount,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> j) => SearchResultItem(
        id: (j['_id'] ?? '').toString(),
        entityType: j['entityType'] as String? ?? 'unknown',
        sourceId: j['sourceId'] as String?,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        imageUrl: j['imageUrl'] as String?,
        deepLink: j['deepLink'] as String?,
        brand: j['brand'] as String?,
        category: j['category'] as String?,
        price: j['price'] as num?,
        currency: j['currency'] as String?,
        city: j['city'] as String?,
        pincode: j['pincode']?.toString(),
        address: j['address'] as String?,
        distanceMeters: _toInt(j['distanceMeters']),
        distanceText: j['distanceText'] as String?,
        // GeoJSON is [lng, lat] — longitude FIRST.
        lat: _coord(j['location'], 1),
        lng: _coord(j['location'], 0),
        tags: ((j['tags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        score: (j['_score'] as num?)?.toDouble(),
        businessId: (j['businessId'] ?? j['sellerId'] ?? j['ownerId'])
            as String?,
        ownerUserId:
            (j['ownerId'] ?? j['ownerUserId'] ?? j['userId'])?.toString(),
        mrp: _toNum(j['mrp'] ?? j['originalPrice'] ?? j['strikePrice']),
        offerPrice: _toNum(j['offerPrice'] ?? j['bankOfferPrice']),
        discountPercentRaw: _toInt(j['discountPercent'] ?? j['discount']),
        rating: _toDouble(j['rating'] ?? j['avgRating']),
        ratingCount: _toInt(j['ratingCount'] ?? j['reviewCount']),
        sponsored: (j['sponsored'] ?? j['isSponsored']) as bool? ?? false,
        assured: (j['assured'] ?? j['isAssured']) as bool? ?? false,
        stockLabel: j['stockLabel'] as String?,
        deliveryBy: (j['deliveryBy'] ?? j['delivery']) as String?,
        warranty: j['warranty'] as String?,
        productCount: _toInt(j['productCount'] ??
            j['totalProductCount'] ??
            j['productsCount'] ??
            j['itemCount']),
      );

  static num? _toNum(dynamic v) =>
      v is num ? v : (v is String ? num.tryParse(v) : null);

  static double? _toDouble(dynamic v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  static int? _toInt(dynamic v) =>
      v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

  /// One coordinate out of a GeoJSON `location` map — index 0 is longitude,
  /// 1 is latitude. Null when absent or malformed. A whole-number coordinate
  /// decodes as `int`, hence the `num` check rather than a cast to `double`.
  static double? _coord(dynamic location, int index) {
    final c = (location is Map) ? location['coordinates'] : null;
    if (c is! List || c.length < 2) return null;
    final v = c[index];
    return v is num ? v.toDouble() : null;
  }

  /// True only when the server actually measured a distance for this row.
  bool get hasDistance => distanceMeters != null;

  /// "1.4 km · Rajpur Road, Dehradun, 248001" — whichever of the two the row
  /// carries, empty when it carries neither. Rows in one list differ, so this
  /// is rendered conditionally per card.
  String get locationLine => [
        if (hasDistance && (distanceText?.isNotEmpty ?? false)) distanceText!,
        if (address?.trim().isNotEmpty ?? false) address!.trim(),
      ].join(' · ');

  /// Effective discount %: explicit from the API, else derived from the MRP
  /// vs the selling price (never fabricated — only shown when a real MRP that
  /// exceeds the price is present).
  int? get discountPercent {
    if (discountPercentRaw != null && discountPercentRaw! > 0) {
      return discountPercentRaw;
    }
    if (mrp != null && price != null && mrp! > price!) {
      return (((mrp! - price!) / mrp!) * 100).round();
    }
    return null;
  }

  /// True when there is a genuine struck-through MRP above the price.
  bool get hasDiscount =>
      mrp != null && price != null && mrp! > price! && (discountPercent ?? 0) > 0;

  /// "10K" / "1.2L" — the product count abbreviated for the listing badge.
  /// Null when the row carries no count (or a zero one), so the badge is
  /// dropped rather than rendered as an empty box.
  String? get productCountLabel {
    final count = productCount;
    if (count == null || count <= 0) return null;
    return formatCompactCount(count);
  }

  /// Indian-style short form for large counts: 10,000 -> "10K",
  /// 1,20,000 -> "1.2L", 2,00,00,000 -> "2Cr". A trailing ".0" is dropped so
  /// round numbers stay narrow inside the badge.
  static String formatCompactCount(int value) {
    if (value < 1000) return '$value';
    if (value < 100000) return '${_trimDecimal(value / 1000)}K';
    if (value < 10000000) return '${_trimDecimal(value / 100000)}L';
    return '${_trimDecimal(value / 10000000)}Cr';
  }

  static String _trimDecimal(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

class SearchResponse {
  final String query;

  /// Size of the ranked candidate pool for this request — **not** a global
  /// match count. The engine fuses a bounded pool (~[maxCandidatePool] rows) per
  /// request, so this grows slightly with `page`. Don't render it as "N results
  /// found" and don't derive a page count from it.
  final int total;

  final int page;
  final int limit;

  /// The scope that actually ran, echoed back so a screen can confirm it asked
  /// for what it thinks it did. Null on older responses.
  final String? category;

  /// Entity types this response was scoped to; null means every type
  /// (`category=all`).
  final List<String>? types;

  /// entityType -> count across the whole result set (drives the type tabs).
  final Map<String, int> facets;
  final bool cached;

  /// Server-parsed natural-language constraints (residual text + filters like
  /// price/color/geo). Used to render an "applied filters" chip.
  final String residualText;
  final Map<String, dynamic> filters;

  final List<SearchResultItem> results;

  SearchResponse({
    required this.query,
    required this.total,
    required this.page,
    required this.limit,
    required this.facets,
    required this.cached,
    required this.residualText,
    required this.filters,
    required this.results,
    this.category,
    this.types,
  });

  /// Ceiling of the server's fused candidate pool. Paging past it only returns
  /// empty pages, so it doubles as the client's stop condition.
  static const int maxCandidatePool = 100;

  /// True while another page is worth asking for.
  ///
  /// Deliberately *not* `page * limit < total`: `total` is the pool size, not a
  /// match count, and it creeps up with each page — so that test keeps
  /// requesting pages that come back empty. Page on what actually arrived, and
  /// stop at the pool ceiling.
  bool get hasMore =>
      results.length == limit && page * limit < maxCandidatePool;

  /// Honest headline count: past the pool ceiling the exact figure isn't
  /// available, so "100+" is the most that can truthfully be shown.
  String get totalLabel =>
      total >= maxCandidatePool ? '$maxCandidatePool+' : '$total';

  factory SearchResponse.fromJson(Map<String, dynamic> j) {
    final parsed = j['parsed'];
    return SearchResponse(
      query: j['query'] as String? ?? '',
      total: (j['total'] as num?)?.toInt() ?? 0,
      page: (j['page'] as num?)?.toInt() ?? 1,
      limit: (j['limit'] as num?)?.toInt() ?? 20,
      category: j['category'] as String?,
      types: (j['types'] as List?)?.map((e) => e.toString()).toList(),
      facets: (j['facets'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
          ) ??
          <String, int>{},
      cached: j['cached'] as bool? ?? false,
      residualText:
          parsed is Map ? (parsed['residualText'] as String? ?? '') : '',
      filters: parsed is Map && parsed['filters'] is Map
          ? Map<String, dynamic>.from(parsed['filters'] as Map)
          : <String, dynamic>{},
      results: ((j['results'] as List?) ?? [])
          .map((e) => SearchResultItem.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Human-readable summary of the parsed constraints, e.g.
  /// `≤ ₹15,000 · red · near me`. Empty when nothing was parsed.
  String get appliedFiltersText {
    final parts = <String>[];
    final price = filters['price'];
    if (price is Map) {
      final gte = price['gte'];
      final lte = price['lte'];
      if (gte != null && lte != null) {
        parts.add('₹${formatPrice(gte)} – ₹${formatPrice(lte)}');
      } else if (lte != null) {
        parts.add('≤ ₹${formatPrice(lte)}');
      } else if (gte != null) {
        parts.add('≥ ₹${formatPrice(gte)}');
      }
    }
    final color = filters['color'];
    if (color is String && color.isNotEmpty) parts.add(color);
    // The colour comes back as the word the user typed, so it stays as-is;
    // "near me" is ours to phrase and is translated.
    if (filters['geo'] == true) parts.add(AppStrings.globalSearchNearMe.tr);
    return parts.join(' · ');
  }

  /// Thousands-grouped price string (no currency symbol), e.g. `13,999`.
  static String formatPrice(dynamic n) {
    final s = (n is num ? n.round() : n).toString();
    // Group in Indian-ish thousands for readability.
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class Suggestion {
  final String entityType;
  final String title;
  final String? subtitle;
  final String? sourceId;
  final String? deepLink;
  final String? imageUrl;

  /// Same per-row address / distance the full search returns — `/suggest`
  /// carries them whenever the suggested entity has them and `lat`/`lng` were
  /// sent. Absent for catalogue rows.
  final String? address;
  final int? distanceMeters;
  final String? distanceText;

  Suggestion({
    required this.entityType,
    required this.title,
    this.subtitle,
    this.sourceId,
    this.deepLink,
    this.imageUrl,
    this.address,
    this.distanceMeters,
    this.distanceText,
  });

  factory Suggestion.fromJson(Map<String, dynamic> j) => Suggestion(
        entityType: j['entityType'] as String? ?? 'unknown',
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        sourceId: j['sourceId'] as String?,
        deepLink: j['deepLink'] as String?,
        imageUrl: j['imageUrl'] as String?,
        address: j['address'] as String?,
        distanceMeters: (j['distanceMeters'] as num?)?.toInt(),
        distanceText: j['distanceText'] as String?,
      );

  bool get hasDistance => distanceMeters != null;

  /// "1.4 km · Rajpur Road, Dehradun" — empty when the row has neither.
  String get locationLine => [
        if (hasDistance && (distanceText?.isNotEmpty ?? false)) distanceText!,
        if (address?.trim().isNotEmpty ?? false) address!.trim(),
      ].join(' · ');
}
