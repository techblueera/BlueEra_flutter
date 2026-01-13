class FoodProductModel {
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

  FoodProductModel({
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
    this.tags,
  });

  FoodProductModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    category = json['category'];
    subCategory = json['subCategory'];
    dietaryType = json['dietaryType'];
    cuisineType = json['cuisineType'];
    cookingMethod = json['cookingMethod'];
    ingredients = json['ingredients'] != null ? List<String>.from(json['ingredients']) : [];
    servingInfo = json['servingInfo'] != null ? List<String>.from(json['servingInfo']) : [];
    shelfLife = json['shelfLife'];
    nutritionalInfo = json['nutritionalInfo'] != null
        ? NutritionalInfo.fromJson(json['nutritionalInfo'])
        : null;
    tags = json['tags'] != null ? List<String>.from(json['tags']) : [];
  }
}

class NutritionalInfo {
  int? calories;
  int? protein;
  int? carbs;
  int? fats;
  int? fiber;

  NutritionalInfo({this.calories, this.protein, this.carbs, this.fats, this.fiber});

  NutritionalInfo.fromJson(Map<String, dynamic> json) {
    calories = json['calories'];
    protein = json['protein'];
    carbs = json['carbs'];
    fats = json['fats'];
    fiber = json['fiber'];
  }
}