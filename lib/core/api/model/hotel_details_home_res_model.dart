import 'dart:convert';
HotelDetailsHomeResModel hotelDetailsHomeResModelFromJson(String str) => HotelDetailsHomeResModel.fromJson(json.decode(str));
String hotelDetailsHomeResModelToJson(HotelDetailsHomeResModel data) => json.encode(data.toJson());
class HotelDetailsHomeResModel {
  HotelDetailsHomeResModel({
      this.success, 
      this.data,});

  HotelDetailsHomeResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? HotelDetailsHomeData.fromJson(json['data']) : null;
  }
  bool? success;
  HotelDetailsHomeData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

HotelDetailsHomeData dataFromJson(String str) => HotelDetailsHomeData.fromJson(json.decode(str));
String dataToJson(HotelDetailsHomeData data) => json.encode(data.toJson());
class HotelDetailsHomeData {
  HotelDetailsHomeData({
      this.businessId, 
      this.profile, 
      this.rooms, 
     });

  HotelDetailsHomeData.fromJson(dynamic json) {
    businessId = json['businessId'];
    profile = json['profile'] != null ? Profile.fromJson(json['profile']) : null;
    if (json['rooms'] != null) {
      rooms = [];
      json['rooms'].forEach((v) {
        rooms?.add(Rooms.fromJson(v));
      });
    }

  }
  String? businessId;
  Profile? profile;
  List<Rooms>? rooms;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['businessId'] = businessId;
    if (profile != null) {
      map['profile'] = profile?.toJson();
    }
    if (rooms != null) {
      map['rooms'] = rooms?.map((v) => v.toJson()).toList();
    }

    return map;
  }

}

Rooms roomsFromJson(String str) => Rooms.fromJson(json.decode(str));
String roomsToJson(Rooms data) => json.encode(data.toJson());
class Rooms {
  Rooms({
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
      this.v, 
      this.amenities, 
      this.coupons,});

  Rooms.fromJson(dynamic json) {
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
    v = json['__v'];
    amenities = json['amenities'] != null ? Amenities.fromJson(json['amenities']) : null;
    if (json['coupons'] != null) {
      coupons = [];
      json['coupons'].forEach((v) {
        // coupons?.add(Dynamic.fromJson(v));
      });
    }
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
  int? v;
  Amenities? amenities;
  List<dynamic>? coupons;

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
    map['__v'] = v;
    if (amenities != null) {
      map['amenities'] = amenities?.toJson();
    }
    if (coupons != null) {
      map['coupons'] = coupons?.map((v) => v.toJson()).toList();
    }
    return map;
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
    if (json['exteriorImages'] != null) {
      exteriorImages = [];
      exteriorImages = json['exteriorImages'] != null ? json['exteriorImages'].cast<String>() : [];

    }
    if (json['washroomImages'] != null) {
      washroomImages = [];

      washroomImages = json['washroomImages'] != null ? json['washroomImages'].cast<String>() : [];


    }
    if (json['amenityImages'] != null) {
      amenityImages = [];

      amenityImages = json['amenityImages'] != null ? json['amenityImages'].cast<String>() : [];

    }
  }
  List<String>? exteriorImages;
  List<String>? washroomImages;
  List<String>? amenityImages;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (exteriorImages != null) {
      map['exteriorImages'] = exteriorImages;

    }
    if (washroomImages != null) {
      map['washroomImages'] = washroomImages;

    }
    if (amenityImages != null) {
      map['amenityImages'] = amenityImages;

    }
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

Profile profileFromJson(String str) => Profile.fromJson(json.decode(str));
String profileToJson(Profile data) => json.encode(data.toJson());
class Profile {
  Profile({
      this.address, 
      this.locationHotel,
      this.id,
      this.businessId, 
      this.v, 
      this.createdAt, 
      this.description, 
      this.name, 
      this.updatedAt, 
      this.logoUrl,
      this.coverUrl,
      this.website,
      this.contacts, 
      this.policy, 
      this.amenities, 
      this.photos,});

  Profile.fromJson(dynamic json) {
    address = json['address'] != null ? Address.fromJson(json['address']) : null;
    locationHotel = json['location'] != null ? LocationHotel.fromJson(json['location']) : null;
    id = json['_id'];
    businessId = json['businessId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    description = json['description'];
    name = json['name'];
    logoUrl = json['logoUrl'];
    coverUrl = json['coverUrl'];
    updatedAt = json['updatedAt'];
    website = json['website'];
    if (json['contacts'] != null) {
      contacts = [];
      json['contacts'].forEach((v) {
        contacts?.add(Contacts.fromJson(v));
      });
    }
    policy = json['policy'] != null ? Policy.fromJson(json['policy']) : null;
    amenities = json['amenities'] != null ? Amenities.fromJson(json['amenities']) : null;
    if (json['photos'] != null) {
      photos = [];
      json['photos'].forEach((v) {
        photos?.add(Photos.fromJson(v));
      });
    }
  }
  Address? address;
  LocationHotel? locationHotel;
  String? id;
  String? businessId;
  int? v;
  String? createdAt;
  String? description;
  String? name;
  String? updatedAt;
  String? website;
  String? logoUrl;
  String? coverUrl;
  List<Contacts>? contacts;
  Policy? policy;
  Amenities? amenities;
  List<Photos>? photos;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (address != null) {
      map['address'] = address?.toJson();
    }
    if (locationHotel != null) {
      map['location'] = locationHotel?.toJson();
    }
    map['_id'] = id;
    map['logoUrl'] = logoUrl;
    map['coverUrl'] = coverUrl;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['description'] = description;
    map['name'] = name;
    map['updatedAt'] = updatedAt;
    map['website'] = website;
    if (contacts != null) {
      map['contacts'] = contacts?.map((v) => v.toJson()).toList();
    }
    if (policy != null) {
      map['policy'] = policy?.toJson();
    }
    if (amenities != null) {
      map['amenities'] = amenities?.toJson();
    }
    if (photos != null) {
      map['photos'] = photos?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Photos photosFromJson(String str) => Photos.fromJson(json.decode(str));
String photosToJson(Photos data) => json.encode(data.toJson());
class Photos {
  Photos({
      this.id, 
      this.category, 
      this.businessId, 
      this.v, 
      this.imageReferences,});

  Photos.fromJson(dynamic json) {
    id = json['_id'];
    category = json['category'];
    businessId = json['businessId'];
    v = json['__v'];
    imageReferences = json['imageReferences'] != null ? json['imageReferences'].cast<String>() : [];
  }
  String? id;
  String? category;
  String? businessId;
  int? v;
  List<String>? imageReferences;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['category'] = category;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['imageReferences'] = imageReferences;
    return map;
  }

}

/*Amenities amenitiesFromJson(String str) => Amenities.fromJson(json.decode(str));
String amenitiesToJson(Amenities data) => json.encode(data.toJson());
class Amenities {
  Amenities({
      this.id, 
      this.businessId, 
      this.v, 
      this.airportTransportation, 
      this.bar, 
      this.cctvSurveillance, 
      this.elevatorLift, 
      this.freeParking, 
      this.frontDesk24x7, 
      this.gym, 
      this.laundryService, 
      this.powerBackup, 
      this.restaurant, 
      this.swimmingPool,});

  Amenities.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    v = json['__v'];
    airportTransportation = json['airportTransportation'];
    bar = json['bar'];
    cctvSurveillance = json['cctvSurveillance'];
    elevatorLift = json['elevatorLift'];
    freeParking = json['freeParking'];
    frontDesk24x7 = json['frontDesk24x7'];
    gym = json['gym'];
    laundryService = json['laundryService'];
    powerBackup = json['powerBackup'];
    restaurant = json['restaurant'];
    swimmingPool = json['swimmingPool'];
  }
  String? id;
  String? businessId;
  int? v;
  bool? airportTransportation;
  bool? bar;
  bool? cctvSurveillance;
  bool? elevatorLift;
  bool? freeParking;
  bool? frontDesk24x7;
  bool? gym;
  bool? laundryService;
  bool? powerBackup;
  bool? restaurant;
  bool? swimmingPool;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['airportTransportation'] = airportTransportation;
    map['bar'] = bar;
    map['cctvSurveillance'] = cctvSurveillance;
    map['elevatorLift'] = elevatorLift;
    map['freeParking'] = freeParking;
    map['frontDesk24x7'] = frontDesk24x7;
    map['gym'] = gym;
    map['laundryService'] = laundryService;
    map['powerBackup'] = powerBackup;
    map['restaurant'] = restaurant;
    map['swimmingPool'] = swimmingPool;
    return map;
  }

}*/

Policy policyFromJson(String str) => Policy.fromJson(json.decode(str));
String policyToJson(Policy data) => json.encode(data.toJson());
class Policy {
  Policy({
      this.foodRestrictions, 
      this.id, 
      this.businessId, 
      this.v, 
      this.aadharMandatory, 
      this.bachelorStudentAllowed, 
      this.checkInHours, 
      this.checkInTime, 
      this.checkOutTime, 
      this.earlyCheckInAllowed, 
      this.freeCancellation, 
      this.lateCheckOutAllowed, 
      this.localIdAllowed, 
      this.marriedCoupleAllowed, 
      this.smokingDrinkingAllowed,});

  Policy.fromJson(dynamic json) {
    foodRestrictions = json['foodRestrictions'] != null ? FoodRestrictions.fromJson(json['foodRestrictions']) : null;
    id = json['_id'];
    businessId = json['businessId'];
    v = json['__v'];
    aadharMandatory = json['aadharMandatory'];
    bachelorStudentAllowed = json['bachelorStudentAllowed'];
    checkInHours = json['checkInHours'];
    checkInTime = json['checkInTime'];
    checkOutTime = json['checkOutTime'];
    earlyCheckInAllowed = json['earlyCheckInAllowed'];
    freeCancellation = json['freeCancellation'];
    lateCheckOutAllowed = json['lateCheckOutAllowed'];
    localIdAllowed = json['localIdAllowed'];
    marriedCoupleAllowed = json['marriedCoupleAllowed'];
    smokingDrinkingAllowed = json['smokingDrinkingAllowed'];
  }
  FoodRestrictions? foodRestrictions;
  String? id;
  String? businessId;
  int? v;
  bool? aadharMandatory;
  bool? bachelorStudentAllowed;
  String? checkInHours;
  String? checkInTime;
  String? checkOutTime;
  bool? earlyCheckInAllowed;
  bool? freeCancellation;
  bool? lateCheckOutAllowed;
  bool? localIdAllowed;
  bool? marriedCoupleAllowed;
  bool? smokingDrinkingAllowed;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (foodRestrictions != null) {
      map['foodRestrictions'] = foodRestrictions?.toJson();
    }
    map['_id'] = id;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['aadharMandatory'] = aadharMandatory;
    map['bachelorStudentAllowed'] = bachelorStudentAllowed;
    map['checkInHours'] = checkInHours;
    map['checkInTime'] = checkInTime;
    map['checkOutTime'] = checkOutTime;
    map['earlyCheckInAllowed'] = earlyCheckInAllowed;
    map['freeCancellation'] = freeCancellation;
    map['lateCheckOutAllowed'] = lateCheckOutAllowed;
    map['localIdAllowed'] = localIdAllowed;
    map['marriedCoupleAllowed'] = marriedCoupleAllowed;
    map['smokingDrinkingAllowed'] = smokingDrinkingAllowed;
    return map;
  }

}

FoodRestrictions foodRestrictionsFromJson(String str) => FoodRestrictions.fromJson(json.decode(str));
String foodRestrictionsToJson(FoodRestrictions data) => json.encode(data.toJson());
class FoodRestrictions {
  FoodRestrictions({
      this.enabled, 
      this.restrictions,});

  FoodRestrictions.fromJson(dynamic json) {
    enabled = json['enabled'];
    restrictions = json['restrictions'] != null ? json['restrictions'].cast<String>() : [];
  }
  bool? enabled;
  List<String>? restrictions;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['enabled'] = enabled;
    map['restrictions'] = restrictions;
    return map;
  }

}

Contacts contactsFromJson(String str) => Contacts.fromJson(json.decode(str));
String contactsToJson(Contacts data) => json.encode(data.toJson());
class Contacts {
  Contacts({
      this.id, 
      this.businessId, 
      this.type, 
      this.email, 
      this.phone, 
      this.address, 
      this.v,});

  Contacts.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    type = json['type'];
    email = json['email'];
    phone = json['phone'];
    address = json['address'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  String? type;
  String? email;
  String? phone;
  String? address;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['type'] = type;
    map['email'] = email;
    map['phone'] = phone;
    map['address'] = address;
    map['__v'] = v;
    return map;
  }

}

Address addressFromJson(String str) => Address.fromJson(json.decode(str));
String addressToJson(Address data) => json.encode(data.toJson());
class Address {
  Address({
      this.country, 
      this.city, 
      this.state, 
      this.pincode,});

  Address.fromJson(dynamic json) {
    country = json['country'];
    city = json['city'];
    state = json['state'];
    pincode = json['pincode'];
  }
  String? country;
  String? city;
  String? state;
  String? pincode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['country'] = country;
    map['city'] = city;
    map['state'] = state;
    map['pincode'] = pincode;
    return map;
  }

}



class LocationHotel {
  LocationHotel({
    this.name,
    this.type,
    this.coordinates,
  });

  LocationHotel.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    // Safely cast the dynamic list to double
    if (json['coordinates'] != null) {
      coordinates = json['coordinates'].cast<double>();
    }
  }

  String? name;
  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

  // Helper getters for easier access in UI
  double? get latitude => coordinates != null && coordinates!.isNotEmpty ? coordinates![0] : null;
  double? get longitude => coordinates != null && coordinates!.length > 1 ? coordinates![1] : null;
}