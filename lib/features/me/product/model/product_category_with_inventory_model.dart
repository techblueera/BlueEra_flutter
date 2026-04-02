/// Root response model for inventoryByCategory API
class ProductInventoryByCategoryResponse {
  bool? status;
  String? businessId;
  List<ProductCategoryWithInventoryModel>? data;

  ProductInventoryByCategoryResponse({
    this.status,
    this.businessId,
    this.data,
  });

  ProductInventoryByCategoryResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    businessId = json['businessId'];
    if (json['data'] != null) {
      data = <ProductCategoryWithInventoryModel>[];
      json['data'].forEach((v) {
        data!.add(ProductCategoryWithInventoryModel.fromJson(v));
      });
    }
  }
}

/// Each item in data array: { category_info, inventories }
class ProductCategoryWithInventoryModel {
  CategoryInfo? categoryInfo;
  List<ProductInventoryItem>? inventories;

  ProductCategoryWithInventoryModel({
    this.categoryInfo,
    this.inventories,
  });

  ProductCategoryWithInventoryModel.fromJson(Map<String, dynamic> json) {
    categoryInfo = json['category_info'] != null
        ? CategoryInfo.fromJson(json['category_info'])
        : null;
    if (json['inventories'] != null) {
      inventories = <ProductInventoryItem>[];
      json['inventories'].forEach((v) {
        inventories!.add(ProductInventoryItem.fromJson(v));
      });
    }
  }

  // Convenience getters for easy access
  String? get name => categoryInfo?.name;
  String? get key => categoryInfo?.key;
  String? get sId => categoryInfo?.sId;
  String? get image => inventories?.isNotEmpty == true
      ? inventories!.first.productDetails?.media?.firstOrNull
      : null;
}

class CategoryInfo {
  String? sId;
  String? name;
  String? key;
  String? parentId;
  int? level;

  CategoryInfo({
    this.sId,
    this.name,
    this.key,
    this.parentId,
    this.level,
  });

  CategoryInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    key = json['key'];
    parentId = json['parentId'];
    level = json['level'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['key'] = key;
    data['parentId'] = parentId;
    data['level'] = level;
    return data;
  }
}

class ProductInventoryItem {
  String? id;
  String? productId;
  String? businessId;
  bool? published;
  bool? isActive;
  ProductInventoryOwner? owner;
  ProductInventoryLocation? businessLocation;
  ProductInventoryDetails? productDetails;
  List<ProductInventoryVariant>? variants;
  String? createdAt;
  String? updatedAt;

  ProductInventoryItem({
    this.id,
    this.productId,
    this.businessId,
    this.published,
    this.isActive,
    this.owner,
    this.businessLocation,
    this.productDetails,
    this.variants,
    this.createdAt,
    this.updatedAt,
  });

  ProductInventoryItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    businessId = json['business_id'];
    published = json['published'];
    isActive = json['isActive'];
    owner = json['owner'] != null
        ? ProductInventoryOwner.fromJson(json['owner'])
        : null;
    businessLocation = json['business_location'] != null
        ? ProductInventoryLocation.fromJson(json['business_location'])
        : null;
    productDetails = json['product_details'] != null
        ? ProductInventoryDetails.fromJson(json['product_details'])
        : null;
    if (json['variants'] != null) {
      variants = <ProductInventoryVariant>[];
      json['variants'].forEach((v) {
        variants!.add(ProductInventoryVariant.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
}

class ProductInventoryOwner {
  String? id;
  String? type;

  ProductInventoryOwner({this.id, this.type});

  ProductInventoryOwner.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
  }
}

class ProductInventoryLocation {
  double? latitude;
  double? longitude;

  ProductInventoryLocation({this.latitude, this.longitude});

  ProductInventoryLocation.fromJson(Map<String, dynamic> json) {
    latitude = (json['latitude'] as num?)?.toDouble();
    longitude = (json['longitude'] as num?)?.toDouble();
  }
}

class ProductInventoryDetails {
  String? sId;
  String? name;
  List<String>? media;
  String? categoryId;

  ProductInventoryDetails({
    this.sId,
    this.name,
    this.media,
    this.categoryId,
  });

  ProductInventoryDetails.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    media = json['media'] != null ? json['media'].cast<String>() : [];
    categoryId = json['category_id'];
  }
}

class ProductInventoryVariant {
  String? id;
  List<String>? mediaRelatedToVariant;
  Map<String, dynamic>? attributesMap;
  String? sku;
  String? hsn;
  bool? stock;
  num? costPrice;
  num? sellingPrice;
  num? mrp;
  bool? variantIsActive;
  String? createdAt;
  String? updatedAt;

  ProductInventoryVariant({
    this.id,
    this.mediaRelatedToVariant,
    this.attributesMap,
    this.sku,
    this.hsn,
    this.stock,
    this.costPrice,
    this.sellingPrice,
    this.mrp,
    this.variantIsActive,
    this.createdAt,
    this.updatedAt,
  });

  ProductInventoryVariant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    mediaRelatedToVariant = json['media_related_to_varient'] != null
        ? json['media_related_to_varient'].cast<String>()
        : [];
    attributesMap = json['attributes_map'] != null
        ? Map<String, dynamic>.from(json['attributes_map'])
        : null;
    sku = json['sku'];
    hsn = json['hsn'];
    stock = json['stock'];
    costPrice = json['costPrice'];
    sellingPrice = json['sellingPrice'];
    mrp = json['mrp'];
    variantIsActive = json['varientIsActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
}
