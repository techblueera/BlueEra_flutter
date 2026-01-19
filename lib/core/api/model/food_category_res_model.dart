import 'dart:convert';

FoodCategoryResModel foodCategoryResModelFromJson(String str) => FoodCategoryResModel.fromJson(json.decode(str));
String foodCategoryResModelToJson(FoodCategoryResModel data) => json.encode(data.toJson());
class FoodCategoryResModel {
  FoodCategoryResModel({
      this.message, 
      this.count, 
      this.data,});

  FoodCategoryResModel.fromJson(dynamic json) {
    message = json['message'];
    count = json['count'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(FoodCategoryData.fromJson(v));
      });
    }
  }
  String? message;
  int? count;
  List<FoodCategoryData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    map['count'] = count;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

FoodCategoryData dataFromJson(String str) => FoodCategoryData.fromJson(json.decode(str));
String dataToJson(FoodCategoryData data) => json.encode(data.toJson());
class FoodCategoryData {
  FoodCategoryData({
      this.id, 
      this.name, 
      this.key, 
      this.isActive, 
      this.parentId, 
      this.level, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  FoodCategoryData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    key = json['key'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? name;
  String? key;
  bool? isActive;
  dynamic parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['key'] = key;
    map['isActive'] = isActive;
    map['parentId'] = parentId;
    map['level'] = level;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}