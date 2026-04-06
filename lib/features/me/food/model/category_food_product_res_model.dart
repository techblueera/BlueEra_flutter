import 'dart:convert';

CategoryFoodProductData dataFromJson(String str) => CategoryFoodProductData.fromJson(json.decode(str));
String dataToJson(CategoryFoodProductData data) => json.encode(data.toJson());
class CategoryFoodProductData {
  CategoryFoodProductData({
      this.id,
      this.name, 
      this.images, 
      this.category, 
      this.dietaryType, 
      this.description,
      this.cookingMethod,
      this.ingredients, 
      this.servingInfo, 
      this.nutritionalInfo, 
      this.tags, 
      this.isActive, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.displayPrice, 
      this.displayMrp, 
      this.variants,
      this.variantId,});

  CategoryFoodProductData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    images = json['images'] != null ? json['images'].cast<String>() : [];
    category = json['category'] != null ? Category.fromJson(json['category']) : null;
    dietaryType = json['dietaryType'];
    description = json['description'];
    cookingMethod = json['cookingMethod'] != null ? json['cookingMethod'].cast<String>() : [];
    ingredients = json['ingredients'] != null ? json['ingredients'].cast<String>() : [];
    if (json['servingInfo'] != null) {
      servingInfo = [];
      json['servingInfo'].forEach((v) {
        // servingInfo?.add(Dynamic.fromJson(v));
      });
    }
    nutritionalInfo = json['nutritionalInfo'] != null ? NutritionalInfo.fromJson(json['nutritionalInfo']) : null;
    if (json['tags'] != null) {
      tags = [];
      json['tags'].forEach((v) {
        // tags?.add(Dynamic.fromJson(v));
      });
    }
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    displayPrice = json['displayPrice'];
    displayMrp = json['displayMrp'];
    variantId = json['variantId'];
    if (json['variants'] != null) {
      variants = [];
      json['variants'].forEach((v) {
        variants?.add(FoodVariants.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  List<String>? images;
  Category? category;
  String? dietaryType;
  String? description;
  List<String>? cookingMethod;
  List<String>? ingredients;
  List<dynamic>? servingInfo;
  NutritionalInfo? nutritionalInfo;
  List<dynamic>? tags;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;
  num? displayPrice;
  int? displayMrp;
  String? variantId;
  List<FoodVariants>? variants;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    map['_id'] = id;
    map['name'] = name;
    map['images'] = images;
    if (category != null) {
      map['category'] = category?.toJson();
    }
    map['dietaryType'] = dietaryType;
    map['description'] = description;
    map['cookingMethod'] = cookingMethod;
    map['ingredients'] = ingredients;
    if (servingInfo != null) {
      map['servingInfo'] = servingInfo?.map((v) => v.toJson()).toList();
    }
    if (nutritionalInfo != null) {
      map['nutritionalInfo'] = nutritionalInfo?.toJson();
    }
    if (tags != null) {
      map['tags'] = tags?.map((v) => v.toJson()).toList();
    }
    map['isActive'] = isActive;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['displayPrice'] = displayPrice;
    map['displayMrp'] = displayMrp;
    map['variantId'] = variantId;
    return map;
  }

  CategoryFoodProductData copyWith({
    String? id,
    String? name,
    List<String>? images,
    Category? category,
    String? dietaryType,
    String? description,
    List<String>? cookingMethod,
    List<String>? ingredients,
    List<dynamic>? servingInfo,
    NutritionalInfo? nutritionalInfo,
    List<dynamic>? tags,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    int? v,
    int? displayPrice,
    int? displayMrp,
    String? variantId,
    List<FoodVariants>? variants,
  }) {
    return CategoryFoodProductData(
      id: id ?? this.id,
      name: name ?? this.name,
      images: images ?? this.images,
      category: category ?? this.category,
      dietaryType: dietaryType ?? this.dietaryType,
      description: description ?? this.description,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      ingredients: ingredients ?? this.ingredients,
      servingInfo: servingInfo ?? this.servingInfo,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
      displayPrice: displayPrice ?? this.displayPrice,
      displayMrp: displayMrp ?? this.displayMrp,
      variantId: variantId ?? this.variantId,
      variants: variants ?? this.variants,
    );
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
  num? calories;
  num? protein;
  num? carbs;
  num? fats;
  num? fiber;

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

}

FoodVariants variantsFromJson(String str) => FoodVariants.fromJson(json.decode(str));
String variantsToJson(FoodVariants data) => json.encode(data.toJson());
class FoodVariants {
  FoodVariants({
    this.id,
    this.product,
    this.variantName,
    this.quantityLabel,
    this.mrp,
    this.baseSellingPrice,
    this.isActive,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
    this.v,});

  FoodVariants.fromJson(dynamic json) {
    id = json['_id'];
    product = json['product'];
    variantName = json['variantName'];
    quantityLabel = json['quantityLabel'];
    mrp = json['mrp'];
    baseSellingPrice = json['baseSellingPrice'];
    isActive = json['isActive'];
    isDefault = json['isDefault'];

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
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

  FoodVariants copyWith({
    String? id,
    String? product,
    String? variantName,
    String? quantityLabel,
    int? mrp,
    int? baseSellingPrice,
    bool? isActive,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
    int? v,
  }) {
    return FoodVariants(
      id: id ?? this.id,
      product: product ?? this.product,
      variantName: variantName ?? this.variantName,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      mrp: mrp ?? this.mrp,
      baseSellingPrice: baseSellingPrice ?? this.baseSellingPrice,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

}