import 'dart:convert';
DepartmentResModel departmentResModelFromJson(String str) => DepartmentResModel.fromJson(json.decode(str));
String departmentResModelToJson(DepartmentResModel data) => json.encode(data.toJson());
class DepartmentResModel {
  DepartmentResModel({
      this.success, 
      this.data, 
      this.pagination,});

  DepartmentResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(DepartmentData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
  }
  bool? success;
  List<DepartmentData>? data;
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

DepartmentData dataFromJson(String str) => DepartmentData.fromJson(json.decode(str));
String dataToJson(DepartmentData data) => json.encode(data.toJson());
class DepartmentData {
  DepartmentData({
      this.id, 
      this.name, 
      this.hodName, 
      this.staffNames, 
      this.description, 
      this.uploadImages, 
      this.schoolId, 
      this.isActive, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  DepartmentData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    hodName = json['hodName'];
    staffNames = json['staffNames'] != null ? json['staffNames'].cast<String>() : [];
    description = json['description'];
    uploadImages = json['uploadImages'] != null ? json['uploadImages'].cast<String>() : [];
    schoolId = json['schoolId'] != null ? SchoolId.fromJson(json['schoolId']) : null;
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? name;
  String? hodName;
  List<String>? staffNames;
  String? description;
  List<String>? uploadImages;
  SchoolId? schoolId;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['hodName'] = hodName;
    map['staffNames'] = staffNames;
    map['description'] = description;
    map['uploadImages'] = uploadImages;
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