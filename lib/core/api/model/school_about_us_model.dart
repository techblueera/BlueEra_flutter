import 'dart:convert';
SchoolAboutUsModel schoolAboutUsModelFromJson(String str) => SchoolAboutUsModel.fromJson(json.decode(str));
String schoolAboutUsModelToJson(SchoolAboutUsModel data) => json.encode(data.toJson());
class SchoolAboutUsModel {
  SchoolAboutUsModel({
      this.success, 
      this.data,});

  SchoolAboutUsModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? AboutUsData.fromJson(json['data']) : null;
  }
  bool? success;
  AboutUsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

AboutUsData dataFromJson(String str) => AboutUsData.fromJson(json.decode(str));
String dataToJson(AboutUsData data) => json.encode(data.toJson());
class AboutUsData {
  AboutUsData({
      this.principalMessage, 
      this.id, 
      this.visionAndMission, 
      this.history, 
      this.management, 
      this.schoolId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  AboutUsData.fromJson(dynamic json) {
    principalMessage = json['principalMessage'] != null ? PrincipalMessage.fromJson(json['principalMessage']) : null;
    history = json['history'] != null ? PrincipalMessage.fromJson(json['history']) : null;
    id = json['_id'];
    visionAndMission = json['visionAndMission'];
    if (json['management'] != null) {
      management = [];
      json['management'].forEach((v) {
        management?.add(Management.fromJson(v));
      });
    }
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  PrincipalMessage? principalMessage;
  String? id;
  String? visionAndMission;
  PrincipalMessage? history;
  List<Management>? management;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (principalMessage != null) {
      map['principalMessage'] = principalMessage?.toJson();
    }
    if (history != null) {
      map['history'] = history?.toJson();
    }
    map['_id'] = id;
    map['visionAndMission'] = visionAndMission;
    // map['history'] = history;
    if (management != null) {
      map['management'] = management?.map((v) => v.toJson()).toList();
    }
    map['schoolId'] = schoolId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Management managementFromJson(String str) => Management.fromJson(json.decode(str));
String managementToJson(Management data) => json.encode(data.toJson());
class Management {
  Management({
      this.name, 
      this.position, 
      this.photo, 
      this.bio, 
      this.qualification,
      this.id,});

  Management.fromJson(dynamic json) {
    name = json['name'];
    position = json['position'];
    photo = json['photo'];
    bio = json['bio'];
    id = json['_id'];
    qualification = json['qualification'] != null ? json['qualification'].cast<String>() : [];

  }
  String? name;
  String? position;
  String? photo;
  String? bio;
  String? id;
  List<String>? qualification;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['position'] = position;
    map['photo'] = photo;
    map['bio'] = bio;
    map['qualification'] = qualification;
    map['_id'] = id;
    return map;
  }

}

PrincipalMessage principalMessageFromJson(String str) => PrincipalMessage.fromJson(json.decode(str));
String principalMessageToJson(PrincipalMessage data) => json.encode(data.toJson());
class PrincipalMessage {
  PrincipalMessage({
      this.name, 
      this.position, 
      this.photo, 
      this.message,});

  PrincipalMessage.fromJson(dynamic json) {
    name = json['name'];
    position = json['position'];
    photo = json['photo'];
    message = json['message'];
  }
  String? name;
  String? position;
  String? photo;
  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['position'] = position;
    map['photo'] = photo;
    map['message'] = message;
    return map;
  }

}