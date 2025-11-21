import 'dart:convert';

PersonalProfessionModel personalProfessionModelFromJson(String str) =>
    PersonalProfessionModel.fromJson(json.decode(str));

String personalProfessionModelToJson(PersonalProfessionModel data) =>
    json.encode(data.toJson());

class PersonalProfessionModel {
  PersonalProfessionModel({
    this.data,
    this.status,
  });

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

ProfessionTypeData dataFromJson(String str) =>
    ProfessionTypeData.fromJson(json.decode(str));

String dataToJson(ProfessionTypeData data) => json.encode(data.toJson());

class ProfessionTypeData {
  ProfessionTypeData({
    this.id,
    this.name,
    this.tagId,
    this.subcategoriesFiledName,
  });

  ProfessionTypeData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    tagId = json['tag_id'];

    if (json['subcategories_filedName'] != null) {
      subcategoriesFiledName = [];
      json['subcategories_filedName'].forEach((v) {
        subcategoriesFiledName?.add(SubcategoriesFiledName.fromJson(v));
      });
    }
  }

  String? id;
  String? name;
  String? tagId;
  List<SubcategoriesFiledName>? subcategoriesFiledName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['tag_id'] = tagId;

    if (subcategoriesFiledName != null) {
      map['subcategories_filedName'] =
          subcategoriesFiledName?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

SubcategoriesFiledName subcategoriesFiledNameFromJson(String str) =>
    SubcategoriesFiledName.fromJson(json.decode(str));

String subcategoriesFiledNameToJson(SubcategoriesFiledName data) =>
    json.encode(data.toJson());

class SubcategoriesFiledName {
  SubcategoriesFiledName({
    this.name,
    this.tagId,
    this.id,
  });

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
