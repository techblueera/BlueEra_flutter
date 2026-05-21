/// Shared product-catalog response shape used by every endpoint that
/// returns a paginated list of products with their variants — text
/// search, snap search, suggested-nearby, and category browse all
/// hand back the same payload.
///
/// Mirrors the API JSON 1:1 — one [Product] per `data[]` entry with a
/// nested `variants[]` list. Consumers that need "one row per variant"
/// (selection sets, cart rows) wrap each pair in [SelectedVariant].
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
class ProductCatalogResponse {
  final List<Product> data;
  final Pagination? pagination;

  ProductCatalogResponse({
    required this.data,
    this.pagination,
  });

  factory ProductCatalogResponse.fromJson(
      Map<String, dynamic> json) {
    final rawData = (json['data'] as List<dynamic>?) ?? const [];
    final products = <Product>[];
    for (final raw in rawData) {
      if (raw is! Map) continue;
      products.add(Product.fromJson(Map<String, dynamic>.from(raw)));
    }
    final paginationRaw = json['pagination'];
    return ProductCatalogResponse(
      data: products,
      pagination: paginationRaw is Map
          ? Pagination.fromJson(Map<String, dynamic>.from(paginationRaw))
          : null,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  /// Free-form warranty string from the API (server spelling is
  /// `productWarrenty` — preserved as a typo on the wire).
  final String productWarranty;
  final List<String> media;
  final List<String> tags;
  final List<String> guidelines;
  final List<ProductDetail> additionalDetails;
  final List<ProductFeature> features;
  final List<Variant> variants;

  Product({
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

  factory Product.fromJson(Map<String, dynamic> json) {
    final variantsRaw = (json['variants'] as List<dynamic>?) ?? const [];
    final additionalRaw =
        (json['additionalDetails'] as List<dynamic>?) ?? const [];
    final featuresRaw = (json['features'] as List<dynamic>?) ?? const [];
    return Product(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      productWarranty: (json['productWarrenty'] ?? '').toString(),
      media: _extractMediaUrls(json['images']),
      tags: List<String>.from(json['tags'] ?? const []),
      guidelines: List<String>.from(json['guidelines'] ?? const []),
      additionalDetails: additionalRaw
          .whereType<Map>()
          .map((e) => ProductDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      features: featuresRaw
          .whereType<Map>()
          .map((e) => ProductFeature.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      variants: variantsRaw
          .whereType<Map>()
          .map((e) => Variant.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class Variant {
  final String id;
  /// Free-form size/quantity string (e.g. "0.15oz", "2 oz Tin").
  final String quantity;
  final Map<String, dynamic> attributes;
  final double mrp;
  final double sellingPrice;
  final List<String> media;

  Variant({
    required this.id,
    required this.quantity,
    required this.attributes,
    required this.mrp,
    required this.sellingPrice,
    required this.media,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    final pricingList = (json['pricing'] as List<dynamic>?) ?? const [];
    final firstPricing = pricingList.isNotEmpty && pricingList.first is Map
        ? Map<String, dynamic>.from(pricingList.first as Map)
        : const <String, dynamic>{};
    return Variant(
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

class ProductDetail {
  final String title;
  final String details;

  ProductDetail({required this.title, required this.details});

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      title: (json['title'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
    );
  }
}

class ProductFeature {
  final String title;

  ProductFeature({required this.title});

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(title: (json['title'] ?? '').toString());
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return Pagination(
      total: asInt(json['total']),
      page: asInt(json['page']),
      limit: asInt(json['limit']),
      totalPages: asInt(json['totalPages']),
    );
  }
}

/// "One row per variant" container — used by selection sets, cart
/// rows, and any UI that paints a card per [Variant] while still
/// needing the parent [Product] for name/media/preview metadata.
class SelectedVariant {
  final Product product;
  final Variant variant;

  const SelectedVariant({required this.product, required this.variant});

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
List<SelectedVariant> flattenProducts(List<Product> products) {
  final out = <SelectedVariant>[];
  for (final p in products) {
    if (p.variants.isEmpty) continue;
    for (final v in p.variants) {
      out.add(SelectedVariant(product: p, variant: v));
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
