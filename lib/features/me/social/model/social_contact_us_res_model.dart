import 'dart:convert';
SocialContactUsResModel socialContactUsResModelFromJson(String str) => SocialContactUsResModel.fromJson(json.decode(str));
String socialContactUsResModelToJson(SocialContactUsResModel data) => json.encode(data.toJson());
class SocialContactUsResModel {
  SocialContactUsResModel({
      this.success, 
      this.data,});

  SocialContactUsResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? SocialContactUsData.fromJson(json['data']) : null;
  }
  bool? success;
  SocialContactUsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

SocialContactUsData dataFromJson(String str) => SocialContactUsData.fromJson(json.decode(str));
String dataToJson(SocialContactUsData data) => json.encode(data.toJson());
class SocialContactUsData {
  SocialContactUsData({
      this.location, 
      this.id, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.email, 
      this.name, 
      this.phoneNo, 
      this.updatedAt, 
      this.websiteUrl,});

  SocialContactUsData.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    email = json['email'];
    name = json['name'];
    phoneNo = json['phoneNo'];
    updatedAt = json['updatedAt'];
    websiteUrl = json['websiteUrl'];
  }
  Location? location;
  String? id;
  String? userId;
  int? v;
  String? createdAt;
  String? email;
  String? name;
  String? phoneNo;
  String? updatedAt;
  String? websiteUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['_id'] = id;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['email'] = email;
    map['name'] = name;
    map['phoneNo'] = phoneNo;
    map['updatedAt'] = updatedAt;
    map['websiteUrl'] = websiteUrl;
    return map;
  }

}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
      this.name, 
      this.type, 
      this.coordinates,});

  Location.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }
  String? name;
  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

}