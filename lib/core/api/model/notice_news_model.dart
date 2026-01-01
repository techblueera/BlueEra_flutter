import 'dart:convert';
NoticeNewsModel noticeNewsModelFromJson(String str) => NoticeNewsModel.fromJson(json.decode(str));
String noticeNewsModelToJson(NoticeNewsModel data) => json.encode(data.toJson());
class NoticeNewsModel {
  NoticeNewsModel({
      this.success, 
      this.data,});

  NoticeNewsModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(NoticeNewsData.fromJson(v));
      });
    }
  }
  bool? success;
  List<NoticeNewsData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

NoticeNewsData dataFromJson(String str) => NoticeNewsData.fromJson(json.decode(str));
String dataToJson(NoticeNewsData data) => json.encode(data.toJson());
class NoticeNewsData {
  NoticeNewsData({
      this.id, 
      this.uploadPhoto, 
      this.title, 
      this.description, 
      this.date, 
      this.schoolId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  NoticeNewsData.fromJson(dynamic json) {
    id = json['_id'];
    uploadPhoto = json['uploadPhoto'];
    title = json['title'];
    description = json['description'];
    date = json['date'];
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? uploadPhoto;
  String? title;
  String? description;
  String? date;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['uploadPhoto'] = uploadPhoto;
    map['title'] = title;
    map['description'] = description;
    map['date'] = date;
    map['schoolId'] = schoolId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}