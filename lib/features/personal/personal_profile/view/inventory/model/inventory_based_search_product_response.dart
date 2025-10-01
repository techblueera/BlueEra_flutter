class InventoryBasedSearchProductResponse {
  List<VariantData> data;
  List<UnUsedProduct> unUsedProduct;

  InventoryBasedSearchProductResponse({
    required this.data,
    required this.unUsedProduct,
  });

  factory InventoryBasedSearchProductResponse.fromJson(Map<String, dynamic> json) {
    return InventoryBasedSearchProductResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => VariantData.fromJson(e))
          .toList() ??
          [],
      unUsedProduct: (json['unUsedProduct'] as List<dynamic>?)
          ?.map((e) => UnUsedProduct.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class VariantData {
  List<String> mediaRelatedToVarient;
  Map<String, dynamic> attributes;
  String sku;
  String hsn;
  String batchNumber;
  DateInfo expiryDate;
  DateInfo manufacteringDate;
  bool stock;
  double costPrice;
  double sellingPrice;
  double mrp;
  bool varientIsActive;
  // DateTime createdAt;
  // DateTime updatedAt;
  ProductInformation productInformation;

  VariantData({
    required this.mediaRelatedToVarient,
    required this.attributes,
    required this.sku,
    required this.hsn,
    required this.batchNumber,
    required this.expiryDate,
    required this.manufacteringDate,
    required this.stock,
    required this.costPrice,
    required this.sellingPrice,
    required this.mrp,
    required this.varientIsActive,
    // required this.createdAt,
    // required this.updatedAt,
    required this.productInformation,
  });

  factory VariantData.fromJson(Map<String, dynamic> json) {
    return VariantData(
      mediaRelatedToVarient:
      List<String>.from(json['media_related_to_varient'] ?? []),
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
      sku: json['sku'] ?? '',
      hsn: json['hsn'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: DateInfo.fromJson(json['expiryDate'] ?? {}),
      manufacteringDate: DateInfo.fromJson(json['manufacteringDate'] ?? {}),
      stock: json['stock'] ?? true,
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      mrp: (json['mrp'] ?? 0).toDouble(),
      varientIsActive: json['varientIsActive'] ?? true,
      // createdAt: DateTime.parse(json['createdAt']),
      // updatedAt: DateTime.parse(json['updatedAt']),
      productInformation:
      ProductInformation.fromJson(json['product_information'] ?? {}),
    );
  }
}

class DateInfo {
  int date;
  int month;
  int year;

  DateInfo({required this.date, required this.month, required this.year});

  factory DateInfo.fromJson(Map<String, dynamic> json) {
    return DateInfo(
      date: json['date'] ?? 0,
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
    );
  }
}

class ProductInformation {
  String id;
  String name;
  String type;
  String symbol;
  String description;
  String brand;
  List<String> media;
  List<String> videoUrl;
  String productWarrenty;
  bool isReturnable;
  int returningDay;
  bool isPublished;
  double mrpPerUnit;
  List<String> guideLine;
  List<String> tags;
  List<AddMoreDetail> addMoreDetails;
  List<ProductFeature> addProductFeatures;
  List<ProductVariant> variants;
  String approvalStatus;
  List<dynamic> options;
  DateTime createdAt;
  DateTime updatedAt;
  bool addedByAdmin;

  ProductInformation({
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.description,
    required this.brand,
    required this.media,
    required this.videoUrl,
    required this.productWarrenty,
    required this.isReturnable,
    required this.returningDay,
    required this.isPublished,
    required this.mrpPerUnit,
    required this.guideLine,
    required this.tags,
    required this.addMoreDetails,
    required this.addProductFeatures,
    required this.variants,
    required this.approvalStatus,
    required this.options,
    required this.createdAt,
    required this.updatedAt,
    required this.addedByAdmin,
  });

  factory ProductInformation.fromJson(Map<String, dynamic> json) {
    return ProductInformation(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      media: List<String>.from(json['media'] ?? []),
      videoUrl: List<String>.from(json['video_url'] ?? []),
      productWarrenty: json['productWarrenty'] ?? '',
      isReturnable: json['is_returnable'] ?? false,
      returningDay: json['returning_day'] ?? 0,
      isPublished: json['is_published'] ?? false,
      mrpPerUnit: (json['mrp_per_unit'] ?? 0).toDouble(),
      guideLine: List<String>.from(json['guideLine'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      addMoreDetails: (json['addMoreDetails'] as List<dynamic>?)
          ?.map((e) => AddMoreDetail.fromJson(e))
          .toList() ??
          [],
      addProductFeatures: (json['addProductFeatures'] as List<dynamic>?)
          ?.map((e) => ProductFeature.fromJson(e))
          .toList() ??
          [],
      variants: (json['variants'] as List<dynamic>?)
          ?.map((e) => ProductVariant.fromJson(e))
          .toList() ??
          [],
      approvalStatus: json['approval_status'] ?? '',
      options: json['options'] ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      addedByAdmin: json['addedByAdmin'] ?? false,
    );
  }
}

class AddMoreDetail {
  String title;
  String details;
  String id;

  AddMoreDetail({required this.title, required this.details, required this.id});

  factory AddMoreDetail.fromJson(Map<String, dynamic> json) {
    return AddMoreDetail(
      title: json['title'] ?? '',
      details: json['details'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}

class ProductFeature {
  String title;
  String id;

  ProductFeature({required this.title, required this.id});

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      title: json['title'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}

class ProductVariant {
  Map<String, dynamic> attributes;
  bool stock;
  List<String> mediaRelatedToVarient;
  bool varientIsActive;
  String id;
  DateTime createdAt;
  DateTime updatedAt;

  ProductVariant({
    required this.attributes,
    required this.stock,
    required this.mediaRelatedToVarient,
    required this.varientIsActive,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
      stock: json['stock'] ?? true,
      mediaRelatedToVarient:
      List<String>.from(json['media_related_to_varient'] ?? []),
      varientIsActive: json['varientIsActive'] ?? true,
      id: json['_id'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class UnUsedProduct {
  String id;
  String name;
  String type;
  String symbol;
  List<String> media;
  List<String> videoUrl;
  String categoryId;
  bool isReturnable;
  int returningDay;
  bool isPublished;
  List<String> guideLine;
  DateInfo expiryTime;
  List<String> tags;
  bool addedByAdmin;
  String approvalStatus;
  List<dynamic> options;
  List<AddMoreDetail> addMoreDetails;
  List<ProductFeature> addProductFeatures;
  List<ProductVariant> variants;
  String description;
  String brand;
  String productWarrenty;
  double mrpPerUnit;
  DateTime createdAt;
  DateTime updatedAt;

  UnUsedProduct({
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
    required this.guideLine,
    required this.expiryTime,
    required this.tags,
    required this.addedByAdmin,
    required this.approvalStatus,
    required this.options,
    required this.addMoreDetails,
    required this.addProductFeatures,
    required this.variants,
    required this.description,
    required this.brand,
    required this.productWarrenty,
    required this.mrpPerUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnUsedProduct.fromJson(Map<String, dynamic> json) {
    return UnUsedProduct(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      symbol: json['symbol'] ?? '',
      media: List<String>.from(json['media'] ?? []),
      videoUrl: List<String>.from(json['video_url'] ?? []),
      categoryId: json['category_id'] ?? '',
      isReturnable: json['is_returnable'] ?? false,
      returningDay: json['returning_day'] ?? 0,
      isPublished: json['is_published'] ?? false,
      guideLine: List<String>.from(json['guideLine'] ?? []),
      expiryTime: DateInfo.fromJson(json['expiry_time'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      addedByAdmin: json['addedByAdmin'] ?? false,
      approvalStatus: json['approval_status'] ?? '',
      options: json['options'] ?? [],
      addMoreDetails: (json['addMoreDetails'] as List<dynamic>?)
          ?.map((e) => AddMoreDetail.fromJson(e))
          .toList() ??
          [],
      addProductFeatures: (json['addProductFeatures'] as List<dynamic>?)
          ?.map((e) => ProductFeature.fromJson(e))
          .toList() ??
          [],
      variants: (json['variants'] as List<dynamic>?)
          ?.map((e) => ProductVariant.fromJson(e))
          .toList() ??
          [],
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      productWarrenty: json['productWarrenty'] ?? '',
      mrpPerUnit: (json['mrp_per_unit'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

