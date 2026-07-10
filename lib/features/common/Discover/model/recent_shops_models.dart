/// Models for the `GET /api/orders/recent-shops` endpoint, which exists on the
/// grocery, product and food services with an (almost) identical contract.
/// See docs/backend/RECENT_SHOPS_FLUTTER_INTEGRATION.md.
///
/// Adapted to the app's HTTP layer: [recentShopsPath] is a RELATIVE path (the
/// `be.beapp.in/api/` base + bearer token are added by ApiBaseHelper), unlike
/// the guide's full-URL raw-Dio client.

/// Which selling vertical the recent shops came from.
enum GroceryVertical { grocery, product, food }

extension GroceryVerticalX on GroceryVertical {
  /// Relative endpoint path for this vertical (base URL prepended by Dio).
  String get recentShopsPath {
    switch (this) {
      case GroceryVertical.grocery:
        return 'grocery-service/api/orders/recent-shops';
      case GroceryVertical.product:
        return 'product-service-v2/api/orders/recent-shops';
      case GroceryVertical.food:
        return 'food-service/api/orders/recent-shops';
    }
  }
}

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

double? _toDouble(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));

/// Images come as `["url", ...]` (food) OR `[{url, altText}, ...]` (grocery/product).
List<String> _parseImages(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map<String>((e) {
        if (e is String) return e;
        if (e is Map && e['url'] != null) return e['url'].toString();
        return '';
      })
      .where((s) => s.isNotEmpty)
      .toList();
}

class RecentShopsResponse {
  final int count;
  final int ordersScanned;
  final List<RecentShop> shops;

  const RecentShopsResponse({
    required this.count,
    required this.ordersScanned,
    required this.shops,
  });

  factory RecentShopsResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    return RecentShopsResponse(
      count: (data['count'] as num?)?.toInt() ?? 0,
      ordersScanned: (data['ordersScanned'] as num?)?.toInt() ?? 0,
      shops: ((data['shops'] as List?) ?? const [])
          .map((e) => RecentShop.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class RecentShop {
  /// Which vertical this shop's order came from (set by the client after the
  /// fetch, so the card can route to the right store type on tap).
  final GroceryVertical vertical;
  final String businessId;
  final BusinessSummary? business;
  final int orderCount;
  final int distinctProducts;
  final int totalItems;
  final DateTime? lastOrderedAt;
  final List<RecentShopItem> items;

  const RecentShop({
    required this.vertical,
    required this.businessId,
    required this.business,
    required this.orderCount,
    required this.distinctProducts,
    required this.totalItems,
    required this.lastOrderedAt,
    required this.items,
  });

  String get displayName => business?.businessName ?? 'Shop';

  factory RecentShop.fromJson(
    Map<String, dynamic> json, {
    GroceryVertical vertical = GroceryVertical.grocery,
  }) =>
      RecentShop(
        vertical: vertical,
        businessId: json['businessId']?.toString() ?? '',
        business: json['business'] == null
            ? null
            : BusinessSummary.fromJson(
                Map<String, dynamic>.from(json['business'] as Map)),
        orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
        distinctProducts: (json['distinctProducts'] as num?)?.toInt() ?? 0,
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
        lastOrderedAt: _parseDate(json['lastOrderedAt']),
        items: ((json['items'] as List?) ?? const [])
            .map((e) =>
                RecentShopItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  RecentShop copyWith({GroceryVertical? vertical}) => RecentShop(
        vertical: vertical ?? this.vertical,
        businessId: businessId,
        business: business,
        orderCount: orderCount,
        distinctProducts: distinctProducts,
        totalItems: totalItems,
        lastOrderedAt: lastOrderedAt,
        items: items,
      );
}

class BusinessSummary {
  final String? businessId;
  final String? businessName;
  final String? logo;
  final String? address;
  final String? cityStatePincode;
  final double? lat;
  final double? lon;
  final String? contactNumber; // null on Food
  final bool? isVerified;
  final double? avgRating;

  const BusinessSummary({
    this.businessId,
    this.businessName,
    this.logo,
    this.address,
    this.cityStatePincode,
    this.lat,
    this.lon,
    this.contactNumber,
    this.isVerified,
    this.avgRating,
  });

  factory BusinessSummary.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map?;
    return BusinessSummary(
      businessId: json['businessId']?.toString(),
      businessName: json['businessName']?.toString(),
      logo: json['logo']?.toString(),
      address: json['address']?.toString(),
      cityStatePincode: json['cityStatePincode']?.toString(),
      lat: _toDouble(loc?['lat']),
      lon: _toDouble(loc?['lon']),
      contactNumber: json['contactNumber']?.toString(),
      isVerified: json['isVerified'] as bool?,
      avgRating: _toDouble(json['avgRating']),
    );
  }
}

class RecentShopItem {
  final String productVariantId;
  final String? inventoryId;
  final String productName;
  final String? brand; // grocery/product
  final String variantName;
  final String? unit; // grocery/product
  final String? quantityLabel; // food
  final List<String> images;
  final num mrp;
  final num sellingPrice;
  final int quantity;
  final int timesOrdered;
  final DateTime? lastOrderedAt;

  const RecentShopItem({
    required this.productVariantId,
    required this.inventoryId,
    required this.productName,
    required this.brand,
    required this.variantName,
    required this.unit,
    required this.quantityLabel,
    required this.images,
    required this.mrp,
    required this.sellingPrice,
    required this.quantity,
    required this.timesOrdered,
    required this.lastOrderedAt,
  });

  /// One pack-size label that works across verticals (unit or quantityLabel).
  String? get sizeLabel =>
      (quantityLabel?.isNotEmpty ?? false) ? quantityLabel : unit;

  String? get firstImage => images.isNotEmpty ? images.first : null;

  factory RecentShopItem.fromJson(Map<String, dynamic> json) => RecentShopItem(
        productVariantId: json['productVariantId']?.toString() ?? '',
        inventoryId: json['inventoryId']?.toString(),
        productName: json['productName']?.toString() ?? '',
        brand: json['brand']?.toString(),
        variantName: json['variantName']?.toString() ?? '',
        unit: json['unit']?.toString(),
        quantityLabel: json['quantityLabel']?.toString(),
        images: _parseImages(json['images']),
        mrp: (json['mrp'] as num?) ?? 0,
        sellingPrice: (json['sellingPrice'] as num?) ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        timesOrdered: (json['timesOrdered'] as num?)?.toInt() ?? 1,
        lastOrderedAt: _parseDate(json['lastOrderedAt']),
      );
}
