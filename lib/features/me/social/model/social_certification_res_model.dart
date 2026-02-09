import 'dart:convert';
SocialCertificationResModel socialCertificationResModelFromJson(String str) => SocialCertificationResModel.fromJson(json.decode(str));
String socialCertificationResModelToJson(SocialCertificationResModel data) => json.encode(data.toJson());
class SocialCertificationResModel {
  SocialCertificationResModel({
      this.success, 
      this.data,});

  SocialCertificationResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SocialCertificationData.fromJson(v));
      });
    }
  }
  bool? success;
  List<SocialCertificationData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

SocialCertificationData dataFromJson(String str) => SocialCertificationData.fromJson(json.decode(str));
String dataToJson(SocialCertificationData data) => json.encode(data.toJson());
class SocialCertificationData {
  SocialCertificationData({
      this.id, 
      this.title, 
      this.issuedDate, 
      this.fileUrl, 
      this.description, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  SocialCertificationData.fromJson(dynamic json) {
    id = json['_id'];
    title = json['title'];
    issuedDate = json['issuedDate'];
    fileUrl = json['fileUrl'];
    description = json['description'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? title;
  String? issuedDate;
  String? fileUrl;
  String? description;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['title'] = title;
    map['issuedDate'] = issuedDate;
    map['fileUrl'] = fileUrl;
    map['description'] = description;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}