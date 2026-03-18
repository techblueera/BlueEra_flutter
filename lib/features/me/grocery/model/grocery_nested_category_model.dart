import 'dart:convert';

class GroceryNestedCategoryModel {
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
  List<GroceryNestedCategoryModel>? children;
  List<Items>? items;

  GroceryNestedCategoryModel({
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

  GroceryNestedCategoryModel.fromJson(Map<String, dynamic> json) {
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
      children = <GroceryNestedCategoryModel>[];
      json['children'].forEach((v) {
        children!.add(GroceryNestedCategoryModel.fromJson(v));
      });
    }

    if (json['items'] != null) {
      items = [];
      json['items'].forEach((v) {
        items?.add(Items.fromJson(v));
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

Items itemsFromJson(String str) => Items.fromJson(json.decode(str));
String itemsToJson(Items data) => json.encode(data.toJson());
class Items {
  Items({
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

  Items.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    product = json['product'] != null ? Product.fromJson(json['product']) : null;
    if (json['variants'] != null) {
      variants = [];
      json['variants'].forEach((v) {
        variants!.add(InventoryVariant.fromJson(v));
      });
    }
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    price = json['price'] != null ? Price.fromJson(json['price']) : null;
    isAvailable = json['isAvailable'];
    preparationTime = json['preparationTime'];
    rating = json['rating'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  Product? product;
  List<InventoryVariant>? variants;
  Location? location;
  Price? price;
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

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
    this.name,
    this.type,
    this.coordinates,});

  Location.fromJson(dynamic json) {
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


Price priceFromJson(String str) => Price.fromJson(json.decode(str));
String priceToJson(Price data) => json.encode(data.toJson());
class Price {
  Price({
    this.mrp,
    this.sellingPrice,
    this.currency,
    this.packingCharges,});

  Price.fromJson(dynamic json) {
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


Product productFromJson(String str) => Product.fromJson(json.decode(str));
String productToJson(Product data) => json.encode(data.toJson());
class Product {
  Product({
    this.id,
    this.name,
    this.description,
    this.images,
    this.dietaryType,
  });

  Product.fromJson(dynamic json) {
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


class InventoryVariant {
  String? id;
  ProductVariant? productVariant;
  Price? price;
  int? preparationTime;
  List<String>? cookingMethod;
  bool? isAvailable;
  num? rating;

  InventoryVariant({
    this.id,
    this.productVariant,
    this.price,
    this.preparationTime,
    this.cookingMethod,
    this.isAvailable,
    this.rating,
  });

  InventoryVariant.fromJson(dynamic json) {
    id = json['_id'];
    productVariant = json['productVariant'] != null
        ? ProductVariant.fromJson(json['productVariant'])
        : null;
    price = json['price'] != null ? Price.fromJson(json['price']) : null;
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

class ProductVariant {
  String? id;
  String? product;
  String? variantName;
  String? quantityLabel;
  num? mrp;
  num? baseSellingPrice;
  bool? isActive;
  bool? isDefault;
  List<String>? images;

  ProductVariant({
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

  ProductVariant.fromJson(dynamic json) {
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