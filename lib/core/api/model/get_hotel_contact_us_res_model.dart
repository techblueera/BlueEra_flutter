import 'dart:convert';
GetHotelContactUsResModel getHotelContactUsResModelFromJson(String str) => GetHotelContactUsResModel.fromJson(json.decode(str));
String getHotelContactUsResModelToJson(GetHotelContactUsResModel data) => json.encode(data.toJson());
class GetHotelContactUsResModel {
  GetHotelContactUsResModel({
      this.success, 
      this.data,});

  GetHotelContactUsResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(HotelContactUsData.fromJson(v));
      });
    }
  }
  bool? success;
  List<HotelContactUsData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

HotelContactUsData dataFromJson(String str) => HotelContactUsData.fromJson(json.decode(str));
String dataToJson(HotelContactUsData data) => json.encode(data.toJson());
class HotelContactUsData {
  HotelContactUsData({
      this.id,
      this.businessId,
      this.type,
      this.email,
      this.phone,
      this.address,
      this.website,
      this.v,});

  HotelContactUsData.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    type = json['type'];
    email = json['email'];
    phone = json['phone'];
    address = json['address'];
    website = json['website'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  String? type;
  String? email;
  String? phone;
  String? address;
  String? website;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['type'] = type;
    map['email'] = email;
    map['phone'] = phone;
    map['address'] = address;
    map['website'] = website;
    map['__v'] = v;
    return map;
  }

}