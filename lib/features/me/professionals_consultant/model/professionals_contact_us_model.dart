import 'dart:convert';
ProfessionalsContactUsModel professionalsContactUsModelFromJson(String str) => ProfessionalsContactUsModel.fromJson(json.decode(str));
String professionalsContactUsModelToJson(ProfessionalsContactUsModel data) => json.encode(data.toJson());
class ProfessionalsContactUsModel {
  ProfessionalsContactUsModel({
      this.success, 
      this.data,});

  ProfessionalsContactUsModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? ProfessionalsContactUsData.fromJson(json['data']) : null;
  }
  bool? success;
  ProfessionalsContactUsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

ProfessionalsContactUsData dataFromJson(String str) => ProfessionalsContactUsData.fromJson(json.decode(str));
String dataToJson(ProfessionalsContactUsData data) => json.encode(data.toJson());
class ProfessionalsContactUsData {
  ProfessionalsContactUsData({
      this.location, 
      this.id, 
      this.userId, 
      this.v, 
      this.address, 
      this.contactPerson, 
      this.createdAt, 
      this.email, 
      this.phone, 
      this.updatedAt, 
      this.website,});

  ProfessionalsContactUsData.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    address = json['address'];
    contactPerson = json['contactPerson'];
    createdAt = json['createdAt'];
    email = json['email'];
    phone = json['phone'];
    updatedAt = json['updatedAt'];
    website = json['website'];
  }
  Location? location;
  String? id;
  String? userId;
  int? v;
  String? address;
  String? contactPerson;
  String? createdAt;
  String? email;
  String? phone;
  String? updatedAt;
  String? website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['_id'] = id;
    map['userId'] = userId;
    map['__v'] = v;
    map['address'] = address;
    map['contactPerson'] = contactPerson;
    map['createdAt'] = createdAt;
    map['email'] = email;
    map['phone'] = phone;
    map['updatedAt'] = updatedAt;
    map['website'] = website;
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