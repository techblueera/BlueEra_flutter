/// Parses the inventory-based product search response.
///
/// The API returns a list of `Product` objects, each with an embedded
/// `variants` array. We fan each variant out into a [VariantData] row so
/// the UI can render one card per variant while still showing parent
/// product metadata (name, description, brand, media, etc.).
///
/// Expected shape (abridged):
/// ```
/// {
///   "data": [
///     { "_id", "name", "currencySymbol", "images": [{"url"}],
///       "variants": [
///         { "_id", "variantName", "attributes",
///           "pricing": [{"mrp", "sellingPrice", "currency"}],
///           "images": [{"url"}], "quantity", "isActive" }
///       ] }
///   ],
///   "pagination": {...}
/// }
/// ```
class InventoryBasedSearchProductResponse {
  final List<VariantData> data;

  InventoryBasedSearchProductResponse({required this.data});

  factory InventoryBasedSearchProductResponse.fromJson(
      Map<String, dynamic> json) {
    final rawData = (json['data'] as List<dynamic>?) ?? const [];
    final flattened = <VariantData>[];
    for (final raw in rawData) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final productInfo = ProductInformation.fromJson(item);
      final variants = (item['variants'] as List<dynamic>?) ?? const [];
      if (variants.isEmpty) {
        flattened.add(VariantData(
          productInformation: productInfo,
          finalVariant: FinalVariant.fromJson(const <String, dynamic>{}),
        ));
        continue;
      }
      for (final v in variants) {
        if (v is! Map) continue;
        flattened.add(VariantData(
          productInformation: productInfo,
          finalVariant: FinalVariant.fromJson(Map<String, dynamic>.from(v)),
        ));
      }
    }
    return InventoryBasedSearchProductResponse(data: flattened);
  }
}

class VariantData {
  final ProductInformation productInformation;
  final FinalVariant finalVariant;

  VariantData({
    required this.productInformation,
    required this.finalVariant,
  });
}

class ProductInformation {
  final String id;
  final String name;
  final String type;
  final String symbol;
  final String description;
  final String brand;
  final String categoryId;
  final List<String> media;
  final List<String> videoUrl;
  final List<String> tags;
  final List<String> guideLine;
  final String productWarrenty;
  final double mrpPerUnit;
  final bool isReturnable;
  final int returningDay;
  final bool isPublished;
  final bool isActive;
  final String approvalStatus;
  final bool addedByAdmin;
  final String createdAt;
  final String updatedAt;
  final DateInfo? expiryTime;
  final List<AddMoreDetail> addMoreDetails;
  final List<ProductFeature> addProductFeatures;
  /// Sibling variants for this product. Used by the snap-search preview
  /// card to derive the unique attribute keys across all variants. The
  /// fanned-out [VariantData] rows in
  /// [InventoryBasedSearchProductResponse.data] each get a reference to
  /// this same list.
  final List<ProductVariant> variants;

  ProductInformation({
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.description,
    required this.brand,
    required this.categoryId,
    required this.media,
    required this.videoUrl,
    required this.tags,
    required this.guideLine,
    required this.productWarrenty,
    required this.mrpPerUnit,
    required this.isReturnable,
    required this.returningDay,
    required this.isPublished,
    required this.isActive,
    required this.approvalStatus,
    required this.addedByAdmin,
    required this.createdAt,
    required this.updatedAt,
    required this.expiryTime,
    required this.addMoreDetails,
    required this.addProductFeatures,
    required this.variants,
  });

  factory ProductInformation.fromJson(Map<String, dynamic> json) {
    final returnDaysRaw = json['returnDays'];
    final additionalDetailsRaw =
        (json['additionalDetails'] as List<dynamic>?) ?? const [];
    final featuresRaw = (json['features'] as List<dynamic>?) ?? const [];
    final variantsRaw = (json['variants'] as List<dynamic>?) ?? const [];
    return ProductInformation(
      id: (json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      symbol: json['currencySymbol'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      categoryId: (json['category'] ?? '').toString(),
      media: _extractMediaUrls(json['images']),
      videoUrl: _extractMediaUrls(json['videos']),
      tags: List<String>.from(json['tags'] ?? const []),
      guideLine: List<String>.from(json['guidelines'] ?? const []),
      productWarrenty: (json['productWarrenty'] ?? '').toString(),
      mrpPerUnit: (json['mrpPerUnit'] ?? 0).toDouble(),
      isReturnable: json['isReturnable'] ?? false,
      returningDay: returnDaysRaw is int
          ? returnDaysRaw
          : int.tryParse('${returnDaysRaw ?? 0}') ?? 0,
      isPublished: json['isPublished'] ?? false,
      isActive: json['isActive'] ?? true,
      approvalStatus: json['approvalStatus'] ?? '',
      addedByAdmin: json['addedByAdmin'] ?? false,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      expiryTime: json['expiryTime'] is Map
          ? DateInfo.fromJson(Map<String, dynamic>.from(json['expiryTime']))
          : null,
      addMoreDetails: additionalDetailsRaw
          .whereType<Map>()
          .map((e) => AddMoreDetail.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      addProductFeatures: featuresRaw
          .whereType<Map>()
          .map((e) => ProductFeature.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      variants: variantsRaw
          .whereType<Map>()
          .map((e) => ProductVariant.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Lightweight sibling-variant view used only for the snap-search
/// preview card. The fully-parsed variant (with pricing, images, sku,
/// etc.) lives on [VariantData.finalVariant] — this class just exposes
/// `attributes` so the preview can build a swatch list across variants.
class ProductVariant {
  final String id;
  final Map<String, dynamic> attributes;

  ProductVariant({required this.id, required this.attributes});

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: (json['_id'] ?? '').toString(),
      attributes: Map<String, dynamic>.from(json['attributes'] ?? const {}),
    );
  }
}

class FinalVariant {
  final String id;
  final String variantName;
  final String value;
  final String sku;
  final String hsn;
  final String unit;
  /// Free-form size/quantity string from the API (e.g. "0.15oz",
  /// "2 oz Tin"). Used by the publish payload to match grocery's
  /// `batches[].quantity` field.
  final String quantity;
  final Map<String, dynamic> attributes;
  final double mrp;
  final double sellingPrice;
  final String currency;
  final List<String> mediaRelatedToVarient;
  final bool varientIsActive;
  final String createdAt;
  final String updatedAt;

  /// `stock` isn't in the new variant payload — `isActive` is the
  /// in-stock proxy that merchants see in the UI.
  bool get stock => varientIsActive;

  FinalVariant({
    required this.id,
    required this.variantName,
    required this.value,
    required this.sku,
    required this.hsn,
    required this.unit,
    required this.quantity,
    required this.attributes,
    required this.mrp,
    required this.sellingPrice,
    required this.currency,
    required this.mediaRelatedToVarient,
    required this.varientIsActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FinalVariant.fromJson(Map<String, dynamic> json) {
    final pricingList = (json['pricing'] as List<dynamic>?) ?? const [];
    final firstPricing = pricingList.isNotEmpty && pricingList.first is Map
        ? Map<String, dynamic>.from(pricingList.first as Map)
        : const <String, dynamic>{};
    return FinalVariant(
      id: (json['_id'] ?? '').toString(),
      variantName: json['variantName'] ?? '',
      value: (json['value'] ?? '').toString(),
      sku: json['sku'] ?? '',
      hsn: json['hsn'] ?? '',
      unit: json['unit'] ?? '',
      quantity: (json['quantity'] ?? json['variantName'] ?? '').toString(),
      attributes: Map<String, dynamic>.from(json['attributes'] ?? const {}),
      mrp: (firstPricing['mrp'] ?? 0).toDouble(),
      sellingPrice: (firstPricing['sellingPrice'] ?? 0).toDouble(),
      currency: (firstPricing['currency'] ?? 'INR').toString(),
      mediaRelatedToVarient: _extractMediaUrls(json['images']),
      varientIsActive: json['isActive'] ?? true,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class DateInfo {
  final int date;
  final int month;
  final int year;
  final int week;
  final bool lifetime;

  DateInfo({
    required this.date,
    required this.month,
    required this.year,
    this.week = 0,
    this.lifetime = false,
  });

  factory DateInfo.fromJson(Map<String, dynamic> json) {
    return DateInfo(
      date: json['date'] ?? 0,
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      week: json['week'] ?? 0,
      lifetime: json['lifetime'] ?? false,
    );
  }
}

class AddMoreDetail {
  final String title;
  final String details;
  final String id;

  AddMoreDetail({
    required this.title,
    required this.details,
    required this.id,
  });

  factory AddMoreDetail.fromJson(Map<String, dynamic> json) {
    return AddMoreDetail(
      title: json['title'] ?? '',
      details: json['details'] ?? '',
      id: (json['_id'] ?? '').toString(),
    );
  }
}

class ProductFeature {
  final String title;
  final String id;

  ProductFeature({required this.title, required this.id});

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      title: json['title'] ?? '',
      id: (json['_id'] ?? '').toString(),
    );
  }
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
