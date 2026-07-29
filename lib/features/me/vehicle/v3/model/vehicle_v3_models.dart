/// Models for the rebuilt vehicle service (v3).
///
/// See docs/backend/FRONTEND_INTEGRATION_GUIDE.md. The catalog is read-only
/// master data in four tiers, and a seller only ever creates the last one:
///
/// ```
/// Category L0 "4 Wheeler" → Category L1 "Maruti Suzuki" (BRAND)
///   → Category L2 "Swift" (MODEL, leaf) → Product "Swift VXi" (TRIM)
///     → ProductVariant "Pearl Arctic White" (COLOUR)
///       → Inventory (seller, USED, 42k km, ₹5.2L)  ← the listing
/// ```
library;

/// Envelope helpers.
///
/// §8 of the guide is blunt that response shapes are not uniform across the
/// service — `{data, pagination}`, `{data}`, a bare array and a bare object
/// are all in play depending on the endpoint. Rather than teach every call
/// site which one it gets, both helpers accept the raw body and dig out the
/// payload wherever it happens to be.
class VehicleV3Envelope {
  const VehicleV3Envelope._();

  /// The list payload of [body], or `[]` when there isn't one. Handles a bare
  /// array, `{data: [...]}`, and the `{data: {docs|items|results: [...]}}`
  /// nesting some paginated readers use.
  static List<dynamic> list(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      final data = body['data'];
      if (data is List) return data;
      if (data is Map) {
        for (final key in const ['docs', 'items', 'results', 'data']) {
          final nested = data[key];
          if (nested is List) return nested;
        }
      }
      for (final key in const ['categories', 'products', 'inventory', 'bookings']) {
        final nested = body[key];
        if (nested is List) return nested;
      }
    }
    return const [];
  }

  /// The single-object payload of [body], or null. A bare object is returned
  /// as-is; `{data: {...}}` is unwrapped.
  static Map<String, dynamic>? object(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      // A write returns `{ message, data }`; a bare object has no `data` at
      // all, in which case the body itself is the payload.
      if (data == null && body.isNotEmpty) {
        return Map<String, dynamic>.from(body);
      }
    }
    return null;
  }

  /// Error text out of either error envelope (`{message}` /
  /// `{status:false, message}`), or null when the body carries none.
  static String? errorMessage(dynamic body) {
    if (body is Map) {
      final message = body['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    return null;
  }
}

/// `{ total, page, limit, totalPages }` — present on product search and every
/// listing list. Absent elsewhere, hence the all-defaults constructor.
class VehiclePaginationV3 {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const VehiclePaginationV3({
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  bool get hasMore => page < totalPages;

  factory VehiclePaginationV3.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VehiclePaginationV3();
    return VehiclePaginationV3(
      total: _int(json['total']) ?? 0,
      page: _int(json['page']) ?? 1,
      limit: _int(json['limit']) ?? 20,
      totalPages: _int(json['totalPages']) ?? 1,
    );
  }

  /// Reads pagination off a raw response body, wherever it sits.
  static VehiclePaginationV3 of(dynamic body) {
    if (body is Map && body['pagination'] is Map) {
      return VehiclePaginationV3.fromJson(
          Map<String, dynamic>.from(body['pagination'] as Map));
    }
    return const VehiclePaginationV3();
  }
}

/// One node of the catalog tree — a type (level 0), a brand (level 1) or a
/// model (level 2, the leaf). The same shape at every level, which is what
/// lets one picker screen walk all three.
class VehicleCategoryV3 {
  final String id;
  final String name;

  /// Globally unique, uppercase (`4W`, `BRAND_MARUTI_SUZUKI`). Stable enough
  /// to hardcode against — unlike [id].
  final String key;
  final String image;

  /// Server-derived. Null on payloads that omit it (some `/children` reads).
  final int? level;
  final String? parentId;

  /// Populated only by the `/nested` reads; empty on the flat ones.
  final List<VehicleCategoryV3> children;

  const VehicleCategoryV3({
    required this.id,
    required this.name,
    this.key = '',
    this.image = '',
    this.level,
    this.parentId,
    this.children = const [],
  });

  /// True when this node can hold trims — i.e. it is a model. Falls back to
  /// "has no children" for payloads that don't carry `level`.
  bool get isLeaf => level == 2 || (level == null && children.isEmpty);

  factory VehicleCategoryV3.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    return VehicleCategoryV3(
      id: _str(json['_id'] ?? json['id']),
      name: _str(json['name']),
      key: _str(json['key']),
      image: _str(json['image'] ?? json['image_url']),
      level: _int(json['level']),
      parentId: _strOrNull(json['parentId'] ?? json['parent_id']),
      children: rawChildren is List
          ? rawChildren
              .whereType<Map>()
              .map((c) => VehicleCategoryV3.fromJson(
                  Map<String, dynamic>.from(c)))
              .toList()
          : const [],
    );
  }

  static List<VehicleCategoryV3> listFrom(dynamic body) =>
      VehicleV3Envelope.list(body)
          .whereType<Map>()
          .map((e) => VehicleCategoryV3.fromJson(Map<String, dynamic>.from(e)))
          .toList();
}

/// A colour of a trim — **the id a listing is created against**. There is no
/// listing without one, which is why the add flow cannot stop at a trim.
class VehicleColorVariantV3 {
  final String id;
  final String colorName;
  final String colorHex;
  final List<String> images;

  const VehicleColorVariantV3({
    required this.id,
    this.colorName = '',
    this.colorHex = '',
    this.images = const [],
  });

  String? get firstImage => images.isEmpty ? null : images.first;

  factory VehicleColorVariantV3.fromJson(Map<String, dynamic> json) =>
      VehicleColorVariantV3(
        id: _str(json['_id'] ?? json['id']),
        colorName: _str(json['colorName'] ?? json['color_name']),
        colorHex: _str(json['colorHex'] ?? json['color_hex']),
        images: _imageUrls(json['images']),
      );
}

/// A trim — "Maruti Swift VXi". Carries the specs the add form pre-fills from
/// (there is no separate prefill endpoint any more) and, when read through
/// `GET /products/:id`, its colours.
class VehicleTrimV3 {
  final String id;
  final String name;
  final String brand;
  final String model;
  final num? exShowroomPrice;
  final String fuelType;
  final String transmission;
  final List<String> images;
  final List<VehicleColorVariantV3> variants;

  /// Buyer-search rollups — only present on `/products/user/search` rows.
  final int? listingCount;
  final num? priceFrom;

  const VehicleTrimV3({
    required this.id,
    required this.name,
    this.brand = '',
    this.model = '',
    this.exShowroomPrice,
    this.fuelType = '',
    this.transmission = '',
    this.images = const [],
    this.variants = const [],
    this.listingCount,
    this.priceFrom,
  });

  String? get firstImage {
    if (images.isNotEmpty) return images.first;
    for (final variant in variants) {
      final image = variant.firstImage;
      if (image != null) return image;
    }
    return null;
  }

  factory VehicleTrimV3.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'];
    return VehicleTrimV3(
      id: _str(json['_id'] ?? json['id']),
      name: _str(json['name']),
      // These arrive either as a plain string or as a populated category
      // object depending on the endpoint.
      brand: _nameOf(json['brand']),
      model: _nameOf(json['model']),
      exShowroomPrice: _num(json['ex_showroom_price']),
      fuelType: _str(json['fuel_type']),
      transmission: _str(json['transmission']),
      images: _imageUrls(json['images']),
      variants: rawVariants is List
          ? rawVariants
              .whereType<Map>()
              .map((v) => VehicleColorVariantV3.fromJson(
                  Map<String, dynamic>.from(v)))
              .toList()
          : const [],
      listingCount: _int(json['listingCount']),
      priceFrom: _num(json['priceFrom']),
    );
  }

  static List<VehicleTrimV3> listFrom(dynamic body) =>
      VehicleV3Envelope.list(body)
          .whereType<Map>()
          .map((e) => VehicleTrimV3.fromJson(Map<String, dynamic>.from(e)))
          .toList();
}

/// A seller's listing. The only tier the app ever creates.
///
/// Reads come back enriched with the joined catalog (`variant`, `product`,
/// `modelCategory`) and, best-effort, the seller — the guide is explicit that
/// `seller`/`sellerBusiness` may be null when the user service is briefly
/// unavailable, so nothing here treats that as an error.
class VehicleListingV3 {
  final String id;
  final String condition; // NEW | USED
  final bool isActive;
  final bool isVerified;

  /// The server's resolved "price to show" (NEW on-road → USED asking →
  /// generic). Preferred over computing one client-side so every surface
  /// agrees.
  final num? displayPrice;

  // Seller-supplied, USED.
  final int? kmDriven;
  final String ownership;
  final int? registrationYear;
  final String conditionGrade;
  final num? expectedPrice;
  final bool? isNegotiable;
  final String insuranceValidTill;
  final bool? rcAvailable;
  final String serviceHistory;
  final String description;

  // Seller-supplied, NEW.
  final num? onRoadPrice;
  final String availability;
  final String deliveryTime;
  final bool? emiAvailable;
  final String specialOffers;

  // Where it is.
  final String city;
  final String state;
  final String address;
  final String pincode;

  final List<String> images;
  final String coverImage;

  /// Joined catalog — what to render the card from.
  final VehicleColorVariantV3? variant;
  final VehicleTrimV3? product;
  final VehicleCategoryV3? modelCategory;

  const VehicleListingV3({
    required this.id,
    required this.condition,
    this.isActive = true,
    this.isVerified = false,
    this.displayPrice,
    this.kmDriven,
    this.ownership = '',
    this.registrationYear,
    this.conditionGrade = '',
    this.expectedPrice,
    this.isNegotiable,
    this.insuranceValidTill = '',
    this.rcAvailable,
    this.serviceHistory = '',
    this.description = '',
    this.onRoadPrice,
    this.availability = '',
    this.deliveryTime = '',
    this.emiAvailable,
    this.specialOffers = '',
    this.city = '',
    this.state = '',
    this.address = '',
    this.pincode = '',
    this.images = const [],
    this.coverImage = '',
    this.variant,
    this.product,
    this.modelCategory,
  });

  bool get isNew => condition.toUpperCase() == 'NEW';

  /// Title for a card: the trim, falling back to the model category.
  String get title {
    final trim = product?.name ?? '';
    if (trim.isNotEmpty) return trim;
    return modelCategory?.name ?? '';
  }

  String get colourLabel => variant?.colorName ?? '';

  /// Cover first, then the seller's own photos, then the catalog artwork —
  /// which is the whole display difference between NEW and USED: a NEW
  /// listing carries no seller photos and shows the catalog's.
  String? get thumbnail {
    if (coverImage.isNotEmpty) return coverImage;
    if (images.isNotEmpty) return images.first;
    return variant?.firstImage ?? product?.firstImage;
  }

  factory VehicleListingV3.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? nested(dynamic value) =>
        value is Map ? Map<String, dynamic>.from(value) : null;

    final variantJson = nested(json['variant'] ?? json['productVariant']);
    final productJson = nested(json['product']);
    final modelJson = nested(json['modelCategory']);

    return VehicleListingV3(
      id: _str(json['_id'] ?? json['id']),
      condition: _str(json['condition']).toUpperCase(),
      isActive: _bool(json['is_active']) ?? true,
      isVerified: _bool(json['is_verified']) ?? false,
      displayPrice: _num(json['display_price']),
      kmDriven: _int(json['km_driven']),
      ownership: _str(json['ownership']),
      registrationYear: _int(json['registration_year']),
      conditionGrade: _str(json['condition_grade']),
      expectedPrice: _num(json['expected_price']),
      isNegotiable: _bool(json['is_negotiable']),
      insuranceValidTill: _str(json['insurance_valid_till']),
      rcAvailable: _bool(json['rc_available']),
      serviceHistory: _str(json['service_history']),
      description: _str(json['description']),
      onRoadPrice: _num(json['on_road_price']),
      availability: _str(json['availability']),
      deliveryTime: _str(json['delivery_time']),
      emiAvailable: _bool(json['emi_available']),
      specialOffers: _str(json['special_offers']),
      city: _str(json['city']),
      state: _str(json['state']),
      address: _str(json['address']),
      pincode: _str(json['pincode']),
      images: _imageUrls(json['images']),
      coverImage: _imageUrl(json['cover_image']) ?? '',
      variant: variantJson == null
          ? null
          : VehicleColorVariantV3.fromJson(variantJson),
      product: productJson == null ? null : VehicleTrimV3.fromJson(productJson),
      modelCategory:
          modelJson == null ? null : VehicleCategoryV3.fromJson(modelJson),
    );
  }

  static List<VehicleListingV3> listFrom(dynamic body) =>
      VehicleV3Envelope.list(body)
          .whereType<Map>()
          .map((e) => VehicleListingV3.fromJson(Map<String, dynamic>.from(e)))
          .toList();
}

/// One "Quick Upload" rail on the add screen: a root category and the trims
/// under it, from `GET /products/by-root-category`.
///
/// The vehicle analogue of grocery's `GroceryRootCategorySection`, and parsed
/// just as defensively — the endpoint may answer with `data` as a **map keyed
/// by category key** (grocery's shape) or as a plain list of sections, so both
/// are accepted rather than guessing.
class VehicleRootCategorySectionV3 {
  final VehicleCategoryV3? category;
  final int productCount;
  final List<VehicleTrimV3> trims;

  const VehicleRootCategorySectionV3({
    this.category,
    this.productCount = 0,
    this.trims = const [],
  });

  String get name => category?.name ?? '';
  String get key => category?.key ?? '';
  String get image => category?.image ?? '';
  String get id => category?.id ?? '';

  factory VehicleRootCategorySectionV3.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    // `products` is the documented key; `trims` accepted in case the service
    // names it after the tier rather than the collection.
    final rawTrims = json['products'] ?? json['trims'];
    return VehicleRootCategorySectionV3(
      category: rawCategory is Map
          ? VehicleCategoryV3.fromJson(Map<String, dynamic>.from(rawCategory))
          : null,
      productCount: _int(json['productCount'] ?? json['totalProductCount']) ?? 0,
      trims: rawTrims is List
          ? rawTrims
              .whereType<Map>()
              .map((e) => VehicleTrimV3.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  /// Sections from a raw response body, whichever of the two shapes it uses.
  static List<VehicleRootCategorySectionV3> listFrom(dynamic body) {
    final data = body is Map ? body['data'] : body;

    // Map keyed by category key → one section per entry (insertion order is
    // preserved, so the server's ordering survives).
    if (data is Map) {
      final sections = <VehicleRootCategorySectionV3>[];
      data.forEach((_, value) {
        if (value is Map) {
          sections.add(VehicleRootCategorySectionV3.fromJson(
              Map<String, dynamic>.from(value)));
        }
      });
      return sections;
    }

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => VehicleRootCategorySectionV3.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}

/// `GET /inventory/summary` — the counters behind the listings-tab header.
class VehicleListingSummaryV3 {
  final int total;
  final int active;
  final int inactive;
  final int verified;
  final int newCount;
  final int usedCount;

  const VehicleListingSummaryV3({
    this.total = 0,
    this.active = 0,
    this.inactive = 0,
    this.verified = 0,
    this.newCount = 0,
    this.usedCount = 0,
  });

  factory VehicleListingSummaryV3.fromJson(Map<String, dynamic> json) =>
      VehicleListingSummaryV3(
        total: _int(json['total']) ?? 0,
        active: _int(json['active']) ?? 0,
        inactive: _int(json['inactive']) ?? 0,
        verified: _int(json['verified']) ?? 0,
        newCount: _int(json['newCount']) ?? 0,
        usedCount: _int(json['usedCount']) ?? 0,
      );
}

// ───── Parsing helpers ──────────────────────────────────────────────
//
// Every field goes through one of these. The service returns numbers as
// strings on some paths and numbers on others, and §8 warns that a gateway
// 502 can put an HTML body in front of the parser, so nothing here assumes a
// type it hasn't checked.

String _str(dynamic value) => value == null ? '' : value.toString().trim();

String? _strOrNull(dynamic value) {
  final s = _str(value);
  return s.isEmpty ? null : s;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

num? _num(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

bool? _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
  }
  return null;
}

/// One image, whether it arrived as `"https://…"` or `{url: "https://…"}`.
String? _imageUrl(dynamic value) {
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  if (value is Map) {
    final url = _str(value['url'] ?? value['image'] ?? value['secure_url']);
    return url.isEmpty ? null : url;
  }
  return null;
}

/// An image array in either of the two shapes above.
List<String> _imageUrls(dynamic value) {
  if (value is! List) return const [];
  return value
      .map(_imageUrl)
      .whereType<String>()
      .toList(growable: false);
}

/// `brand` / `model` come through as a plain string on some endpoints and a
/// populated category object on others.
String _nameOf(dynamic value) {
  if (value is Map) return _str(value['name']);
  return _str(value);
}
