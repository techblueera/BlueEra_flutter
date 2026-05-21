import 'package:BlueEra/features/me/manufacturer/model/manufacturer_product_catalog_response.dart';

class ManufacturerProductSnapSearchResponseModel {
  bool? success;
  String? message;
  ManufacturerProductSnapSearchData? data;

  ManufacturerProductSnapSearchResponseModel({this.success, this.message, this.data});

  ManufacturerProductSnapSearchResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null
        ? ManufacturerProductSnapSearchData.fromJson(json['data'])
        : null;
  }
}

class ManufacturerProductSnapSearchData {
  int? totalDetected;
  int? foundCount;
  int? missingCount;
  List<ManufacturerProductSnapFoundItem>? foundProducts;
  List<ManufacturerProductSnapMissingItem>? missingProducts;

  ManufacturerProductSnapSearchData({
    this.totalDetected,
    this.foundCount,
    this.missingCount,
    this.foundProducts,
    this.missingProducts,
  });

  ManufacturerProductSnapSearchData.fromJson(Map<String, dynamic> json) {
    totalDetected = json['totalDetected'];
    foundCount = json['foundCount'];
    missingCount = json['missingCount'];
    if (json['foundProducts'] != null) {
      foundProducts = <ManufacturerProductSnapFoundItem>[];
      json['foundProducts'].forEach((v) {
        foundProducts!.add(ManufacturerProductSnapFoundItem.fromJson(v));
      });
    }
    if (json['missingProducts'] != null) {
      missingProducts = <ManufacturerProductSnapMissingItem>[];
      json['missingProducts'].forEach((v) {
        missingProducts!.add(ManufacturerProductSnapMissingItem.fromJson(v));
      });
    }
  }
}

/// One found item from the snap search response. The API splits the
/// payload across `product_information` (product metadata) and
/// `inventory_details` (variants list); we merge them into a single
/// [ManufacturerProduct] so the rest of the app handles snap-found items exactly
/// like text-search results.
class ManufacturerProductSnapFoundItem {
  String? aiIdentifiedAs;
  ManufacturerProduct? product;

  ManufacturerProductSnapFoundItem({this.aiIdentifiedAs, this.product});

  ManufacturerProductSnapFoundItem.fromJson(Map<String, dynamic> json) {
    aiIdentifiedAs = json['aiIdentifiedAs'];

    final productInfo = json['product_information'];
    final inventoryDetails = json['inventory_details'];
    if (productInfo is Map && inventoryDetails is Map) {
      // Merge: take product fields from product_information, splice in
      // the variants list from inventory_details, then parse through
      // the unified ManufacturerProduct.fromJson.
      final merged = Map<String, dynamic>.from(productInfo);
      merged['variants'] = inventoryDetails['variants'] ?? const [];
      product = ManufacturerProduct.fromJson(merged);
    }
  }
}

class ManufacturerProductSnapMissingItem {
  String? name;
  String? brand;
  String? searchKeywords;
  num? approxPrice;
  String? unit;

  ManufacturerProductSnapMissingItem({
    this.name,
    this.brand,
    this.searchKeywords,
    this.approxPrice,
    this.unit,
  });

  ManufacturerProductSnapMissingItem.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    brand = json['brand'];
    searchKeywords = json['searchKeywords'];
    approxPrice = json['approxPrice'];
    unit = json['unit'];
  }
}
