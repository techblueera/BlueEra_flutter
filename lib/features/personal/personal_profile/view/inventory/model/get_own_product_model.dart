class GetOwnProductModel {
  final bool status;
  final String message;
  final List<OwnProductData> data;

  GetOwnProductModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory GetOwnProductModel.fromJson(Map<String, dynamic> json) {
    return GetOwnProductModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => OwnProductData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class OwnProductData {
  final Product product;

  OwnProductData({required this.product});

  factory OwnProductData.fromJson(Map<String, dynamic> json) {
    return OwnProductData(
      product: Product.fromJson(json['product'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
    };
  }
}

class Product {
  final ProductDetails? details;
  final SellerClassification? sellerClassification;

  Product({
    this.details,
    this.sellerClassification,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      details:
      json['details'] != null ? ProductDetails.fromJson(json['details']) : null,
      sellerClassification: json['sellerCalsification'] != null
          ? SellerClassification.fromJson(json['sellerCalsification'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'details': details?.toJson(),
      'sellerCalsification': sellerClassification?.toJson(),
    };
  }
}

class ProductDetails {
  final List<ProductOption> options;
  final List<String> media;
  final List<String> videoUrl;
  final List<String> tags;
  final List<AddMoreDetail> addMoreDetails;
  final List<ProductFeature> addProductFeatures;
  final String id;
  final String name;
  final String type;
  final String symbol;
  final String description;
  final String brand;
  final String categoryId;
  final String productWarranty;
  final bool isReturnable;
  final int returningDay;
  final bool isPublished;
  final num mrpPerUnit;
  final String sku;
  final String hsn;

  ProductDetails({
    required this.options,
    required this.media,
    required this.videoUrl,
    required this.tags,
    required this.addMoreDetails,
    required this.addProductFeatures,
    required this.id,
    required this.name,
    required this.type,
    required this.symbol,
    required this.description,
    required this.brand,
    required this.categoryId,
    required this.productWarranty,
    required this.isReturnable,
    required this.returningDay,
    required this.isPublished,
    required this.mrpPerUnit,
    required this.sku,
    required this.hsn,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => ProductOption.fromJson(e))
          .toList(),
      media: List<String>.from(json['media'] ?? []),
      videoUrl: List<String>.from(json['video_url'] ?? []),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      addMoreDetails: (json['add_more_details'] as List<dynamic>? ?? [])
          .map((e) => AddMoreDetail.fromJson(e))
          .toList(),
      addProductFeatures:
      (json['add_product_features'] as List<dynamic>? ?? [])
          .map((e) => ProductFeature.fromJson(e))
          .toList(),
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      categoryId: json['category_id'] ?? '',
      productWarranty: json['product_warranty'] ?? '',
      isReturnable: json['is_returnable'] ?? false,
      returningDay: json['returning_day'] ?? 0,
      isPublished: json['is_published'] ?? false,
      mrpPerUnit: json['mrp_per_unit'] ?? 0,
      sku: json['sku'] ?? '',
      hsn: json['hsn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'options': options.map((e) => e.toJson()).toList(),
      'media': media,
      'video_url': videoUrl,
      'tags': tags,
      'add_more_details': addMoreDetails.map((e) => e.toJson()).toList(),
      'add_product_features':
      addProductFeatures.map((e) => e.toJson()).toList(),
      'id': id,
      'name': name,
      'type': type,
      'symbol': symbol,
      'description': description,
      'brand': brand,
      'category_id': categoryId,
      'product_warranty': productWarranty,
      'is_returnable': isReturnable,
      'returning_day': returningDay,
      'is_published': isPublished,
      'mrp_per_unit': mrpPerUnit,
      'sku': sku,
      'hsn': hsn,
    };
  }
}

class ProductOption {
  final List<String> value;
  final String attribute;

  ProductOption({required this.value, required this.attribute});

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      value: List<String>.from(json['value'] ?? []),
      attribute: json['attribute'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'attribute': attribute,
    };
  }
}

class AddMoreDetail {
  final String title;
  final String details;

  AddMoreDetail({required this.title, required this.details});

  factory AddMoreDetail.fromJson(Map<String, dynamic> json) {
    return AddMoreDetail(
      title: json['title'] ?? '',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'details': details,
    };
  }
}

class ProductFeature {
  final String title;

  ProductFeature({required this.title});

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }
}

class SellerClassification {
  final String id;
  final String productId;
  final String businessId;
  final List<Variant> variants;
  final bool isActive;

  SellerClassification({
    required this.id,
    required this.productId,
    required this.businessId,
    required this.variants,
    required this.isActive,
  });

  factory SellerClassification.fromJson(Map<String, dynamic> json) {
    return SellerClassification(
      id: json['_id'] ?? '',
      productId: json['product_id'] ?? '',
      businessId: json['business_id'] ?? '',
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((e) => Variant.fromJson(e))
          .toList(),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'product_id': productId,
      'business_id': businessId,
      'variants': variants.map((e) => e.toJson()).toList(),
      'isActive': isActive,
    };
  }
}

class Variant {
  final Map<String, dynamic> attributes; // dynamic attributes
  final bool stock;
  final num sellingPrice;
  final List<String> mediaRelatedToVariant;
  final num mrp;
  final bool variantIsActive;
  final String id;

  Variant({
    required this.attributes,
    required this.stock,
    required this.sellingPrice,
    required this.mediaRelatedToVariant,
    required this.mrp,
    required this.variantIsActive,
    required this.id,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      attributes: json['attributes'] ?? {},
      stock: json['stock'] ?? false,
      sellingPrice: json['sellingPrice'] ?? 0,
      mediaRelatedToVariant:
      List<String>.from(json['media_related_to_varient'] ?? []),
      mrp: json['mrp'] ?? 0,
      variantIsActive: json['varientIsActive'] ?? false,
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attributes': attributes,
      'stock': stock,
      'sellingPrice': sellingPrice,
      'media_related_to_varient': mediaRelatedToVariant,
      'mrp': mrp,
      'varientIsActive': variantIsActive,
      '_id': id,
    };
  }
}
