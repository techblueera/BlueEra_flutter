import '../../../../core/api/model/images.dart';

class GroceryProductModel {
  List<GroceryCategoryProductGroup>? data;
  Pagination? pagination;

  GroceryProductModel({this.data, this.pagination});

  GroceryProductModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <GroceryCategoryProductGroup>[];
      json['data'].forEach((v) {
        data!.add(GroceryCategoryProductGroup.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    return data;
  }
}

/// Top-level array item: a category bundled with its products.
class GroceryCategoryProductGroup {
  ProductCategoryInfo? category;

  GroceryCategoryProductGroup({this.category});

  GroceryCategoryProductGroup.fromJson(Map<String, dynamic> json) {
    category = json['category'] != null
        ? ProductCategoryInfo.fromJson(json['category'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (category != null) data['category'] = category!.toJson();
    return data;
  }
}

class ProductCategoryInfo {
  String? sId;
  String? name;
  String? image;
  String? lastUpdate;
  int? productVariantCount;
  List<GroceryProductData>? products;

  ProductCategoryInfo({
    this.sId,
    this.name,
    this.image,
    this.lastUpdate,
    this.productVariantCount,
    this.products,
  });

  ProductCategoryInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    image = json['image'];
    lastUpdate = json['lastUpdate'];
    productVariantCount = json['productVariantCount'];
    if (json['products'] != null) {
      products = <GroceryProductData>[];
      json['products'].forEach((v) {
        products!.add(GroceryProductData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['image'] = image;
    data['lastUpdate'] = lastUpdate;
    data['productVariantCount'] = productVariantCount;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GroceryProductData {
  String? sId;
  String? name;
  String? description;
  String? brand;
  String? category;
  List<String>? tags;
  List<Images>? images;
  bool? isActive;
  bool? isVegetarian;
  String? countryOfOrigin;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<ProductVariants>? variants;
  String? lastInventoryAddedOrUpdated;

  GroceryProductData({
    this.sId,
    this.name,
    this.description,
    this.brand,
    this.category,
    this.tags,
    this.images,
    this.isActive,
    this.isVegetarian,
    this.countryOfOrigin,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.variants,
    this.lastInventoryAddedOrUpdated,
  });

  GroceryProductData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    // Server may send category as a String id (legacy) or as an object
    // (newer responses where category is bundled at the parent group
    // level). Coerce to String when present so callers can keep using it.
    final dynamic rawCategory = json['category'];
    if (rawCategory is String) {
      category = rawCategory;
    } else if (rawCategory is Map && rawCategory['_id'] is String) {
      category = rawCategory['_id'] as String;
    } else {
      category = null;
    }
    tags = (json['tags'] as List?)?.cast<String>() ?? [];
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(Images.fromJson(v));
      });
    }
    isActive = json['isActive'];
    isVegetarian = json['isVegetarian'];
    countryOfOrigin = json['countryOfOrigin'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    if (json['variants'] != null) {
      variants = <ProductVariants>[];
      json['variants'].forEach((v) {
        variants!.add(ProductVariants.fromJson(v));
      });
    }
    lastInventoryAddedOrUpdated = json['lastInventoryAddedOrUpdated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['description'] = description;
    data['brand'] = brand;
    data['category'] = category;
    data['tags'] = tags;
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    data['isActive'] = isActive;
    data['isVegetarian'] = isVegetarian;
    data['countryOfOrigin'] = countryOfOrigin;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    if (variants != null) {
      data['variants'] = variants!.map((v) => v.toJson()).toList();
    }
    data['lastInventoryAddedOrUpdated'] = lastInventoryAddedOrUpdated;
    return data;
  }

  GroceryProductData copyWith({
    String? sId,
    String? name,
    String? description,
    String? brand,
    String? category,
    List<String>? tags,
    List<Images>? images,
    bool? isActive,
    bool? isVegetarian,
    String? countryOfOrigin,
    String? createdAt,
    String? updatedAt,
    int? iV,
    List<ProductVariants>? variants,
    String? lastInventoryAddedOrUpdated,
  }) {
    return GroceryProductData(
      sId: sId ?? this.sId,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iV: iV ?? this.iV,
      variants: variants ?? this.variants,
      lastInventoryAddedOrUpdated:
          lastInventoryAddedOrUpdated ?? this.lastInventoryAddedOrUpdated,
    );
  }
}

class ProductVariants {
  String? sId;
  String? product;
  String? variantName;
  String? unit;
  List<Pricing>? pricing;
  List<Images>? images;
  String? quantity;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? sku;
  String? barcode;
  bool? isVegetarian;
  Inventory? inventory;

  ProductVariants({
    this.sId,
    this.product,
    this.variantName,
    this.unit,
    this.pricing,
    this.images,
    this.quantity,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.sku,
    this.barcode,
    this.isVegetarian,
    this.inventory,
  });

  ProductVariants.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    product = json['product'];
    variantName = json['variantName'];
    unit = json['unit'];

    if (json['pricing'] != null) {
      pricing = <Pricing>[];
      json['pricing'].forEach((v) {
        pricing!.add(Pricing.fromJson(v));
      });
    }

    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(Images.fromJson(v));
      });
    }

    quantity = json['quantity'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    sku = json['sku'];
    barcode = json['barcode'];
    isVegetarian = json['isVegetarian'];
    inventory = json['inventory'] != null
        ? Inventory.fromJson(json['inventory'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'product': product,
      'variantName': variantName,
      'unit': unit,
      'pricing': pricing?.map((v) => v.toJson()).toList(),
      'images': images?.map((v) => v.toJson()).toList(),
      'quantity': quantity,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
      'sku': sku,
      'barcode': barcode,
      'isVegetarian': isVegetarian,
      if (inventory != null) 'inventory': inventory!.toJson(),
    };
  }

  /// New - Helpful for updating data
  ProductVariants copyWith({
    String? sId,
    String? product,
    String? variantName,
    String? unit,
    List<Pricing>? pricing,
    List<Images>? images,
    String? quantity,
    String? createdAt,
    String? updatedAt,
    int? iV,
    String? sku,
    String? barcode,
    bool? isVegetarian,
    Inventory? inventory,
  }) {
    return ProductVariants(
      sId: sId ?? this.sId,
      product: product ?? this.product,
      variantName: variantName ?? this.variantName,
      unit: unit ?? this.unit,
      pricing: pricing ?? this.pricing,
      images: images ?? this.images,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iV: iV ?? this.iV,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      inventory: inventory ?? this.inventory,
    );
  }
}

class Pricing {
  String? pincode;
  String? cityName;
  num? mrp;
  num? sellingPrice;
  String? currency;
  String? sId;

  Pricing({
    this.pincode,
    this.cityName,
    this.mrp,
    this.sellingPrice,
    this.currency,
    this.sId,
  });

  Pricing.fromJson(Map<String, dynamic> json) {
    pincode = json['pincode'];
    cityName = json['cityName'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    currency = json['currency'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pincode'] = pincode;
    data['cityName'] = cityName;
    data['mrp'] = mrp;
    data['sellingPrice'] = sellingPrice;
    data['currency'] = currency;
    data['_id'] = sId;
    return data;
  }

  Pricing copyWith({
    String? pincode,
    String? cityName,
    num? mrp,
    num? sellingPrice,
    String? currency,
    String? sId,
  }) {
    return Pricing(
      pincode: pincode ?? this.pincode,
      cityName: cityName ?? this.cityName,
      mrp: mrp ?? this.mrp,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currency: currency ?? this.currency,
      sId: sId ?? this.sId,
    );
  }
}

class Inventory {
  String? inventoryId;
  String? pincode;
  String? cityName;
  List<Batches>? batches;
  num? totalStock;
  bool? isOutOfStock;

  Inventory({
    this.inventoryId,
    this.pincode,
    this.cityName,
    this.batches,
    this.totalStock,
    this.isOutOfStock,
  });

  Inventory.fromJson(Map<String, dynamic> json) {
    inventoryId = json['inventoryId'];
    pincode = json['pincode'];
    cityName = json['cityName'];
    if (json['batches'] != null) {
      batches = <Batches>[];
      json['batches'].forEach((v) {
        batches!.add(Batches.fromJson(v));
      });
    }
    totalStock = json['totalStock'];
    isOutOfStock = json['isOutOfStock'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['inventoryId'] = inventoryId;
    data['pincode'] = pincode;
    data['cityName'] = cityName;
    if (batches != null) {
      data['batches'] = batches!.map((v) => v.toJson()).toList();
    }
    data['totalStock'] = totalStock;
    data['isOutOfStock'] = isOutOfStock;
    return data;
  }
}

class Batches {
  String? batchNumber;
  String? quantity;
  num? mrp;
  num? sellingPrice;
  String? sId;

  Batches(
      {this.batchNumber, this.quantity, this.mrp, this.sellingPrice, this.sId});

  Batches.fromJson(Map<String, dynamic> json) {
    batchNumber = json['batchNumber'];
    quantity = json['quantity'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['batchNumber'] = batchNumber;
    data['quantity'] = quantity;
    data['mrp'] = mrp;
    data['sellingPrice'] = sellingPrice;
    data['_id'] = sId;
    return data;
  }
}

class Pagination {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  Pagination({this.total, this.page, this.limit, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['page'] = page;
    data['limit'] = limit;
    data['totalPages'] = totalPages;
    return data;
  }
}
