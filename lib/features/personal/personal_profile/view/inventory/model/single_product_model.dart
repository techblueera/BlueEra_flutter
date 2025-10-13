class SingleProductModel {
  final bool status;
  final SingleProductData data;

  SingleProductModel({required this.status, required this.data});

  factory SingleProductModel.fromJson(Map<String, dynamic> json) {
    return SingleProductModel(
      status: json['status'] ?? false,
      data: SingleProductData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'data': data.toJson(),
  };
}

class SingleProductData {
  final String id;
  final String name;
  final String type;
  final String symbol;
  final String description;
  final String brand;
  final Options options;
  final List<String> media;
  final List<String> videoUrl;
  final String categoryId;
  final String productWarrenty;
  final bool isReturnable;
  final int returningDay;
  final bool isPublished;
  final double mrpPerUnit;
  final List<String> guideLine;
  final ExpiryTime expiryTime;
  final List<String> tags;
  final List<ProductDetail> addMoreDetails;
  final List<ProductFeature> addProductFeatures;
  final String createdByBusiness;
  final bool addedByAdmin;
  final String approvalStatus;
  final String createdAt;
  final String updatedAt;
  final int v;
  final List<Variant> variants;

  SingleProductData({
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.description,
    required this.brand,
    required this.options,
    required this.media,
    required this.videoUrl,
    required this.categoryId,
    required this.productWarrenty,
    required this.isReturnable,
    required this.returningDay,
    required this.isPublished,
    required this.mrpPerUnit,
    required this.guideLine,
    required this.expiryTime,
    required this.tags,
    required this.addMoreDetails,
    required this.addProductFeatures,
    required this.createdByBusiness,
    required this.addedByAdmin,
    required this.approvalStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.variants,
  });

  factory SingleProductData.fromJson(Map<String, dynamic> json) {
    return SingleProductData(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      options: Options.fromJson(json['options'] ?? {}),
      media: List<String>.from(json['media'] ?? []),
      videoUrl: List<String>.from(json['video_url'] ?? []),
      categoryId: json['category_id'] ?? '',
      productWarrenty: json['productWarrenty'] ?? '',
      isReturnable: json['is_returnable'] ?? false,
      returningDay: json['returning_day'] ?? 0,
      isPublished: json['is_published'] ?? false,
      mrpPerUnit: (json['mrp_per_unit'] ?? 0).toDouble(),
      guideLine: List<String>.from(json['guideLine'] ?? []),
      expiryTime: ExpiryTime.fromJson(json['expiry_time'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      addMoreDetails: (json['addMoreDetails'] as List<dynamic>? ?? [])
          .map((e) => ProductDetail.fromJson(e))
          .toList(),
      addProductFeatures: (json['addProductFeatures'] as List<dynamic>? ?? [])
          .map((e) => ProductFeature.fromJson(e))
          .toList(),
      createdByBusiness: json['created_by_business'] ?? '',
      addedByAdmin: json['addedByAdmin'] ?? false,
      approvalStatus: json['approval_status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      v: json['__v'] ?? 0,
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((e) => Variant.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'type': type,
    'symbol': symbol,
    'description': description,
    'brand': brand,
    'options': options.toJson(),
    'media': media,
    'video_url': videoUrl,
    'category_id': categoryId,
    'productWarrenty': productWarrenty,
    'is_returnable': isReturnable,
    'returning_day': returningDay,
    'is_published': isPublished,
    'mrp_per_unit': mrpPerUnit,
    'guideLine': guideLine,
    'expiry_time': expiryTime.toJson(),
    'tags': tags,
    'addMoreDetails': addMoreDetails.map((e) => e.toJson()).toList(),
    'addProductFeatures': addProductFeatures.map((e) => e.toJson()).toList(),
    'created_by_business': createdByBusiness,
    'addedByAdmin': addedByAdmin,
    'approval_status': approvalStatus,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    '__v': v,
    'variants': variants.map((e) => e.toJson()).toList(),
  };
}

class Options {
  final List<ColorOption> color;
  final List<SizeOption> size;

  Options({required this.color, required this.size});

  factory Options.fromJson(Map<String, dynamic> json) {
    return Options(
      color: (json['color'] as List<dynamic>? ?? [])
          .map((e) => ColorOption.fromJson(e))
          .toList(),
      size: (json['size'] as List<dynamic>? ?? [])
          .map((e) => SizeOption.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'color': color.map((e) => e.toJson()).toList(),
    'size': size.map((e) => e.toJson()).toList(),
  };
}

class ColorOption {
  final String colorCode;
  final String colorName;

  ColorOption({required this.colorCode, required this.colorName});

  factory ColorOption.fromJson(Map<String, dynamic> json) {
    return ColorOption(
      colorCode: json['color_code'] ?? '',
      colorName: json['color_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'color_code': colorCode,
    'color_name': colorName,
  };
}

class SizeOption {
  final String properties;

  SizeOption({required this.properties});

  factory SizeOption.fromJson(Map<String, dynamic> json) {
    return SizeOption(
      properties: json['properties'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'properties': properties,
  };
}

class ExpiryTime {
  final dynamic date;
  final dynamic month;
  final dynamic year;
  final dynamic week;
  final bool lifetime;

  ExpiryTime({
    this.date,
    this.month,
    this.year,
    this.week,
    required this.lifetime,
  });

  factory ExpiryTime.fromJson(Map<String, dynamic> json) {
    return ExpiryTime(
      date: json['date'],
      month: json['month'],
      year: json['year'],
      week: json['week'],
      lifetime: json['lifetime'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'month': month,
    'year': year,
    'week': week,
    'lifetime': lifetime,
  };
}

class ProductDetail {
  final String title;
  final String details;
  final String id;

  ProductDetail({required this.title, required this.details, required this.id});

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      title: json['title'] ?? '',
      details: json['details'] ?? '',
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'details': details,
    '_id': id,
  };
}

class ProductFeature {
  final String title;
  final String id;

  ProductFeature({required this.title, required this.id});

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      title: json['title'] ?? '',
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    '_id': id,
  };
}

class Variant {
  final List<String> mediaRelatedToVariant;
  final Map<String, dynamic> attributesMap;
  final Map<String, dynamic> attributesStruct;
  final String sku;
  final String hsn;
  final String batchNumber;
  final dynamic expiryDate;
  final dynamic manufacteringDate;
  final bool stock;
  final double costPrice;
  final double sellingPrice;
  final double mrp;
  final bool variantIsActive;
  final String createdAt;
  final String updatedAt;
  final String id;

  Variant({
    required this.mediaRelatedToVariant,
    required this.attributesMap,
    required this.attributesStruct,
    required this.sku,
    required this.hsn,
    required this.batchNumber,
    this.expiryDate,
    this.manufacteringDate,
    required this.stock,
    required this.costPrice,
    required this.sellingPrice,
    required this.mrp,
    required this.variantIsActive,
    required this.createdAt,
    required this.updatedAt,
    required this.id,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      mediaRelatedToVariant: List<String>.from(json['media_related_to_varient'] ?? []),
      attributesMap: json['attributes_map'] ?? {},
      attributesStruct: json['attributes_struct'] ?? {},
      sku: json['sku'] ?? '',
      hsn: json['hsn'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'],
      manufacteringDate: json['manufacteringDate'],
      stock: json['stock'] ?? false,
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      mrp: (json['mrp'] ?? 0).toDouble(),
      variantIsActive: json['varientIsActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      id: json['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'media_related_to_varient': mediaRelatedToVariant,
    'attributes_map': attributesMap,
    'attributes_struct': attributesStruct,
    'sku': sku,
    'hsn': hsn,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate,
    'manufacteringDate': manufacteringDate,
    'stock': stock,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'mrp': mrp,
    'varientIsActive': variantIsActive,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'id': id,
  };
}
