/// Model for the grocery Search-Order "search-by-product" response — the list
/// of nearby **stores** (grouped by business) that stock a given product.
///
/// See docs/backend/SEARCH_ORDER_FLUTTER_GUIDE.md (step 2). The API returns one
/// entry per business with an aggregate (`matchingVariantCount`,
/// `minSellingPrice`, `totalStock`) plus the raw `inventories` rows. The store
/// profile (name / logo / address / distance) may be populated on the row under
/// a few common aliases, so it is parsed defensively — the card still renders a
/// sensible fallback when a field is absent.
///
/// The top-level rollups are **not** dependable: the backend has been seen to
/// stop populating them (the sibling business-products response hit the same
/// thing — see the note in grocery_business_products_model.dart). So
/// [minSellingPrice] and [totalStock] fall back to figures derived from the
/// `inventories` rows, and an absent stock rollup stays `null` (unknown) rather
/// than collapsing to `0`, which would read as "out of stock".
class StoreMatch {
  final String businessId;
  final int matchingVariantCount;

  /// Rollups exactly as sent — null when the backend omitted them. Prefer the
  /// derived [minSellingPrice] / [totalStock] for display.
  final num? reportedMinSellingPrice;
  final int? reportedTotalStock;

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
    required this.inventories,
    this.reportedMinSellingPrice,
    this.reportedTotalStock,
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
      reportedMinSellingPrice: _toNum(j['minSellingPrice']),
      reportedTotalStock:
          _toInt(j['totalStock'] ?? j['stock'] ?? j['availableStock']),
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

  /// Every pack/size this store stocks for the product, parsed from the raw
  /// [inventories] rows — the real source of the grocery pack size (500 g,
  /// 1 kg) and the per-pack price/stock.
  late final List<StoreVariantOption> variantOptions = inventories
      .whereType<Map>()
      .map((e) => StoreVariantOption.fromInventoryRow(
            Map<String, dynamic>.from(e),
            // Deliberately the *reported* rollup, not the derived one: the
            // derived price comes from these very rows.
            fallbackSellingPrice: reportedMinSellingPrice ?? 0,
          ))
      .whereType<StoreVariantOption>()
      .toList();

  /// Cheapest price this store charges — the rollup when the backend sent one,
  /// else the cheapest of its own inventory rows. 0 when nothing priced it.
  late final num minSellingPrice = reportedMinSellingPrice ?? _derivedMinPrice;

  num get _derivedMinPrice {
    num? cheapest;
    for (final option in variantOptions) {
      final price = option.sellingPrice;
      if (price <= 0) continue;
      if (cheapest == null || price < cheapest) cheapest = price;
    }
    return cheapest ?? 0;
  }

  /// Units this store holds — the rollup when sent, else summed from its rows.
  /// **Null means unknown**, which is not the same as zero: callers must not
  /// render "out of stock" for it.
  late final int? totalStock = reportedTotalStock ?? _derivedStock;

  int? get _derivedStock {
    var sum = 0;
    var found = false;
    for (final option in variantOptions) {
      final stock = option.stock;
      if (stock == null) continue;
      sum += stock;
      found = true;
    }
    return found ? sum : null;
  }

  /// Tri-state availability: true/false when something reported a figure, null
  /// when nothing did.
  bool? get inStock => totalStock == null ? null : totalStock! > 0;

  /// The option for [variantId], or the store's first option when [variantId]
  /// is null/blank. Null when this store doesn't stock that variant at all.
  StoreVariantOption? optionFor(String? variantId) {
    if (variantId == null || variantId.isEmpty) {
      return variantOptions.isEmpty ? null : variantOptions.first;
    }
    for (final o in variantOptions) {
      if (o.variantId == variantId) return o;
    }
    return null;
  }

  /// True when this store carries the given pack — drives the store list
  /// filtering once the user picks a size.
  bool stocksVariant(String variantId) =>
      variantOptions.any((o) => o.variantId == variantId);

  /// An orderable line for [variantId] (guide step 4) — inventoryId +
  /// productVariantId + pricing, so a cart line can be built from a tapped
  /// store without a second fetch. Null when no usable line exists.
  StoreOrderLine? orderLineFor(String? variantId) {
    final option = optionFor(variantId);
    if (option == null) return null;
    return StoreOrderLine(
      inventoryId: option.inventoryId,
      productVariantId: option.variantId,
      mrp: option.mrp ?? 0,
      sellingPrice: option.sellingPrice,
    );
  }

  /// The first orderable inventory line for this store.
  StoreOrderLine? get firstOrderableLine => orderLineFor(null);

  static num? _toNum(dynamic v) =>
      v is num ? v : (v is String ? num.tryParse(v) : null);
  static int? _toInt(dynamic v) =>
      v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
  static double? _toDouble(dynamic v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
}

/// One pack/size a store stocks for the product — a single `inventories[]` row
/// of search-by-product, flattened.
///
/// The populated `productVariant` carries the grocery pack size as a
/// `quantity` + `unit` pair (`"500"` + `"g"`), which [packLabel] renders as
/// "500 g". Stock comes from the row's aggregate when present, else from the
/// sum of its batch quantities. Everything is parsed defensively and stays
/// null when the API doesn't send it, so the UI can hide what it doesn't know.
class StoreVariantOption {
  final String inventoryId;
  final String variantId;
  final String? variantName;

  /// Unit of measure, verbatim from the API (`g`, `kg`, `ml`, `l`, `piece`…).
  final String? unit;

  /// Pack size amount, verbatim from the API (`500`, `1`).
  final String? quantity;

  final num? mrp;
  final num sellingPrice;

  /// Units on hand for this pack. Null when the row carries no stock figure at
  /// all — unknown is not the same as zero, so the UI stays quiet instead of
  /// claiming "out of stock".
  final int? stock;

  final bool? isVegetarian;

  StoreVariantOption({
    required this.inventoryId,
    required this.variantId,
    required this.sellingPrice,
    this.variantName,
    this.unit,
    this.quantity,
    this.mrp,
    this.stock,
    this.isVegetarian,
  });

  /// Human pack label — "500 g" / "1 kg", falling back to the variant name.
  /// Null when the variant carries no size information at all.
  String? get packLabel {
    final q = quantity?.trim() ?? '';
    final u = unit?.trim() ?? '';
    if (q.isNotEmpty && u.isNotEmpty) return '$q $u';
    if (q.isNotEmpty) return q;
    if (u.isNotEmpty) return u;
    final n = variantName?.trim() ?? '';
    return n.isNotEmpty ? n : null;
  }

  /// Tri-state stock: true/false when the API reported a figure, null when it
  /// didn't.
  bool? get inStock => stock == null ? null : stock! > 0;

  /// Discount % against the MRP — only when a genuine MRP above the selling
  /// price is present.
  int? get discountPercent {
    final m = mrp;
    if (m == null || m <= sellingPrice || m <= 0) return null;
    return (((m - sellingPrice) / m) * 100).round();
  }

  static StoreVariantOption? fromInventoryRow(
    Map<String, dynamic> inv, {
    required num fallbackSellingPrice,
  }) {
    final inventoryId = (inv['inventoryId'] ?? inv['_id'])?.toString();
    if (inventoryId == null || inventoryId.isEmpty) return null;

    final rawVariant = inv['productVariant'];
    final variant = rawVariant is Map
        ? Map<String, dynamic>.from(rawVariant)
        : const <String, dynamic>{};
    // Populated object → its _id; unpopulated → the id string itself.
    final variantId = (variant['_id'] ??
                variant['id'] ??
                (rawVariant is String ? rawVariant : null))
            ?.toString() ??
        '';

    final batches = inv['batches'];
    final batch =
        (batches is List && batches.isNotEmpty && batches.first is Map)
            ? Map<String, dynamic>.from(batches.first as Map)
            : null;
    final pricingList = variant['pricing'];
    final pricing = (pricingList is List &&
            pricingList.isNotEmpty &&
            pricingList.first is Map)
        ? Map<String, dynamic>.from(pricingList.first as Map)
        : null;

    return StoreVariantOption(
      inventoryId: inventoryId,
      variantId: variantId,
      // `variant['quantity']` is the pack size; batch `quantity` is stock.
      variantName: variant['variantName']?.toString(),
      unit: variant['unit']?.toString(),
      quantity: variant['quantity']?.toString(),
      mrp: StoreMatch._toNum(batch?['mrp'] ?? pricing?['mrp']),
      sellingPrice:
          StoreMatch._toNum(batch?['sellingPrice'] ?? pricing?['sellingPrice']) ??
              fallbackSellingPrice,
      stock: _stockOf(inv),
      isVegetarian: variant['isVegetarian'] as bool?,
    );
  }

  /// Units on hand for an inventory row: the explicit flag/aggregate when the
  /// API sends one, else the sum of batch quantities, else null (unknown).
  static int? _stockOf(Map<String, dynamic> inv) {
    if (inv['isOutOfStock'] == true) return 0;
    final direct = StoreMatch._toInt(
        inv['totalStock'] ?? inv['stock'] ?? inv['availableStock']);
    if (direct != null) return direct;

    final batches = inv['batches'];
    if (batches is List) {
      var sum = 0;
      var found = false;
      for (final b in batches) {
        if (b is! Map) continue;
        final q = StoreMatch._toInt(b['quantity'] ?? b['availableQuantity']);
        if (q != null) {
          sum += q;
          found = true;
        }
      }
      if (found) return sum;
    }
    return null;
  }
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
