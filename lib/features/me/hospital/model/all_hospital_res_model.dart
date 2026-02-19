import 'dart:convert';

import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
AllHospitalResModel allHospitalResModelFromJson(String str) => AllHospitalResModel.fromJson(json.decode(str));
String allHospitalResModelToJson(AllHospitalResModel data) => json.encode(data.toJson());
class AllHospitalResModel {
  AllHospitalResModel({
      this.success, 
      this.data, 
      this.totalPages, 
      this.currentPage, 
      this.totalCount,});

  AllHospitalResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(HospitalFullData.fromJson(v));
      });
    }
    totalPages = json['totalPages'];
    currentPage = json['currentPage'];
    totalCount = json['totalCount'];
  }
  bool? success;
  List<HospitalFullData>? data;
  int? totalPages;
  int? currentPage;
  int? totalCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['totalPages'] = totalPages;
    map['currentPage'] = currentPage;
    map['totalCount'] = totalCount;
    return map;
  }

}
