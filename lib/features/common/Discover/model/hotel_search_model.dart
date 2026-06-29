import 'dart:convert';

import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';

class HotelSearchModelResponse {
  bool? success;
  List<HotelServiceData>? data;
  Pagination? pagination;

  HotelSearchModelResponse({this.success, this.data, this.pagination});

  HotelSearchModelResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <HotelServiceData>[];
      json['data'].forEach((v) {
        data!.add(new HotelServiceData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class HotelServiceData {
  String? businessId;
  Profile? profile;
  List<Rooms>? rooms;

  HotelServiceData({this.businessId, this.profile, this.rooms});

  HotelServiceData.fromJson(Map<String, dynamic> json) {
    businessId = json['businessId'];
    profile =
    json['profile'] != null ? new Profile.fromJson(json['profile']) : null;
    if (json['rooms'] != null) {
      rooms = <Rooms>[];
      json['rooms'].forEach((v) {
        rooms!.add(new Rooms.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['businessId'] = this.businessId;
    if (this.profile != null) {
      data['profile'] = this.profile!.toJson();
    }
    if (this.rooms != null) {
      data['rooms'] = this.rooms!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Profile {
  String? sId;
  String? businessId;
  String? name;
  String? description;
  String? website;
  Address? address;
  Location? location;
  String? logoUrl;
  String? coverUrl;
  String? createdAt;
  String? updatedAt;
  int? iV;
  double? distance;
  List<Contacts>? contacts;
  Policy? policy;
  Amenities? amenities;
  List<Photos>? photos;
  int? rating;
  int? reviews;

  Profile(
      {this.sId,
        this.businessId,
        this.name,
        this.description,
        this.website,
        this.address,
        this.location,
        this.logoUrl,
        this.coverUrl,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.distance,
        this.contacts,
        this.policy,
        this.amenities,
        this.photos,
        this.rating,
        this.reviews,
      });

  Profile.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    businessId = json['businessId'];
    name = json['name'];
    description = json['description'];
    website = json['website'];
    address =
    json['address'] != null ? new Address.fromJson(json['address']) : null;
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    logoUrl = json['logoUrl'];
    coverUrl = json['coverUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    distance = json['distance'];
    if (json['contacts'] != null) {
      contacts = <Contacts>[];
      json['contacts'].forEach((v) {
        contacts!.add(new Contacts.fromJson(v));
      });
    }
    policy =
    json['policy'] != null ? new Policy.fromJson(json['policy']) : null;
    amenities = json['amenities'] != null
        ? new Amenities.fromJson(json['amenities'])
        : null;
    if (json['photos'] != null) {
      photos = [];
      json['photos'].forEach((v) {
        photos?.add(Photos.fromJson(v));
      });
    }
    rating = json['rating'];
    reviews = json['reviews'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['name'] = this.name;
    data['description'] = this.description;
    data['website'] = this.website;
    if (this.address != null) {
      data['address'] = this.address!.toJson();
    }
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['logoUrl'] = this.logoUrl;
    data['coverUrl'] = this.coverUrl;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['distance'] = this.distance;
    if (this.contacts != null) {
      data['contacts'] = this.contacts!.map((v) => v.toJson()).toList();
    }
    if (this.policy != null) {
      data['policy'] = this.policy!.toJson();
    }
    if (this.amenities != null) {
      data['amenities'] = this.amenities!.toJson();
    }
    if (photos != null) {
      data['photos'] = photos?.map((v) => v.toJson()).toList();
    }
    data['rating'] = rating;
    data['reviews'] = reviews;
    return data;
  }
}

class Address {
  String? street;
  String? city;
  String? state;
  String? pincode;
  String? country;

  Address({this.street, this.city, this.state, this.pincode, this.country});

  Address.fromJson(Map<String, dynamic> json) {
    street = json['street'];
    city = json['city'];
    state = json['state'];
    pincode = json['pincode'];
    country = json['country'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['street'] = this.street;
    data['city'] = this.city;
    data['state'] = this.state;
    data['pincode'] = this.pincode;
    data['country'] = this.country;
    return data;
  }
}

class Location {
  String? name;
  String? type;
  List<double>? coordinates;

  Location({
    this.name,
    this.type,
    this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = name;
    data['type'] = this.type;
    data['coordinates'] = this.coordinates;
    return data;
  }
}

class Contacts {
  String? sId;
  String? businessId;
  String? type;
  String? email;
  String? phone;
  String? address;
  int? iV;

  Contacts(
      {this.sId,
        this.businessId,
        this.type,
        this.email,
        this.phone,
        this.address,
        this.iV});

  Contacts.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    businessId = json['businessId'];
    type = json['type'];
    email = json['email'];
    phone = json['phone'];
    address = json['address'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['type'] = this.type;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['address'] = this.address;
    data['__v'] = this.iV;
    return data;
  }
}

class Policy {
  FoodRestrictions? foodRestrictions;
  String? sId;
  String? businessId;
  String? checkInTime;
  String? checkOutTime;
  bool? earlyCheckInAllowed;
  bool? lateCheckOutAllowed;
  bool? marriedCoupleAllowed;
  bool? bachelorStudentAllowed;
  bool? freeCancellation;
  bool? localIdAllowed;
  bool? aadharMandatory;
  bool? smokingDrinkingAllowed;
  int? iV;

  Policy(
      {this.foodRestrictions,
        this.sId,
        this.businessId,
        this.checkInTime,
        this.checkOutTime,
        this.earlyCheckInAllowed,
        this.lateCheckOutAllowed,
        this.marriedCoupleAllowed,
        this.bachelorStudentAllowed,
        this.freeCancellation,
        this.localIdAllowed,
        this.aadharMandatory,
        this.smokingDrinkingAllowed,
        this.iV});

  Policy.fromJson(Map<String, dynamic> json) {
    foodRestrictions = json['foodRestrictions'] != null
        ? new FoodRestrictions.fromJson(json['foodRestrictions'])
        : null;
    sId = json['_id'];
    businessId = json['businessId'];
    checkInTime = json['checkInTime'];
    checkOutTime = json['checkOutTime'];
    earlyCheckInAllowed = json['earlyCheckInAllowed'];
    lateCheckOutAllowed = json['lateCheckOutAllowed'];
    marriedCoupleAllowed = json['marriedCoupleAllowed'];
    bachelorStudentAllowed = json['bachelorStudentAllowed'];
    freeCancellation = json['freeCancellation'];
    localIdAllowed = json['localIdAllowed'];
    aadharMandatory = json['aadharMandatory'];
    smokingDrinkingAllowed = json['smokingDrinkingAllowed'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.foodRestrictions != null) {
      data['foodRestrictions'] = this.foodRestrictions!.toJson();
    }
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['checkInTime'] = this.checkInTime;
    data['checkOutTime'] = this.checkOutTime;
    data['earlyCheckInAllowed'] = this.earlyCheckInAllowed;
    data['lateCheckOutAllowed'] = this.lateCheckOutAllowed;
    data['marriedCoupleAllowed'] = this.marriedCoupleAllowed;
    data['bachelorStudentAllowed'] = this.bachelorStudentAllowed;
    data['freeCancellation'] = this.freeCancellation;
    data['localIdAllowed'] = this.localIdAllowed;
    data['aadharMandatory'] = this.aadharMandatory;
    data['smokingDrinkingAllowed'] = this.smokingDrinkingAllowed;
    data['__v'] = this.iV;
    return data;
  }
}

class FoodRestrictions {
  bool? enabled;

  FoodRestrictions({this.enabled});

  FoodRestrictions.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['enabled'] = this.enabled;
    return data;
  }
}

Amenities amenitiesFromJson(String str) => Amenities.fromJson(json.decode(str));
String amenitiesToJson(Amenities data) => json.encode(data.toJson());
class Amenities {
  Amenities({
    this.id,
    this.businessId,
    this.roomId,
    this.airConditioning,
    this.freeWifi,
    this.television,
    this.roomService,
    this.powerBackup,
    this.balcony,
    this.attachedBathroom,
    this.wardrobe,
    this.deskChair,
    this.roomRefrigerators,
    this.electricKettle,
    this.freeParking,
    this.restaurant,
    this.frontDesk24x7,
    this.elevatorLift,
    this.cctvSurveillance,
    this.laundryService,
    this.swimmingPool,
    this.airportTransportation,
    this.bar,
    this.gym,
    this.v,});

  Amenities.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    roomId = json['roomId'];
    airConditioning = json['airConditioning'];
    freeWifi = json['freeWifi'];
    television = json['television'];
    roomService = json['roomService'];
    powerBackup = json['powerBackup'];
    balcony = json['balcony'];
    attachedBathroom = json['attachedBathroom'];
    wardrobe = json['wardrobe'];
    deskChair = json['deskChair'];
    roomRefrigerators = json['roomRefrigerators'];
    electricKettle = json['electricKettle'];
    freeParking = json['freeParking'];
    restaurant = json['restaurant'];
    frontDesk24x7 = json['frontDesk24x7'];
    elevatorLift = json['elevatorLift'];
    cctvSurveillance = json['cctvSurveillance'];
    laundryService = json['laundryService'];
    swimmingPool = json['swimmingPool'];
    airportTransportation = json['airportTransportation'];
    bar = json['bar'];
    gym = json['gym'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  String? roomId;
  bool? airConditioning;
  bool? freeWifi;
  bool? television;
  bool? roomService;
  bool? powerBackup;
  bool? balcony;
  bool? attachedBathroom;
  bool? wardrobe;
  bool? deskChair;
  bool? roomRefrigerators;
  bool? electricKettle;
  bool? freeParking;
  bool? restaurant;
  bool? frontDesk24x7;
  bool? elevatorLift;
  bool? cctvSurveillance;
  bool? laundryService;
  bool? swimmingPool;
  bool? airportTransportation;
  bool? bar;
  bool? gym;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['roomId'] = roomId;
    map['airConditioning'] = airConditioning;
    map['freeWifi'] = freeWifi;
    map['television'] = television;
    map['roomService'] = roomService;
    map['powerBackup'] = powerBackup;
    map['balcony'] = balcony;
    map['attachedBathroom'] = attachedBathroom;
    map['wardrobe'] = wardrobe;
    map['deskChair'] = deskChair;
    map['roomRefrigerators'] = roomRefrigerators;
    map['electricKettle'] = electricKettle;
    map['freeParking'] = freeParking;
    map['restaurant'] = restaurant;
    map['frontDesk24x7'] = frontDesk24x7;
    map['elevatorLift'] = elevatorLift;
    map['cctvSurveillance'] = cctvSurveillance;
    map['laundryService'] = laundryService;
    map['swimmingPool'] = swimmingPool;
    map['airportTransportation'] = airportTransportation;
    map['bar'] = bar;
    map['gym'] = gym;
    map['__v'] = v;
    return map;
  }

}

class Rooms {
  Size? size;
  Images? images;
  String? sId;
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
  int? iV;
  Amenities? amenities;
  List<Coupons>? coupons;

  Rooms(
      {this.size,
        this.images,
        this.sId,
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
        this.iV,
        this.amenities,
        this.coupons});

  Rooms.fromJson(Map<String, dynamic> json) {
    size = json['size'] != null ? new Size.fromJson(json['size']) : null;
    images =
    json['images'] != null ? new Images.fromJson(json['images']) : null;
    sId = json['_id'];
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
    iV = json['__v'];
    amenities = json['amenities'] != null
        ? new Amenities.fromJson(json['amenities'])
        : null;
    if (json['coupons'] != null) {
      coupons = <Coupons>[];
      json['coupons'].forEach((v) {
        coupons!.add(new Coupons.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.size != null) {
      data['size'] = this.size!.toJson();
    }
    if (this.images != null) {
      data['images'] = this.images!.toJson();
    }
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['name'] = this.name;
    data['type'] = this.type;
    data['totalRooms'] = this.totalRooms;
    data['bedType'] = this.bedType;
    data['maxOccupancy'] = this.maxOccupancy;
    data['pricePerDay'] = this.pricePerDay;
    data['discount'] = this.discount;
    data['isActive'] = this.isActive;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.amenities != null) {
      data['amenities'] = this.amenities!.toJson();
    }
    if (this.coupons != null) {
      data['coupons'] = this.coupons!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Size {
  int? length;
  int? width;

  Size({this.length, this.width});

  Size.fromJson(Map<String, dynamic> json) {
    length = json['length'];
    width = json['width'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['length'] = this.length;
    data['width'] = this.width;
    return data;
  }
}

class Images {
  List<String>? exteriorImages;
  List<String>? washroomImages;
  List<String>? amenityImages;

  Images({this.exteriorImages, this.washroomImages, this.amenityImages});

  Images.fromJson(Map<String, dynamic> json) {
    exteriorImages = json['exteriorImages'] != null ? json['exteriorImages'].cast<String>() : [];
    washroomImages = json['washroomImages'] != null ? json['washroomImages'].cast<String>() : [];
    amenityImages = json['amenityImages'] != null ? json['amenityImages'].cast<String>() : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['exteriorImages'] = this.exteriorImages;
    data['washroomImages'] = this.washroomImages;
    data['amenityImages'] = this.amenityImages;
    return data;
  }
}

class Coupons {
  String? sId;
  String? roomId;
  String? businessId;
  String? couponName;
  String? description;
  String? codeName;
  String? discountType;
  int? discountValue;
  String? validUntil;
  bool? isActive;
  int? iV;

  Coupons(
      {this.sId,
        this.roomId,
        this.businessId,
        this.couponName,
        this.description,
        this.codeName,
        this.discountType,
        this.discountValue,
        this.validUntil,
        this.isActive,
        this.iV});

  Coupons.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    roomId = json['roomId'];
    businessId = json['businessId'];
    couponName = json['couponName'];
    description = json['description'];
    codeName = json['codeName'];
    discountType = json['discountType'];
    discountValue = json['discountValue'];
    validUntil = json['validUntil'];
    isActive = json['isActive'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['roomId'] = this.roomId;
    data['businessId'] = this.businessId;
    data['couponName'] = this.couponName;
    data['description'] = this.description;
    data['codeName'] = this.codeName;
    data['discountType'] = this.discountType;
    data['discountValue'] = this.discountValue;
    data['validUntil'] = this.validUntil;
    data['isActive'] = this.isActive;
    data['__v'] = this.iV;
    return data;
  }
}

class Pagination {
  int? total;
  int? page;
  int? limit;
  int? pages;

  Pagination({this.total, this.page, this.limit, this.pages});

  Pagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    pages = json['pages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['page'] = this.page;
    data['limit'] = this.limit;
    data['pages'] = this.pages;
    return data;
  }
}