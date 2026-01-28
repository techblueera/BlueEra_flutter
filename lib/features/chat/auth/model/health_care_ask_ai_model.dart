import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';

class HealthCareAskAiModel extends BaseAiChatModel {
  List<String>? suggestions;
  Data? data;

  HealthCareAskAiModel(
      { super.role,
        super.message,
        super.conversationId,
        super.timestamp,
        this.suggestions,
        this.data,
      });

  HealthCareAskAiModel.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    message = json['reply'] ?? json['content'];
    conversationId = json['conversationId'];
    suggestions = json['suggestions'].cast<String>();
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role'] = this.role;
    data['reply'] = this.message;
    data['conversationId'] = this.conversationId;
    data['suggestions'] = this.suggestions;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['timestamp'] = this.timestamp;
    return data;
  }
}

class Data {
  bool? success;
  List<HotelData>? hotelData;

  Data({this.success, this.hotelData});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      hotelData = <HotelData>[];
      json['data'].forEach((v) {
        hotelData!.add(new HotelData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.hotelData != null) {
      data['data'] = this.hotelData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HotelData {
  String? businessId;
  Profile? profile;
  List<Rooms>? rooms;

  HotelData({this.businessId, this.profile, this.rooms});

  HotelData.fromJson(Map<String, dynamic> json) {
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
  Address? address;
  Location? location;
  String? sId;
  String? businessId;
  int? iV;
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

  Profile(
      {this.address,
        this.location,
        this.sId,
        this.businessId,
        this.iV,
        this.createdAt,
        this.description,
        this.name,
        this.updatedAt,
        this.website,
        this.logoUrl,
        this.coverUrl,
        this.contacts,
        this.policy,
        this.amenities,
        this.photos});

  Profile.fromJson(Map<String, dynamic> json) {
    address =
    json['address'] != null ? new Address.fromJson(json['address']) : null;
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    sId = json['_id'];
    businessId = json['businessId'];
    iV = json['__v'];
    createdAt = json['createdAt'];
    description = json['description'];
    name = json['name'];
    updatedAt = json['updatedAt'];
    website = json['website'];
    logoUrl = json['logoUrl'];
    coverUrl = json['coverUrl'];
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
      photos = <Photos>[];
      json['photos'].forEach((v) {
        photos!.add(new Photos.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.address != null) {
      data['address'] = this.address!.toJson();
    }
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['__v'] = this.iV;
    data['createdAt'] = this.createdAt;
    data['description'] = this.description;
    data['name'] = this.name;
    data['updatedAt'] = this.updatedAt;
    data['website'] = this.website;
    data['logoUrl'] = this.logoUrl;
    data['coverUrl'] = this.coverUrl;
    if (this.contacts != null) {
      data['contacts'] = this.contacts!.map((v) => v.toJson()).toList();
    }
    if (this.policy != null) {
      data['policy'] = this.policy!.toJson();
    }
    if (this.amenities != null) {
      data['amenities'] = this.amenities!.toJson();
    }
    if (this.photos != null) {
      data['photos'] = this.photos!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Address {
  String? country;
  String? city;
  String? state;
  String? pincode;

  Address({this.country, this.city, this.state, this.pincode});

  Address.fromJson(Map<String, dynamic> json) {
    country = json['country'];
    city = json['city'];
    state = json['state'];
    pincode = json['pincode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['country'] = this.country;
    data['city'] = this.city;
    data['state'] = this.state;
    data['pincode'] = this.pincode;
    return data;
  }
}

class Location {
  String? name;
  String? type;
  List<double>? coordinates;

  Location({this.name, this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'].cast<double>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
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
  int? iV;
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

  Policy(
      {this.foodRestrictions,
        this.sId,
        this.businessId,
        this.iV,
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
        this.smokingDrinkingAllowed});

  Policy.fromJson(Map<String, dynamic> json) {
    foodRestrictions = json['foodRestrictions'] != null
        ? new FoodRestrictions.fromJson(json['foodRestrictions'])
        : null;
    sId = json['_id'];
    businessId = json['businessId'];
    iV = json['__v'];
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.foodRestrictions != null) {
      data['foodRestrictions'] = this.foodRestrictions!.toJson();
    }
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['__v'] = this.iV;
    data['aadharMandatory'] = this.aadharMandatory;
    data['bachelorStudentAllowed'] = this.bachelorStudentAllowed;
    data['checkInHours'] = this.checkInHours;
    data['checkInTime'] = this.checkInTime;
    data['checkOutTime'] = this.checkOutTime;
    data['earlyCheckInAllowed'] = this.earlyCheckInAllowed;
    data['freeCancellation'] = this.freeCancellation;
    data['lateCheckOutAllowed'] = this.lateCheckOutAllowed;
    data['localIdAllowed'] = this.localIdAllowed;
    data['marriedCoupleAllowed'] = this.marriedCoupleAllowed;
    data['smokingDrinkingAllowed'] = this.smokingDrinkingAllowed;
    return data;
  }
}

class FoodRestrictions {
  bool? enabled;
  List<String>? restrictions;

  FoodRestrictions({this.enabled, this.restrictions});

  FoodRestrictions.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'];
    restrictions = json['restrictions'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['enabled'] = this.enabled;
    data['restrictions'] = this.restrictions;
    return data;
  }
}

class Amenities {
  String? sId;
  String? businessId;
  int? iV;
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

  Amenities(
      {this.sId,
        this.businessId,
        this.iV,
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
        this.swimmingPool});

  Amenities.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    businessId = json['businessId'];
    iV = json['__v'];
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['__v'] = this.iV;
    data['airportTransportation'] = this.airportTransportation;
    data['bar'] = this.bar;
    data['cctvSurveillance'] = this.cctvSurveillance;
    data['elevatorLift'] = this.elevatorLift;
    data['freeParking'] = this.freeParking;
    data['frontDesk24x7'] = this.frontDesk24x7;
    data['gym'] = this.gym;
    data['laundryService'] = this.laundryService;
    data['powerBackup'] = this.powerBackup;
    data['restaurant'] = this.restaurant;
    data['swimmingPool'] = this.swimmingPool;
    return data;
  }
}

class Photos {
  String? sId;
  String? category;
  String? businessId;
  int? iV;
  List<String>? imageReferences;
  String? createdAt;
  String? updatedAt;

  Photos(
      {this.sId,
        this.category,
        this.businessId,
        this.iV,
        this.imageReferences,
        this.createdAt,
        this.updatedAt});

  Photos.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    category = json['category'];
    businessId = json['businessId'];
    iV = json['__v'];
    imageReferences = json['imageReferences'].cast<String>();
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['category'] = this.category;
    data['businessId'] = this.businessId;
    data['__v'] = this.iV;
    data['imageReferences'] = this.imageReferences;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
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
  int? iV;
  Amenities? amenities;
  String? createdAt;
  String? updatedAt;

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
        this.iV,
        this.amenities,
        this.createdAt,
        this.updatedAt});

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
    iV = json['__v'];
    amenities = json['amenities'] != null
        ? new Amenities.fromJson(json['amenities'])
        : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
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
    data['__v'] = this.iV;
    if (this.amenities != null) {
      data['amenities'] = this.amenities!.toJson();
    }
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
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
    exteriorImages = json['exteriorImages'].cast<String>();
    washroomImages = json['washroomImages'].cast<String>();
    amenityImages = json['amenityImages'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['exteriorImages'] = this.exteriorImages;
    data['washroomImages'] = this.washroomImages;
    data['amenityImages'] = this.amenityImages;
    return data;
  }
}
