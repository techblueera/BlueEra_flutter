import 'dart:convert';
AcademicCalenderResModel academicCalenderResModelFromJson(String str) => AcademicCalenderResModel.fromJson(json.decode(str));
String academicCalenderResModelToJson(AcademicCalenderResModel data) => json.encode(data.toJson());
class AcademicCalenderResModel {
  AcademicCalenderResModel({
      this.success, 
      this.data,});

  AcademicCalenderResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(AcademicCalenderData.fromJson(v));
      });
    }
  }
  bool? success;
  List<AcademicCalenderData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

AcademicCalenderData dataFromJson(String str) => AcademicCalenderData.fromJson(json.decode(str));
String dataToJson(AcademicCalenderData data) => json.encode(data.toJson());
class AcademicCalenderData {
  AcademicCalenderData({
      this.id, 
      this.title, 
      this.uploadPhoto,
      this.description, 
      this.schoolId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  AcademicCalenderData.fromJson(dynamic json) {
    id = json['_id'];
    title = json['title'];
    uploadPhoto = json['fileUrl'];
    description = json['description'];
    schoolId = json['schoolId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? title;
  String? uploadPhoto;
  String? description;
  String? schoolId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['title'] = title;
    map['fileUrl'] = uploadPhoto;
    map['description'] = description;
    map['schoolId'] = schoolId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}