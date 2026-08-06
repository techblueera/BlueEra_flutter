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

  // `total_product_count` / `total_category_count` used to arrive here. The
  // listing dropped them — it no longer fans out to the inventory services to
  // collect them — and they now come from the per-catalogue
  // `business-product-stats` endpoints instead. Kept out of the model on
  // purpose: parsed-but-always-null fields invite a fallback that would render
  // a permanent `0`. See StoreCountsModel.
  String? quirkyMessage;
  int? chatClickCount;
  List<StoreCategoryBrief>? categories;

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
    this.quirkyMessage,
    this.chatClickCount,
    this.categories,
  });

  /// Parses a store from `user-service/business/search` — and still from the
  /// old `map-service/api/stores` payload, which is also what [toJson] writes,
  /// so the Hive cache round-trips through here unchanged.
  ///
  /// The two shapes disagree on more than field names:
  ///  * the id is `_id` on search, `id` on the old listing (and in the cache);
  ///  * `total_ratings` arrives as a NUMBER on search and a string before, so
  ///    it is stringified rather than cast — an `as String?` on `0` throws;
  ///  * the category comes as `category_details` (an object) alongside
  ///    `category_Of_Business`, which on search is a bare tag STRING and must
  ///    not be fed to [CategoryOfBusiness.fromJson].
  ///
  /// Fields search does not return at all — `views`, `follower_count`,
  /// `is_followed`, `quirky_message`, `chat_click_count`, `categories` — land
  /// as null, which is what the widgets reading them already handle.
  factory GetAllStoreResModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asObject(dynamic value) =>
        value is Map ? Map<String, dynamic>.from(value) : null;

    final categoryJson = asObject(json['category_of_business']) ??
        asObject(json['category_details']) ??
        asObject(json['category_Of_Business']);
    final subCategoryJson = asObject(json['sub_category_of_business']) ??
        asObject(json['sub_category_details']) ??
        asObject(json['sub_category_Of_Business']);

    return GetAllStoreResModel(
      livePhotos: json['live_photos'] != null
          ? List<String>.from(json['live_photos'].map((x) => x.toString()))
          : [],
      id: (json['id'] ?? json['_id'])?.toString(),
      userId: json['user_id']?.toString(),
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
      avgRating: (json['avg_rating'] as num?)?.toInt(),
      totalRatings: json['total_ratings']?.toString(),
      views: json['views']?.toString(),
      followerCount: json['follower_count']?.toString(),
      isFollowed: json['is_followed'],
      categoryOfBusiness:
          categoryJson != null ? CategoryOfBusiness.fromJson(categoryJson) : null,
      subCategoryOfBusiness: subCategoryJson != null
          ? SubCategoryOfBusiness.fromJson(subCategoryJson)
          : null,
      quirkyMessage: json['quirky_message'],
      chatClickCount: json['chat_click_count'] is int
          ? json['chat_click_count'] as int
          : (json['chat_click_count'] is num
              ? (json['chat_click_count'] as num).toInt()
              : int.tryParse(json['chat_click_count']?.toString() ?? '')),
      categories: json['categories'] is List
          ? (json['categories'] as List)
              .whereType<Map>()
              .map((e) => StoreCategoryBrief.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList()
          : null,
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
    map['quirky_message'] = quirkyMessage;
    map['chat_click_count'] = chatClickCount;
    map['categories'] = categories?.map((c) => c.toJson()).toList();
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
    String? quirkyMessage,
    int? chatClickCount,
    List<StoreCategoryBrief>? categories,
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
      quirkyMessage: quirkyMessage ?? this.quirkyMessage,
      chatClickCount: chatClickCount ?? this.chatClickCount,
      categories: categories ?? this.categories,
    );
  }
}

class StoreCategoryBrief {
  final String? id;
  final String? name;
  final String? key;
  final String? image;

  StoreCategoryBrief({this.id, this.name, this.key, this.image});

  factory StoreCategoryBrief.fromJson(Map<String, dynamic> json) {
    return StoreCategoryBrief(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      key: json['key']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'key': key,
        'image': image,
      };
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
    // `_id` on `business/search`'s `category_details`, `id` on the old listing
    // and on anything read back out of the cache.
    id = (json['id'] ?? json['_id'])?.toString();
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
    // `_id` on `business/search`, `id` on the old listing / the cache.
    id = (json['id'] ?? json['_id'])?.toString();
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