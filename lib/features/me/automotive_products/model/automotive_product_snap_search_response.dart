import 'package:BlueEra/features/me/automotive_products/model/automotive_product_catalog_response.dart';

class AutomotiveProductSnapSearchResponseModel {
  bool? success;
  String? message;
  AutomotiveProductSnapSearchData? data;

  AutomotiveProductSnapSearchResponseModel({this.success, this.message, this.data});

  AutomotiveProductSnapSearchResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null
        ? AutomotiveProductSnapSearchData.fromJson(json['data'])
        : null;
  }
}

class AutomotiveProductSnapSearchData {
  int? totalDetected;
  int? foundCount;
  int? missingCount;
  List<AutomotiveProductSnapFoundItem>? foundProducts;
  List<AutomotiveProductSnapMissingItem>? missingProducts;

  AutomotiveProductSnapSearchData({
    this.totalDetected,
    this.foundCount,
    this.missingCount,
    this.foundProducts,
    this.missingProducts,
  });

  AutomotiveProductSnapSearchData.fromJson(Map<String, dynamic> json) {
    totalDetected = json['totalDetected'];
    foundCount = json['foundCount'];
    missingCount = json['missingCount'];
    if (json['foundProducts'] != null) {
      foundProducts = <AutomotiveProductSnapFoundItem>[];
      json['foundProducts'].forEach((v) {
        foundProducts!.add(AutomotiveProductSnapFoundItem.fromJson(v));
      });
    }
    if (json['missingProducts'] != null) {
      missingProducts = <AutomotiveProductSnapMissingItem>[];
      json['missingProducts'].forEach((v) {
        missingProducts!.add(AutomotiveProductSnapMissingItem.fromJson(v));
      });
    }
  }
}

/// One found item from the snap search response. The API splits the
/// payload across `product_information` (product metadata) and
/// `inventory_details` (variants list); we merge them into a single
/// [AutomotiveProduct] so the rest of the app handles snap-found items exactly
/// like text-search results.
class AutomotiveProductSnapFoundItem {
  String? aiIdentifiedAs;
  AutomotiveProduct? product;

  AutomotiveProductSnapFoundItem({this.aiIdentifiedAs, this.product});

  AutomotiveProductSnapFoundItem.fromJson(Map<String, dynamic> json) {
    aiIdentifiedAs = json['aiIdentifiedAs'];

    final productInfo = json['product_information'];
    final inventoryDetails = json['inventory_details'];
    if (productInfo is Map && inventoryDetails is Map) {
      // Merge: take product fields from product_information, splice in
      // the variants list from inventory_details, then parse through
      // the unified AutomotiveProduct.fromJson.
      final merged = Map<String, dynamic>.from(productInfo);
      merged['variants'] = inventoryDetails['variants'] ?? const [];
      product = AutomotiveProduct.fromJson(merged);
    }
  }
}

class AutomotiveProductSnapMissingItem {
  String? name;
  String? brand;
  String? searchKeywords;
  num? approxPrice;
  String? unit;

  AutomotiveProductSnapMissingItem({
    this.name,
    this.brand,
    this.searchKeywords,
    this.approxPrice,
    this.unit,
  });

  AutomotiveProductSnapMissingItem.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    brand = json['brand'];
    searchKeywords = json['searchKeywords'];
    approxPrice = json['approxPrice'];
    unit = json['unit'];
  }
}
