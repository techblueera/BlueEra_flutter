/// Model for the grocery Search-Order "search-by-product" response — the list
/// of nearby **stores** (grouped by business) that stock a given product.
///
/// See docs/backend/SEARCH_ORDER_FLUTTER_GUIDE.md (step 2). The API returns one
/// entry per business with an aggregate (`matchingVariantCount`,
/// `minSellingPrice`, `totalStock`) plus the raw `inventories` rows. The store
/// profile (name / logo / address / distance) may be populated on the row under
/// a few common aliases, so it is parsed defensively — the card still renders a
/// sensible fallback when a field is absent.
class StoreMatch {
  final String businessId;
  final int matchingVariantCount;
  final num minSellingPrice;
  final int totalStock;

  /// Raw inventory rows (each carries `inventoryId`, `productVariant`,
  /// `product`, `batches`) — kept so an order line can be built without a
  /// second fetch (see [firstOrderableLine]).
  final List<dynamic> inventories;

  // ── Store profile (populated defensively) ──────────────────────────────
  final String? businessName;
  final String? businessLogo;
  final String? businessAddress;
  final String? city;
  final String? pincode;

  /// Distance to the store in km, when the backend attaches it.
  final double? distanceKm;

  StoreMatch({
    required this.businessId,
    required this.matchingVariantCount,
    required this.minSellingPrice,
    required this.totalStock,
    required this.inventories,
    this.businessName,
    this.businessLogo,
    this.businessAddress,
    this.city,
    this.pincode,
    this.distanceKm,
  });

  factory StoreMatch.fromJson(Map<String, dynamic> j) {
    // The store profile can arrive nested under a populated object or flattened
    // onto the row; look in both places.
    final biz = (j['business'] ?? j['businessProfile'] ?? j['store']);
    final b = biz is Map ? Map<String, dynamic>.from(biz) : const {};

    return StoreMatch(
      businessId: (j['businessId'] ?? j['_id'] ?? '').toString(),
      matchingVariantCount: _toInt(j['matchingVariantCount']) ?? 0,
      minSellingPrice: _toNum(j['minSellingPrice']) ?? 0,
      totalStock: _toInt(j['totalStock']) ?? 0,
      inventories: (j['inventories'] as List?) ?? const [],
      businessName: (j['businessName'] ??
              j['storeName'] ??
              b['businessName'] ??
              b['name'] ??
              b['storeName'])
          ?.toString(),
      businessLogo: (j['businessLogo'] ??
              j['logo'] ??
              b['businessLogo'] ??
              b['logo'] ??
              b['profileImage'] ??
              b['image'])
          ?.toString(),
      businessAddress:
          (j['address'] ?? b['address'] ?? b['fullAddress'])?.toString(),
      city: (j['cityName'] ?? j['city'] ?? b['cityName'] ?? b['city'])
          ?.toString(),
      pincode: (j['pincode'] ?? b['pincode'])?.toString(),
      distanceKm:
          _toDouble(j['distance'] ?? j['distanceInKm'] ?? j['distanceKm']),
    );
  }

  /// A one-line human summary of the store's address, best-effort.
  String? get locationLine {
    final parts = <String>[
      if (businessAddress != null && businessAddress!.trim().isNotEmpty)
        businessAddress!.trim(),
      if ((businessAddress == null || businessAddress!.trim().isEmpty) &&
          city != null &&
          city!.trim().isNotEmpty)
        city!.trim(),
      if (pincode != null && pincode!.trim().isNotEmpty) pincode!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// The first orderable inventory line for this store — inventoryId +
  /// productVariantId + pricing — so a cart line can be built directly from a
  /// tapped store (guide step 4). Null when the row carries no usable line.
  StoreOrderLine? get firstOrderableLine {
    for (final raw in inventories) {
      if (raw is! Map) continue;
      final inv = Map<String, dynamic>.from(raw);
      final inventoryId =
          (inv['inventoryId'] ?? inv['_id'])?.toString();
      if (inventoryId == null || inventoryId.isEmpty) continue;

      final variant = inv['productVariant'];
      final variantId = variant is Map
          ? (variant['_id'] ?? variant['id'])?.toString()
          : variant?.toString();

      final batches = inv['batches'];
      final batch = (batches is List && batches.isNotEmpty && batches.first is Map)
          ? Map<String, dynamic>.from(batches.first as Map)
          : null;
      final pricing = (variant is Map && variant['pricing'] is List &&
              (variant['pricing'] as List).isNotEmpty &&
              (variant['pricing'] as List).first is Map)
          ? Map<String, dynamic>.from((variant['pricing'] as List).first as Map)
          : null;

      final mrp = _toNum(batch?['mrp'] ?? pricing?['mrp']) ?? 0;
      final sellingPrice =
          _toNum(batch?['sellingPrice'] ?? pricing?['sellingPrice']) ??
              minSellingPrice;

      return StoreOrderLine(
        inventoryId: inventoryId,
        productVariantId: variantId ?? '',
        mrp: mrp,
        sellingPrice: sellingPrice,
      );
    }
    return null;
  }

  static num? _toNum(dynamic v) =>
      v is num ? v : (v is String ? num.tryParse(v) : null);
  static int? _toInt(dynamic v) =>
      v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
  static double? _toDouble(dynamic v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
}

/// A minimal order line derived from a [StoreMatch] inventory row — the pieces
/// `POST /orders` needs (guide step 4).
class StoreOrderLine {
  final String inventoryId;
  final String productVariantId;
  final num mrp;
  final num sellingPrice;

  StoreOrderLine({
    required this.inventoryId,
    required this.productVariantId,
    required this.mrp,
    required this.sellingPrice,
  });
}
