import 'dart:convert';
HotelPropertyPhotoResModel hotelPropertyPhotoResModelFromJson(String str) => HotelPropertyPhotoResModel.fromJson(json.decode(str));
String hotelPropertyPhotoResModelToJson(HotelPropertyPhotoResModel data) => json.encode(data.toJson());
class HotelPropertyPhotoResModel {
  HotelPropertyPhotoResModel({
      this.success, 
      this.data,});

  HotelPropertyPhotoResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(HotelPropertyPhotoData.fromJson(v));
      });
    }
  }
  bool? success;
  List<HotelPropertyPhotoData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

HotelPropertyPhotoData dataFromJson(String str) => HotelPropertyPhotoData.fromJson(json.decode(str));
String dataToJson(HotelPropertyPhotoData data) => json.encode(data.toJson());
class HotelPropertyPhotoData {
  HotelPropertyPhotoData({
      this.id, 
      this.category, 
      this.businessId, 
      this.v, 
      this.updatedAt,
      this.imageReferences,});

  HotelPropertyPhotoData.fromJson(dynamic json) {
    id = json['_id'];
    category = json['category'];
    businessId = json['businessId'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    imageReferences = json['imageReferences'] != null ? json['imageReferences'].cast<String>() : [];
  }
  String? id;
  String? category;
  String? businessId;
  String? updatedAt;
  int? v;
  List<String>? imageReferences;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['category'] = category;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['imageReferences'] = imageReferences;
    map['updatedAt'] = updatedAt;
    return map;
  }

}