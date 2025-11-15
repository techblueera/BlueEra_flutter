import 'dart:convert';
RentalServiceModel rentalServiceModelFromJson(String str) => RentalServiceModel.fromJson(json.decode(str));
String rentalServiceModelToJson(RentalServiceModel data) => json.encode(data.toJson());
class RentalServiceModel {
  RentalServiceModel({
      this.status, 
      this.message, 
      this.data,});

  RentalServiceModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(RentalDataList.fromJson(v));
      });
    }
  }
  bool? status;
  String? message;
  List<RentalDataList>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

RentalDataList dataFromJson(String str) => RentalDataList.fromJson(json.decode(str));
String dataToJson(RentalDataList data) => json.encode(data.toJson());
class RentalDataList {
  RentalDataList({
      this.id, 
      this.userId, 
      this.name, 
      this.description, 
      this.contactNumber, 
      this.type, 
      this.tenant, 
      this.bhk, 
      this.availability, 
      this.addedBy, 
      this.highlights, 
      this.images, 
      this.address, 
      this.city, 
      this.pincode, 
      this.priceUnit,
      this.isActive, 
      this.isNegotiable, 
      this.rating, 
      this.reviews, 
      this.createdAt, 
      this.updatedAt, 
      this.distance,
      this.lat,
      this.lng,
      this.v,});

  RentalDataList.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    name = json['name'];
    description = json['description'];
    contactNumber = json['contact_number'];
    type = json['type'];
    tenant = json['tenant'];
    bhk = json['bhk'];
    availability = json['availability'];
    addedBy = json['addedBy'];
    highlights = json['highlights'] != null ? json['highlights'].cast<String>() : [];
    images = json['images'] != null ? json['images'].cast<String>() : [];
    address = json['address'];
    city = json['city'];
    pincode = json['pincode'];
    priceUnit = json['priceUnit'];
    isActive = json['is_active'];
    isNegotiable = json['is_negotiable'];
    rating = json['rating'];
    reviews = json['reviews'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    distance = json['distance'];
    lng = json['lng'];
    lat = json['lat'];
    v = json['__v'];
  }
  String? id;
  String? userId;
  String? name;
  String? description;
  String? contactNumber;
  String? type;
  String? tenant;
  String? bhk;
  String? availability;
  String? addedBy;
  List<String>? highlights;
  List<String>? images;
  String? address;
  String? city;
  String? pincode;
  String? priceUnit;
  bool? isActive;
  bool? isNegotiable;
  int? rating;
  int? reviews;
  String? createdAt;
  String? updatedAt;
  int? v;
  num? distance;
  num? lat;
  num? lng;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['name'] = name;
    map['description'] = description;
    map['contact_number'] = contactNumber;
    map['type'] = type;
    map['tenant'] = tenant;
    map['bhk'] = bhk;
    map['availability'] = availability;
    map['addedBy'] = addedBy;
    map['highlights'] = highlights;
    map['images'] = images;
    map['address'] = address;
    map['city'] = city;
    map['pincode'] = pincode;

    map['priceUnit'] = priceUnit;
    map['is_active'] = isActive;
    map['is_negotiable'] = isNegotiable;
    map['rating'] = rating;
    map['reviews'] = reviews;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['distance'] = distance;
    map['lat'] = lat;
    map['lng'] = lng;
    map['__v'] = v;
    return map;
  }

}

