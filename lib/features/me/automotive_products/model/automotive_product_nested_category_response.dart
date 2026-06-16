import 'dart:convert';

class AutomotiveProductNestedCategoryResponse {
  String? sId;
  String? name;
  String? key;
  bool? isActive;
  String? parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? description;
  String? image;
  List<AutomotiveProductNestedCategoryResponse>? children;
  List<AutomotiveItems>? items;

  AutomotiveProductNestedCategoryResponse({
    this.sId,
    this.name,
    this.key,
    this.isActive,
    this.parentId,
    this.level,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.description,
    this.image,
    this.children,
    this.items,
  });

  AutomotiveProductNestedCategoryResponse.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    key = json['key'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    description = json['description'];
    image = json['image'];

    if (json['children'] != null) {
      children = <AutomotiveProductNestedCategoryResponse>[];
      json['children'].forEach((v) {
        children!.add(AutomotiveProductNestedCategoryResponse.fromJson(v));
      });
    }

    if (json['items'] != null) {
      items = [];
      json['items'].forEach((v) {
        items?.add(AutomotiveItems.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['key'] = key;
    data['isActive'] = isActive;
    data['parentId'] = parentId;
    data['level'] = level;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['description'] = description;
    data['image'] = image;
    if (children != null) {
      data['children'] = children!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

AutomotiveItems itemsFromJson(String str) => AutomotiveItems.fromJson(json.decode(str));
String itemsToJson(AutomotiveItems data) => json.encode(data.toJson());
class AutomotiveItems {
  AutomotiveItems({
    this.id,
    this.businessId,
    this.product,
    this.variants,
    this.location,
    this.price,
    this.isAvailable,
    this.preparationTime,
    this.rating,
    this.createdAt,
    this.updatedAt,
    this.v,});

  AutomotiveItems.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    product = json['product'] != null ? AutomotiveProduct.fromJson(json['product']) : null;
    if (json['variants'] != null) {
      variants = [];
      json['variants'].forEach((v) {
        variants!.add(AutomotiveInventoryVariant.fromJson(v));
      });
    }
    location = json['location'] != null ? AutomotiveLocation.fromJson(json['location']) : null;
    price = json['price'] != null ? AutomotivePrice.fromJson(json['price']) : null;
    isAvailable = json['isAvailable'];
    preparationTime = json['preparationTime'];
    rating = json['rating'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  AutomotiveProduct? product;
  List<AutomotiveInventoryVariant>? variants;
  AutomotiveLocation? location;
  AutomotivePrice? price;
  bool? isAvailable;
  int? preparationTime;
  int? rating;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    if (product != null) {
      map['product'] = product?.toJson();
    }
    if (variants != null) {
      map['variants'] = variants!.map((v) => v.toJson()).toList();
    }
    if (location != null) {
      map['location'] = location?.toJson();
    }
    if (price != null) {
      map['price'] = price?.toJson();
    }
    map['isAvailable'] = isAvailable;
    map['preparationTime'] = preparationTime;
    map['rating'] = rating;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

AutomotiveLocation locationFromJson(String str) => AutomotiveLocation.fromJson(json.decode(str));
String locationToJson(AutomotiveLocation data) => json.encode(data.toJson());
class AutomotiveLocation {
  AutomotiveLocation({
    this.name,
    this.type,
    this.coordinates,});

  AutomotiveLocation.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }
  String? name;
  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

}


AutomotivePrice priceFromJson(String str) => AutomotivePrice.fromJson(json.decode(str));
String priceToJson(AutomotivePrice data) => json.encode(data.toJson());
class AutomotivePrice {
  AutomotivePrice({
    this.mrp,
    this.sellingPrice,
    this.currency,
    this.packingCharges,});

  AutomotivePrice.fromJson(dynamic json) {
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
    currency = json['currency'];
    packingCharges = json['packingCharges'];
  }
  int? mrp;
  int? sellingPrice;
  String? currency;
  int? packingCharges;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['mrp'] = mrp;
    map['sellingPrice'] = sellingPrice;
    map['currency'] = currency;
    map['packingCharges'] = packingCharges;
    return map;
  }

}


AutomotiveProduct productFromJson(String str) => AutomotiveProduct.fromJson(json.decode(str));
String productToJson(AutomotiveProduct data) => json.encode(data.toJson());
class AutomotiveProduct {
  AutomotiveProduct({
    this.id,
    this.name,
    this.description,
    this.images,
    this.dietaryType,
  });

  AutomotiveProduct.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    images = json['images'] != null ? json['images'].cast<String>() : [];
    dietaryType = json['dietaryType'];

  }
  String? id;
  String? name;
  String? description;
  List<String>? images;
  String? dietaryType;


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['images'] = images;
    map['dietaryType'] = dietaryType;
    return map;
  }

}


class AutomotiveInventoryVariant {
  String? id;
  AutomotiveProductVariant? productVariant;
  AutomotivePrice? price;
  int? preparationTime;
  List<String>? cookingMethod;
  bool? isAvailable;
  num? rating;

  AutomotiveInventoryVariant({
    this.id,
    this.productVariant,
    this.price,
    this.preparationTime,
    this.cookingMethod,
    this.isAvailable,
    this.rating,
  });

  AutomotiveInventoryVariant.fromJson(dynamic json) {
    id = json['_id'];
    productVariant = json['productVariant'] != null
        ? AutomotiveProductVariant.fromJson(json['productVariant'])
        : null;
    price = json['price'] != null ? AutomotivePrice.fromJson(json['price']) : null;
    preparationTime = json['preparationTime'];
    cookingMethod = json['cookingMethod'] != null ? json['cookingMethod'].cast<String>() : [];
    isAvailable = json['isAvailable'];
    rating = json['rating'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    if (productVariant != null) map['productVariant'] = productVariant!.toJson();
    if (price != null) map['price'] = price!.toJson();
    map['preparationTime'] = preparationTime;
    map['cookingMethod'] = cookingMethod;
    map['isAvailable'] = isAvailable;
    map['rating'] = rating;
    return map;
  }
}

class AutomotiveProductVariant {
  String? id;
  String? product;
  String? variantName;
  String? quantityLabel;
  num? mrp;
  num? baseSellingPrice;
  bool? isActive;
  bool? isDefault;
  List<String>? images;

  AutomotiveProductVariant({
    this.id,
    this.product,
    this.variantName,
    this.quantityLabel,
    this.mrp,
    this.baseSellingPrice,
    this.isActive,
    this.isDefault,
    this.images,
  });

  AutomotiveProductVariant.fromJson(dynamic json) {
    id = json['_id'];
    product = json['product'];
    variantName = json['variantName'];
    quantityLabel = json['quantityLabel'];
    mrp = json['mrp'];
    baseSellingPrice = json['baseSellingPrice'];
    isActive = json['isActive'];
    isDefault = json['isDefault'];
    images = json['images'] != null ? json['images'].cast<String>() : [];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['product'] = product;
    map['variantName'] = variantName;
    map['quantityLabel'] = quantityLabel;
    map['mrp'] = mrp;
    map['baseSellingPrice'] = baseSellingPrice;
    map['isActive'] = isActive;
    map['isDefault'] = isDefault;
    map['images'] = images;
    return map;
  }
}