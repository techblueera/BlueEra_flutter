import 'dart:convert';

class GetProductModel {
  final bool status;
  final String message;
  final List<GetProductData> data;

  GetProductModel({
    required this.status,
    required this.message,
    required this.data,
  });

  /// Handles two response shapes:
  ///
  /// 1. Legacy flat: `{ data: [{ product: {...} }, ...] }` — one entry
  ///    per product, used by older endpoints (channel, discover, store).
  /// 2. New category-grouped: `{ data: [{ category: { ..., products:
  ///    [{ ..., variants: [...] }] } }, ...] }` — returned by the
  ///    refreshed `fetchProductsRepo` API. We flatten this into one
  ///    [GetProductData] per product so the rest of the app (top-selling
  ///    shelf, cart screens, etc.) keeps consuming a flat list.
  factory GetProductModel.fromJson(Map<String, dynamic> json) {
    final rawData = (json['data'] as List<dynamic>? ?? const []);
    final flattened = <GetProductData>[];
    for (final entry in rawData) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      if (map['category'] is Map) {
        final cat = Map<String, dynamic>.from(map['category'] as Map);
        final products =
            (cat['products'] as List<dynamic>? ?? const <dynamic>[]);
        for (final p in products) {
          if (p is! Map) continue;
          flattened.add(GetProductData.fromCategoryProduct(
            category: cat,
            product: Map<String, dynamic>.from(p),
          ));
        }
      } else {
        flattened.add(GetProductData.fromJson(map));
      }
    }
    return GetProductModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: flattened,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class GetProductData {
  final ProductStore product;

  GetProductData({required this.product});

  factory GetProductData.fromJson(Map<String, dynamic> json) {
    return GetProductData(
      product: ProductStore.fromJson(json['product'] ?? {}),
    );
  }

  /// Constructs a [GetProductData] from one product entry inside the
  /// new category-grouped API response. We synthesize a legacy-shaped
  /// envelope so the existing [ProductStore]/[ProductDetails]/[Variant]
  /// factories can parse it without per-field dual-mode forks.
  factory GetProductData.fromCategoryProduct({
    required Map<String, dynamic> category,
    required Map<String, dynamic> product,
  }) {
    final variantsRaw = (product['variants'] as List<dynamic>? ?? const []);
    final synthesizedVariants = <Map<String, dynamic>>[];
    String? businessId;
    for (final v in variantsRaw) {
      if (v is! Map) continue;
      final variant = Map<String, dynamic>.from(v);
      final pricing = (variant['pricing'] as List<dynamic>? ?? const []);
      final firstPricing = pricing.isNotEmpty && pricing.first is Map
          ? Map<String, dynamic>.from(pricing.first as Map)
          : const <String, dynamic>{};
      final inventory = variant['inventory'] is Map
          ? Map<String, dynamic>.from(variant['inventory'] as Map)
          : const <String, dynamic>{};
      businessId ??= inventory['businessId']?.toString();
      synthesizedVariants.add({
        '_id': variant['_id'] ?? '',
        // The inventory record's own id — the one the inventory-update
        // endpoint (`PUT /inventory/{id}`) expects, distinct from the
        // variant `_id`.
        'inventory_id': inventory['_id'] ?? inventory['inventoryId'] ?? '',
        'attributes': variant['attributes'] ?? const <String, dynamic>{},
        'stock': inventory['isOutOfStock'] != true,
        'sellingPrice': firstPricing['sellingPrice'] ?? 0,
        'mrp': firstPricing['mrp'] ?? 0,
        'media_related_to_varient': _extractMediaUrls(variant['images']),
        'varientIsActive': variant['isActive'] ?? true,
      });
    }

    final synth = <String, dynamic>{
      'business_id': businessId ?? '',
      'category': category['_id'] ?? '',
      'details': {
        '_id': product['_id'] ?? '',
        'name': product['name'] ?? '',
        'description': product['description'] ?? '',
        'brand': product['brand'] ?? '',
        'media': _extractMediaUrls(product['images']),
        'video_url': _extractMediaUrls(product['videos']),
        'tags': const <String>[],
        'add_more_details': const <dynamic>[],
        'add_product_features': const <dynamic>[],
        'type': product['type'] ?? '',
        'symbol': product['currencySymbol'] ?? '',
        'product_warranty': product['productWarrenty'] ?? '',
        'is_returnable': product['isReturnable'] ?? false,
        'returning_day': product['returnDays'] ?? 0,
        'is_published': product['isPublished'] ?? false,
        'mrp_per_unit': product['mrpPerUnit'] ?? 0,
        'sku': '',
        'hsn': '',
        'category': {
          'id': category['_id'] ?? '',
          'name': category['name'] ?? '',
          'image_url': category['image'] ?? '',
          'active': category['isActive'] ?? true,
        },
      },
      'sellerCalsification': {
        '_id': '',
        'product_id': product['_id'] ?? '',
        'isActive': true,
        'variants': synthesizedVariants,
      },
    };
    return GetProductData(product: ProductStore.fromJson(synth));
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
    };
  }

  /// Resolves the product's display image with a fallback chain:
  /// product-level [ProductDetails.media] first, then the first
  /// variant's [Variant.mediaRelatedToVariant]. Returns null when the
  /// product carries no usable image anywhere.
  ///
  /// Single source of truth so every surface (top-selling tile, cart
  /// thumbnail, …) renders the same photo. Products that only store
  /// media at the variant level used to show fine in the cart — which
  /// has this fallback — but blank wherever the fallback was missing.
  String? get primaryImageUrl {
    final media = product.details?.media;
    if (media != null && media.isNotEmpty && media.first.isNotEmpty) {
      return media.first;
    }
    final variants = product.sellerClassification?.variants;
    if (variants != null && variants.isNotEmpty) {
      final variantMedia = variants.first.mediaRelatedToVariant;
      if (variantMedia.isNotEmpty && variantMedia.first.isNotEmpty) {
        return variantMedia.first;
      }
    }
    return null;
  }
}

/// Extracts URL strings from the API's `images` / `videos` arrays
/// where each entry is an object `{ url, altText, _id }`. Falls back
/// to plain string entries (legacy shape) when present.
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

class ProductStore {
  final ProductDetails? details;
  final SellerClassification? sellerClassification;
  final String? business_name;
  final String? business_logo;
  final String? businessId;
  final String? category;
  final String? user_id;
  final String? mobile_no;
  ProductStore({this.user_id, this.mobile_no, this.business_name, this.business_logo, this.businessId, this.category,
    this.details,
    this.sellerClassification,
  });

  factory ProductStore.fromJson(Map<String, dynamic> json) {
    return ProductStore(
      details: json['details'] != null
          ? ProductDetails.fromJson(json['details'])
          : null,
      sellerClassification: json['sellerCalsification'] != null
          ? SellerClassification.fromJson(json['sellerCalsification'])
          : null,
      business_name: json['business_name'] ?? '',
      business_logo: json['business_logo'] ?? '',
      businessId: json['business_id'] ?? '',
      category: json['category'] ?? '',
      mobile_no: json['mobile_no'] ?? '',
      user_id: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {

      'details': details?.toJson(),
      'sellerCalsification': sellerClassification?.toJson(),
      'business_name': business_name,
      'category': category,
      'business_logo': business_logo,
      'business_id': businessId,
      'user_id': user_id,
      'mobile_no': mobile_no,
    };
  }
}

class ProductDetails {
  // final List<ProductOption> options;
  final List<String> media;
  final List<String> videoUrl;
  final List<String> tags;
  final List<AddMoreDetail> addMoreDetails;
  final List<ProductFeature> addProductFeatures;
  final String id;
  final String name;
  final String type;
  final String symbol;
  final String description;
  final String brand;
  final Category category;
  final String productWarranty;
  final bool isReturnable;
  final int returningDay;
  final bool isPublished;
  final num mrpPerUnit;
  final String sku;
  final String hsn;

  ProductDetails({
    // required this.options,
    required this.media,
    required this.videoUrl,
    required this.tags,
    required this.addMoreDetails,
    required this.addProductFeatures,
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.description,
    required this.brand,
    required this.category,
    required this.productWarranty,
    required this.isReturnable,
    required this.returningDay,
    required this.isPublished,
    required this.mrpPerUnit,
    required this.sku,
    required this.hsn,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      // options: (json['options'] as List<dynamic>? ?? [])
      //     .map((e) => ProductOption.fromJson(e))
      //     .toList(),
      media: List<String>.from(json['media'] ?? []),
      videoUrl: List<String>.from(json['video_url'] ?? []),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      addMoreDetails: (json['add_more_details'] as List<dynamic>? ?? [])
          .map((e) => AddMoreDetail.fromJson(e))
          .toList(),
      addProductFeatures: (json['add_product_features'] as List<dynamic>? ?? [])
          .map((e) => ProductFeature.fromJson(e))
          .toList(),
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      category: Category.fromJson(json['category'] ?? {}),
      productWarranty: json['product_warranty'] ?? '',
      isReturnable: json['is_returnable'] ?? false,
      returningDay: json['returning_day'] ?? 0,
      isPublished: json['is_published'] ?? false,
      mrpPerUnit: json['mrp_per_unit'] ?? 0,
      sku: json['sku'] ?? '',
      hsn: json['hsn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'options': options.map((e) => e.toJson()).toList(),
      'media': media,
      'video_url': videoUrl,
      'tags': tags,
      'add_more_details': addMoreDetails.map((e) => e.toJson()).toList(),
      'add_product_features':
          addProductFeatures.map((e) => e.toJson()).toList(),
      'id': id,
      'name': name,
      'type': type,
      'symbol': symbol,
      'description': description,
      'brand': brand,
       'category': category.toJson(),
      'product_warranty': productWarranty,
      'is_returnable': isReturnable,
      'returning_day': returningDay,
      'is_published': isPublished,
      'mrp_per_unit': mrpPerUnit,
      'sku': sku,
      'hsn': hsn,
    };
  }
}

class Category {
  final List<String> path;
  final String id;
  final String name;
  final String parentId;
  final String imageUrl;
  final bool active;

  Category({
    required this.path,
    required this.id,
    required this.name,
    required this.parentId,
    required this.imageUrl,
    required this.active,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      path: List<String>.from(json['path'] ?? []),
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      parentId: json['parent_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'id': id,
      'name': name,
      'parent_id': parentId,
      'image_url': imageUrl,
      'active': active,
    };
  }
}


class ProductOption {
  final List<String> value;
  final String attribute;

  ProductOption({required this.value, required this.attribute});

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      value: List<String>.from(json['value'] ?? []),
      attribute: json['attribute'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'attribute': attribute,
    };
  }
}

class AddMoreDetail {
  final String title;
  final String details;

  AddMoreDetail({required this.title, required this.details});

  factory AddMoreDetail.fromJson(Map<String, dynamic> json) {
    return AddMoreDetail(
      title: json['title'] ?? '',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'details': details,
    };
  }
}

class ProductFeature {
  final String title;

  ProductFeature({required this.title});

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }
}

class SellerClassification {
  final String id;
  final String productId;
  final List<Variant> variants;
  final bool isActive;
  BusinessLocation? businessLocation;
  Owner? owner;

  SellerClassification({
    required this.id,
    required this.productId,
    required this.variants,
    required this.isActive,
    this.businessLocation,
    this.owner,
  });

  factory SellerClassification.fromJson(Map<String, dynamic> json) {
    return SellerClassification(
      id: json['_id'] ?? '',
      productId: json['product_id'] ?? '',
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((e) => Variant.fromJson(e))
          .toList(),
      isActive: json['isActive'] ?? false,
      businessLocation: json['business_location'] != null
          ? BusinessLocation.fromJson(json['business_location'])
          : null,
      owner: json['owner'] != null
          ? Owner.fromJson(json['owner'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'product_id': productId,
      'variants': variants.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'business_location': businessLocation?.toJson(),
      'owner': owner?.toJson(),
    };
  }
}

class Owner {
  final String id;
  final String type;

  Owner({
    required this.id,
    required this.type,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type
    };
  }
}

class Variant {
  final Map<String, dynamic> attributes; // dynamic attributes
  final bool stock;
  // Mutable so a successful price edit can be reflected in-memory without a
  // full (and possibly stale) product refetch.
  num sellingPrice;
  num mrp;
  bool variantIsActive;
  final List<String> mediaRelatedToVariant;
  final String id;

  /// The inventory record id for this variant (distinct from the variant
  /// `_id`). This is what `PUT /inventory/{id}` expects.
  final String inventoryId;

  Variant({
    required this.attributes,
    required this.stock,
    required this.sellingPrice,
    required this.mediaRelatedToVariant,
    required this.mrp,
    required this.variantIsActive,
    required this.id,
    this.inventoryId = '',
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      attributes: json['attributes'] ?? {},
      stock: json['stock'] ?? false,
      sellingPrice: json['sellingPrice'] ?? 0,
      mediaRelatedToVariant:
          List<String>.from(json['media_related_to_varient'] ?? []),
      mrp: json['mrp'] ?? 0,
      variantIsActive: json['varientIsActive'] ?? false,
      id: json['_id'] ?? '',
      inventoryId:
          (json['inventory_id'] ?? json['inventoryId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attributes': attributes,
      'stock': stock,
      'sellingPrice': sellingPrice,
      'media_related_to_varient': mediaRelatedToVariant,
      'mrp': mrp,
      'varientIsActive': variantIsActive,
      '_id': id,
      'inventory_id': inventoryId,
    };
  }
}

BusinessLocation businessLocationFromJson(String str) =>
    BusinessLocation.fromJson(json.decode(str));

String businessLocationToJson(BusinessLocation data) =>
    json.encode(data.toJson());

class BusinessLocation {
  BusinessLocation({
    this.latitude,
    this.longitude,
  });

  BusinessLocation.fromJson(dynamic json) {
    latitude = json['lat'] is num ? json['lat'] as num : null;
    longitude = json['lon'] is num ? json['lon'] as num : null;
  }

  num? latitude;
  num? longitude;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['lat'] = latitude;
    map['lon'] = longitude;
    return map;
  }
}

