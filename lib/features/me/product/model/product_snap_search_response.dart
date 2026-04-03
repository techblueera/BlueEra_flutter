import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';

class ProductSnapSearchResponseModel {
  bool? success;
  String? message;
  ProductSnapSearchData? data;

  ProductSnapSearchResponseModel({this.success, this.message, this.data});

  ProductSnapSearchResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null
        ? ProductSnapSearchData.fromJson(json['data'])
        : null;
  }
}

class ProductSnapSearchData {
  int? totalDetected;
  int? foundCount;
  int? missingCount;
  List<ProductSnapFoundItem>? foundProducts;
  List<ProductSnapMissingItem>? missingProducts;

  ProductSnapSearchData({
    this.totalDetected,
    this.foundCount,
    this.missingCount,
    this.foundProducts,
    this.missingProducts,
  });

  ProductSnapSearchData.fromJson(Map<String, dynamic> json) {
    totalDetected = json['totalDetected'];
    foundCount = json['foundCount'];
    missingCount = json['missingCount'];
    if (json['foundProducts'] != null) {
      foundProducts = <ProductSnapFoundItem>[];
      json['foundProducts'].forEach((v) {
        foundProducts!.add(ProductSnapFoundItem.fromJson(v));
      });
    }
    if (json['missingProducts'] != null) {
      missingProducts = <ProductSnapMissingItem>[];
      json['missingProducts'].forEach((v) {
        missingProducts!.add(ProductSnapMissingItem.fromJson(v));
      });
    }
  }
}

class ProductSnapFoundItem {
  String? aiIdentifiedAs;
  List<VariantData> variants;

  ProductSnapFoundItem({this.aiIdentifiedAs, this.variants = const []});

  ProductSnapFoundItem.fromJson(Map<String, dynamic> json)
      : variants = [] {
    aiIdentifiedAs = json['aiIdentifiedAs'];

    final productInfo = json['product_information'] as Map<String, dynamic>?;
    final inventoryDetails = json['inventory_details'] as Map<String, dynamic>?;

    if (productInfo != null && inventoryDetails != null) {
      final inventoryVariants = inventoryDetails['variants'] as List<dynamic>? ?? [];
      for (final v in inventoryVariants) {
        variants.add(VariantData.fromJson({
          'product_information': productInfo,
          'final_variant': v,
        }));
      }
    }
  }
}

class ProductSnapMissingItem {
  String? name;
  String? brand;
  String? searchKeywords;
  num? approxPrice;
  String? unit;

  ProductSnapMissingItem({
    this.name,
    this.brand,
    this.searchKeywords,
    this.approxPrice,
    this.unit,
  });

  ProductSnapMissingItem.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    brand = json['brand'];
    searchKeywords = json['searchKeywords'];
    approxPrice = json['approxPrice'];
    unit = json['unit'];
  }
}
