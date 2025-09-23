class GenerateAiProductContent {
  final String? productName;
  final String? productDescription;
  final String? productCategory;
  final List<String>? features;
  final Specifications? specifications;
  final String? userGuide;
  final List<String>? seoKeywordTags;
  final String? approxMrpInr;
  final List<String>? possibleVariants;
  final String? expiryOrWarranty;

  GenerateAiProductContent({
    this.productName,
    this.productDescription,
    this.productCategory,
    this.features,
    this.specifications,
    this.userGuide,
    this.seoKeywordTags,
    this.approxMrpInr,
    this.possibleVariants,
    this.expiryOrWarranty,
  });

  factory GenerateAiProductContent.fromJson(Map<String, dynamic> json) {
    return GenerateAiProductContent(
      productName: json['product_name'] as String?,
      productDescription: json['product_description'] as String?,
      productCategory: json['product_category'] as String?,
      features: (json['features'] as List<dynamic>?)?.map((e) => e as String).toList(),
      specifications: json['specifications'] != null
          ? Specifications.fromJson(json['specifications'] as Map<String, dynamic>)
          : null,
      userGuide: json['user_guide'] as String?,
      seoKeywordTags: (json['seo_keyword_tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      approxMrpInr: json['approx_mrp_inr'] as String?,
      possibleVariants: (json['possible_variants'] as List<dynamic>?)?.map((e) => e as String).toList(),
      expiryOrWarranty: json['expiry_or_warranty'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'product_description': productDescription,
    'product_category': productCategory,
    'features': features,
    'specifications': specifications?.toJson(),
    'user_guide': userGuide,
    'seo_keyword_tags': seoKeywordTags,
    'approx_mrp_inr': approxMrpInr,
    'possible_variants': possibleVariants,
    'expiry_or_warranty': expiryOrWarranty,
  };

  GenerateAiProductContent copyWith({
    String? productName,
    String? productDescription,
    String? productCategory,
    List<String>? features,
    Specifications? specifications,
    String? userGuide,
    List<String>? seoKeywordTags,
    String? approxMrpInr,
    List<String>? possibleVariants,
    String? expiryOrWarranty,
  }) {
    return GenerateAiProductContent(
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productCategory: productCategory ?? this.productCategory,
      features: features ?? this.features,
      specifications: specifications ?? this.specifications,
      userGuide: userGuide ?? this.userGuide,
      seoKeywordTags: seoKeywordTags ?? this.seoKeywordTags,
      approxMrpInr: approxMrpInr ?? this.approxMrpInr,
      possibleVariants: possibleVariants ?? this.possibleVariants,
      expiryOrWarranty: expiryOrWarranty ?? this.expiryOrWarranty,
    );
  }
}

class Specifications {
  final String? brand;
  final String? volume;
  final String? keyIngredient;
  final String? otherIngredients;
  final String? skinType;
  final String? texture;

  Specifications({
    this.brand,
    this.volume,
    this.keyIngredient,
    this.otherIngredients,
    this.skinType,
    this.texture,
  });

  factory Specifications.fromJson(Map<String, dynamic> json) {
    return Specifications(
      brand: json['Brand'] as String?,
      volume: json['Volume'] as String?,
      keyIngredient: json['Key Ingredient'] as String?,
      otherIngredients: json['Other Ingredients'] as String?,
      skinType: json['Skin Type'] as String?,
      texture: json['Texture'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'Brand': brand,
    'Volume': volume,
    'Key Ingredient': keyIngredient,
    'Other Ingredients': otherIngredients,
    'Skin Type': skinType,
    'Texture': texture,
  };

  Specifications copyWith({
    String? brand,
    String? volume,
    String? keyIngredient,
    String? otherIngredients,
    String? skinType,
    String? texture,
  }) {
    return Specifications(
      brand: brand ?? this.brand,
      volume: volume ?? this.volume,
      keyIngredient: keyIngredient ?? this.keyIngredient,
      otherIngredients: otherIngredients ?? this.otherIngredients,
      skinType: skinType ?? this.skinType,
      texture: texture ?? this.texture,
    );
  }
}
