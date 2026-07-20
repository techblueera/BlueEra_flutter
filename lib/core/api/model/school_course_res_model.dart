import 'dart:convert';
SchoolCourseResModel schoolCourseResModelFromJson(String str) => SchoolCourseResModel.fromJson(json.decode(str));
String schoolCourseResModelToJson(SchoolCourseResModel data) => json.encode(data.toJson());
class SchoolCourseResModel {
  SchoolCourseResModel({
      this.success, 
      this.data, 
      this.pagination,});

  SchoolCourseResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SchoolCourseData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
  }
  bool? success;
  List<SchoolCourseData>? data;
  Pagination? pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    return map;
  }

}

Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
String paginationToJson(Pagination data) => json.encode(data.toJson());
class Pagination {
  Pagination({
      this.currentPage, 
      this.totalPages, 
      this.totalItems, 
      this.hasNext, 
      this.hasPrev,});

  Pagination.fromJson(dynamic json) {
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    hasNext = json['hasNext'];
    hasPrev = json['hasPrev'];
  }
  String? currentPage;
  int? totalPages;
  int? totalItems;
  bool? hasNext;
  bool? hasPrev;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['currentPage'] = currentPage;
    map['totalPages'] = totalPages;
    map['totalItems'] = totalItems;
    map['hasNext'] = hasNext;
    map['hasPrev'] = hasPrev;
    return map;
  }

}

SchoolCourseData dataFromJson(String str) => SchoolCourseData.fromJson(json.decode(str));
String dataToJson(SchoolCourseData data) => json.encode(data.toJson());
class SchoolCourseData {
  SchoolCourseData({
      this.courseFees,
      this.id,
      this.name,
      this.admissionProcess,
      this.eligibility,
      this.duration,
      this.description,
      this.image,
      this.schoolId,
      this.isActive,
      this.createdAt,
      this.updatedAt,
      this.v,});

  SchoolCourseData.fromJson(dynamic json) {
    courseFees = json['courseFees'] != null ? CourseFees.fromJson(json['courseFees']) : null;
    id = json['_id'];
    name = json['name'];
    admissionProcess = json['admissionProcess'];
    eligibility = json['eligibility'];
    duration = json['duration'];
    description = json['description'];
    image = json['image']?.toString();
    schoolId = json['schoolId'] != null ? SchoolId.fromJson(json['schoolId']) : null;
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  CourseFees? courseFees;
  String? id;
  String? name;
  String? admissionProcess;
  String? eligibility;
  String? duration;
  String? description;
  String? image;
  SchoolId? schoolId;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (courseFees != null) {
      map['courseFees'] = courseFees?.toJson();
    }
    map['_id'] = id;
    map['name'] = name;
    map['admissionProcess'] = admissionProcess;
    map['eligibility'] = eligibility;
    map['duration'] = duration;
    map['description'] = description;
    map['image'] = image;
    if (schoolId != null) {
      map['schoolId'] = schoolId?.toJson();
    }
    map['isActive'] = isActive;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

SchoolId schoolIdFromJson(String str) => SchoolId.fromJson(json.decode(str));
String schoolIdToJson(SchoolId data) => json.encode(data.toJson());
class SchoolId {
  SchoolId({
      this.id, 
      this.name, 
      this.type,});

  SchoolId.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    type = json['type'];
  }
  String? id;
  String? name;
  String? type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['type'] = type;
    return map;
  }

}

CourseFees courseFeesFromJson(String str) => CourseFees.fromJson(json.decode(str));
String courseFeesToJson(CourseFees data) => json.encode(data.toJson());
class CourseFees {
  CourseFees({
      this.monthly, 
      this.yearly,});

  CourseFees.fromJson(dynamic json) {
    monthly = json['monthly'];
    yearly = json['yearly'];
  }
  int? monthly;
  int? yearly;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['monthly'] = monthly;
    map['yearly'] = yearly;
    return map;
  }

}