class InventoryBasedSearchProductResponse {
  final List<ProductData> data;
  final List<ProductDetail> unUsedProduct;

  InventoryBasedSearchProductResponse({
    required this.data,
    required this.unUsedProduct,
  });

  factory InventoryBasedSearchProductResponse.fromJson(Map<String, dynamic> json) {
    return InventoryBasedSearchProductResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => ProductData.fromJson(e))
          .toList(),
      unUsedProduct: (json['unUsedProduct'] as List<dynamic>)
          .map((e) => ProductDetail.fromJson(e))
          .toList(), // <-- map to ProductDetail
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'unUsedProduct': unUsedProduct.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductData {
  final List<Inventory> inventories;
  final String id;
  final String productId;
  final String businessId;
  final BusinessLocation? businessLocation;
  final bool published;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductData({
    required this.inventories,
    required this.id,
    required this.productId,
    required this.businessId,
    this.businessLocation,
    required this.published,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      inventories: (json['inventories'] as List<dynamic>)
          .map((e) => Inventory.fromJson(e))
          .toList(),
      id: json['id'],
      productId: json['product_id'],
      businessId: json['business_id'],
      businessLocation: json['business_location'] != null
          ? BusinessLocation.fromJson(json['business_location'])
          : null,
      published: json['published'] ?? false,
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventories': inventories.map((e) => e.toJson()).toList(),
      'id': id,
      'product_id': productId,
      'business_id': businessId,
      'business_location': businessLocation?.toJson(),
      'published': published,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Inventory {
  final List<Variants> variants;
  final String id;
  final String productId;
  final String businessId;
  final bool published;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Inventory({
    required this.variants,
    required this.id,
    required this.productId,
    required this.businessId,
    required this.published,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      variants: (json['variants'] as List<dynamic>)
          .map((e) => Variants.fromJson(e))
          .toList(),
      id: json['id'],
      productId: json['product_id'],
      businessId: json['business_id'],
      published: json['published'] ?? false,
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variants': variants.map((e) => e.toJson()).toList(),
      'id': id,
      'product_id': productId,
      'business_id': businessId,
      'published': published,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class Variants {
  final List<String> mediaRelatedToVarient;
  final Map<String, dynamic> attributes;
  final String sku;
  final String hsn;
  final String batchNumber;
  final DateInfo manufacteringDate;
  final bool stock;
  final double costPrice;
  final double sellingPrice;
  final double mrp;
  final bool varientIsActive;
  final String createdAt;
  final String updatedAt;
  final ProductDetail product;

  Variants({
    required this.mediaRelatedToVarient,
    required this.attributes,
    required this.sku,
    required this.hsn,
    required this.batchNumber,
    required this.manufacteringDate,
    required this.stock,
    required this.costPrice,
    required this.sellingPrice,
    required this.mrp,
    required this.varientIsActive,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
  });

  factory Variants.fromJson(Map<String, dynamic> json) {
    return Variants(
      mediaRelatedToVarient:
      List<String>.from(json['media_related_to_varient'] ?? []),
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
      sku: json['sku'] ?? '',
      hsn: json['hsn'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      manufacteringDate: DateInfo.fromJson(json['manufacteringDate'] ?? {}),
      stock: json['stock'] ?? false,
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      mrp: (json['mrp'] ?? 0).toDouble(),
      varientIsActive: json['varientIsActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      product: ProductDetail.fromJson(json['product']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media_related_to_varient': mediaRelatedToVarient,
      'attributes': attributes,
      'sku': sku,
      'hsn': hsn,
      'batchNumber': batchNumber,
      'manufacteringDate': manufacteringDate.toJson(),
      'stock': stock,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'mrp': mrp,
      'varientIsActive': varientIsActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'product': product.toJson(),
    };
  }
}

class DateInfo {
  final int date;
  final int month;
  final int year;

  DateInfo({required this.date, required this.month, required this.year});

  factory DateInfo.fromJson(Map<String, dynamic> json) {
    return DateInfo(
      date: json['date'] ?? 0,
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'month': month,
      'year': year,
    };
  }
}

class ProductDetail {
  final String id;
  final String name;
  final String type;
  final String symbol;
  final List<String> media;
  final List<dynamic> videoUrl;
  final String categoryId;
  final bool isReturnable;
  final int returningDay;
  final bool isPublished;
  final List<String> tags;
  final bool addedByAdmin;
  final String approvalStatus;
  final List<Option> options;
  final List<Map<String, dynamic>> addMoreDetails;
  final List<Map<String, dynamic>> addProductFeatures;
  final List<dynamic> variants;
  final String description;
  final String brand;
  final String productWarranty;
  final double mrpPerUnit;
  final String createdAt;
  final String updatedAt;

  ProductDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.media,
    required this.videoUrl,
    required this.categoryId,
    required this.isReturnable,
    required this.returningDay,
    required this.isPublished,
    required this.tags,
    required this.addedByAdmin,
    required this.approvalStatus,
    required this.options,
    required this.addMoreDetails,
    required this.addProductFeatures,
    required this.variants,
    required this.description,
    required this.brand,
    required this.productWarranty,
    required this.mrpPerUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      symbol: json['symbol'],
      media: List<String>.from(json['media'] ?? []),
      videoUrl: List<dynamic>.from(json['video_url'] ?? []),
      categoryId: json['category_id'],
      isReturnable: json['is_returnable'] ?? false,
      returningDay: json['returning_day'] ?? 0,
      isPublished: json['is_published'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      addedByAdmin: json['addedByAdmin'] ?? false,
      approvalStatus: json['approval_status'] ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => Option.fromJson(e))
          .toList(),
      addMoreDetails: List<Map<String, dynamic>>.from(json['addMoreDetails'] ?? []),
      addProductFeatures:
      List<Map<String, dynamic>>.from(json['addProductFeatures'] ?? []),
      variants: List<dynamic>.from(json['variants'] ?? []),
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      productWarranty: json['productWarrenty'] ?? '',
      mrpPerUnit: (json['mrp_per_unit'] ?? 0).toDouble(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'symbol': symbol,
      'media': media,
      'video_url': videoUrl,
      'category_id': categoryId,
      'is_returnable': isReturnable,
      'returning_day': returningDay,
      'is_published': isPublished,
      'tags': tags,
      'addedByAdmin': addedByAdmin,
      'approval_status': approvalStatus,
      'options': options.map((e) => e.toJson()).toList(),
      'addMoreDetails': addMoreDetails,
      'addProductFeatures': addProductFeatures,
      'variants': variants,
      'description': description,
      'brand': brand,
      'productWarrenty': productWarranty,
      'mrp_per_unit': mrpPerUnit,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class Option {
  final String attribute;
  final List<String> value;
  final String id;

  Option({required this.attribute, required this.value, required this.id});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      attribute: json['attribute'],
      value: List<String>.from(json['value'] ?? []),
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attribute': attribute,
      'value': value,
      '_id': id,
    };
  }
}

class BusinessLocation {
  final double latitude;
  final double longitude;

  BusinessLocation({required this.latitude, required this.longitude});

  factory BusinessLocation.fromJson(Map<String, dynamic> json) {
    return BusinessLocation(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
