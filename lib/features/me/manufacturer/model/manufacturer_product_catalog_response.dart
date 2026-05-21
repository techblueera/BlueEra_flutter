/// Shared product-catalog response shape used by every endpoint that
/// returns a paginated list of products with their variants — text
/// search, snap search, suggested-nearby, and category browse all
/// hand back the same payload.
///
/// Mirrors the API JSON 1:1 — one [ManufacturerProduct] per `data[]` entry with a
/// nested `variants[]` list. Consumers that need "one row per variant"
/// (selection sets, cart rows) wrap each pair in [ManufacturerSelectedVariant].
///
/// Expected shape (abridged, only fields the app actually reads):
/// ```
/// {
///   "data": [
///     {
///       "_id", "name", "description", "tags": [...],
///       "images": [{"url"}], "guidelines": [...],
///       "productWarrenty",
///       "additionalDetails": [{"title", "details"}],
///       "features": [{"title"}],
///       "variants": [
///         {
///           "_id", "attributes", "quantity",
///           "pricing": [{"mrp", "sellingPrice"}],
///           "images": [{"url"}]
///         }
///       ]
///     }
///   ],
///   "pagination": { "total", "page", "limit", "totalPages" }
/// }
/// ```
class ManufacturerProductCatalogResponse {
  final List<ManufacturerProduct> data;
  final ManufacturerPagination? pagination;

  ManufacturerProductCatalogResponse({
    required this.data,
    this.pagination,
  });

  factory ManufacturerProductCatalogResponse.fromJson(
      Map<String, dynamic> json) {
    final rawData = (json['data'] as List<dynamic>?) ?? const [];
    final products = <ManufacturerProduct>[];
    for (final raw in rawData) {
      if (raw is! Map) continue;
      products.add(ManufacturerProduct.fromJson(Map<String, dynamic>.from(raw)));
    }
    final paginationRaw = json['pagination'];
    return ManufacturerProductCatalogResponse(
      data: products,
      pagination: paginationRaw is Map
          ? ManufacturerPagination.fromJson(Map<String, dynamic>.from(paginationRaw))
          : null,
    );
  }
}

class ManufacturerProduct {
  final String id;
  final String name;
  final String description;
  /// Free-form warranty string from the API (server spelling is
  /// `productWarrenty` — preserved as a typo on the wire).
  final String productWarranty;
  final List<String> media;
  final List<String> tags;
  final List<String> guidelines;
  final List<ManufacturerProductDetail> additionalDetails;
  final List<ManufacturerProductFeature> features;
  final List<ManufacturerVariant> variants;

  ManufacturerProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.productWarranty,
    required this.media,
    required this.tags,
    required this.guidelines,
    required this.additionalDetails,
    required this.features,
    required this.variants,
  });

  factory ManufacturerProduct.fromJson(Map<String, dynamic> json) {
    final variantsRaw = (json['variants'] as List<dynamic>?) ?? const [];
    final additionalRaw =
        (json['additionalDetails'] as List<dynamic>?) ?? const [];
    final featuresRaw = (json['features'] as List<dynamic>?) ?? const [];
    return ManufacturerProduct(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      productWarranty: (json['productWarrenty'] ?? '').toString(),
      media: _extractMediaUrls(json['images']),
      tags: List<String>.from(json['tags'] ?? const []),
      guidelines: List<String>.from(json['guidelines'] ?? const []),
      additionalDetails: additionalRaw
          .whereType<Map>()
          .map((e) => ManufacturerProductDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      features: featuresRaw
          .whereType<Map>()
          .map((e) => ManufacturerProductFeature.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      variants: variantsRaw
          .whereType<Map>()
          .map((e) => ManufacturerVariant.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ManufacturerVariant {
  final String id;
  /// Free-form size/quantity string (e.g. "0.15oz", "2 oz Tin").
  final String quantity;
  final Map<String, dynamic> attributes;
  final double mrp;
  final double sellingPrice;
  final List<String> media;

  ManufacturerVariant({
    required this.id,
    required this.quantity,
    required this.attributes,
    required this.mrp,
    required this.sellingPrice,
    required this.media,
  });

  factory ManufacturerVariant.fromJson(Map<String, dynamic> json) {
    final pricingList = (json['pricing'] as List<dynamic>?) ?? const [];
    final firstPricing = pricingList.isNotEmpty && pricingList.first is Map
        ? Map<String, dynamic>.from(pricingList.first as Map)
        : const <String, dynamic>{};
    return ManufacturerVariant(
      id: (json['_id'] ?? '').toString(),
      quantity: (json['quantity'] ?? '').toString(),
      attributes:
          Map<String, dynamic>.from(json['attributes'] ?? const {}),
      mrp: (firstPricing['mrp'] ?? 0).toDouble(),
      sellingPrice: (firstPricing['sellingPrice'] ?? 0).toDouble(),
      media: _extractMediaUrls(json['images']),
    );
  }
}

class ManufacturerProductDetail {
  final String title;
  final String details;

  ManufacturerProductDetail({required this.title, required this.details});

  factory ManufacturerProductDetail.fromJson(Map<String, dynamic> json) {
    return ManufacturerProductDetail(
      title: (json['title'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
    );
  }
}

class ManufacturerProductFeature {
  final String title;

  ManufacturerProductFeature({required this.title});

  factory ManufacturerProductFeature.fromJson(Map<String, dynamic> json) {
    return ManufacturerProductFeature(title: (json['title'] ?? '').toString());
  }
}

class ManufacturerPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  ManufacturerPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ManufacturerPagination.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return ManufacturerPagination(
      total: asInt(json['total']),
      page: asInt(json['page']),
      limit: asInt(json['limit']),
      totalPages: asInt(json['totalPages']),
    );
  }
}

/// "One row per variant" container — used by selection sets, cart
/// rows, and any UI that paints a card per [ManufacturerVariant] while still
/// needing the parent [ManufacturerProduct] for name/media/preview metadata.
class ManufacturerSelectedVariant {
  final ManufacturerProduct product;
  final ManufacturerVariant variant;

  const ManufacturerSelectedVariant({required this.product, required this.variant});

  String get id => variant.id;

  /// Best image for this variant: parent product media wins (it's the
  /// hero shot), variant media is the fallback when the parent has
  /// none.
  String get primaryImageUrl {
    if (product.media.isNotEmpty && product.media.first.isNotEmpty) {
      return product.media.first;
    }
    if (variant.media.isNotEmpty && variant.media.first.isNotEmpty) {
      return variant.media.first;
    }
    return '';
  }
}

/// Flattens a list of products into per-variant rows. Used by UI that
/// needs to paint one card per variant (e.g. the search/snap grid).
List<ManufacturerSelectedVariant> flattenProducts(List<ManufacturerProduct> products) {
  final out = <ManufacturerSelectedVariant>[];
  for (final p in products) {
    if (p.variants.isEmpty) continue;
    for (final v in p.variants) {
      out.add(ManufacturerSelectedVariant(product: p, variant: v));
    }
  }
  return out;
}

/// Extracts URL strings from the API's `images` / `videos` arrays where
/// each entry is an object `{ url, altText, _id }`.
List<String> _extractMediaUrls(dynamic raw) {
  if (raw is! List) return const [];
  final out = <String>[];
  for (final e in raw) {
    if (e is String && e.isNotEmpty) {
      out.add(e);
    } else if (e is Map) {
      final url = (e['url'] ?? '').toString();
      if (url.isNotEmpty) out.add(url);
    }
  }
  return out;
}
