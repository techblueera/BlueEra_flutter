import 'dart:convert';
HospitalGalleryResModel hospitalGalleryResModelFromJson(String str) => HospitalGalleryResModel.fromJson(json.decode(str));
String hospitalGalleryResModelToJson(HospitalGalleryResModel data) => json.encode(data.toJson());
class HospitalGalleryResModel {
  HospitalGalleryResModel({
      this.success, 
      this.data,});

  HospitalGalleryResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(HospitalGalleryData.fromJson(v));
      });
    }
  }
  bool? success;
  List<HospitalGalleryData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

HospitalGalleryData dataFromJson(String str) => HospitalGalleryData.fromJson(json.decode(str));
String dataToJson(HospitalGalleryData data) => json.encode(data.toJson());
class HospitalGalleryData {
  HospitalGalleryData({
      this.id, 
      this.title, 
      this.images, 
      this.hospitalId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  HospitalGalleryData.fromJson(dynamic json) {
    id = json['_id'];
    title = json['title'];
    images = json['images'] != null ? json['images'].cast<String>() : [];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? title;
  List<String>? images;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['title'] = title;
    map['images'] = images;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}