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

  AllStoresFeedData({
    this.type,
    this.inventoryData,
    this.businessData,
    this.foodData,
    this.servicesData,
  });

  AllStoresFeedData.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    inventoryData = json['inventory_data'] != null
        ? InventoryData.fromJson(json['inventory_data'])
        : null;
    businessData = json['business_data'] != null
        ? GetAllStoreResModel.fromJson(json['business_data'])
        : null;
    foodData = json['food_data'] != null
        ? GetFoodDetailsModel.fromJson(json['food_data'])
        : null;
    servicesData = json['services_data'] != null
        ? GetServiceModel.fromJson(json['services_data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    if (inventoryData != null) data['inventory_data'] = inventoryData!.toJson();
    if (businessData != null) data['business_data'] = businessData!.toJson();
    if (foodData != null) data['food_data'] = foodData!.toJson();
    if (servicesData != null) data['services_data'] = servicesData!.toJson();
    return data;
  }

  AllStoresFeedData copyWith({
    String? type,
    InventoryData? inventoryData,
    GetAllStoreResModel? businessData,
    GetFoodDetailsModel? foodData,
    GetServiceModel? servicesData,
  }) {
    return AllStoresFeedData(
      type: type ?? this.type,
      inventoryData: inventoryData ?? this.inventoryData,
      businessData: businessData ?? this.businessData,
      foodData: foodData ?? this.foodData,
      servicesData: servicesData ?? this.servicesData,
    );
  }
}

class InventoryData {
  ProductStore? product;
  String? type;
  double? distance;

  InventoryData({this.product, this.type, this.distance});

  InventoryData.fromJson(Map<String, dynamic> json) {
    product =
    json['product'] != null ? ProductStore.fromJson(json['product']) : null;
    type = json['type'];
    distance = json['distance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (product != null) data['product'] = product!.toJson();
    data['type'] = type;
    data['distance'] = distance;
    return data;
  }

  InventoryData copyWith({
    ProductStore? product,
    String? type,
    double? distance,
  }) {
    return InventoryData(
      product: product ?? this.product,
      type: type ?? this.type,
      distance: distance ?? this.distance,
    );
  }
}

class Pagination {
  int? currentPage;
  int? totalPages;
  int? itemsPerPage;
  int? totalItems;

  Pagination({
    this.currentPage,
    this.totalPages,
    this.itemsPerPage,
    this.totalItems,
  });

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    itemsPerPage = json['itemsPerPage'];
    totalItems = json['totalItems'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['currentPage'] = currentPage;
    data['totalPages'] = totalPages;
    data['itemsPerPage'] = itemsPerPage;
    data['totalItems'] = totalItems;
    return data;
  }

  Pagination copyWith({
    int? currentPage,
    int? totalPages,
    int? itemsPerPage,
    int? totalItems,
  }) {
    return Pagination(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

