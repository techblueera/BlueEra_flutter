import 'dart:convert';
SocialActivityResModel socialActivityResModelFromJson(String str) => SocialActivityResModel.fromJson(json.decode(str));
String socialActivityResModelToJson(SocialActivityResModel data) => json.encode(data.toJson());
class SocialActivityResModel {
  SocialActivityResModel({
      this.success, 
      this.data,});

  SocialActivityResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SocialActivityData.fromJson(v));
      });
    }
  }
  bool? success;
  List<SocialActivityData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

SocialActivityData dataFromJson(String str) => SocialActivityData.fromJson(json.decode(str));
String dataToJson(SocialActivityData data) => json.encode(data.toJson());
class SocialActivityData {
  SocialActivityData({
      this.location, 
      this.id, 
      this.title, 
      this.description, 
      this.mediaUrl, 
      this.mediaType, 
      this.activityType, 
      this.date, 
      this.role, 
      this.organisationName, 
      this.impact, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  SocialActivityData.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    id = json['_id'];
    title = json['title'];
    description = json['description'];
    mediaUrl = json['mediaUrl'];
    mediaType = json['mediaType'];
    activityType = json['activityType'];
    date = json['date'];
    role = json['role'];
    organisationName = json['organisationName'];
    impact = json['impact'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  Location? location;
  String? id;
  String? title;
  String? description;
  String? mediaUrl;
  String? mediaType;
  String? activityType;
  String? date;
  String? role;
  String? organisationName;
  String? impact;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['_id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['mediaUrl'] = mediaUrl;
    map['mediaType'] = mediaType;
    map['activityType'] = activityType;
    map['date'] = date;
    map['role'] = role;
    map['organisationName'] = organisationName;
    map['impact'] = impact;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
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