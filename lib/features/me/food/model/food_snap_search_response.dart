import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';

class FoodSnapSearchResponseModel {
  bool? success;
  String? message;
  FoodProductSnapSearchData? data;

  FoodSnapSearchResponseModel({this.success, this.message, this.data});

  FoodSnapSearchResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new FoodProductSnapSearchData.fromJson(json['data']) : null;
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

class FoodProductSnapSearchData {
  int? totalDetected;
  int? foundCount;
  int? missingCount;
  List<FoundProducts>? foundProducts;
  List<MissingFoodProducts>? missingProducts;

  FoodProductSnapSearchData(
      {this.totalDetected,
        this.foundCount,
        this.missingCount,
        this.foundProducts,
        this.missingProducts});

  FoodProductSnapSearchData.fromJson(Map<String, dynamic> json) {
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
      missingProducts = <MissingFoodProducts>[];
      json['missingProducts'].forEach((v) {
        missingProducts!.add(new MissingFoodProducts.fromJson(v));
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
  CategoryFoodProductData? productDetails;

  FoundProducts({this.aiIdentifiedAs, this.productDetails});

  FoundProducts.fromJson(Map<String, dynamic> json) {
    aiIdentifiedAs = json['aiIdentifiedAs'];
    productDetails = json['productDetails'] != null
        ? new CategoryFoodProductData.fromJson(json['productDetails'])
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

class MissingFoodProducts {
  String? name;
  String? brand;
  String? searchKeywords;
  num? approxPrice;
  String? unit;

  // keys for local navigation management and missing product created flow
  String? productId;
  String? inventoryId;

  MissingFoodProducts({
    this.name,
    this.brand,
    this.searchKeywords,
    this.approxPrice,
    this.unit,
    this.productId,
    this.inventoryId,
  });

  MissingFoodProducts.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    brand = json['brand'];
    searchKeywords = json['searchKeywords'];
    approxPrice = json['approxPrice'];
    unit = json['unit'];
    productId = json['productId'];
    inventoryId = json['inventoryId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['brand'] = this.brand;
    data['searchKeywords'] = this.searchKeywords;
    data['approxPrice'] = this.approxPrice;
    data['unit'] = this.unit;
    data['productId'] = this.productId;
    data['inventoryId'] = this.inventoryId;
    return data;
  }
}