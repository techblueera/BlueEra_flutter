class RentalServiceResponse {
  bool? status;
  String? message;
  List<RentalServiceData>? data;

  RentalServiceResponse({this.status, this.message, this.data});

  RentalServiceResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <RentalServiceData>[];
      json['data'].forEach((v) {
        data!.add(RentalServiceData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RentalServiceData {
  String? sId;
  String? userId;
  String? name;
  String? description;
  String? contactNumber;
  String? type;
  List<String>? highlights;
  List<String>? additionalRules;
  List<String>? images;
  List<AdditionalDetails>? additionalDetails;
  String? address;
  String? city;
  String? pincode;
  String? landmark;
  NearbyLocations? nearbyLocations;
  Location? location;
  String? price;
  String? priceUnit;
  String? checkInTime;
  String? checkOutTime;
  bool? isActive;
  bool? isNegotiable;
  int? rating;
  int? reviews;
  String? addedBy;
  OwnerDetails? ownerDetails;
  PropertyDetails? propertyDetails;
  VehicleDetails? vehicleDetails;
  EquipmentDetails? equipmentDetails;
  String? createdAt;
  String? updatedAt;
  int? iV;
  double? lat;
  double? lng;

  RentalServiceData({
    this.sId,
    this.userId,
    this.name,
    this.description,
    this.contactNumber,
    this.type,
    this.highlights,
    this.additionalRules,
    this.images,
    this.additionalDetails,
    this.address,
    this.city,
    this.pincode,
    this.landmark,
    this.nearbyLocations,
    this.location,
    this.price,
    this.priceUnit,
    this.checkInTime,
    this.checkOutTime,
    this.isActive,
    this.isNegotiable,
    this.rating,
    this.reviews,
    this.addedBy,
    this.ownerDetails,
    this.propertyDetails,
    this.vehicleDetails,
    this.equipmentDetails,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.lat,
    this.lng,
  });

  RentalServiceData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    name = json['name'];
    description = json['description'];
    contactNumber = json['contactNumber'];
    type = json['type'];
    highlights = json['highlights'] != null ? List<String>.from(json['highlights']) : null;
    additionalRules = json['additionalRules'] != null ? List<String>.from(json['additionalRules']) : null;
    images = json['images'] != null ? List<String>.from(json['images']) : null;
    if (json['additionalDetails'] != null) {
      additionalDetails = <AdditionalDetails>[];
      json['additionalDetails'].forEach((v) {
        additionalDetails!.add(AdditionalDetails.fromJson(v));
      });
    }
    address = json['address'];
    city = json['city'];
    pincode = json['pincode'];
    landmark = json['landmark'];
    nearbyLocations = json['nearbyLocations'] != null
        ? NearbyLocations.fromJson(json['nearbyLocations'])
        : null;
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    price = json['price'];
    priceUnit = json['priceUnit'];
    checkInTime = json['checkInTime'];
    checkOutTime = json['checkOutTime'];
    isActive = json['is_active'];
    isNegotiable = json['is_negotiable'];
    rating = json['rating'];
    reviews = json['reviews'];
    addedBy = json['addedBy'];
    ownerDetails = json['ownerDetails'] != null
        ? OwnerDetails.fromJson(json['ownerDetails'])
        : null;
    propertyDetails = json['propertyDetails'] != null
        ? PropertyDetails.fromJson(json['propertyDetails'])
        : null;
    vehicleDetails = json['vehicleDetails'] != null
        ? VehicleDetails.fromJson(json['vehicleDetails'])
        : null;
    equipmentDetails = json['equipmentDetails'] != null
        ? EquipmentDetails.fromJson(json['equipmentDetails'])
        : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    iV = json['__v'];
    lat = json['lat']?.toDouble();
    lng = json['lng']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['userId'] = userId;
    data['name'] = name;
    data['description'] = description;
    data['contactNumber'] = contactNumber;
    data['type'] = type;
    data['highlights'] = highlights;
    data['additionalRules'] = additionalRules;
    data['images'] = images;
    if (additionalDetails != null) {
      data['additionalDetails'] = additionalDetails!.map((v) => v.toJson()).toList();
    }
    data['address'] = address;
    data['city'] = city;
    data['pincode'] = pincode;
    data['landmark'] = landmark;
    if (nearbyLocations != null) {
      data['nearbyLocations'] = nearbyLocations!.toJson();
    }
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['price'] = price;
    data['priceUnit'] = priceUnit;
    data['checkInTime'] = checkInTime;
    data['checkOutTime'] = checkOutTime;
    data['is_active'] = isActive;
    data['is_negotiable'] = isNegotiable;
    data['rating'] = rating;
    data['reviews'] = reviews;
    data['addedBy'] = addedBy;
    if (ownerDetails != null) {
      data['ownerDetails'] = ownerDetails!.toJson();
    }
    if (propertyDetails != null) {
      data['propertyDetails'] = propertyDetails!.toJson();
    }
    if (vehicleDetails != null) {
      data['vehicleDetails'] = vehicleDetails!.toJson();
    }
    if (equipmentDetails != null) {
      data['equipmentDetails'] = equipmentDetails!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['__v'] = iV;
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}

class AdditionalDetails {
  String? title;
  String? details;

  AdditionalDetails({this.title, this.details});

  AdditionalDetails.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    details = json['details'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['details'] = details;
    return data;
  }
}

class NearbyLocations {
  String? railwayStation;
  String? airport;
  String? busStand;
  String? famousPlace;

  NearbyLocations({
    this.railwayStation,
    this.airport,
    this.busStand,
    this.famousPlace,
  });

  NearbyLocations.fromJson(Map<String, dynamic> json) {
    railwayStation = json['railwayStation'];
    airport = json['airport'];
    busStand = json['busStand'];
    famousPlace = json['famousPlace'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['railwayStation'] = railwayStation;
    data['airport'] = airport;
    data['busStand'] = busStand;
    data['famousPlace'] = famousPlace;
    return data;
  }
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = json['coordinates'] != null
        ? List<double>.from(json['coordinates'].map((x) => x.toDouble()))
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['coordinates'] = coordinates;
    return data;
  }
}

class OwnerDetails {
  String? ownerName;
  String? contactNumber;
  String? email;

  OwnerDetails({this.ownerName, this.contactNumber, this.email});

  OwnerDetails.fromJson(Map<String, dynamic> json) {
    ownerName = json['ownerName'];
    contactNumber = json['contactNumber'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ownerName'] = ownerName;
    data['contactNumber'] = contactNumber;
    data['email'] = email;
    return data;
  }
}

class PropertyDetails {
  String? propertyType;
  String? bhk;
  String? tenantPreference;
  MaxPeople? maxPeople;
  int? beds;
  Restrictions? restrictions;
  List<String>? amenities;
  List<String>? roomImages;
  List<String>? kitchenImages;
  List<String>? bathroomImages;
  List<String>? roadImages;
  List<String>? otherImages;

  PropertyDetails({
    this.propertyType,
    this.bhk,
    this.tenantPreference,
    this.maxPeople,
    this.beds,
    this.restrictions,
    this.amenities,
    this.roomImages,
    this.kitchenImages,
    this.bathroomImages,
    this.roadImages,
    this.otherImages,
  });

  PropertyDetails.fromJson(Map<String, dynamic> json) {
    propertyType = json['propertyType'];
    bhk = json['bhk'];
    tenantPreference = json['tenantPreference'];
    maxPeople = json['maxPeople'] != null ? MaxPeople.fromJson(json['maxPeople']) : null;
    beds = json['beds'];
    restrictions = json['restrictions'] != null
        ? Restrictions.fromJson(json['restrictions'])
        : null;
    amenities = json['amenities'] != null ? List<String>.from(json['amenities']) : null;
    roomImages = json['roomImages'] != null ? List<String>.from(json['roomImages']) : null;
    kitchenImages = json['kitchenImages'] != null ? List<String>.from(json['kitchenImages']) : null;
    bathroomImages = json['bathroomImages'] != null ? List<String>.from(json['bathroomImages']) : null;
    roadImages = json['roadImages'] != null ? List<String>.from(json['roadImages']) : null;
    otherImages = json['otherImages'] != null ? List<String>.from(json['otherImages']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['propertyType'] = propertyType;
    data['bhk'] = bhk;
    data['tenantPreference'] = tenantPreference;
    if (maxPeople != null) {
      data['maxPeople'] = maxPeople!.toJson();
    }
    data['beds'] = beds;
    if (restrictions != null) {
      data['restrictions'] = restrictions!.toJson();
    }
    data['amenities'] = amenities;
    data['roomImages'] = roomImages;
    data['kitchenImages'] = kitchenImages;
    data['bathroomImages'] = bathroomImages;
    data['roadImages'] = roadImages;
    data['otherImages'] = otherImages;
    return data;
  }
}

class MaxPeople {
  int? adults;
  int? children;

  MaxPeople({this.adults, this.children});

  MaxPeople.fromJson(Map<String, dynamic> json) {
    adults = json['adults'];
    children = json['children'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['adults'] = adults;
    data['children'] = children;
    return data;
  }
}

class Restrictions {
  bool? unmarriedCoupleAllowed;
  bool? studentOrBachelorAllowed;
  FoodRestriction? foodRestriction;
  bool? pets;
  bool? smoking;

  Restrictions({this.unmarriedCoupleAllowed, this.pets, this.smoking});

  Restrictions.fromJson(Map<String, dynamic> json) {
    unmarriedCoupleAllowed = json['unmarriedCoupleAllowed'];
    studentOrBachelorAllowed = json['studentOrBachelorAllowed'];
    foodRestriction = json['foodRestriction'] != null
        ? FoodRestriction.fromJson(json['foodRestriction'])
        : null;
    pets = json['pets'];
    smoking = json['smoking'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['unmarriedCoupleAllowed'] = unmarriedCoupleAllowed;
    data['studentOrBachelorAllowed'] = studentOrBachelorAllowed;
    if (foodRestriction != null) {
      data['foodRestriction'] = foodRestriction!.toJson();
    }
    data['pets'] = pets;
    data['smoking'] = smoking;
    return data;
  }
}

class FoodRestriction {
  bool? isFoodRestriction;
  String? allowedFood;

  FoodRestriction({this.isFoodRestriction, this.allowedFood});

  FoodRestriction.fromJson(Map<String, dynamic> json) {
    isFoodRestriction = json['isFoodRestriction'];
    allowedFood = json['allowedFood'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isFoodRestriction'] = isFoodRestriction;
    data['allowedFood'] = allowedFood;
    return data;
  }
}

class VehicleDetails {
  String? registrationType;
  List<String>? restrictions;
  String? vehicleType;
  String? brand;
  String? registrationNumber;
  int? yearOfManufacture;
  String? fuelType;
  int? seatingCapacity;
  String? loadCapacity;
  String? capacityUnit;
  String? securityDeposit;
  String? pickupLocation;
  DocumentRequired? documentRequired;
  List<String>? vehicleFrontImage;
  List<String>? vehicleBackImage;
  String? vehicleNoPlateImg;
  List<String>? vehicleLeftSideImage;
  List<String>? vehicleRightHandSideImage;

  VehicleDetails({
    this.registrationType,
    this.restrictions,
    this.vehicleType,
    this.brand,
    this.registrationNumber,
    this.yearOfManufacture,
    this.fuelType,
    this.seatingCapacity,
    this.loadCapacity,
    this.capacityUnit,
    this.securityDeposit,
    this.pickupLocation,
    this.documentRequired,
    this.vehicleFrontImage,
    this.vehicleBackImage,
    this.vehicleNoPlateImg,
    this.vehicleLeftSideImage,
    this.vehicleRightHandSideImage,
  });

  VehicleDetails.fromJson(Map<String, dynamic> json) {
    registrationType = json['registrationType'];

    if (json['restrictions'] != null) {
      restrictions = List<String>.from(json['restrictions']);
    }

    vehicleType = json['vehicleType'];
    brand = json['brand'];
    registrationNumber = json['registrationNumber'];
    yearOfManufacture = json['yearOfManufacture'];
    fuelType = json['fuelType'];
    seatingCapacity = json['seatingCapacity'];
    loadCapacity = json['loadCapacity'];
    capacityUnit = json['capacityUnit'];
    securityDeposit = json['securityDeposit'];
    pickupLocation = json['pickupLocation'];

    documentRequired = json['documentRequired'] != null
        ? DocumentRequired.fromJson(json['documentRequired'])
        : null;

    // Image Parsing
    vehicleFrontImage = json['vehicleFrontImage']?.cast<String>();
    vehicleBackImage = json['vehicleBackImage']?.cast<String>();

    // Note: vehicleNoPlateImg is a String, not a List
    vehicleNoPlateImg = json['vehicleNoPlateImg'];

    vehicleLeftSideImage = json['vehicleLeftSideImage']?.cast<String>();
    vehicleRightHandSideImage = json['vehicleRightHandSideImage']?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['registrationType'] = registrationType;
    data['restrictions'] = restrictions;
    data['vehicleType'] = vehicleType;
    data['brand'] = brand;
    data['registrationNumber'] = registrationNumber;
    data['yearOfManufacture'] = yearOfManufacture;
    data['fuelType'] = fuelType;
    data['seatingCapacity'] = seatingCapacity;
    data['loadCapacity'] = loadCapacity;
    data['capacityUnit'] = capacityUnit;
    data['securityDeposit'] = securityDeposit;
    data['pickupLocation'] = pickupLocation;
    if (documentRequired != null) data['documentRequired'] = documentRequired!.toJson();
    data['vehicleFrontImage'] = vehicleFrontImage;
    data['vehicleBackImage'] = vehicleBackImage;
    data['vehicleNoPlateImg'] = vehicleNoPlateImg;
    data['vehicleLeftSideImage'] = vehicleLeftSideImage;
    data['vehicleRightHandSideImage'] = vehicleRightHandSideImage;

    return data;
  }
}

class DocumentRequired {
  bool? adharCard;
  bool? addressProof;
  bool? drivingLicence;

  DocumentRequired({this.adharCard, this.addressProof, this.drivingLicence});

  DocumentRequired.fromJson(Map<String, dynamic> json) {
    adharCard = json['adharCard'];
    addressProof = json['addressProof'];
    drivingLicence = json['drivingLicence'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['adharCard'] = adharCard;
    data['addressProof'] = addressProof;
    data['drivingLicence'] = drivingLicence;
    return data;
  }
}

class EquipmentDetails {
  EquipmentDetails();

  EquipmentDetails.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    return data;
  }
}