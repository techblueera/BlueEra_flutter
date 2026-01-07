import 'dart:convert';
CampusLifeCategoriesResModel campusLifeCategoriesResModelFromJson(String str) => CampusLifeCategoriesResModel.fromJson(json.decode(str));
String campusLifeCategoriesResModelToJson(CampusLifeCategoriesResModel data) => json.encode(data.toJson());
class CampusLifeCategoriesResModel {
  CampusLifeCategoriesResModel({
      this.status, 
      this.data, 
      this.count,});

  CampusLifeCategoriesResModel.fromJson(dynamic json) {
    status = json['status'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(CampusLifeCategoriesData.fromJson(v));
      });
    }
    count = json['count'];
  }
  bool? status;
  List<CampusLifeCategoriesData>? data;
  int? count;
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['count'] = count;
    return map;
  }

}

CampusLifeCategoriesData dataFromJson(String str) => CampusLifeCategoriesData.fromJson(json.decode(str));
String dataToJson(CampusLifeCategoriesData data) => json.encode(data.toJson());
class CampusLifeCategoriesData {
  CampusLifeCategoriesData({
      this.id, 
      this.name, 
      this.type, 
      this.active, 
      this.subCategories,
      this.v, 
      this.createdAt, 
      this.updatedAt,});

  CampusLifeCategoriesData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    type = json['type'];
    active = json['active'];

    if (json['subCategories'] != null) {
      subCategories = [];
      json['subCategories'].forEach((v) {
        subCategories?.add(SubCategories.fromJson(v));
      });
    }
    v = json['__v'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? name;
  String? type;
  bool? active;

  List<SubCategories>? subCategories;
  int? v;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['type'] = type;
    map['active'] = active;

    if (subCategories != null) {
      map['subCategories'] = subCategories?.map((v) => v.toJson()).toList();
    }
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

SubCategories subCategoriesFromJson(String str) => SubCategories.fromJson(json.decode(str));
String subCategoriesToJson(SubCategories data) => json.encode(data.toJson());
class SubCategories {
  SubCategories({
      this.name, 
      this.type, 
      this.active, 
      this.deletedAt, 
      this.createdBy, 
      this.id, 
      this.createdAt, 
      this.updatedAt,});

  SubCategories.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    active = json['active'];
    deletedAt = json['deleted_at'];
    createdBy = json['created_by'];
    id = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  String? name;
  String? type;
  bool? active;
  dynamic deletedAt;
  dynamic createdBy;
  String? id;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['active'] = active;
    map['deleted_at'] = deletedAt;
    map['created_by'] = createdBy;
    map['_id'] = id;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}