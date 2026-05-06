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
  MyFoodProductData({this.productDetails});

  MyFoodProductData.fromJson(Map<String, dynamic> json) {
    if (json['productDetails'] != null) {
      productDetails = CategoryFoodProductData.fromJson(json['productDetails']);

      // The kitchen-inventory search API wraps each product in an inventory document.
      // We must propagate the wrapper's ID (the inventoryId) to the variants.
      final String? wrapperInventoryId =
          (json['_id'] ?? json['inventoryId'] ?? json['id'])?.toString();
      final String? coveredVariantId =
          (json['productVariant'] ?? json['variant'])?.toString();

      if (wrapperInventoryId != null &&
          wrapperInventoryId.isNotEmpty &&
          productDetails!.variants != null) {
        productDetails!.variants = productDetails!.variants!.map((v) {
          // If the wrapper specifies a variant, match it.
          // Otherwise, if it's a single-variant product or we're missing the match key,
          // inject into any variant that is missing an inventoryId.
          final bool isMatch = coveredVariantId != null
              ? v.id == coveredVariantId
              : (v.inventoryId == null || v.inventoryId!.isEmpty);

          if (isMatch && (v.inventoryId == null || v.inventoryId!.isEmpty)) {
            return v.copyWith(inventoryId: wrapperInventoryId);
          }
          return v;
        }).toList();
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (productDetails != null) {
      data['productDetails'] = productDetails!.toJson();
    }
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
