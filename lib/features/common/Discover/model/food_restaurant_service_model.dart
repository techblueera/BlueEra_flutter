import 'dart:convert';

import '../../../../core/api/model/new_food_home_res_model.dart';
FoodRestaurantServiceModel foodRestaurantServiceModelFromJson(String str) => FoodRestaurantServiceModel.fromJson(json.decode(str));
String foodRestaurantServiceModelToJson(FoodRestaurantServiceModel data) => json.encode(data.toJson());
class FoodRestaurantServiceModel {
  FoodRestaurantServiceModel({
      this.success, 
      this.count, 
      this.totalPages, 
      this.currentPage, 
      this.data,});

  FoodRestaurantServiceModel.fromJson(dynamic json) {
    success = json['success'];
    count = json['count'];
    totalPages = json['totalPages'];
    currentPage = json['currentPage'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(FoodData.fromJson(v));
      });
    }
  }
  bool? success;
  int? count;
  int? totalPages;
  int? currentPage;
  List<FoodData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['count'] = count;
    map['totalPages'] = totalPages;
    map['currentPage'] = currentPage;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/*
Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      this.id, 
      this.name, 
      this.description, 
      this.images, 
      this.category, 
      this.dietaryType, 
      this.cuisineType, 
      this.cookingMethod, 
      this.ingredients, 
      this.servingInfo, 
      this.shelfLife, 
      this.nutritionalInfo, 
      this.tags, 
      this.isActive, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.variants, 
      this.displayPrice, 
      this.displayMrp, 
      this.defaultVariantId,});

  Data.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    images = json['images'] != null ? json['images'].cast<String>() : [];
    category = json['category'] != null ? Category.fromJson(json['category']) : null;
    dietaryType = json['dietaryType'];
    cuisineType = json['cuisineType'];
    cookingMethod = json['cookingMethod'];
    ingredients = json['ingredients'] != null ? json['ingredients'].cast<String>() : [];
    servingInfo = json['servingInfo'] != null ? json['servingInfo'].cast<String>() : [];
    shelfLife = json['shelfLife'];
    nutritionalInfo = json['nutritionalInfo'] != null ? NutritionalInfo.fromJson(json['nutritionalInfo']) : null;
    tags = json['tags'] != null ? json['tags'].cast<String>() : [];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['variants'] != null) {
      variants = [];
      json['variants'].forEach((v) {
        variants?.add(Variants.fromJson(v));
      });
    }
    displayPrice = json['displayPrice'];
    displayMrp = json['displayMrp'];
    defaultVariantId = json['defaultVariantId'];
  }
  String? id;
  String? name;
  String? description;
  List<String>? images;
  Category? category;
  String? dietaryType;
  String? cuisineType;
  String? cookingMethod;
  List<String>? ingredients;
  List<String>? servingInfo;
  String? shelfLife;
  NutritionalInfo? nutritionalInfo;
  List<String>? tags;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<Variants>? variants;
  int? displayPrice;
  int? displayMrp;
  String? defaultVariantId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['images'] = images;
    if (category != null) {
      map['category'] = category?.toJson();
    }
    map['dietaryType'] = dietaryType;
    map['cuisineType'] = cuisineType;
    map['cookingMethod'] = cookingMethod;
    map['ingredients'] = ingredients;
    map['servingInfo'] = servingInfo;
    map['shelfLife'] = shelfLife;
    if (nutritionalInfo != null) {
      map['nutritionalInfo'] = nutritionalInfo?.toJson();
    }
    map['tags'] = tags;
    map['isActive'] = isActive;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    map['displayPrice'] = displayPrice;
    map['displayMrp'] = displayMrp;
    map['defaultVariantId'] = defaultVariantId;
    return map;
  }

}

Variants variantsFromJson(String str) => Variants.fromJson(json.decode(str));
String variantsToJson(Variants data) => json.encode(data.toJson());
class Variants {
  Variants({
      this.id, 
      this.product, 
      this.variantName, 
      this.quantityLabel, 
      this.mrp, 
      this.baseSellingPrice, 
      this.isActive, 
      this.isDefault, 
      this.images, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Variants.fromJson(dynamic json) {
    id = json['_id'];
    product = json['product'];
    variantName = json['variantName'];
    quantityLabel = json['quantityLabel'];
    mrp = json['mrp'];
    baseSellingPrice = json['baseSellingPrice'];
    isActive = json['isActive'];
    isDefault = json['isDefault'];
    if (json['images'] != null) {
      images = [];
      json['images'].forEach((v) {
        // images?.add(Dynamic.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? product;
  String? variantName;
  String? quantityLabel;
  int? mrp;
  int? baseSellingPrice;
  bool? isActive;
  bool? isDefault;
  List<dynamic>? images;
  String? createdAt;
  String? updatedAt;
  int? v;

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
    if (images != null) {
      map['images'] = images?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

NutritionalInfo nutritionalInfoFromJson(String str) => NutritionalInfo.fromJson(json.decode(str));
String nutritionalInfoToJson(NutritionalInfo data) => json.encode(data.toJson());
class NutritionalInfo {
  NutritionalInfo({
      this.calories, 
      this.protein, 
      this.carbs, 
      this.fats, 
      this.fiber,});

  NutritionalInfo.fromJson(dynamic json) {
    calories = json['calories'];
    protein = json['protein'];
    carbs = json['carbs'];
    fats = json['fats'];
    fiber = json['fiber'];
  }
  int? calories;
  int? protein;
  int? carbs;
  int? fats;
  int? fiber;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['calories'] = calories;
    map['protein'] = protein;
    map['carbs'] = carbs;
    map['fats'] = fats;
    map['fiber'] = fiber;
    return map;
  }

}

Category categoryFromJson(String str) => Category.fromJson(json.decode(str));
String categoryToJson(Category data) => json.encode(data.toJson());
class Category {
  Category({
      this.id, 
      this.name,});

  Category.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
  }
  String? id;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    return map;
  }

}*/
