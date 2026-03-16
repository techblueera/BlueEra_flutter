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
      this.image,
      this.key,
      this.isActive, 
      this.parentId, 
      this.level, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.children,});

  FoodCategoryData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    image = json['image'];
    key = json['key'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['children'] != null) {
      children = [];
      json['children'].forEach((v) {
        children?.add(Children.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  String? image;
  String? key;
  bool? isActive;
  dynamic parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<Children>? children;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['image'] = image;
    map['key'] = key;
    map['isActive'] = isActive;
    map['parentId'] = parentId;
    map['level'] = level;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (children != null) {
      map['children'] = children?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Children childrenFromJson(String str) => Children.fromJson(json.decode(str));
String childrenToJson(Children data) => json.encode(data.toJson());
class Children {
  Children({
      this.id, 
      this.name, 
      this.key, 
      this.type, 
      this.image,
      this.isActive,
      this.parentId, 
      this.level, 
      this.createdAt, 
      this.updatedAt, 
      this.v,
      this.children,
    });

  Children.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    key = json['key'];
    type = json['type'];
    image = json['image'];
    isActive = json['isActive'];
    parentId = json['parentId'];
    level = json['level'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['children'] != null) {
      children = [];
      json['children'].forEach((v) {
        children?.add(Children.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  String? key;
  String? type;
  String? image;
  bool? isActive;
  String? parentId;
  int? level;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<Children>? children;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['key'] = key;
    map['type'] = type;
    map['image'] = image;
    map['isActive'] = isActive;
    map['parentId'] = parentId;
    map['level'] = level;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (children != null) {
      map['children'] = children?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}