import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';

class GrocerySnapSearchResponseModel {
  bool? success;
  String? message;
  ProductSnapSearchData? data;

  GrocerySnapSearchResponseModel({this.success, this.message, this.data});

  GrocerySnapSearchResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new ProductSnapSearchData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ProductSnapSearchData {
  int? totalDetected;
  int? foundCount;
  int? missingCount;
  List<FoundProducts>? foundProducts;
  List<MissingProducts>? missingProducts;

  ProductSnapSearchData(
      {this.totalDetected,
        this.foundCount,
        this.missingCount,
        this.foundProducts,
        this.missingProducts});

  ProductSnapSearchData.fromJson(Map<String, dynamic> json) {
    totalDetected = json['totalDetected'];
    foundCount = json['foundCount'];
    missingCount = json['missingCount'];
    if (json['foundProducts'] != null) {
      foundProducts = <FoundProducts>[];
      json['foundProducts'].forEach((v) {
        foundProducts!.add(new FoundProducts.fromJson(v));
      });
    }
    if (json['missingProducts'] != null) {
      missingProducts = <MissingProducts>[];
      json['missingProducts'].forEach((v) {
        missingProducts!.add(new MissingProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalDetected'] = this.totalDetected;
    data['foundCount'] = this.foundCount;
    data['missingCount'] = this.missingCount;
    if (this.foundProducts != null) {
      data['foundProducts'] =
          this.foundProducts!.map((v) => v.toJson()).toList();
    }
    if (this.missingProducts != null) {
      data['missingProducts'] =
          this.missingProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FoundProducts {
  String? aiIdentifiedAs;
  GroceryProductData? productDetails;

  FoundProducts({this.aiIdentifiedAs, this.productDetails});

  FoundProducts.fromJson(Map<String, dynamic> json) {
    aiIdentifiedAs = json['aiIdentifiedAs'];
    productDetails = json['productDetails'] != null
        ? new GroceryProductData.fromJson(json['productDetails'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['aiIdentifiedAs'] = this.aiIdentifiedAs;
    if (this.productDetails != null) {
      data['productDetails'] = this.productDetails!.toJson();
    }
    return data;
  }
}

class MissingProducts {
  String? name;
  String? brand;
  String? searchKeywords;
  num? approxPrice;
  String? unit;

  MissingProducts({this.name, this.brand, this.searchKeywords, this.approxPrice, this.unit});

  MissingProducts.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    brand = json['brand'];
    searchKeywords = json['searchKeywords'];
    approxPrice = json['approxPrice'];
    unit = json['unit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['brand'] = this.brand;
    data['searchKeywords'] = this.searchKeywords;
    data['approxPrice'] = this.approxPrice;
    data['unit'] = this.unit;
    return data;
  }
}