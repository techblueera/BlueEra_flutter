import 'dart:convert';
GetServiceModel getServiceModelFromJson(String str) => GetServiceModel.fromJson(json.decode(str));
String getServiceModelToJson(GetServiceModel data) => json.encode(data.toJson());
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
      this.addOns, 
      this.priceOptions, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.servingOptions, 
      this.variants,});

  GetServiceModel.fromJson(dynamic json) {
    priceRange = json['priceRange'] != null ? PriceRange.fromJson(json['priceRange']) : null;



    id = json['_id'];
    userId = json['userId'];
    type = json['type'];
    title = json['title'];
    description = json['description'];

    if (json['timings'] != null) {
      timings = [];
      json['timings'].forEach((v) {
        timings?.add(Timings.fromJson(v));
      });
    }
    facilities = json['facilities'] != null ? json['facilities'].cast<String>() : [];
    seoTags = json['seoTags'] != null ? json['seoTags'].cast<String>() : [];
    photos = json['photos'] != null ? json['photos'].cast<String>() : [];
    keyMinerals = json['keyMinerals'] != null ? json['keyMinerals'].cast<String>() : [];
    variants = json['variants'] != null ? json['variants'].cast<String>() : [];
    addOns = json['addOns'] != null ? json['addOns'].cast<String>() : [];
    priceOptions = json['priceOptions'] != null ? json['priceOptions'].cast<String>() : [];
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

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (priceRange != null) {
      map['priceRange'] = priceRange?.toJson();
    }

    map['_id'] = id;
    map['userId'] = userId;
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
    return map;
  }

}

ExtraDetails extraDetailsFromJson(String str) => ExtraDetails.fromJson(json.decode(str));
String extraDetailsToJson(ExtraDetails data) => json.encode(data.toJson());
class ExtraDetails {
  ExtraDetails({
      this.title, 
      this.details,});

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
      this.type,});

  Discounts.fromJson(dynamic json) {
    name = json['name'];
    description = json['description'];
    type = json['type'];
  }
  String? name;
  String? description;
  String? type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['description'] = description;
    map['type'] = type;
    return map;
  }

}

Timings timingsFromJson(String str) => Timings.fromJson(json.decode(str));
String timingsToJson(Timings data) => json.encode(data.toJson());
class Timings {
  Timings({
      this.start, 
      this.end, 
      this.special,});

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

PriceRange priceRangeFromJson(String str) => PriceRange.fromJson(json.decode(str));
String priceRangeToJson(PriceRange data) => json.encode(data.toJson());
class PriceRange {
  PriceRange({
      this.min, 
      this.max,});

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