import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';

class AllStoresFeedResponseModel {
  bool? status;
  String? message;
  List<AllStoresFeedData>? data;
  Pagination? pagination;

  AllStoresFeedResponseModel(
      {this.status, this.message, this.data, this.pagination});

  AllStoresFeedResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <AllStoresFeedData>[];
      json['data'].forEach((v) {
        data!.add(new AllStoresFeedData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class AllStoresFeedData {
  String? type;
  InventoryData? inventoryData;
  GetAllStoreResModel? businessData;
  GetFoodDetailsModel? foodData;
  GetServiceModel? servicesData;

  AllStoresFeedData(
      {this.type,
        this.inventoryData,
        this.businessData,
        this.foodData,
        this.servicesData});

  AllStoresFeedData.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    inventoryData = json['inventory_data'] != null
        ? new InventoryData.fromJson(json['inventory_data'])
        : null;
    businessData = json['business_data'] != null
        ? new GetAllStoreResModel.fromJson(json['business_data'])
        : null;
    foodData = json['food_data'] != null
        ? new GetFoodDetailsModel.fromJson(json['food_data'])
        : null;
    servicesData = json['services_data'] != null
        ? new GetServiceModel.fromJson(json['services_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.inventoryData != null) {
      data['inventory_data'] = this.inventoryData!.toJson();
    }
    if (this.businessData != null) {
      data['business_data'] = this.businessData!.toJson();
    }
    data['food_data'] = this.foodData;
    data['services_data'] = this.servicesData;
    return data;
  }
}

class InventoryData {
  ProductStore? product;
  String? type;
  double? distance;

  InventoryData({this.product, this.type, this.distance});

  InventoryData.fromJson(Map<String, dynamic> json) {
    product =
    json['product'] != null ? new ProductStore.fromJson(json['product']) : null;
    type = json['type'];
    distance = json['distance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.product != null) {
      data['product'] = this.product!.toJson();
    }
    data['type'] = this.type;
    data['distance'] = this.distance;
    return data;
  }
}

class Pagination {
  int? currentPage;
  int? totalPages;
  int? itemsPerPage;
  int? totalItems;

  Pagination(
      {this.currentPage, this.totalPages, this.itemsPerPage, this.totalItems});

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    itemsPerPage = json['itemsPerPage'];
    totalItems = json['totalItems'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['totalPages'] = this.totalPages;
    data['itemsPerPage'] = this.itemsPerPage;
    data['totalItems'] = this.totalItems;
    return data;
  }

}
