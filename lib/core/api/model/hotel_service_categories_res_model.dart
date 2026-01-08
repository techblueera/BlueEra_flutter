import 'dart:convert';
HotelServiceCategoriesResModel hotelServiceCategoriesResModelFromJson(String str) => HotelServiceCategoriesResModel.fromJson(json.decode(str));
String hotelServiceCategoriesResModelToJson(HotelServiceCategoriesResModel data) => json.encode(data.toJson());
class HotelServiceCategoriesResModel {
  HotelServiceCategoriesResModel({
      this.success, 
      this.message, 
      this.data,});

  HotelServiceCategoriesResModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(HotelServiceCategoriesData.fromJson(v));
      });
    }
  }
  bool? success;
  String? message;
  List<HotelServiceCategoriesData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

HotelServiceCategoriesData dataFromJson(String str) => HotelServiceCategoriesData.fromJson(json.decode(str));
String dataToJson(HotelServiceCategoriesData data) => json.encode(data.toJson());
class HotelServiceCategoriesData {
  HotelServiceCategoriesData({
      this.id, 
      this.name, 
      this.key, 
      this.isEnabled,
      this.parentId, 
      this.level, 
      this.type, 
      this.rules, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.children,});

  HotelServiceCategoriesData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    key = json['key'];
    isEnabled = json['isEnabled'];
    parentId = json['parentId'];
    level = json['level'];
    type = json['type'];
    rules = json['rules'] != null ? Rules.fromJson(json['rules']) : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['children'] != null) {
      children = [];
      json['children'].forEach((v) {
        children?.add(HotelServiceCategoriesData.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  String? key;
  bool? isEnabled;
  dynamic parentId;
  int? level;
  String? type;
  Rules? rules;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<HotelServiceCategoriesData>? children;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['key'] = key;
    map['isEnabled'] = isEnabled;
    map['parentId'] = parentId;
    map['level'] = level;
    map['type'] = type;
    if (rules != null) {
      map['rules'] = rules?.toJson();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (children != null) {
      map['children'] = children?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Rules rulesFromJson(String str) => Rules.fromJson(json.decode(str));
String rulesToJson(Rules data) => json.encode(data.toJson());
class Rules {
  Rules({
      this.allowChildren, 
      this.allowOfferings,});

  Rules.fromJson(dynamic json) {
    allowChildren = json['allowChildren'];
    allowOfferings = json['allowOfferings'];
  }
  bool? allowChildren;
  bool? allowOfferings;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['allowChildren'] = allowChildren;
    map['allowOfferings'] = allowOfferings;
    return map;
  }

}