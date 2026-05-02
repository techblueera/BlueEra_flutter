import '../../../../core/api/model/images.dart';

class GroceryProductModel {
  List<GroceryProductData>? data;
  Pagination? pagination;

  GroceryProductModel({this.data, this.pagination});

  GroceryProductModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <GroceryProductData>[];
      json['data'].forEach((v) {
        data!.add(new GroceryProductData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
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

  GroceryProductData(
      {this.sId,
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
        this.lastInventoryAddedOrUpdated});

  GroceryProductData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    category = json['category'];
    tags = (json['tags'] as List?)?.cast<String>() ?? [];
    if (json['images'] != null) {
      images = <Images>[];
      json['images'].forEach((v) {
        images!.add(new Images.fromJson(v));
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
        variants!.add(new ProductVariants.fromJson(v));
      });
    }
    lastInventoryAddedOrUpdated = json['lastInventoryAddedOrUpdated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['description'] = this.description;
    data['brand'] = this.brand;
    data['category'] = this.category;
    data['tags'] = this.tags;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    data['isActive'] = this.isActive;
    data['isVegetarian'] = this.isVegetarian;
    data['countryOfOrigin'] = this.countryOfOrigin;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.variants != null) {
      data['variants'] = this.variants!.map((v) => v.toJson()).toList();
    }
    data['lastInventoryAddedOrUpdated'] = this.lastInventoryAddedOrUpdated;
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
      lastInventoryAddedOrUpdated: lastInventoryAddedOrUpdated ?? this.lastInventoryAddedOrUpdated,
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
  Inventory? inventory;
  bool? isVegetarian;

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
    this.inventory,
    this.isVegetarian
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
    inventory = json['inventory'] != null
        ? Inventory.fromJson(json['inventory'])
        : null;
    isVegetarian = json['isVegetarian'];
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
      if (inventory != null) 'inventory': inventory!.toJson(),
      'isVegetarian': isVegetarian,
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

  Pricing(
      {this.pincode,
        this.cityName,
        this.mrp,
        this.sellingPrice,
        this.currency,
        this.sId});

  Pricing.fromJson(Map<String, dynamic> json) {
    pincode = json['pincode'];
    cityName = json['cityName'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    currency = json['currency'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pincode'] = this.pincode;
    data['cityName'] = this.cityName;
    data['mrp'] = this.mrp;
    data['sellingPrice'] = this.sellingPrice;
    data['currency'] = this.currency;
    data['_id'] = this.sId;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['batchNumber'] = this.batchNumber;
    data['quantity'] = this.quantity;
    data['mrp'] = this.mrp;
    data['sellingPrice'] = this.sellingPrice;
    data['_id'] = this.sId;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['page'] = this.page;
    data['limit'] = this.limit;
    data['totalPages'] = this.totalPages;
    return data;
  }
}

