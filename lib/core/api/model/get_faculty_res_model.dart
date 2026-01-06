import 'dart:convert';
GetFacultyResModel getFacultyResModelFromJson(String str) => GetFacultyResModel.fromJson(json.decode(str));
String getFacultyResModelToJson(GetFacultyResModel data) => json.encode(data.toJson());
class GetFacultyResModel {
  GetFacultyResModel({
      this.success, 
      this.data, 
      this.pagination,});

  GetFacultyResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(FacultyData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
  }
  bool? success;
  List<FacultyData>? data;
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

FacultyData dataFromJson(String str) => FacultyData.fromJson(json.decode(str));
String dataToJson(FacultyData data) => json.encode(data.toJson());
class FacultyData {
  FacultyData({
      this.experience, 
      this.id, 
      this.name, 
      this.position, 
      this.school, 
      this.qualifications, 
      this.email, 
      this.phone, 
      this.photo, 
      this.bio, 
      this.isActive,
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  FacultyData.fromJson(dynamic json) {
    experience = json['experience'] != null ? Experience.fromJson(json['experience']) : null;
    id = json['_id'];
    name = json['name'];
    position = json['position'];
    school = json['school'] != null ? School.fromJson(json['school']) : null;
    qualifications = json['qualifications'] != null ? json['qualifications'].cast<String>() : [];
    email = json['email'];
    phone = json['phone'];
    photo = json['photo'];
    bio = json['bio'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  Experience? experience;
  String? id;
  String? name;
  String? position;
  School? school;
  List<String>? qualifications;
  String? email;
  String? phone;
  String? photo;
  String? bio;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (experience != null) {
      map['experience'] = experience?.toJson();
    }
    map['_id'] = id;
    map['name'] = name;
    map['position'] = position;
    if (school != null) {
      map['school'] = school?.toJson();
    }
    map['qualifications'] = qualifications;
    map['email'] = email;
    map['phone'] = phone;
    map['photo'] = photo;
    map['bio'] = bio;

    map['isActive'] = isActive;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

School schoolFromJson(String str) => School.fromJson(json.decode(str));
String schoolToJson(School data) => json.encode(data.toJson());
class School {
  School({
      this.id, 
      this.name, 
      this.type,});

  School.fromJson(dynamic json) {
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

Experience experienceFromJson(String str) => Experience.fromJson(json.decode(str));
String experienceToJson(Experience data) => json.encode(data.toJson());
class Experience {
  Experience({
      this.years, 
      this.details,});

  Experience.fromJson(dynamic json) {
    years = json['years'];
    details = json['details'];
  }
  int? years;
  String? details;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['years'] = years;
    map['details'] = details;
    return map;
  }

}