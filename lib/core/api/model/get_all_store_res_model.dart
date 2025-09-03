import 'dart:convert';
GetAllStoreResModel getAllStoreResModelFromJson(String str) => GetAllStoreResModel.fromJson(json.decode(str));
String getAllStoreResModelToJson(GetAllStoreResModel data) => json.encode(data.toJson());
class GetAllStoreResModel {
  GetAllStoreResModel({
    this.livePhotos,
    this.id,
    this.userId,
    this.businessName,
    this.dateOfIncorporation,
    this.typeOfBusiness,
    this.logo,
    this.subCategoryOfBusiness,
    this.businessDescription,
    this.businessNumber,
    this.natureOfBusiness,
    this.cityStatePincode,
    this.address,
    this.gst,
    this.isActive,
    this.businessIsVerified,
    this.businessLocation,
    this.websiteUrl,
    this.createdAt,
    this.updatedAt,
    this.avgRating,
    this.categoryOfBusiness,
    this.totalRatings,
    this.distance,
  });

  GetAllStoreResModel.fromJson(dynamic json) {
    if (json['live_photos'] != null) {
      livePhotos = List<String>.from(json['live_photos'].map((x) => x.toString()));
    }
    id = json['id'];
    userId = json['user_id'];
    businessName = json['business_name'];
    dateOfIncorporation = json['date_of_incorporation'] != null
        ? DateOfIncorporation.fromJson(json['date_of_incorporation'])
        : null;
    typeOfBusiness = json['type_of_business'];
    logo = json['logo'];
    subCategoryOfBusiness = json['sub_category_Of_Business'];
    businessDescription = json['business_description'];
    businessNumber = json['business_number'];
    natureOfBusiness = json['Nature_of_Business'];
    cityStatePincode = json['city_state_pincode'];
    address = json['address'];
    gst = json['gst'] != null ? Gst.fromJson(json['gst']) : null;
    isActive = json['isActive'];
    businessIsVerified = json['business_isVerified'];
    businessLocation = json['business_location'] != null
        ? BusinessLocation.fromJson(json['business_location'])
        : null;
    websiteUrl = json['website_url'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    avgRating = json['avg_rating'];
    totalRatings = json['total_ratings'];
    distance = json['distance'];
    categoryOfBusiness = json['category_of_business'] != null
        ? CategoryOfBusiness.fromJson(json['category_of_business'])
        : null;
  }

  List<String>? livePhotos; // <-- Now array of strings
  String? id;
  String? userId;
  String? businessName;
  DateOfIncorporation? dateOfIncorporation;
  String? typeOfBusiness;
  String? logo;
  String? subCategoryOfBusiness;
  String? businessDescription;
  dynamic businessNumber;
  String? natureOfBusiness;
  String? cityStatePincode;
  String? address;
  Gst? gst;
  bool? isActive;
  bool? businessIsVerified;
  BusinessLocation? businessLocation;
  String? websiteUrl;
  String? createdAt;
  String? updatedAt;
  int? avgRating;
  int? totalRatings;
  num? distance;
  CategoryOfBusiness? categoryOfBusiness;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (livePhotos != null) {
      map['live_photos'] = List<dynamic>.from(livePhotos!.map((x) => x));
    }
    map['id'] = id;
    map['user_id'] = userId;
    map['business_name'] = businessName;
    if (dateOfIncorporation != null) {
      map['date_of_incorporation'] = dateOfIncorporation?.toJson();
    }
    map['type_of_business'] = typeOfBusiness;
    map['logo'] = logo;
    map['sub_category_Of_Business'] = subCategoryOfBusiness;
    map['business_description'] = businessDescription;
    map['business_number'] = businessNumber;
    map['Nature_of_Business'] = natureOfBusiness;
    map['city_state_pincode'] = cityStatePincode;
    map['address'] = address;
    if (gst != null) {
      map['gst'] = gst?.toJson();
    }
    map['isActive'] = isActive;
    map['business_isVerified'] = businessIsVerified;
    if (businessLocation != null) {
      map['business_location'] = businessLocation?.toJson();
    }
    map['website_url'] = websiteUrl;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['avg_rating'] = avgRating;
    map['total_ratings'] = totalRatings;
    map['distance'] = distance;
    if (categoryOfBusiness != null) {
      map['category_of_business'] = categoryOfBusiness!.toJson();
    }
    return map;
  }
}

BusinessLocation businessLocationFromJson(String str) => BusinessLocation.fromJson(json.decode(str));
String businessLocationToJson(BusinessLocation data) => json.encode(data.toJson());
class BusinessLocation {
  BusinessLocation({
      this.lat, 
      this.lon,});

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

Gst gstFromJson(String str) => Gst.fromJson(json.decode(str));
String gstToJson(Gst data) => json.encode(data.toJson());
class Gst {
  Gst({
      this.have, 
      this.number, 
      this.gstVerification,});

  Gst.fromJson(dynamic json) {
    have = json['have'];
    number = json['number'];
    gstVerification = json['gst_verification'];
  }
  bool? have;
  String? number;
  bool? gstVerification;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['have'] = have;
    map['number'] = number;
    map['gst_verification'] = gstVerification;
    return map;
  }

}

DateOfIncorporation dateOfIncorporationFromJson(String str) => DateOfIncorporation.fromJson(json.decode(str));
String dateOfIncorporationToJson(DateOfIncorporation data) => json.encode(data.toJson());
class DateOfIncorporation {
  DateOfIncorporation({
      this.date, 
      this.month, 
      this.year,});

  DateOfIncorporation.fromJson(dynamic json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
  }
  int? date;
  int? month;
  int? year;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['date'] = date;
    map['month'] = month;
    map['year'] = year;
    return map;
  }

}

class CategoryOfBusiness {
  String? id;
  String? name;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? createdBy;
  String? updatedBy;
  bool? active;
  String? imageUrl;

  CategoryOfBusiness(
      {this.id,
        this.name,
        this.createdAt,
        this.updatedAt,
        this.deletedAt,
        this.createdBy,
        this.updatedBy,
        this.active,
        this.imageUrl});

  CategoryOfBusiness.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    active = json['active'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    data['created_by'] = this.createdBy;
    data['updated_by'] = this.updatedBy;
    data['active'] = this.active;
    data['image_url'] = this.imageUrl;
    return data;
  }
}