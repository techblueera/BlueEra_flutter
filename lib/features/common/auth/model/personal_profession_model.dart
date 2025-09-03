import 'dart:convert';
PersonalProfessionModel personalProfessionModelFromJson(String str) => PersonalProfessionModel.fromJson(json.decode(str));
String personalProfessionModelToJson(PersonalProfessionModel data) => json.encode(data.toJson());
class PersonalProfessionModel {
  PersonalProfessionModel({
      this.data, 
      this.status,});

  PersonalProfessionModel.fromJson(dynamic json) {
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(ProfessionTypeData.fromJson(v));
      });
    }
    status = json['status'];
  }
  List<ProfessionTypeData>? data;
  bool? status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['status'] = status;
    return map;
  }

}

ProfessionTypeData dataFromJson(String str) => ProfessionTypeData.fromJson(json.decode(str));
String dataToJson(ProfessionTypeData data) => json.encode(data.toJson());
class ProfessionTypeData {
  ProfessionTypeData({
      this.id, 
      this.name, 
      this.tagId, 
      this.isActive, 
      this.deletedAt, 
      this.deletedBy, 
      this.subcategoriesFiledName, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  ProfessionTypeData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    tagId = json['tag_id'];
    isActive = json['isActive'];
    deletedAt = json['deletedAt'];
    deletedBy = json['deletedBy'];
    if (json['subcategories_filedName'] != null) {
      subcategoriesFiledName = [];
      json['subcategories_filedName'].forEach((v) {
        subcategoriesFiledName?.add(SubcategoriesFiledName.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? name;
  String? tagId;
  bool? isActive;
  dynamic deletedAt;
  dynamic deletedBy;
  List<SubcategoriesFiledName>? subcategoriesFiledName;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['tag_id'] = tagId;
    map['isActive'] = isActive;
    map['deletedAt'] = deletedAt;
    map['deletedBy'] = deletedBy;
    if (subcategoriesFiledName != null) {
      map['subcategories_filedName'] = subcategoriesFiledName?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

SubcategoriesFiledName subcategoriesFiledNameFromJson(String str) => SubcategoriesFiledName.fromJson(json.decode(str));
String subcategoriesFiledNameToJson(SubcategoriesFiledName data) => json.encode(data.toJson());
class SubcategoriesFiledName {
  SubcategoriesFiledName({
      this.name, 
      this.tagId, 
      this.id,});

  SubcategoriesFiledName.fromJson(dynamic json) {
    name = json['name'];
    tagId = json['tag_id'];
    id = json['_id'];
  }
  String? name;
  String? tagId;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['tag_id'] = tagId;
    map['_id'] = id;
    return map;
  }

}