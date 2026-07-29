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

  /// Subtree total — this node's products plus every descendant's.
  ///
  /// The one to badge with. See
  /// docs/backend/flutter-categories-levels-and-counts.md §1: counts arrive on
  /// every node in every response mode, and count **active products only**, so
  /// a `0` means "nothing on sale here", not "broken category".
  int productCount = 0;

  /// Products sitting directly ON this node. Usually 0 on a level-0 row while
  /// [productCount] is large — which is exactly why badges must not use it.
  int directProductCount = 0;

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
    this.productCount = 0,
    this.directProductCount = 0,
    this.children,
    this.items,
  });

  /// Anything to show behind this node.
  bool get hasStock => productCount > 0;

  /// True once a subtree has been loaded. Meaningless on a `?level=` row,
  /// where `children` is never sent — use [hasStock] to decide whether a tap
  /// is worthwhile.
  bool get hasChildren => children?.isNotEmpty ?? false;

  /// Worth showing to a merchant browsing for stock: active, and with
  /// something beneath it. §4's "hiding dead ends".
  bool get isSellable => (isActive ?? true) && hasStock;

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
    // `totalProductCount` is documented as an alias of `productCount`; accept
    // either so a payload that ships only one of them still badges.
    productCount =
        _asInt(json['productCount'] ?? json['totalProductCount']) ?? 0;
    directProductCount = _asInt(json['directProductCount']) ?? 0;

    if (json['children'] != null) {
      children = <AutomotiveProductNestedCategoryResponse>[];
      json['children'].forEach((v) {
        // Nested maps from JSON decode come in as Map<dynamic, dynamic>;
        // the recursive ctor needs a typed Map<String, dynamic>.
        children!.add(AutomotiveProductNestedCategoryResponse.fromJson(
          Map<String, dynamic>.from(v as Map),
        ));
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
    // Round-tripped so the Hive-cached level-0 list replays with its badges
    // intact instead of showing 0 until the network refresh lands.
    data['productCount'] = productCount;
    data['directProductCount'] = directProductCount;
    if (children != null) {
      data['children'] = children!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// Counts arrive as numbers, but a `num`/`String` shows up often enough in
/// this codebase's payloads that a hard cast isn't worth the crash.
int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
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