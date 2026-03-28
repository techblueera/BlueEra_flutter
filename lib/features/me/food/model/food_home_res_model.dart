import 'dart:convert';

import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/food/model/food_category_res_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_nested_category_model.dart';
FoodHomeResModel newFoodHomeResModelFromJson(String str) => FoodHomeResModel.fromJson(json.decode(str));
String newFoodHomeResModelToJson(FoodHomeResModel data) => json.encode(data.toJson());
class FoodHomeResModel {
  FoodHomeResModel({
    this.success,
    this.data,});

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
    this.businessProfileDetails,
    this.restaurantSpecials,
    this.gallery,
    this.contact,});

  FoodData.fromJson(dynamic json) {
    businessProfileDetails = json['businessProfile'] != null ? BusinessProfileDetails.fromJson(json['businessProfile']) : null;
    if (json['foodMenu'] != null) {
      foodMenu = [];
      json['foodMenu'].forEach((v) {
        foodMenu?.add(GroceryNestedCategoryModel.fromJson(v));
      });
    }
    if (json['restaurantSpecials'] != null) {
      restaurantSpecials = [];
      json['restaurantSpecials'].forEach((v) {
        restaurantSpecials?.add(RestaurantSpecial.fromJson(v));
      });
    }
    if (json['gallery'] != null) {
      gallery = [];
      json['gallery'].forEach((v) {
        gallery?.add(FoodGallery.fromJson(v));
      });
    }
    contact = json['contact'] != null ? FoodContact.fromJson(json['contact']) : null;
  }
  BusinessProfileDetails? businessProfileDetails;
  List<GroceryNestedCategoryModel>? foodMenu;
  List<RestaurantSpecial>? restaurantSpecials;
  List<FoodGallery>? gallery;
  FoodContact? contact;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (foodMenu != null) {
      map['foodMenu'] = foodMenu?.map((v) => v.toJson()).toList();
    }
    if (restaurantSpecials != null) {
      map['restaurantSpecials'] = restaurantSpecials?.map((v) => v.toJson()).toList();
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

FoodContact contactFromJson(String str) => FoodContact.fromJson(json.decode(str));
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
    this.updatedAt,});

  FoodContact.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    department = json['department'];
    email = json['email'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
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
  Location? location;
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
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['name'] = name;
    map['pageLink'] = pageLink;
    map['phone'] = phone;
    map['updatedAt'] = updatedAt;
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

FoodGallery galleryFromJson(String str) => FoodGallery.fromJson(json.decode(str));
String galleryToJson(FoodGallery data) => json.encode(data.toJson());
class FoodGallery {
  FoodGallery({
    this.id,
    this.businessId,
    this.imageUrls,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.v,});

  FoodGallery.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    imageUrls = json['imageUrls'] != null ? json['imageUrls'].cast<String>() : [];
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

SubCategories subCategoriesFromJson(String str) => SubCategories.fromJson(json.decode(str));
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
    this.image,
    this.subSubCategories});

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
    image = json['image'];
    if (json['subSubCategories'] != null) {
      subSubCategories = [];
      json['subSubCategories'].forEach((v) {
        subSubCategories?.add(SubSubCategories.fromJson(v));
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
  String? image;
  List<SubSubCategories>? subSubCategories;

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
    map['image'] = image;
    if (subSubCategories != null) {
      map['subSubCategories'] = subSubCategories?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

SubSubCategories subSubCategoriesFromJson(String str) => SubSubCategories.fromJson(json.decode(str));
String subSubCategoriesToJson(SubCategories data) => json.encode(data.toJson());
class SubSubCategories {
  SubSubCategories({
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
    this.image,
    this.items,});

  SubSubCategories.fromJson(dynamic json) {
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
    image = json['image'];
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
  String? image;
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
    map['image'] = image;
    if (items != null) {
      map['items'] = items?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

class RestaurantSpecial {
  RestaurantSpecial({
    this.id,
    this.name,
    this.description,
    this.image,
    this.rating,
  });

  RestaurantSpecial.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    image = json['image'];
    rating = json['rating'];
  }

  String? id;
  String? name;
  String? description;
  String? image;
  num? rating;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['image'] = image;
    map['rating'] = rating;
    return map;
  }
}

