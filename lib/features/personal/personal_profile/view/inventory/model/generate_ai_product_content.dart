class GenerateAiProductContent {
  final String? productName;
  final String? productDescription;
  final String? productCategory;
  final List<String>? features;
  final Specifications? specifications;
  final List<String>? userGuide; // changed to List<String>
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
      userGuide: (json['user_guide'] as List<dynamic>?)?.map((e) => e as String).toList(),
      seoKeywordTags: (json['seo_keyword_tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      approxMrpInr: json['approx_mrp_inr']?.toString(),
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
    List<String>? userGuide,
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
  final String? display;
  final String? processor;
  final String? camera;
  final String? storage;
  final String? operatingSystem;

  Specifications({
    this.display,
    this.processor,
    this.camera,
    this.storage,
    this.operatingSystem,
  });

  factory Specifications.fromJson(Map<String, dynamic> json) {
    return Specifications(
      display: json['Display'] as String?,
      processor: json['Processor'] as String?,
      camera: json['Camera'] as String?,
      storage: json['Storage'] as String?,
      operatingSystem: json['Operating System'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'Display': display,
    'Processor': processor,
    'Camera': camera,
    'Storage': storage,
    'Operating System': operatingSystem,
  };

  Specifications copyWith({
    String? display,
    String? processor,
    String? camera,
    String? storage,
    String? operatingSystem,
  }) {
    return Specifications(
      display: display ?? this.display,
      processor: processor ?? this.processor,
      camera: camera ?? this.camera,
      storage: storage ?? this.storage,
      operatingSystem: operatingSystem ?? this.operatingSystem,
    );
  }
}
