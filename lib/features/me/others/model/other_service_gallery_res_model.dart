import 'dart:convert';
OtherServiceGalleryResModel otherServiceGalleryResModelFromJson(String str) => OtherServiceGalleryResModel.fromJson(json.decode(str));
String otherServiceGalleryResModelToJson(OtherServiceGalleryResModel data) => json.encode(data.toJson());
class OtherServiceGalleryResModel {
  OtherServiceGalleryResModel({
      this.success, 
      this.data,});

  OtherServiceGalleryResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(OtherServiceGalleryData.fromJson(v));
      });
    }
  }
  bool? success;
  List<OtherServiceGalleryData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

OtherServiceGalleryData dataFromJson(String str) => OtherServiceGalleryData.fromJson(json.decode(str));
String dataToJson(OtherServiceGalleryData data) => json.encode(data.toJson());
class OtherServiceGalleryData {
  OtherServiceGalleryData({
      this.id, 
      this.userId, 
      this.businessProfileId, 
      this.imageUrls, 
      this.title, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  OtherServiceGalleryData.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    businessProfileId = json['businessProfileId'];
    imageUrls = json['imageUrls'] != null ? json['imageUrls'].cast<String>() : [];
    title = json['title'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? userId;
  String? businessProfileId;
  List<String>? imageUrls;
  String? title;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['businessProfileId'] = businessProfileId;
    map['imageUrls'] = imageUrls;
    map['title'] = title;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}