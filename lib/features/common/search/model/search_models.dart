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
  final double? score;

  /// Seller/business id, when the backend attaches one to the result (grocery
  /// products may). Used to group the item under its store in the cart; falls
  /// back to the product id when absent.
  final String? businessId;

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
    this.score,
    this.businessId,
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
        score: (j['_score'] as num?)?.toDouble(),
        businessId: (j['businessId'] ?? j['sellerId'] ?? j['ownerId'])
            as String?,
      );
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
