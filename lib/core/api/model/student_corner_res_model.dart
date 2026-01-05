import 'dart:convert';
StudentCornerResModel studentCornerResModelFromJson(String str) => StudentCornerResModel.fromJson(json.decode(str));
String studentCornerResModelToJson(StudentCornerResModel data) => json.encode(data.toJson());
class StudentCornerResModel {
  StudentCornerResModel({
      this.success, 
      this.data,});

  StudentCornerResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? StudentCornerData.fromJson(json['data']) : null;
  }
  bool? success;
  StudentCornerData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

StudentCornerData dataFromJson(String str) => StudentCornerData.fromJson(json.decode(str));
String dataToJson(StudentCornerData data) => json.encode(data.toJson());
class StudentCornerData {
  StudentCornerData({
      this.id, 
      this.schoolId, 
      this.timeTable, 
      this.syllabus, 
      this.examSchedule, 
      this.results, 
      this.downloads, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  StudentCornerData.fromJson(dynamic json) {
    id = json['_id'];
    schoolId = json['schoolId'];
    if (json['timeTable'] != null) {
      timeTable = [];
      json['timeTable'].forEach((v) {
        timeTable?.add(StudentCornerItem.fromJson(v));
      });
    }
    if (json['syllabus'] != null) {
      syllabus = [];
      json['syllabus'].forEach((v) {
        syllabus?.add(StudentCornerItem.fromJson(v));
      });
    }
    if (json['examSchedule'] != null) {
      examSchedule = [];
      json['examSchedule'].forEach((v) {
        examSchedule?.add(StudentCornerItem.fromJson(v));
      });
    }
    if (json['results'] != null) {
      results = [];
      json['results'].forEach((v) {
        results?.add(StudentCornerItem.fromJson(v));
      });
    }
    if (json['downloads'] != null) {
      downloads = [];
      json['downloads'].forEach((v) {
        downloads?.add(StudentCornerItem.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? schoolId;
  List<StudentCornerItem>? timeTable;
  List<StudentCornerItem>? syllabus;
  List<StudentCornerItem>? examSchedule;
  List<StudentCornerItem>? results;
  List<StudentCornerItem>? downloads;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['schoolId'] = schoolId;
    if (timeTable != null) {
      map['timeTable'] = timeTable?.map((v) => v.toJson()).toList();
    }
    if (syllabus != null) {
      map['syllabus'] = syllabus?.map((v) => v.toJson()).toList();
    }
    if (examSchedule != null) {
      map['examSchedule'] = examSchedule?.map((v) => v.toJson()).toList();
    }
    if (results != null) {
      map['results'] = results?.map((v) => v.toJson()).toList();
    }
    if (downloads != null) {
      map['downloads'] = downloads?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}


StudentCornerItem timeTableFromJson(String str) => StudentCornerItem.fromJson(json.decode(str));
String timeTableToJson(StudentCornerItem data) => json.encode(data.toJson());
class StudentCornerItem {
  StudentCornerItem({
      this.title, 
      this.uploadPhoto,
      this.description, 
      this.id,});

  StudentCornerItem.fromJson(dynamic json) {
    title = json['title'];
    uploadPhoto = json['fileUrl'];
    description = json['description'];
    id = json['_id'];
  }
  String? title;
  String? uploadPhoto;
  String? description;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['fileUrl'] = uploadPhoto;
    map['description'] = description;
    map['_id'] = id;
    return map;
  }

}