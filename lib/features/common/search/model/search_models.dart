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
      );

  static num? _toNum(dynamic v) =>
      v is num ? v : (v is String ? num.tryParse(v) : null);

  static double? _toDouble(dynamic v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  static int? _toInt(dynamic v) =>
      v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

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
}

class SearchResponse {
  final String query;
  final int total;
  final int page;
  final int limit;

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
  });

  /// True while more pages exist for the current query/type.
  bool get hasMore => page * limit < total;

  factory SearchResponse.fromJson(Map<String, dynamic> j) {
    final parsed = j['parsed'];
    return SearchResponse(
      query: j['query'] as String? ?? '',
      total: (j['total'] as num?)?.toInt() ?? 0,
      page: (j['page'] as num?)?.toInt() ?? 1,
      limit: (j['limit'] as num?)?.toInt() ?? 20,
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
    if (filters['geo'] == true) parts.add('near me');
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

  Suggestion({
    required this.entityType,
    required this.title,
    this.subtitle,
    this.sourceId,
    this.deepLink,
    this.imageUrl,
  });

  factory Suggestion.fromJson(Map<String, dynamic> j) => Suggestion(
        entityType: j['entityType'] as String? ?? 'unknown',
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        sourceId: j['sourceId'] as String?,
        deepLink: j['deepLink'] as String?,
        imageUrl: j['imageUrl'] as String?,
      );
}
