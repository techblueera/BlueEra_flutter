import 'dart:convert';

import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';

HotelContactUsResModel hotelContactUsResModelFromJson(String str) => HotelContactUsResModel.fromJson(json.decode(str));
String hotelContactUsResModelToJson(HotelContactUsResModel data) => json.encode(data.toJson());
class HotelContactUsResModel {
  HotelContactUsResModel({
      this.success, 
      this.message, 
      this.data,});

  HotelContactUsResModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? HotelContactUsData.fromJson(json['data']) : null;
  }
  bool? success;
  String? message;
  HotelContactUsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

HotelContactUsData dataFromJson(String str) => HotelContactUsData.fromJson(json.decode(str));
String dataToJson(HotelContactUsData data) => json.encode(data.toJson());
class HotelContactUsData {
  HotelContactUsData({
      this.id, 
      this.name, 

      this.contactNumber, 
      this.email, 
      this.website,
      this.description, 
      this.departments, 
      this.emergencyContacts, 
      this.isActive, 
      this.address,

      this.v, 
 });

  HotelContactUsData.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    contactNumber = json['contactNumber'];
    email = json['email'];
    website = json['website'];
    address = json['address'];
    description = json['description'];
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments?.add(Departments.fromJson(v));
      });
    }
    emergencyContacts = json['emergencyContacts'] != null ? EmergencyContacts.fromJson(json['emergencyContacts']) : null;
    isActive = json['isActive'];

    v = json['__v'];
  }
  String? id;
  String? name;
  String? contactNumber;
  String? email;
  String? website;
  String? address;
  String? description;
  List<Departments>? departments;
  EmergencyContacts? emergencyContacts;
  bool? isActive;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['contactNumber'] = contactNumber;
    map['email'] = email;
    map['website'] = website;
    map['address'] = address;
    map['description'] = description;
    if (departments != null) {
      map['departments'] = departments?.map((v) => v.toJson()).toList();
    }
    if (emergencyContacts != null) {
      map['emergencyContacts'] = emergencyContacts?.toJson();
    }
    map['isActive'] = isActive;

    map['__v'] = v;
    return map;
  }

}

EmergencyContacts emergencyContactsFromJson(String str) => EmergencyContacts.fromJson(json.decode(str));
String emergencyContactsToJson(EmergencyContacts data) => json.encode(data.toJson());
class EmergencyContacts {
  EmergencyContacts({
      this.phone, 
      this.policeStation, 
      this.hospital, 
      this.fireBrigade,});

  EmergencyContacts.fromJson(dynamic json) {
    phone = json['phone'];
    policeStation = json['policeStation'];
    hospital = json['hospital'];
    fireBrigade = json['fireBrigade'];
  }
  String? phone;
  String? policeStation;
  String? hospital;
  String? fireBrigade;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phone'] = phone;
    map['policeStation'] = policeStation;
    map['hospital'] = hospital;
    map['fireBrigade'] = fireBrigade;
    return map;
  }

}
//
// Departments departmentsFromJson(String str) => Departments.fromJson(json.decode(str));
// String departmentsToJson(Departments data) => json.encode(data.toJson());
// class Departments {
//   Departments({
//       this.title,
//       this.email,
//       this.phone,
//       this.id,});
//
//   Departments.fromJson(dynamic json) {
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