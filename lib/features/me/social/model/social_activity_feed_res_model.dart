import 'dart:convert';
SocialActivityFeedResModel socialActivityFeedResModelFromJson(String str) => SocialActivityFeedResModel.fromJson(json.decode(str));
String socialActivityFeedResModelToJson(SocialActivityFeedResModel data) => json.encode(data.toJson());
class SocialActivityFeedResModel {
  SocialActivityFeedResModel({
      this.success, 
      this.data,});

  SocialActivityFeedResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SocialActivityFeedData.fromJson(v));
      });
    }
  }
  bool? success;
  List<SocialActivityFeedData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

SocialActivityFeedData dataFromJson(String str) => SocialActivityFeedData.fromJson(json.decode(str));
String dataToJson(SocialActivityFeedData data) => json.encode(data.toJson());
class SocialActivityFeedData {
  SocialActivityFeedData({
      this.id, 
      this.title, 
      this.mediaUrls, 
      this.mediaType, 
      this.description, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  SocialActivityFeedData.fromJson(dynamic json) {
    id = json['_id'];
    title = json['title'];
    mediaUrls = json['mediaUrls'] != null ? json['mediaUrls'].cast<String>() : [];
    mediaType = json['mediaType'];
    description = json['description'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? title;
  List<String>? mediaUrls;
  String? mediaType;
  String? description;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['title'] = title;
    map['mediaUrls'] = mediaUrls;
    map['mediaType'] = mediaType;
    map['description'] = description;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}