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
  List<VariantsData>? variants;

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
        this.variants});

  GroceryProductData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    category = json['category'];
    tags = json['tags'].cast<String>();
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
      variants = <VariantsData>[];
      json['variants'].forEach((v) {
        variants!.add(new VariantsData.fromJson(v));
      });
    }
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
    return data;
  }
}

class Images {
  String? url;
  String? sId;

  Images({this.url, this.sId});

  Images.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['_id'] = this.sId;
    return data;
  }
}

class VariantsData {
  String? sId;
  String? product;
  String? variantName;
  String? unit;
  List<Pricing>? pricing;
  List<ProductImage>? images;
  num? weight;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? sku;
  String? barcode;

  VariantsData({
    this.sId,
    this.product,
    this.variantName,
    this.unit,
    this.pricing,
    this.images,
    this.weight,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.sku,
    this.barcode,
  });

  VariantsData.fromJson(Map<String, dynamic> json) {
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
      images = <ProductImage>[];
      json['images'].forEach((v) {
        images!.add(ProductImage.fromJson(v));
      });
    }

    weight = json['weight'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    sku = json['sku'];
    barcode = json['barcode'];
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': sId,
      'product': product,
      'variantName': variantName,
      'unit': unit,
      'pricing': pricing?.map((v) => v.toJson()).toList(),
      'images': images?.map((v) => v.toJson()).toList(),
      'weight': weight,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': iV,
      'sku': sku,
      'barcode': barcode,
    };
  }

  /// New - Helpful for updating data
  VariantsData copyWith({
    String? sId,
    String? product,
    String? variantName,
    String? unit,
    List<Pricing>? pricing,
    List<ProductImage>? images,
    num? weight,
    String? createdAt,
    String? updatedAt,
    int? iV,
    String? sku,
    String? barcode,
  }) {
    return VariantsData(
      sId: sId ?? this.sId,
      product: product ?? this.product,
      variantName: variantName ?? this.variantName,
      unit: unit ?? this.unit,
      pricing: pricing ?? this.pricing,
      images: images ?? this.images,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iV: iV ?? this.iV,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
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

class ProductImage {
  String? url;
  String? id;

  ProductImage({this.url, this.id});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'],
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    '_id': id,
  };
}