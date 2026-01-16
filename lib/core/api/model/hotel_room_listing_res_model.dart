import 'dart:convert';
HotelRoomListingResModel hotelRoomListingResModelFromJson(String str) => HotelRoomListingResModel.fromJson(json.decode(str));
String hotelRoomListingResModelToJson(HotelRoomListingResModel data) => json.encode(data.toJson());
class HotelRoomListingResModel {
  HotelRoomListingResModel({
      this.success, 
      this.data,});

  HotelRoomListingResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(HotelRoomData.fromJson(v));
      });
    }
  }
  bool? success;
  List<HotelRoomData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

HotelRoomData dataFromJson(String str) => HotelRoomData.fromJson(json.decode(str));
String dataToJson(HotelRoomData data) => json.encode(data.toJson());
class HotelRoomData {
  HotelRoomData({
      this.size, 
      this.images, 
      this.id, 
      this.businessId, 
      this.name, 
      this.type, 
      this.totalRooms, 
      this.bedType, 
      this.maxOccupancy, 
      this.pricePerDay, 
      this.discount, 
      this.isActive, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  HotelRoomData.fromJson(dynamic json) {
    size = json['size'] != null ? Size.fromJson(json['size']) : null;
    images = json['images'] != null ? Images.fromJson(json['images']) : null;
    id = json['_id'];
    businessId = json['businessId'];
    name = json['name'];
    type = json['type'];
    totalRooms = json['totalRooms'];
    bedType = json['bedType'];
    maxOccupancy = json['maxOccupancy'];
    pricePerDay = json['pricePerDay'];
    discount = json['discount'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  Size? size;
  Images? images;
  String? id;
  String? businessId;
  String? name;
  String? type;
  int? totalRooms;
  String? bedType;
  String? maxOccupancy;
  int? pricePerDay;
  int? discount;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (size != null) {
      map['size'] = size?.toJson();
    }
    if (images != null) {
      map['images'] = images?.toJson();
    }
    map['_id'] = id;
    map['businessId'] = businessId;
    map['name'] = name;
    map['type'] = type;
    map['totalRooms'] = totalRooms;
    map['bedType'] = bedType;
    map['maxOccupancy'] = maxOccupancy;
    map['pricePerDay'] = pricePerDay;
    map['discount'] = discount;
    map['isActive'] = isActive;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Images imagesFromJson(String str) => Images.fromJson(json.decode(str));
String imagesToJson(Images data) => json.encode(data.toJson());
class Images {
  Images({
      this.exteriorImages, 
      this.washroomImages, 
      this.amenityImages,});

  Images.fromJson(dynamic json) {
    exteriorImages = json['exteriorImages'] != null ? json['exteriorImages'].cast<String>() : [];
    washroomImages = json['washroomImages'] != null ? json['washroomImages'].cast<String>() : [];
    amenityImages = json['amenityImages'] != null ? json['amenityImages'].cast<String>() : [];
  }
  List<String>? exteriorImages;
  List<String>? washroomImages;
  List<String>? amenityImages;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['exteriorImages'] = exteriorImages;
    map['washroomImages'] = washroomImages;
    map['amenityImages'] = amenityImages;
    return map;
  }

}

Size sizeFromJson(String str) => Size.fromJson(json.decode(str));
String sizeToJson(Size data) => json.encode(data.toJson());
class Size {
  Size({
      this.length, 
      this.width,});

  Size.fromJson(dynamic json) {
    length = json['length'];
    width = json['width'];
  }
  int? length;
  int? width;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['length'] = length;
    map['width'] = width;
    return map;
  }

}