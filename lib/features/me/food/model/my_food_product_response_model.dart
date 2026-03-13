import 'dart:convert';

import 'package:BlueEra/features/me/food/model/category_food_product_res_model.dart';

MyFoodProductResponseModel myFoodProductResponseModelFromJson(String str) =>
    MyFoodProductResponseModel.fromJson(json.decode(str));

String myFoodProductResponseModelToJson(MyFoodProductResponseModel data) =>
    json.encode(data.toJson());

class MyFoodProductResponseModel {
  bool? success;
  List<MyFoodProductData>? data;
  Pagination? pagination;

  MyFoodProductResponseModel({this.success, this.data, this.pagination});

  MyFoodProductResponseModel.fromJson(Map<String, dynamic> json) {
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
    productDetails = json['productDetails'] != null
        ? CategoryFoodProductData.fromJson(json['productDetails'])
        : null;
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