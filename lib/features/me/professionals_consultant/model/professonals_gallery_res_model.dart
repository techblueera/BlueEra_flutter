import 'dart:convert';
ProfessonalsGalleryResModel professonalsGalleryResModelFromJson(String str) => ProfessonalsGalleryResModel.fromJson(json.decode(str));
String professonalsGalleryResModelToJson(ProfessonalsGalleryResModel data) => json.encode(data.toJson());
class ProfessonalsGalleryResModel {
  ProfessonalsGalleryResModel({
      this.success, 
      this.data,});

  ProfessonalsGalleryResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? ProfessonalsGalleryData.fromJson(json['data']) : null;
  }
  bool? success;
  ProfessonalsGalleryData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

ProfessonalsGalleryData dataFromJson(String str) => ProfessonalsGalleryData.fromJson(json.decode(str));
String dataToJson(ProfessonalsGalleryData data) => json.encode(data.toJson());
class ProfessonalsGalleryData {
  ProfessonalsGalleryData({
      this.id, 
      this.userId, 
      this.title, 
      this.imageKeys, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.signedUrls,});

  ProfessonalsGalleryData.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    title = json['title'];
    imageKeys = json['imageKeys'] != null ? json['imageKeys'].cast<String>() : [];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    signedUrls = json['signedUrls'] != null ? json['signedUrls'].cast<String>() : [];
  }
  String? id;
  String? userId;
  String? title;
  List<String>? imageKeys;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<String>? signedUrls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['title'] = title;
    map['imageKeys'] = imageKeys;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['signedUrls'] = signedUrls;
    return map;
  }

}