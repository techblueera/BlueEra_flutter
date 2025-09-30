import 'dart:convert';
ProductResponse productModelFromJson(String str) => ProductResponse.fromJson(json.decode(str));
String productModelToJson(ProductResponse data) => json.encode(data.toJson());
class ProductResponse {
  ProductResponse({
      this.status, 
      this.message, 
      this.data,});

  ProductResponse.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(ProductData.fromJson(v));
      });
    }
  }
  bool? status;
  String? message;
  List<ProductData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

ProductData dataFromJson(String str) => ProductData.fromJson(json.decode(str));
String dataToJson(ProductData data) => json.encode(data.toJson());
class ProductData {
  ProductData({
      this.product,});

  ProductData.fromJson(dynamic json) {
    product = json['product'] != null ? Product.fromJson(json['product']) : null;
  }
  Product? product;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (product != null) {
      map['product'] = product?.toJson();
    }
    return map;
  }

}

Product productFromJson(String str) => Product.fromJson(json.decode(str));
String productToJson(Product data) => json.encode(data.toJson());
class Product {
  Product({
      this.details, 
      this.sellerCalsification,});

  Product.fromJson(dynamic json) {
    details = json['details'] != null ? Details.fromJson(json['details']) : null;
    sellerCalsification = json['sellerCalsification'] != null ? SellerCalsification.fromJson(json['sellerCalsification']) : null;
  }
  Details? details;
  SellerCalsification? sellerCalsification;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (details != null) {
      map['details'] = details?.toJson();
    }
    if (sellerCalsification != null) {
      map['sellerCalsification'] = sellerCalsification?.toJson();
    }
    return map;
  }

}

SellerCalsification sellerCalsificationFromJson(String str) => SellerCalsification.fromJson(json.decode(str));
String sellerCalsificationToJson(SellerCalsification data) => json.encode(data.toJson());
class SellerCalsification {
  SellerCalsification({
      this.businessLocation, 
      this.id, 
      this.productId, 
      this.businessId, 
      this.variants, 
      this.isActive, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  SellerCalsification.fromJson(dynamic json) {
    businessLocation = json['business_location'] != null ? BusinessLocation.fromJson(json['business_location']) : null;
    id = json['_id'];
    productId = json['product_id'];
    businessId = json['business_id'];
    if (json['variants'] != null) {
      variants = [];
      json['variants'].forEach((v) {
        variants?.add(Variants.fromJson(v));
      });
    }
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  BusinessLocation? businessLocation;
  String? id;
  String? productId;
  String? businessId;
  List<Variants>? variants;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (businessLocation != null) {
      map['business_location'] = businessLocation?.toJson();
    }
    map['_id'] = id;
    map['product_id'] = productId;
    map['business_id'] = businessId;
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    map['isActive'] = isActive;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Variants variantsFromJson(String str) => Variants.fromJson(json.decode(str));
String variantsToJson(Variants data) => json.encode(data.toJson());
class Variants {
  Variants({
      this.attributes, 
      this.stock, 
      this.sellingPrice, 
      this.mediaRelatedToVarient, 
      this.mrp, 
      this.varientIsActive, 
      this.id, 
      this.createdAt, 
      this.updatedAt,});

  Variants.fromJson(dynamic json) {
    attributes = json['attributes'] != null ? Attributes.fromJson(json['attributes']) : null;
    stock = json['stock'];
    sellingPrice = json['sellingPrice'];
    mediaRelatedToVarient = json['media_related_to_varient'] != null ? json['media_related_to_varient'].cast<String>() : [];
    mrp = json['mrp'];
    varientIsActive = json['varientIsActive'];
    id = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  Attributes? attributes;
  bool? stock;
  int? sellingPrice;
  List<String>? mediaRelatedToVarient;
  int? mrp;
  bool? varientIsActive;
  String? id;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (attributes != null) {
      map['attributes'] = attributes?.toJson();
    }
    map['stock'] = stock;
    map['sellingPrice'] = sellingPrice;
    map['media_related_to_varient'] = mediaRelatedToVarient;
    map['mrp'] = mrp;
    map['varientIsActive'] = varientIsActive;
    map['_id'] = id;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

Attributes attributesFromJson(String str) => Attributes.fromJson(json.decode(str));
String attributesToJson(Attributes data) => json.encode(data.toJson());
class Attributes {
  Attributes({
      this.color, 
      this.storage, 
      this.ram,});

  Attributes.fromJson(dynamic json) {
    color = json['color'];
    storage = json['storage'];
    ram = json['ram'];
  }
  String? color;
  String? storage;
  String? ram;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['color'] = color;
    map['storage'] = storage;
    map['ram'] = ram;
    return map;
  }

}

BusinessLocation businessLocationFromJson(String str) => BusinessLocation.fromJson(json.decode(str));
String businessLocationToJson(BusinessLocation data) => json.encode(data.toJson());
class BusinessLocation {
  BusinessLocation({
      this.latitude, 
      this.longitude,});

  BusinessLocation.fromJson(dynamic json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }
  double? latitude;
  double? longitude;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    return map;
  }

}

Details detailsFromJson(String str) => Details.fromJson(json.decode(str));
String detailsToJson(Details data) => json.encode(data.toJson());
class Details {
  Details({
      this.options, 
      this.media, 
      this.tags,
      this.addMoreDetails,
      this.addProductFeatures, 
      this.id, 
      this.name, 
      this.type, 
      this.symbol, 
      this.description, 
      this.brand, 
      this.categoryId, 
      this.productWarranty, 
      this.isReturnable, 
      this.returningDay, 
      this.isPublished, 
      this.mrpPerUnit, 
      this.sku, 
      this.hsn, 
      this.expiryTime, 
      this.linkOrReferralWebsite,});

  Details.fromJson(dynamic json) {

    options: json["options"] == null
            ? []
            : List<dynamic>.from(json["options"]!.map((x) => x));
    media = json['media'] != null ? json['media'].cast<String>() : [];

    tags = json['tags'] != null ? json['tags'].cast<String>() : [];
    if (json['add_more_details'] != null) {
      addMoreDetails = [];
      json['add_more_details'].forEach((v) {
        addMoreDetails?.add(AddMoreDetails.fromJson(v));
      });
    }
    if (json['add_product_features'] != null) {
      addProductFeatures = [];
      json['add_product_features'].forEach((v) {
        addProductFeatures?.add(AddProductFeatures.fromJson(v));
      });
    }
    id = json['id'];
    name = json['name'];
    type = json['type'];
    symbol = json['symbol'];
    description = json['description'];
    brand = json['brand'];
    categoryId = json['category_id'];
    productWarranty = json['product_warranty'];
    isReturnable = json['is_returnable'];
    returningDay = json['returning_day'];
    isPublished = json['is_published'];
    mrpPerUnit = json['mrp_per_unit'];
    sku = json['sku'];
    hsn = json['hsn'];
    expiryTime = json['expiry_time'] != null ? ExpiryTime.fromJson(json['expiry_time']) : null;
    linkOrReferralWebsite = json['link_or_referral_website'];
  }
  List<dynamic>? options;
  List<String>? media;
  List<String>? tags;
  List<AddMoreDetails>? addMoreDetails;
  List<AddProductFeatures>? addProductFeatures;
  String? id;
  String? name;
  String? type;
  String? symbol;
  String? description;
  String? brand;
  String? categoryId;
  String? productWarranty;
  bool? isReturnable;
  int? returningDay;
  bool? isPublished;
  int? mrpPerUnit;
  String? sku;
  String? hsn;
  ExpiryTime? expiryTime;
  dynamic linkOrReferralWebsite;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (options != null) {
      map['options'] = options?.map((v) => v.toJson()).toList();
    }
    map['media'] = media;

    map['tags'] = tags;
    if (addMoreDetails != null) {
      map['add_more_details'] = addMoreDetails?.map((v) => v.toJson()).toList();
    }
    if (addProductFeatures != null) {
      map['add_product_features'] = addProductFeatures?.map((v) => v.toJson()).toList();
    }
    map['id'] = id;
    map['name'] = name;
    map['type'] = type;
    map['symbol'] = symbol;
    map['description'] = description;
    map['brand'] = brand;
    map['category_id'] = categoryId;
    map['product_warranty'] = productWarranty;
    map['is_returnable'] = isReturnable;
    map['returning_day'] = returningDay;
    map['is_published'] = isPublished;
    map['mrp_per_unit'] = mrpPerUnit;
    map['sku'] = sku;
    map['hsn'] = hsn;
    if (expiryTime != null) {
      map['expiry_time'] = expiryTime?.toJson();
    }
    map['link_or_referral_website'] = linkOrReferralWebsite;
    return map;
  }

}

ExpiryTime expiryTimeFromJson(String str) => ExpiryTime.fromJson(json.decode(str));
String expiryTimeToJson(ExpiryTime data) => json.encode(data.toJson());
class ExpiryTime {
  ExpiryTime({
      this.date, 
      this.month, 
      this.year,});

  ExpiryTime.fromJson(dynamic json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
  }
  int? date;
  int? month;
  int? year;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['date'] = date;
    map['month'] = month;
    map['year'] = year;
    return map;
  }

}

AddProductFeatures addProductFeaturesFromJson(String str) => AddProductFeatures.fromJson(json.decode(str));
String addProductFeaturesToJson(AddProductFeatures data) => json.encode(data.toJson());
class AddProductFeatures {
  AddProductFeatures({
      this.title,});

  AddProductFeatures.fromJson(dynamic json) {
    title = json['title'];
  }
  String? title;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    return map;
  }

}

AddMoreDetails addMoreDetailsFromJson(String str) => AddMoreDetails.fromJson(json.decode(str));
String addMoreDetailsToJson(AddMoreDetails data) => json.encode(data.toJson());
class AddMoreDetails {
  AddMoreDetails({
      this.title, 
      this.details,});

  AddMoreDetails.fromJson(dynamic json) {
    title = json['title'];
    details = json['details'];
  }
  String? title;
  String? details;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['details'] = details;
    return map;
  }

}