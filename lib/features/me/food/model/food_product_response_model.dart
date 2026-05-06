import 'dart:convert';

import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';

FoodProductResponseModel myFoodProductResponseModelFromJson(String str) =>
    FoodProductResponseModel.fromJson(json.decode(str));

String myFoodProductResponseModelToJson(FoodProductResponseModel data) =>
    json.encode(data.toJson());

class FoodProductResponseModel {
  bool? success;
  List<MyFoodProductData>? data;
  Pagination? pagination;

  FoodProductResponseModel({this.success, this.data, this.pagination});

  FoodProductResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <MyFoodProductData>[];
      json['data'].forEach((v) {
        data!.add(MyFoodProductData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    return data;
  }
}

class MyFoodProductData {
  CategoryFoodProductData? productDetails;

  /// Outer-level inventory identifier returned by the food category
  /// listing API alongside `productDetails`. The variants nested inside
  /// `productDetails` don't carry their own `inventoryId` on this
  /// endpoint (only the discount-products endpoint embeds it at the
  /// variant level), so consumers (`getCustomerFoodProductByCategoryIdApi`)
  /// read this and copy it down into each variant before exposing the
  /// list — that way `buildBulkOrderItems` can keep reading
  /// `variant.inventoryId` uniformly across both flows.
  String? inventoryId;

  MyFoodProductData({this.productDetails, this.inventoryId});

  MyFoodProductData.fromJson(Map<String, dynamic> json) {
    productDetails = json['productDetails'] != null
        ? CategoryFoodProductData.fromJson(json['productDetails'])
        : null;
    // Some backend variants of this payload key the inventory id as
    // `inventoryId`, others as `_id` of the inventory record. Try
    // both — falls back to null if neither is present.
    inventoryId = (json['inventoryId'] ?? json['_id'])?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (productDetails != null) {
      data['productDetails'] = productDetails!.toJson();
    }
    data['inventoryId'] = inventoryId;
    return data;
  }
}

class Pagination {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  Pagination({this.total, this.page, this.limit, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['page'] = page;
    data['limit'] = limit;
    data['totalPages'] = totalPages;
    return data;
  }
}