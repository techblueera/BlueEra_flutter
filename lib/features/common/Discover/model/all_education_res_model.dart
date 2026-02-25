import 'dart:convert';

import 'package:BlueEra/core/api/model/school_details_res_model.dart';
AllEducationResModel allEducationResModelFromJson(String str) => AllEducationResModel.fromJson(json.decode(str));
String allEducationResModelToJson(AllEducationResModel data) => json.encode(data.toJson());
class AllEducationResModel {
  AllEducationResModel({
      this.success, 
      this.data, 
      this.pagination,});

  AllEducationResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SchoolDetailsData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
  }
  bool? success;
  List<SchoolDetailsData>? data;
  Pagination? pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    return map;
  }

}

Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
String paginationToJson(Pagination data) => json.encode(data.toJson());
class Pagination {
  Pagination({
      this.currentPage, 
      this.totalPages, 
      this.totalItems, 
      this.hasNext, 
      this.hasPrev,});

  Pagination.fromJson(dynamic json) {
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    hasNext = json['hasNext'];
    hasPrev = json['hasPrev'];
  }
  String? currentPage;
  int? totalPages;
  int? totalItems;
  bool? hasNext;
  bool? hasPrev;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['currentPage'] = currentPage;
    map['totalPages'] = totalPages;
    map['totalItems'] = totalItems;
    map['hasNext'] = hasNext;
    map['hasPrev'] = hasPrev;
    return map;
  }

}
