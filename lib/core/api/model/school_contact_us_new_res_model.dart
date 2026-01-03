// import 'dart:convert';
// SchoolContactUsNewResModel schoolContactUsNewResModelFromJson(String str) => SchoolContactUsNewResModel.fromJson(json.decode(str));
// String schoolContactUsNewResModelToJson(SchoolContactUsNewResModel data) => json.encode(data.toJson());
// class SchoolContactUsNewResModel {
//   SchoolContactUsNewResModel({
//       this.success,
//       this.data,});
//
//   SchoolContactUsNewResModel.fromJson(dynamic json) {
//     success = json['success'];
//     if (json['data'] != null) {
//       data = [];
//       json['data'].forEach((v) {
//         data?.add(SchoolContactUsData.fromJson(v));
//       });
//     }
//   }
//   bool? success;
//   List<SchoolContactUsData>? data;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['success'] = success;
//     if (data != null) {
//       map['data'] = data?.map((v) => v.toJson()).toList();
//     }
//     return map;
//   }
//
// }
//
// SchoolContactUsData dataFromJson(String str) => SchoolContactUsData.fromJson(json.decode(str));
// String dataToJson(SchoolContactUsData data) => json.encode(data.toJson());
// class SchoolContactUsData {
//   SchoolContactUsData({
//       this.branch,
//       this.id,
//       this.website,
//       this.address,
//       this.location,
//       this.schoolId,
//       this.contactInfo,
//       this.createdAt,
//       this.updatedAt,
//       this.v,
//       // this.departments,
//   });
//
//   SchoolContactUsData.fromJson(dynamic json) {
//     branch = json['branch'];
//     id = json['_id'];
//     website = json['website'];
//     address = json['address'];
//     location = json['location'] != null ? Location.fromJson(json['location']) : null;
//     schoolId = json['schoolId'];
//     if (json['contactInfo'] != null) {
//       contactInfo = [];
//       json['contactInfo'].forEach((v) {
//         contactInfo?.add(ContactInfo.fromJson(v));
//       });
//     }
//     createdAt = json['createdAt'];
//     updatedAt = json['updatedAt'];
//     v = json['__v'];
//     // if (json['departments'] != null) {
//     //   departments = [];
//     //   json['departments'].forEach((v) {
//     //     departments?.add(Dynamic.fromJson(v));
//     //   });
//     // }
//   }
//   String? branch;
//   String? id;
//   String? website;
//   String? address;
//   Location? location;
//   String? schoolId;
//   List<ContactInfo>? contactInfo;
//   String? createdAt;
//   String? updatedAt;
//   int? v;
//   // List<dynamic>? departments;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['branch'] = branch;
//     map['_id'] = id;
//     map['website'] = website;
//     map['address'] = address;
//     if (location != null) {
//       map['location'] = location?.toJson();
//     }
//     map['schoolId'] = schoolId;
//     if (contactInfo != null) {
//       map['contactInfo'] = contactInfo?.map((v) => v.toJson()).toList();
//     }
//     map['createdAt'] = createdAt;
//     map['updatedAt'] = updatedAt;
//     map['__v'] = v;
//     // if (departments != null) {
//     //   map['departments'] = departments?.map((v) => v.toJson()).toList();
//     // }
//     return map;
//   }
//
// }
//
// ContactInfo contactInfoFromJson(String str) => ContactInfo.fromJson(json.decode(str));
// String contactInfoToJson(ContactInfo data) => json.encode(data.toJson());
// class ContactInfo {
//   ContactInfo({
//       this.title,
//       this.email,
//       this.phone,
//       this.id,});
//
//   ContactInfo.fromJson(dynamic json) {
//     title = json['title'];
//     email = json['email'];
//     phone = json['phone'];
//     id = json['_id'];
//   }
//   String? title;
//   String? email;
//   String? phone;
//   String? id;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['title'] = title;
//     map['email'] = email;
//     map['phone'] = phone;
//     map['_id'] = id;
//     return map;
//   }
//
// }
//
// Location locationFromJson(String str) => Location.fromJson(json.decode(str));
// String locationToJson(Location data) => json.encode(data.toJson());
// class Location {
//   Location({
//       this.type,
//       this.coordinates,});
//
//   Location.fromJson(dynamic json) {
//     type = json['type'];
//     coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
//   }
//   String? type;
//   List<double>? coordinates;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['type'] = type;
//     map['coordinates'] = coordinates;
//     return map;
//   }
//
// }