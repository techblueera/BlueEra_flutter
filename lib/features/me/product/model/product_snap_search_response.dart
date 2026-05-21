import 'package:BlueEra/features/me/product/model/product_catalog_response.dart';

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

/// One found item from the snap search response. The API splits the
/// payload across `product_information` (product metadata) and
/// `inventory_details` (variants list); we merge them into a single
/// [Product] so the rest of the app handles snap-found items exactly
/// like text-search results.
class ProductSnapFoundItem {
  String? aiIdentifiedAs;
  Product? product;

  ProductSnapFoundItem({this.aiIdentifiedAs, this.product});

  ProductSnapFoundItem.fromJson(Map<String, dynamic> json) {
    aiIdentifiedAs = json['aiIdentifiedAs'];

    final productInfo = json['product_information'];
    final inventoryDetails = json['inventory_details'];
    if (productInfo is Map && inventoryDetails is Map) {
      // Merge: take product fields from product_information, splice in
      // the variants list from inventory_details, then parse through
      // the unified Product.fromJson.
      final merged = Map<String, dynamic>.from(productInfo);
      merged['variants'] = inventoryDetails['variants'] ?? const [];
      product = Product.fromJson(merged);
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
