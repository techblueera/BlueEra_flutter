import 'dart:convert';
FoodAiResModel foodAiResModelFromJson(String str) => FoodAiResModel.fromJson(json.decode(str));
String foodAiResModelToJson(FoodAiResModel data) => json.encode(data.toJson());
class FoodAiResModel {
  FoodAiResModel({
      this.productName, 
      this.shortDescription, 
      this.category, 
      this.cuisine, 
      this.shelfLife, 
      this.keyIngredients, 
      this.servingOptions, 
      this.accompaniments, 
      this.nutritionalSummaryPer100g, 
      this.keyMinerals, 
      this.seoTags,});

  FoodAiResModel.fromJson(dynamic json) {
    productName = json['productName'];
    shortDescription = json['shortDescription'];
    category = json['category'];
    cuisine = json['cuisine'];
    shelfLife = json['shelfLife'];
    keyIngredients = json['keyIngredients'] != null ? json['keyIngredients'].cast<String>() : [];
    if (json['servingOptions'] != null) {
      servingOptions = [];
      json['servingOptions'].forEach((v) {
        servingOptions?.add(ServingOptions.fromJson(v));
      });
    }
    accompaniments = json['accompaniments'] != null ? json['accompaniments'].cast<String>() : [];
    nutritionalSummaryPer100g = json['nutritionalSummary_per100g'] != null ? NutritionalSummaryPer100g.fromJson(json['nutritionalSummary_per100g']) : null;
    keyMinerals = json['keyMinerals'] != null ? json['keyMinerals'].cast<String>() : [];
    seoTags = json['seoTags'] != null ? json['seoTags'].cast<String>() : [];
  }
  String? productName;
  String? shortDescription;
  String? category;
  String? cuisine;
  String? shelfLife;
  List<String>? keyIngredients;
  List<ServingOptions>? servingOptions;
  List<String>? accompaniments;
  NutritionalSummaryPer100g? nutritionalSummaryPer100g;
  List<String>? keyMinerals;
  List<String>? seoTags;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['productName'] = productName;
    map['shortDescription'] = shortDescription;
    map['category'] = category;
    map['cuisine'] = cuisine;
    map['shelfLife'] = shelfLife;
    map['keyIngredients'] = keyIngredients;
    if (servingOptions != null) {
      map['servingOptions'] = servingOptions?.map((v) => v.toJson()).toList();
    }
    map['accompaniments'] = accompaniments;
    if (nutritionalSummaryPer100g != null) {
      map['nutritionalSummary_per100g'] = nutritionalSummaryPer100g?.toJson();
    }
    map['keyMinerals'] = keyMinerals;
    map['seoTags'] = seoTags;
    return map;
  }

}

NutritionalSummaryPer100g nutritionalSummaryPer100gFromJson(String str) => NutritionalSummaryPer100g.fromJson(json.decode(str));
String nutritionalSummaryPer100gToJson(NutritionalSummaryPer100g data) => json.encode(data.toJson());
class NutritionalSummaryPer100g {
  NutritionalSummaryPer100g({
      this.caloriesKcal, 
      this.proteinG, 
      this.carbsG, 
      this.fatG,});

  NutritionalSummaryPer100g.fromJson(dynamic json) {
    caloriesKcal = json['calories_kcal'];
    proteinG = json['protein_g'];
    carbsG = json['carbs_g'];
    fatG = json['fat_g'];
  }
  String? caloriesKcal;
  String? proteinG;
  String? carbsG;
  String? fatG;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['calories_kcal'] = caloriesKcal;
    map['protein_g'] = proteinG;
    map['carbs_g'] = carbsG;
    map['fat_g'] = fatG;
    return map;
  }

}

ServingOptions servingOptionsFromJson(String str) => ServingOptions.fromJson(json.decode(str));
String servingOptionsToJson(ServingOptions data) => json.encode(data.toJson());
class ServingOptions {
  ServingOptions({
      this.size, 
      this.serves,});

  ServingOptions.fromJson(dynamic json) {
    size = json['size'];
    serves = json['serves'];
  }
  String? size;
  int? serves;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['size'] = size;
    map['serves'] = serves;
    return map;
  }

}