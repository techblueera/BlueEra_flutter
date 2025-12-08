class GroceryProductModel {
  List<GroceryProductData>? data;
  Pagination? pagination;

  GroceryProductModel({this.data, this.pagination});

  GroceryProductModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(GroceryProductData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (data != null) json['data'] = data!.map((v) => v.toJson()).toList();
    if (pagination != null) json['pagination'] = pagination!.toJson();
    return json;
  }
}

class GroceryProductData {
  String? sId;
  String? product;
  String? variantName;
  String? unit;
  String? sku;
  String? barcode;
  List<Pricing>? pricing;
  List<ProductImage>? images;
  String? createdAt;
  String? updatedAt;
  int? iV;
  ProductInfo? productInfo;

  GroceryProductData({
    this.sId,
    this.product,
    this.variantName,
    this.unit,
    this.sku,
    this.barcode,
    this.pricing,
    this.images,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.productInfo,
  });

  GroceryProductData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    product = json['product'];
    variantName = json['variantName'];
    unit = json['unit'];
    sku = json['sku'];
    barcode = json['barcode'];

    if (json['pricing'] != null) {
      pricing = [];
      json['pricing'].forEach((v) {
        pricing!.add(Pricing.fromJson(v));
      });
    }
    images = json['images'] != null
        ? List<ProductImage>.from(
      json['images'].map((x) => ProductImage.fromJson(x)),
    )
        : [];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];

    productInfo =
    json['productInfo'] != null ? ProductInfo.fromJson(json['productInfo']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json['_id'] = sId;
    json['product'] = product;
    json['variantName'] = variantName;
    json['unit'] = unit;
    json['sku'] = sku;
    json['barcode'] = barcode;
    if (pricing != null) json['pricing'] = pricing!.map((v) => v.toJson()).toList();
    if (images != null) json['barcode'] =  images!.map((x) => x.toJson()).toList();
    json['createdAt'] = createdAt;
    json['updatedAt'] = updatedAt;
    json['__v'] = iV;

    if (productInfo != null) json['productInfo'] = productInfo!.toJson();

    return json;
  }
}

class Pricing {
  String? pincode;
  String? cityName;
  int? mrp;
  int? sellingPrice;
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
    return {
      'pincode': pincode,
      'cityName': cityName,
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'currency': currency,
      '_id': sId,
    };
  }
}

class ProductInfo {
  String? name;
  String? description;
  String? brand;
  List<ProductImage>? images; // <---- IMPORTANT
  bool? isVegetarian;
  String? countryOfOrigin;

  ProductInfo({
    this.name,
    this.description,
    this.brand,
    this.images,
    this.isVegetarian,
    this.countryOfOrigin,
  });

  ProductInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    brand = json['brand'];
    images = json['images'] != null
        ? List<ProductImage>.from(
      json['images'].map((x) => ProductImage.fromJson(x)),
    )
        : [];
    isVegetarian = json['isVegetarian'];
    countryOfOrigin = json['countryOfOrigin'];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'brand': brand,
      'images': images?.map((x) => x.toJson()).toList(),
      'isVegetarian': isVegetarian,
      'countryOfOrigin': countryOfOrigin,
    };
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
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }
}
