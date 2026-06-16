/// AI-generated product content returned by the "generate via AI" endpoint.
///
/// New response shape:
/// ```json
/// {
///   "productData": { name, type, currencySymbol, description, brand, category,
///       tags[], mrpPerUnit, warranty, isReturnable, returnDays, expiryDuration,
///       guidelines[], additionalDetails[{title, details}], features[{title}],
///       countryOfOrigin, manufacturerDetails{name, address, customerCare} },
///   "variantData": [ { variantName, value, attributes{}, unit, quantity,
///       pricing[{mrp, sellingPrice, currency}], weight, dimensions{l,w,h},
///       specification{}, isActive } ]
/// }
/// ```
class AutomotiveGenerateAiProductContent {
  final AutomotiveAiProductData? productData;
  final List<AutomotiveAiVariantData> variantData;

  AutomotiveGenerateAiProductContent({
    this.productData,
    this.variantData = const [],
  });

  factory AutomotiveGenerateAiProductContent.fromJson(Map<String, dynamic> json) {
    return AutomotiveGenerateAiProductContent(
      productData: json['productData'] != null
          ? AutomotiveAiProductData.fromJson(
              Map<String, dynamic>.from(json['productData']))
          : null,
      variantData: (json['variantData'] as List?)
              ?.map((e) =>
                  AutomotiveAiVariantData.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'productData': productData?.toJson(),
        'variantData': variantData.map((e) => e.toJson()).toList(),
      };

  // ── Convenience accessors used by the Add-AutomotiveProduct (AI) step 2 screen ──────
  String? get productName => productData?.name;
  String? get description => productData?.description;
  String? get brand => productData?.brand;
  String? get category => productData?.category;
  String? get currencySymbol => productData?.currencySymbol;
  String? get countryOfOrigin => productData?.countryOfOrigin;
  num? get mrp => productData?.mrpPerUnit;
  String? get warranty => productData?.warranty;
  String? get durationOfExpiryFromManufacture => productData?.expiryDuration;
  bool get isReturnable => productData?.isReturnable ?? false;
  int get returnDays => productData?.returnDays ?? 0;
  List<String>? get tags => productData?.tags;
  List<String>? get features => productData?.features;
  List<AutomotiveSpecification>? get specifications => productData?.additionalDetails;
  List<String>? get userGuide => productData?.guidelines;
  AutomotiveAiManufacturerDetails? get manufacturerDetails =>
      productData?.manufacturerDetails;

  /// Attribute name → distinct values collected across every variant
  /// (variant attributes + specification). Drives the variant chips shown on
  /// the step 2 review screen. Null when there are no variants.
  Map<String, List<dynamic>>? get variant {
    if (variantData.isEmpty) return null;
    final map = <String, List<dynamic>>{};
    void collect(Map<String, dynamic> src) {
      src.forEach((key, value) {
        if (value == null) return;
        final list = map.putIfAbsent(key, () => <dynamic>[]);
        final str = value.toString();
        if (str.isNotEmpty && !list.contains(str)) list.add(str);
      });
    }

    for (final v in variantData) {
      collect(v.attributes);
      collect(v.specification);
    }
    return map.isEmpty ? null : map;
  }
}

class AutomotiveAiProductData {
  final String? name;
  final String? type;
  final String? currencySymbol;
  final String? description;
  final String? brand;
  final String? category;
  final List<String> tags;
  final num? mrpPerUnit;
  final String? warranty;
  final bool isReturnable;
  final int returnDays;
  final String? expiryDuration;
  final List<String> guidelines;
  final List<AutomotiveSpecification> additionalDetails;
  final List<String> features;
  final String? countryOfOrigin;
  final AutomotiveAiManufacturerDetails? manufacturerDetails;

  AutomotiveAiProductData({
    this.name,
    this.type,
    this.currencySymbol,
    this.description,
    this.brand,
    this.category,
    this.tags = const [],
    this.mrpPerUnit,
    this.warranty,
    this.isReturnable = false,
    this.returnDays = 0,
    this.expiryDuration,
    this.guidelines = const [],
    this.additionalDetails = const [],
    this.features = const [],
    this.countryOfOrigin,
    this.manufacturerDetails,
  });

  factory AutomotiveAiProductData.fromJson(Map<String, dynamic> json) {
    return AutomotiveAiProductData(
      name: json['name'],
      type: json['type'],
      currencySymbol: json['currencySymbol'],
      description: json['description'],
      brand: json['brand'],
      category: json['category'],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      mrpPerUnit: json['mrpPerUnit'],
      warranty: json['warranty'],
      isReturnable: json['isReturnable'] ?? false,
      returnDays: (json['returnDays'] as num?)?.toInt() ?? 0,
      expiryDuration: json['expiryDuration'],
      guidelines:
          (json['guidelines'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      additionalDetails: (json['additionalDetails'] as List?)
              ?.map((e) =>
                  AutomotiveSpecification.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      // features arrive as [{title: ...}] — flatten to plain strings.
      features: (json['features'] as List?)
              ?.map((e) => e is Map
                  ? (e['title']?.toString() ?? '')
                  : e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      countryOfOrigin: json['countryOfOrigin'],
      manufacturerDetails: json['manufacturerDetails'] != null
          ? AutomotiveAiManufacturerDetails.fromJson(
              Map<String, dynamic>.from(json['manufacturerDetails']))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'currencySymbol': currencySymbol,
        'description': description,
        'brand': brand,
        'category': category,
        'tags': tags,
        'mrpPerUnit': mrpPerUnit,
        'warranty': warranty,
        'isReturnable': isReturnable,
        'returnDays': returnDays,
        'expiryDuration': expiryDuration,
        'guidelines': guidelines,
        'additionalDetails':
            additionalDetails.map((e) => e.toJson()).toList(),
        'features': features.map((e) => {'title': e}).toList(),
        'countryOfOrigin': countryOfOrigin,
        'manufacturerDetails': manufacturerDetails?.toJson(),
      };
}

class AutomotiveAiManufacturerDetails {
  final String? name;
  final String? address;
  final String? customerCare;

  AutomotiveAiManufacturerDetails({this.name, this.address, this.customerCare});

  factory AutomotiveAiManufacturerDetails.fromJson(Map<String, dynamic> json) =>
      AutomotiveAiManufacturerDetails(
        name: json['name'],
        address: json['address'],
        customerCare: json['customerCare'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'customerCare': customerCare,
      };
}

class AutomotiveAiVariantData {
  final String? variantName;
  final String? value;
  final Map<String, dynamic> attributes;
  final String? unit;
  final String? quantity;
  final List<AutomotiveAiPricing> pricing;
  final num? weight;
  final AutomotiveAiDimensions? dimensions;
  final Map<String, dynamic> specification;
  final bool isActive;

  AutomotiveAiVariantData({
    this.variantName,
    this.value,
    this.attributes = const {},
    this.unit,
    this.quantity,
    this.pricing = const [],
    this.weight,
    this.dimensions,
    this.specification = const {},
    this.isActive = true,
  });

  factory AutomotiveAiVariantData.fromJson(Map<String, dynamic> json) {
    return AutomotiveAiVariantData(
      variantName: json['variantName'],
      value: json['value'],
      attributes: json['attributes'] != null
          ? Map<String, dynamic>.from(json['attributes'])
          : const {},
      unit: json['unit'],
      quantity: json['quantity']?.toString(),
      pricing: (json['pricing'] as List?)
              ?.map((e) => AutomotiveAiPricing.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      weight: json['weight'],
      dimensions: json['dimensions'] != null
          ? AutomotiveAiDimensions.fromJson(Map<String, dynamic>.from(json['dimensions']))
          : null,
      specification: json['specification'] != null
          ? Map<String, dynamic>.from(json['specification'])
          : const {},
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'variantName': variantName,
        'value': value,
        'attributes': attributes,
        'unit': unit,
        'quantity': quantity,
        'pricing': pricing.map((e) => e.toJson()).toList(),
        'weight': weight,
        'dimensions': dimensions?.toJson(),
        'specification': specification,
        'isActive': isActive,
      };
}

class AutomotiveAiPricing {
  final num? mrp;
  final num? sellingPrice;
  final String? currency;

  AutomotiveAiPricing({this.mrp, this.sellingPrice, this.currency});

  factory AutomotiveAiPricing.fromJson(Map<String, dynamic> json) => AutomotiveAiPricing(
        mrp: json['mrp'],
        sellingPrice: json['sellingPrice'],
        currency: json['currency'],
      );

  Map<String, dynamic> toJson() => {
        'mrp': mrp,
        'sellingPrice': sellingPrice,
        'currency': currency,
      };
}

class AutomotiveAiDimensions {
  final num? length;
  final num? width;
  final num? height;

  AutomotiveAiDimensions({this.length, this.width, this.height});

  factory AutomotiveAiDimensions.fromJson(Map<String, dynamic> json) => AutomotiveAiDimensions(
        length: json['length'],
        width: json['width'],
        height: json['height'],
      );

  Map<String, dynamic> toJson() => {
        'length': length,
        'width': width,
        'height': height,
      };
}

class AutomotiveSpecification {
  final String? title;
  final String? details;

  AutomotiveSpecification({this.title, this.details});

  factory AutomotiveSpecification.fromJson(Map<String, dynamic> json) => AutomotiveSpecification(
        title: json['title'],
        details: json['details'],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'details': details,
      };
}
