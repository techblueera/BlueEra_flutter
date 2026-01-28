import 'dart:convert';

import '../../map/model/food_service_model_response.dart';

GetServiceModel getServiceModelFromJson(String str) =>
    GetServiceModel.fromJson(json.decode(str));

String getServiceModelToJson(GetServiceModel data) =>
    json.encode(data.toJson());

class GetServiceModel {
  GetServiceModel({
    this.priceRange,
    this.keyIngredients,
    this.accompaniments,
    this.keyMinerals,
    this.seoTags,
    this.id,
    this.userId,
    this.type,
    this.title,
    this.description,
    this.photos,
    this.timings,
    this.facilities,
    this.priceType,
    this.perUnit,
    this.discounts,
    this.extraDetails,
    this.isActive,
    this.isDeleted,
    this.category,
    this.businessName,
    this.subCategory,
    this.addOns,
    this.priceOptions,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.servingOptions,
    this.business,
    this.serviceProvider,
    this.variants,
    this.providerDetails,
  });

  GetServiceModel.fromJson(dynamic json) {
    priceRange = json['priceRange'] != null
        ? PriceRange.fromJson(json['priceRange'])
        : null;

    id = json['_id'];
    userId = json['userId'];
    category = json['category'];
    businessName = json['businessName'];
    subCategory = json['subCategory'];
    type = json['type'];
    title = json['title'];
    description = json['description'];

    if (json['timings'] != null) {
      timings = [];
      json['timings'].forEach((v) {
        timings?.add(Timings.fromJson(v));
      });
    }
    facilities =
        json['facilities'] != null ? json['facilities'].cast<String>() : [];
    seoTags = json['seoTags'] != null ? json['seoTags'].cast<String>() : [];
    photos = json['photos'] != null ? json['photos'].cast<String>() : [];
    keyMinerals =
        json['keyMinerals'] != null ? json['keyMinerals'].cast<String>() : [];
    variants = json['variants'] != null ? json['variants'].cast<String>() : [];
    addOns = json['addOns'] != null ? json['addOns'].cast<String>() : [];
    priceOptions =
        json['priceOptions'] != null ? json['priceOptions'].cast<String>() : [];
    priceType = json['priceType'];
    perUnit = json['perUnit'];
    if (json['discounts'] != null) {
      discounts = [];
      json['discounts'].forEach((v) {
        discounts?.add(Discounts.fromJson(v));
      });
    }
    if (json['extraDetails'] != null) {
      extraDetails = [];
      json['extraDetails'].forEach((v) {
        extraDetails?.add(ExtraDetails.fromJson(v));
      });
    }
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    business = json['business'] != null
        ? new BusinessService.fromJson(json['business'])
        : null;
    serviceProvider = json['serviceProvider'] != null
        ? new ServiceProvider.fromJson(json['serviceProvider'])
        : null;
    providerDetails = json['providerDetails'] != null
        ? ProviderDetails.fromJson(json['providerDetails'])
        : null;

  }

  PriceRange? priceRange;
  List<String>? keyIngredients;
  List<String>? accompaniments;
  List<String>? keyMinerals;
  List<String>? seoTags;
  String? id;
  String? userId;
  String? type;
  String? title;
  String? description;
  String? category;
  String? subCategory;
  String? businessName;
  List<String>? photos;
  List<Timings>? timings;
  List<String>? facilities;
  String? priceType;
  String? perUnit;
  List<Discounts>? discounts;
  List<ExtraDetails>? extraDetails;
  bool? isActive;
  bool? isDeleted;
  List<String>? addOns;
  List<String>? priceOptions;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<dynamic>? servingOptions;
  List<dynamic>? variants;
  BusinessService? business;
  ServiceProvider? serviceProvider;
  ProviderDetails? providerDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (priceRange != null) {
      map['priceRange'] = priceRange?.toJson();
    }

    map['_id'] = id;
    map['userId'] = userId;
    map['category'] = category;
    map['businessName'] = businessName;
    map['subCategory'] = subCategory;
    map['type'] = type;
    map['title'] = title;
    map['description'] = description;
    if (photos != null) {
      map['photos'] = photos;
    }
    if (timings != null) {
      map['timings'] = timings?.map((v) => v.toJson()).toList();
    }

    map['facilities'] = facilities;
    map['priceType'] = priceType;
    map['perUnit'] = perUnit;
    if (discounts != null) {
      map['discounts'] = discounts?.map((v) => v.toJson()).toList();
    }
    if (extraDetails != null) {
      map['extraDetails'] = extraDetails?.map((v) => v.toJson()).toList();
    }
    map['isActive'] = isActive;
    map['isDeleted'] = isDeleted;
    if (addOns != null) {
      map['addOns'] = addOns;
    }
    if (priceOptions != null) {
      map['priceOptions'] = priceOptions;
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (servingOptions != null) {
      map['servingOptions'] = servingOptions?.map((v) => v.toJson()).toList();
    }
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    if (this.business != null) {
      map['business'] = this.business!.toJson();
    }
    if (this.serviceProvider != null) {
      map['serviceProvider'] = this.serviceProvider!.toJson();
    }
    if (providerDetails != null) {
      map['providerDetails'] = providerDetails!.toJson();
    }
    return map;
  }
}



ExtraDetails extraDetailsFromJson(String str) =>
    ExtraDetails.fromJson(json.decode(str));

String extraDetailsToJson(ExtraDetails data) => json.encode(data.toJson());

class ExtraDetails {
  ExtraDetails({
    this.title,
    this.details,
  });

  ExtraDetails.fromJson(dynamic json) {
    title = json['title'];
    details = json['details'];
  }

  String? title;
  String? details;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['details'] = details;
    return map;
  }
}

Discounts discountsFromJson(String str) => Discounts.fromJson(json.decode(str));

String discountsToJson(Discounts data) => json.encode(data.toJson());

class Discounts {
  Discounts({
    this.name,
    this.description,
    this.amountOff,
    this.type,
  });

  Discounts.fromJson(dynamic json) {
    name = json['name'];
    description = json['description'];
    type = json['type'];
    amountOff = json['amountOff'];
  }

  String? name;
  String? description;
  String? type;
  num? amountOff;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['description'] = description;
    map['type'] = type;
    map['amountOff'] = amountOff;
    return map;
  }
}

Timings timingsFromJson(String str) => Timings.fromJson(json.decode(str));

String timingsToJson(Timings data) => json.encode(data.toJson());

class Timings {
  Timings({
    this.start,
    this.end,
    this.special,
  });

  Timings.fromJson(dynamic json) {
    start = json['start'];
    end = json['end'];
    special = json['special'];
  }

  String? start;
  String? end;
  bool? special;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['start'] = start;
    map['end'] = end;
    map['special'] = special;
    return map;
  }
}

PriceRange priceRangeFromJson(String str) =>
    PriceRange.fromJson(json.decode(str));

String priceRangeToJson(PriceRange data) => json.encode(data.toJson());

class PriceRange {
  PriceRange({
    this.min,
    this.max,
  });

  PriceRange.fromJson(dynamic json) {
    min = json['min'];
    max = json['max'];
  }

  int? min;
  int? max;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['min'] = min;
    map['max'] = max;
    return map;
  }
}

class BusinessLocation {
  BusinessLocation({
    this.lat,
    this.lon,
  });

  BusinessLocation.fromJson(dynamic json) {
    lat = json['lat'];
    lon = json['lon'];
  }

  num? lat;
  num? lon;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['lat'] = lat;
    map['lon'] = lon;
    return map;
  }
}

class BusinessService {
  String? id;
  String? userId;
  String? businessName;
  String? typeOfBusiness;
  String? logo;
  String? address;
  BusinessLocation? businessLocation;
  String? createdAt;
  String? updatedAt;
  CategoryOfBusiness? categoryOfBusiness;
  List<OwnerDetails>? ownerDetails;


  BusinessService({
    this.id,
    this.userId,
    this.businessName,
    this.typeOfBusiness,
    this.logo,
    this.businessLocation,
    this.createdAt,
    this.updatedAt,
    this.address,
    this.categoryOfBusiness,
    this.ownerDetails,

  });

  BusinessService.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    address = json['address'];
    businessName = json['business_name'];

    typeOfBusiness = json['type_of_business'];
    logo = json['logo'];
    businessLocation = json['business_location'] != null
        ? new BusinessLocation.fromJson(json['business_location'])
        : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    categoryOfBusiness = json['category_of_business'] != null
        ? CategoryOfBusiness.fromJson(json['category_of_business'])
        : null;
    if (json['owner_details'] != null) {
      ownerDetails = <OwnerDetails>[];
      json['owner_details'].forEach((v) {
        ownerDetails!.add(new OwnerDetails.fromJson(v));
      });
    }


  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['address'] = this.address;
    data['business_name'] = this.businessName;

    data['type_of_business'] = this.typeOfBusiness;
    data['logo'] = this.logo;

    if (this.businessLocation != null) {
      data['business_location'] = this.businessLocation!.toJson();
    }
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (categoryOfBusiness != null) {
      data['category_of_business'] = categoryOfBusiness!.toJson();
    }

    if (this.ownerDetails != null) {
      data['owner_details'] =
          this.ownerDetails!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class ServiceProvider {
  String? id;
  String? type;

  ServiceProvider({
    this.id,
    this.type
  });

  ServiceProvider.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['id'] = this.id;
    data['type'] = this.type;
    return data;
  }
}

class ProviderDetails {
  String? id;
  String? name;
  String? profileImage;
  String? location;
  String? profession;
  bool? verified;

  ProviderDetails(
      {this.id,
        this.name,
        this.profileImage,
        this.location,
        this.profession,
        this.verified
      });

  ProviderDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profileImage = json['profile_image'];
    location = json['location'];
    profession = json['profession'];
    verified = json['verified'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile_image'] = this.profileImage;
    data['location'] = this.location;
    data['profession'] = this.profession;
    data['verified'] = this.verified;
    return data;
  }
}