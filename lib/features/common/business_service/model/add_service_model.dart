import 'dart:convert';
AddServiceModel addServiceModelFromJson(String str) => AddServiceModel.fromJson(json.decode(str));
String addServiceModelToJson(AddServiceModel data) => json.encode(data.toJson());
class AddServiceModel {
  AddServiceModel({
      this.service, 
      this.uploadUrls,});

  AddServiceModel.fromJson(dynamic json) {
    service = json['service'] != null ? Service.fromJson(json['service']) : null;
    uploadUrls = json['uploadUrls'] != null ? UploadUrls.fromJson(json['uploadUrls']) : null;
  }
  Service? service;
  UploadUrls? uploadUrls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (service != null) {
      map['service'] = service?.toJson();
    }
    if (uploadUrls != null) {
      map['uploadUrls'] = uploadUrls?.toJson();
    }
    return map;
  }

}

UploadUrls uploadUrlsFromJson(String str) => UploadUrls.fromJson(json.decode(str));
String uploadUrlsToJson(UploadUrls data) => json.encode(data.toJson());
class UploadUrls {
  UploadUrls({
      this.video, 
      this.images,});

  UploadUrls.fromJson(dynamic json) {
    video = json['video'];
    images = json['images'] != null ? json['images'].cast<String>() : [];
  }
  String? video;
  List<String>? images;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['video'] = video;
    map['images'] = images;
    return map;
  }

}

Service serviceFromJson(String str) => Service.fromJson(json.decode(str));
String serviceToJson(Service data) => json.encode(data.toJson());
class Service {
  Service({
      this.userId, 
      this.type, 
      this.title, 
      this.description, 
      this.photos, 
      this.category, 
      this.subCategory, 

      this.timings, 
      this.facilities, 
      this.priceType, 
      this.priceOptions, 
      this.discounts, 
      this.extraDetails, 
      this.isActive, 
      this.isDeleted, 
      this.id, 
      this.addOns, 
      this.servingOptions, 
      this.variants, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.demoVideo,});

  Service.fromJson(dynamic json) {
    userId = json['userId'];
    type = json['type'];
    title = json['title'];
    description = json['description'];
    photos = json['photos'] != null ? json['photos'].cast<String>() : [];
    category = json['category'];
    subCategory = json['subCategory'];

    if (json['timings'] != null) {
      timings = [];
      json['timings'].forEach((v) {
        timings?.add(Timings.fromJson(v));
      });
    }
    facilities = json['facilities'] != null ? json['facilities'].cast<String>() : [];
    priceType = json['priceType'];
    if (json['priceOptions'] != null) {
      priceOptions = [];
      json['priceOptions'].forEach((v) {
        priceOptions?.add(PriceOptions.fromJson(v));
      });
    }
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
    id = json['_id'];

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    demoVideo = json['demoVideo'];
  }
  String? userId;
  String? type;
  String? title;
  String? description;
  List<String>? photos;
  String? category;
  String? subCategory;

  List<Timings>? timings;
  List<String>? facilities;
  String? priceType;
  List<PriceOptions>? priceOptions;
  List<Discounts>? discounts;
  List<ExtraDetails>? extraDetails;
  bool? isActive;
  bool? isDeleted;
  String? id;
  List<dynamic>? addOns;
  List<dynamic>? servingOptions;
  List<dynamic>? variants;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? demoVideo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userId'] = userId;
    map['type'] = type;
    map['title'] = title;
    map['description'] = description;
    map['photos'] = photos;
    map['category'] = category;
    map['subCategory'] = subCategory;

    if (timings != null) {
      map['timings'] = timings?.map((v) => v.toJson()).toList();
    }
    map['facilities'] = facilities;
    map['priceType'] = priceType;
    if (priceOptions != null) {
      map['priceOptions'] = priceOptions?.map((v) => v.toJson()).toList();
    }
    if (discounts != null) {
      map['discounts'] = discounts?.map((v) => v.toJson()).toList();
    }
    if (extraDetails != null) {
      map['extraDetails'] = extraDetails?.map((v) => v.toJson()).toList();
    }
    map['isActive'] = isActive;
    map['isDeleted'] = isDeleted;
    map['_id'] = id;
    if (addOns != null) {
      map['addOns'] = addOns?.map((v) => v.toJson()).toList();
    }
    if (servingOptions != null) {
      map['servingOptions'] = servingOptions?.map((v) => v.toJson()).toList();
    }
    if (variants != null) {
      map['variants'] = variants?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['demoVideo'] = demoVideo;
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
      this.amountOff, 
      this.type,});

  Discounts.fromJson(dynamic json) {
    name = json['name'];
    description = json['description'];
    amountOff = json['amountOff'];
    type = json['type'];
  }
  String? name;
  String? description;
  int? amountOff;
  String? type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['description'] = description;
    map['amountOff'] = amountOff;
    map['type'] = type;
    return map;
  }

}

PriceOptions priceOptionsFromJson(String str) => PriceOptions.fromJson(json.decode(str));
String priceOptionsToJson(PriceOptions data) => json.encode(data.toJson());
class PriceOptions {
  PriceOptions({
      this.label, 
      this.price,});

  PriceOptions.fromJson(dynamic json) {
    label = json['label'];
    price = json['price'];
  }
  String? label;
  int? price;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['label'] = label;
    map['price'] = price;
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