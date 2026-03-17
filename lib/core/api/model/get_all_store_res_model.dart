import 'dart:convert';

GetAllStoreResModel getAllStoreResModelFromJson(String str) =>
    GetAllStoreResModel.fromJson(json.decode(str));

String getAllStoreResModelToJson(GetAllStoreResModel data) =>
    json.encode(data.toJson());

class GetAllStoreResModel {
  List<String>? livePhotos;
  String? id;
  String? userId;
  String? businessName;
  DateOfIncorporation? dateOfIncorporation;
  String? logo;
  String? businessDescription;
  String? natureOfBusiness;
  String? address;
  BusinessLocation? businessLocation;
  String? websiteUrl;
  String? createdAt;
  int? avgRating;
  String? totalRatings;
  String? views;
  String? followerCount;
  bool? isFollowed;
  CategoryOfBusiness? categoryOfBusiness;
  SubCategoryOfBusiness? subCategoryOfBusiness;
  int? totalProductCount;
  int? totalCategoryCount;
  String? quirkyMessage;

  GetAllStoreResModel({
    this.livePhotos,
    this.id,
    this.userId,
    this.businessName,
    this.dateOfIncorporation,
    this.logo,
    this.businessDescription,
    this.natureOfBusiness,
    this.address,
    this.businessLocation,
    this.websiteUrl,
    this.createdAt,
    this.avgRating,
    this.totalRatings,
    this.views,
    this.followerCount,
    this.isFollowed,
    this.categoryOfBusiness,
    this.subCategoryOfBusiness,
    this.totalProductCount,
    this.totalCategoryCount,
    this.quirkyMessage,
  });

  factory GetAllStoreResModel.fromJson(Map<String, dynamic> json) {
    return GetAllStoreResModel(
      livePhotos: json['live_photos'] != null
          ? List<String>.from(json['live_photos'].map((x) => x.toString()))
          : [],
      id: json['id'],
      userId: json['user_id'],
      businessName: json['business_name'],
      dateOfIncorporation: json['date_of_incorporation'] != null
          ? DateOfIncorporation.fromJson(json['date_of_incorporation'])
          : null,
      logo: json['logo'],
      businessDescription: json['business_description'],
      natureOfBusiness: json['Nature_of_Business'],
      address: json['address'],
      businessLocation: json['business_location'] != null
          ? BusinessLocation.fromJson(json['business_location'])
          : null,
      websiteUrl: json['website_url'],
      createdAt: json['created_at'],
      avgRating: json['avg_rating'],
      totalRatings: json['total_ratings'],
      views: json['views'],
      followerCount: json['follower_count'],
      isFollowed: json['is_followed'],
      categoryOfBusiness: json['category_of_business'] != null
          ? CategoryOfBusiness.fromJson(json['category_of_business'])
          : null,
      subCategoryOfBusiness: json['sub_category_of_business'] != null
          ? SubCategoryOfBusiness.fromJson(json['sub_category_of_business'])
          : null,
      totalProductCount: json['total_product_count'],
      totalCategoryCount: json['total_category_count'],
      quirkyMessage: json['quirky_message'],

    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['live_photos'] = livePhotos;
    map['id'] = id;
    map['user_id'] = userId;
    map['business_name'] = businessName;
    map['date_of_incorporation'] = dateOfIncorporation?.toJson();
    map['logo'] = logo;
    map['business_description'] = businessDescription;
    map['Nature_of_Business'] = natureOfBusiness;
    map['address'] = address;
    map['business_location'] = businessLocation?.toJson();
    map['website_url'] = websiteUrl;
    map['created_at'] = createdAt;
    map['avg_rating'] = avgRating;
    map['total_ratings'] = totalRatings;
    map['views'] = views;
    map['follower_count'] = followerCount;
    map['is_followed'] = isFollowed;
    map['category_of_business'] = categoryOfBusiness?.toJson();
    map['sub_category_of_business'] = subCategoryOfBusiness?.toJson();
    map['total_product_count'] = totalProductCount;
    map['total_category_count'] = totalCategoryCount;
    map['quirky_message'] = quirkyMessage;
    return map;
  }

  GetAllStoreResModel copyWith({
    List<String>? livePhotos,
    String? id,
    String? userId,
    String? businessName,
    DateOfIncorporation? dateOfIncorporation,
    String? typeOfBusiness,
    String? logo,
    String? businessDescription,
    dynamic businessNumber,
    String? natureOfBusiness,
    String? cityStatePincode,
    String? address,
    bool? isActive,
    bool? businessIsVerified,
    BusinessLocation? businessLocation,
    String? websiteUrl,
    String? createdAt,
    String? updatedAt,
    int? avgRating,
    String? totalRatings,
    String? views,
    String? followerCount,
    bool? isFollowed,
    num? distance,
    CategoryOfBusiness? categoryOfBusiness,
    SubCategoryOfBusiness? subCategoryOfBusiness,
    int? totalProductCount,
    int? totalCategoryCount,
    String? quirkyMessage
  }) {
    return GetAllStoreResModel(
      livePhotos: livePhotos ?? this.livePhotos,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      dateOfIncorporation: dateOfIncorporation ?? this.dateOfIncorporation,
      logo: logo ?? this.logo,
      businessDescription: businessDescription ?? this.businessDescription,
      natureOfBusiness: natureOfBusiness ?? this.natureOfBusiness,
      address: address ?? this.address,
      businessLocation: businessLocation ?? this.businessLocation,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      createdAt: createdAt ?? this.createdAt,
      avgRating: avgRating ?? this.avgRating,
      totalRatings: totalRatings ?? this.totalRatings,
      views: views ?? this.views,
      followerCount: followerCount ?? this.followerCount,
      isFollowed: isFollowed ?? this.isFollowed,
      categoryOfBusiness: categoryOfBusiness ?? this.categoryOfBusiness,
      subCategoryOfBusiness: subCategoryOfBusiness ?? this.subCategoryOfBusiness,
      totalProductCount: totalProductCount ?? this.totalProductCount,
      totalCategoryCount: totalCategoryCount ?? this.totalCategoryCount,
      quirkyMessage: quirkyMessage ?? this.quirkyMessage,
    );
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

class SubCategoryOfBusiness {
  String? id;
  String? name;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? createdBy;
  String? updatedBy;
  bool? active;
  String? categoryId;

  SubCategoryOfBusiness(
      {this.id,
        this.name,
        this.createdAt,
        this.updatedAt,
        this.deletedAt,
        this.createdBy,
        this.updatedBy,
        this.active,
        this.categoryId});

  SubCategoryOfBusiness.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    active = json['active'];
    categoryId = json['category_id'];
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
    data['category_id'] = this.categoryId;
    return data;
  }
}