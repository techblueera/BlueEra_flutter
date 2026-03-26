import 'dart:convert';

import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
SchoolContactUsResModel schoolContactUsResModelFromJson(String str) => SchoolContactUsResModel.fromJson(json.decode(str));
String schoolContactUsResModelToJson(SchoolContactUsResModel data) => json.encode(data.toJson());
class SchoolContactUsResModel {
  SchoolContactUsResModel({
      this.success, 
      this.data,});

  SchoolContactUsResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SchoolContactUsData.fromJson(v));
      });
    }
  }
  bool? success;
  List<SchoolContactUsData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

SchoolContactUsData dataFromJson(String str) => SchoolContactUsData.fromJson(json.decode(str));
String dataToJson(SchoolContactUsData data) => json.encode(data.toJson());
class SchoolContactUsData {
  SchoolContactUsData({
      this.branch, 
      this.id, 
      this.departments, 
      this.schoolId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  SchoolContactUsData.fromJson(dynamic json) {
    branch = json['branch'] != null ? Branch.fromJson(json['branch']) : null;
    id = json['_id'];
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments?.add(OtherProfileDepartments.fromJson(v));
      });
    }
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  Branch? branch;
  String? id;
  List<OtherProfileDepartments>? departments;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (branch != null) {
      map['branch'] = branch?.toJson();
    }
    map['_id'] = id;
    if (departments != null) {
      map['departments'] = departments?.map((v) => v.toJson()).toList();
    }
    map['schoolId'] = schoolId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Departments departmentsFromJson(String str) => Departments.fromJson(json.decode(str));
String departmentsToJson(Departments data) => json.encode(data.toJson());
class Departments {
  Departments({
      this.department, 
      this.role, 
      this.email, 
      this.phone, 
      this.id,});

  Departments.fromJson(dynamic json) {
    department = json['department'];
    role = json['role'];
    email = json['email'];
    phone = json['phone'];
    id = json['_id'];
  }
  String? department;
  String? role;
  String? email;
  String? phone;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['department'] = department;
    map['role'] = role;
    map['email'] = email;
    map['phone'] = phone;
    map['_id'] = id;
    return map;
  }

}

Branch branchFromJson(String str) => Branch.fromJson(json.decode(str));
String branchToJson(Branch data) => json.encode(data.toJson());
class Branch {
  Branch({
      this.location, 
      this.name, 
      this.website,});

  Branch.fromJson(dynamic json) {
    location = json['location'] != null ? SchoolLocation.fromJson(json['location']) : null;
    name = json['name'];
    website = json['website'];
  }
  SchoolLocation? location;
  String? name;
  String? website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['name'] = name;
    map['website'] = website;
    return map;
  }

}

SchoolLocation locationFromJson(String str) => SchoolLocation.fromJson(json.decode(str));
String locationToJson(SchoolLocation data) => json.encode(data.toJson());
class SchoolLocation {
  SchoolLocation({
      this.name,
      this.coordinates,});

  SchoolLocation.fromJson(dynamic json) {
    name = json['name'];
    // coordinates = json['coordinates'] != null ? json['coordinates'] : [];
    coordinates= (json['coordinates'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
  }
  String? name;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['coordinates'] = coordinates;
    return map;
  }

}

