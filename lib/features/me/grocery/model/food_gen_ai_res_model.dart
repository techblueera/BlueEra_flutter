import 'dart:convert';
FoodGenAiResModel foodGenAiResModelFromJson(String str) => FoodGenAiResModel.fromJson(json.decode(str));
String foodGenAiResModelToJson(FoodGenAiResModel data) => json.encode(data.toJson());
class FoodGenAiResModel {
  FoodGenAiResModel({
      this.success, 
      this.data,});

  FoodGenAiResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(FoodGenAiData.fromJson(v));
      });
    }
  }
  bool? success;
  List<FoodGenAiData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

FoodGenAiData dataFromJson(String str) => FoodGenAiData.fromJson(json.decode(str));
String dataToJson(FoodGenAiData data) => json.encode(data.toJson());
class FoodGenAiData {
  FoodGenAiData({
      this.name, 
      this.description, 
      this.category, 
      this.subCategory, 
      this.dietaryType, 
      this.cuisineType, 
      this.cookingMethod, 
      this.ingredients, 
      this.servingInfo, 
      this.shelfLife, 
      this.nutritionalInfo, 
      this.tags,});

  FoodGenAiData.fromJson(dynamic json) {
    name = json['name'];
    description = json['description'];
    category = json['category'];
    subCategory = json['subCategory'];
    dietaryType = json['dietaryType'];
    cuisineType = json['cuisineType'];
    cookingMethod = json['cookingMethod'];
    ingredients = json['ingredients'] != null ? json['ingredients'].cast<String>() : [];
    servingInfo = json['servingInfo'] != null ? json['servingInfo'].cast<String>() : [];
    shelfLife = json['shelfLife'];
    nutritionalInfo = json['nutritionalInfo'] != null ? NutritionalInfo.fromJson(json['nutritionalInfo']) : null;
    tags = json['tags'] != null ? json['tags'].cast<String>() : [];
  }
  String? name;
  String? description;
  String? category;
  String? subCategory;
  String? dietaryType;
  String? cuisineType;
  String? cookingMethod;
  List<String>? ingredients;
  List<String>? servingInfo;
  String? shelfLife;
  NutritionalInfo? nutritionalInfo;
  List<String>? tags;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['description'] = description;
    map['category'] = category;
    map['subCategory'] = subCategory;
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