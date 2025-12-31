import 'dart:convert';
SchoolContactUsModel schoolContactUsModelFromJson(String str) => SchoolContactUsModel.fromJson(json.decode(str));
String schoolContactUsModelToJson(SchoolContactUsModel data) => json.encode(data.toJson());
class SchoolContactUsModel {
  SchoolContactUsModel({
      this.success, 
      this.data,});

  SchoolContactUsModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? SchoolContactUsData.fromJson(json['data']) : null;
  }
  bool? success;
  SchoolContactUsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

SchoolContactUsData dataFromJson(String str) => SchoolContactUsData.fromJson(json.decode(str));
String dataToJson(SchoolContactUsData data) => json.encode(data.toJson());
class SchoolContactUsData {
  SchoolContactUsData({
      this.location, 
      this.id, 
      this.website, 
      this.address, 
      this.schoolId, 
      this.contactInfo, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.branch,});

  SchoolContactUsData.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    id = json['_id'];
    website = json['website'];
    address = json['address'];
    schoolId = json['schoolId'];
    if (json['contactInfo'] != null) {
      contactInfo = [];
      json['contactInfo'].forEach((v) {
        contactInfo?.add(ContactInfo.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    branch = json['branch'];
  }
  Location? location;
  String? id;
  String? website;
  String? address;
  String? schoolId;
  List<ContactInfo>? contactInfo;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? branch;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['_id'] = id;
    map['website'] = website;
    map['address'] = address;
    map['schoolId'] = schoolId;
    if (contactInfo != null) {
      map['contactInfo'] = contactInfo?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['branch'] = branch;
    return map;
  }

}

ContactInfo contactInfoFromJson(String str) => ContactInfo.fromJson(json.decode(str));
String contactInfoToJson(ContactInfo data) => json.encode(data.toJson());
class ContactInfo {
  ContactInfo({
      this.title, 
      this.email, 
      this.phone, 
      this.id,});

  ContactInfo.fromJson(dynamic json) {
    title = json['title'];
    email = json['email'];
    phone = json['phone'];
    id = json['_id'];
  }
  String? title;
  String? email;
  String? phone;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['email'] = email;
    map['phone'] = phone;
    map['_id'] = id;
    return map;
  }

}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
      this.type, 
      this.coordinates,});

  Location.fromJson(dynamic json) {
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }
  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

}