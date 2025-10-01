class FoodModel {
  String? id;
  String? userId;
  String? type;
  String? title;
  String? description;
  List<String>? photos;
  String? category;
  String? subCategory;
  List<String>? addOns;
  List<String>? keyIngredients;
  List<ServingOption>? servingOptions;
  List<String>? accompaniments;
  NutritionalSummary? nutritionalSummaryPer100g;
  List<String>? keyMinerals;
  List<String>? seoTags;
  List<String>? facilities;
  String? priceType;
  int? singlePrice;
  bool? isActive;
  bool? isDeleted;
  List<String>? variants;
  List<String>? timings;
  List<String>? priceOptions;
  List<String>? discounts;
  List<String>? extraDetails;
  String? createdAt;
  String? updatedAt;

  FoodModel({
    this.id,
    this.userId,
    this.type,
    this.title,
    this.description,
    this.photos,
    this.category,
    this.subCategory,
    this.addOns,
    this.keyIngredients,
    this.servingOptions,
    this.accompaniments,
    this.nutritionalSummaryPer100g,
    this.keyMinerals,
    this.seoTags,
    this.facilities,
    this.priceType,
    this.singlePrice,
    this.isActive,
    this.isDeleted,
    this.variants,
    this.timings,
    this.priceOptions,
    this.discounts,
    this.extraDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json["_id"],
      userId: json["userId"],
      type: json["type"],
      title: json["title"],
      description: json["description"],
      photos: List<String>.from(json["photos"] ?? []),
      category: json["category"],
      subCategory: json["subCategory"],
      addOns: List<String>.from(json["addOns"] ?? []),
      keyIngredients: List<String>.from(json["keyIngredients"] ?? []),
      servingOptions: (json["servingOptions"] as List? ?? [])
          .map((e) => ServingOption.fromJson(e))
          .toList(),
      accompaniments: List<String>.from(json["accompaniments"] ?? []),
      nutritionalSummaryPer100g: json["nutritionalSummary_per100g"] != null
          ? NutritionalSummary.fromJson(json["nutritionalSummary_per100g"])
          : null,
      keyMinerals: List<String>.from(json["keyMinerals"] ?? []),
      seoTags: List<String>.from(json["seoTags"] ?? []),
      facilities: List<String>.from(json["facilities"] ?? []),
      priceType: json["priceType"],
      singlePrice: json["singlePrice"],
      isActive: json["isActive"],
      isDeleted: json["isDeleted"],
      variants: List<String>.from(json["variants"] ?? []),
      timings: List<String>.from(json["timings"] ?? []),
      priceOptions: List<String>.from(json["priceOptions"] ?? []),
      discounts: List<String>.from(json["discounts"] ?? []),
      extraDetails: List<String>.from(json["extraDetails"] ?? []),
      createdAt: json["createdAt"],
      updatedAt: json["updatedAt"],
    );
  }
}

class ServingOption {
  String? size;
  int? serves;

  ServingOption({this.size, this.serves});

  factory ServingOption.fromJson(Map<String, dynamic> json) {
    return ServingOption(
      size: json["size"],
      serves: json["serves"],
    );
  }
}

class NutritionalSummary {
  String? caloriesKcal;
  String? proteinG;
  String? carbsG;
  String? fatG;

  NutritionalSummary({this.caloriesKcal, this.proteinG, this.carbsG, this.fatG});

  factory NutritionalSummary.fromJson(Map<String, dynamic> json) {
    return NutritionalSummary(
      caloriesKcal: json["calories_kcal"],
      proteinG: json["protein_g"],
      carbsG: json["carbs_g"],
      fatG: json["fat_g"],
    );
  }
}
