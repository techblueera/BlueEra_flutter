import 'dart:convert';

FoodHomeResModel foodHomeResModelFromJson(String str) =>
    FoodHomeResModel.fromJson(json.decode(str));

String foodHomeResModelToJson(FoodHomeResModel data) =>
    json.encode(data.toJson());

class FoodHomeResModel {
  FoodHomeResModel({
    this.success,
    this.data,
  });

  FoodHomeResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? FoodData.fromJson(json['data']) : null;
  }

  bool? success;
  FoodData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

FoodData dataFromJson(String str) => FoodData.fromJson(json.decode(str));

String dataToJson(FoodData data) => json.encode(data.toJson());

class FoodData {
  FoodData({
    this.foodMenu,
    this.restaurantSpecials,
    this.gallery,
    this.contact,
  });

  FoodData.fromJson(dynamic json) {
    if (json['foodMenu'] != null) {
      foodMenu = [];
      json['foodMenu'].forEach((v) {
        foodMenu?.add(FoodMenu.fromJson(v));
      });
    }
    if (json['restaurantSpecials'] != null) {
      restaurantSpecials = [];
      // json['restaurantSpecials'].forEach((v) {
      //   restaurantSpecials?.add(Dynamic.fromJson(v));
      // });
    }
    if (json['gallery'] != null) {
      gallery = [];
      json['gallery'].forEach((v) {
        gallery?.add(FoodGallery.fromJson(v));
      });
    }
    contact =
        json['contact'] != null ? FoodContact.fromJson(json['contact']) : null;
  }

  List<FoodMenu>? foodMenu;
  List<dynamic>? restaurantSpecials;
  FoodContact? contact;
  List<FoodGallery>? gallery;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (foodMenu != null) {
      map['foodMenu'] = foodMenu?.map((v) => v.toJson()).toList();
    }
    if (restaurantSpecials != null) {
      map['restaurantSpecials'] =
          restaurantSpecials?.map((v) => v.toJson()).toList();
    }
    if (gallery != null) {
      map['gallery'] = gallery?.map((v) => v.toJson()).toList();
    }

    if (contact != null) {
      map['contact'] = contact?.toJson();
    }
    return map;
  }
}

FoodMenu foodMenuFromJson(String str) => FoodMenu.fromJson(json.decode(str));

String foodMenuToJson(FoodMenu data) => json.encode(data.toJson());

class FoodMenu {
  FoodMenu({
    this.id,
    this.name,
    this.key,
    this.isActive,
    this.parentId,
    this.level,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.subCategories,
  });

  FoodMenu.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    key = json['key'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['subCategories'] != null) {
      subCategories = [];
      json['subCategories'].forEach((v) {
        subCategories?.add(SubCategories.fromJson(v));
      });
    }
  }

  String? id;
  String? name;
  String? key;
  bool? isActive;
  dynamic parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<SubCategories>? subCategories;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['key'] = key;
    map['isActive'] = isActive;
    map['parentId'] = parentId;
    map['level'] = level;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (subCategories != null) {
      map['subCategories'] = subCategories?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

SubCategories subCategoriesFromJson(String str) =>
    SubCategories.fromJson(json.decode(str));

String subCategoriesToJson(SubCategories data) => json.encode(data.toJson());

class SubCategories {
  SubCategories({
    this.id,
    this.name,
    this.key,
    this.type,
    this.isActive,
    this.parentId,
    this.level,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.items,
  });

  SubCategories.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    key = json['key'];
    type = json['type'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['items'] != null) {
      items = [];
      json['items'].forEach((v) {
        items?.add(Items.fromJson(v));
      });
    }
  }

  String? id;
  String? name;
  String? key;
  String? type;
  bool? isActive;
  String? parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<Items>? items;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['key'] = key;
    map['type'] = type;
    map['isActive'] = isActive;
    map['parentId'] = parentId;
    map['level'] = level;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (items != null) {
      map['items'] = items?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

Items itemsFromJson(String str) => Items.fromJson(json.decode(str));

String itemsToJson(Items data) => json.encode(data.toJson());

class Items {
  Items({
    this.id,
    this.businessId,
    this.productVariant,
    this.product,
    this.location,
    this.price,
    this.isAvailable,
    this.preparationTime,
    this.rating,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  Items.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    productVariant = json['productVariant'] != null
        ? ProductVariant.fromJson(json['productVariant'])
        : null;
    product =
        json['product'] != null ? Product.fromJson(json['product']) : null;
    location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
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
  ProductVariant? productVariant;
  Product? product;
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
    if (productVariant != null) {
      map['productVariant'] = productVariant?.toJson();
    }
    if (product != null) {
      map['product'] = product?.toJson();
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

Price priceFromJson(String str) => Price.fromJson(json.decode(str));

String priceToJson(Price data) => json.encode(data.toJson());

class Price {
  Price({
    this.mrp,
    this.sellingPrice,
    this.currency,
    this.packingCharges,
  });

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

Location locationFromJson(String str) => Location.fromJson(json.decode(str));

String locationToJson(Location data) => json.encode(data.toJson());

class Location {
  Location({
    this.type,
    this.coordinates,
    this.address,
    this.pincode,
  });

  Location.fromJson(dynamic json) {
    type = json['type'];
    coordinates =
        json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
    address = json['address'];
    pincode = json['pincode'];
  }

  String? type;
  List<double>? coordinates;
  String? address;
  String? pincode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['coordinates'] = coordinates;
    map['address'] = address;
    map['pincode'] = pincode;
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

ProductVariant productVariantFromJson(String str) =>
    ProductVariant.fromJson(json.decode(str));

String productVariantToJson(ProductVariant data) => json.encode(data.toJson());

class ProductVariant {
  ProductVariant({
    this.id,
    this.variantName,
    this.quantityLabel,
  });

  ProductVariant.fromJson(dynamic json) {
    id = json['_id'];
    variantName = json['variantName'];
    quantityLabel = json['quantityLabel'];
  }

  String? id;
  String? variantName;
  String? quantityLabel;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['variantName'] = variantName;
    map['quantityLabel'] = quantityLabel;
    return map;
  }
}

FoodContact contactFromJson(String str) =>
    FoodContact.fromJson(json.decode(str));

String contactToJson(FoodContact data) => json.encode(data.toJson());

class FoodContact {
  FoodContact({
    this.id,
    this.businessId,
    this.v,
    this.createdAt,
    this.department,
    this.email,
    this.location,
    this.name,
    this.pageLink,
    this.phone,
    this.updatedAt,
  });

  FoodContact.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    department = json['department'];
    email = json['email'];
    location = json['location'] != null ? LocationFood.fromJson(json['location']) : null;
    name = json['name'];
    pageLink = json['pageLink'];
    phone = json['phone'];
    updatedAt = json['updatedAt'];
  }

  String? id;
  String? businessId;
  int? v;
  String? createdAt;
  String? department;
  String? email;
  LocationFood? location;
  String? name;
  String? pageLink;
  String? phone;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['department'] = department;
    map['email'] = email;
    map['location'] = location;
    map['name'] = name;
    map['pageLink'] = pageLink;
    map['phone'] = phone;
    map['updatedAt'] = updatedAt;
    return map;
  }
}

FoodGallery galleryFromJson(String str) =>
    FoodGallery.fromJson(json.decode(str));

String galleryToJson(FoodGallery data) => json.encode(data.toJson());

class FoodGallery {
  FoodGallery({
    this.id,
    this.businessId,
    this.imageUrls,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  FoodGallery.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    imageUrls =
        json['imageUrls'] != null ? json['imageUrls'].cast<String>() : [];
    title = json['title'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }

  String? id;
  String? businessId;
  List<String>? imageUrls;
  String? title;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['imageUrls'] = imageUrls;
    map['title'] = title;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }
}


class LocationFood {
  LocationFood({
    this.name,
    this.type,
    this.coordinates,
  });

  LocationFood.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    // Safely cast the dynamic list to double
    if (json['coordinates'] != null) {
      coordinates = json['coordinates'].cast<double>();
    }
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

  // Helper getters for easier access in UI
  double? get latitude => coordinates != null && coordinates!.isNotEmpty ? coordinates![0] : null;
  double? get longitude => coordinates != null && coordinates!.length > 1 ? coordinates![1] : null;
}
