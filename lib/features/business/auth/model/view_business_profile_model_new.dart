// import 'dart:convert';
// ViewBusinessProfileModelNew viewBusinessProfileModelNewFromJson(String str) => ViewBusinessProfileModelNew.fromJson(json.decode(str));
// String viewBusinessProfileModelNewToJson(ViewBusinessProfileModelNew data) => json.encode(data.toJson());
// class ViewBusinessProfileModelNew {
//   ViewBusinessProfileModelNew({
//       this.status,
//       this.data,
//       this.userContactNo,
//       this.relatedStores,});
//
//   ViewBusinessProfileModelNew.fromJson(dynamic json) {
//     status = json['status'];
//     data = json['data'] != null ? Data.fromJson(json['data']) : null;
//     userContactNo = json['userContactNo'];
//     if (json['relatedStores'] != null) {
//       relatedStores = [];
//       json['relatedStores'].forEach((v) {
//         relatedStores?.add(RelatedStores.fromJson(v));
//       });
//     }
//   }
//   bool? status;
//   Data? data;
//   String? userContactNo;
//   List<RelatedStores>? relatedStores;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['status'] = status;
//     if (data != null) {
//       map['data'] = data?.toJson();
//     }
//     map['userContactNo'] = userContactNo;
//     if (relatedStores != null) {
//       map['relatedStores'] = relatedStores?.map((v) => v.toJson()).toList();
//     }
//     return map;
//   }
//
// }
//
// RelatedStores relatedStoresFromJson(String str) => RelatedStores.fromJson(json.decode(str));
// String relatedStoresToJson(RelatedStores data) => json.encode(data.toJson());
// class RelatedStores {
//   RelatedStores({
//       this.id,
//       this.businessName,
//       this.logo,
//       this.address,
//       this.avgRating,
//       this.totalRatings,});
//
//   RelatedStores.fromJson(dynamic json) {
//     id = json['_id'];
//     businessName = json['business_name'];
//     logo = json['logo'];
//     address = json['address'];
//     avgRating = json['avg_rating'];
//     totalRatings = json['total_ratings'];
//   }
//   String? id;
//   String? businessName;
//   String? logo;
//   String? address;
//   int? avgRating;
//   int? totalRatings;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['business_name'] = businessName;
//     map['logo'] = logo;
//     map['address'] = address;
//     map['avg_rating'] = avgRating;
//     map['total_ratings'] = totalRatings;
//     return map;
//   }
//
// }
//
// Data dataFromJson(String str) => Data.fromJson(json.decode(str));
// String dataToJson(Data data) => json.encode(data.toJson());
// class Data {
//   Data({
//       this.id,
//       this.userId,
//       this.gst,
//       this.isActive,
//       this.businessIsVerified,
//       this.businessLocation,
//       this.livePhotos,
//       this.ownerDetails,
//       this.createdAt,
//       this.updatedAt,
//       this.v,
//       this.natureOfBusiness,
//       this.businessName,
//       this.categoryOfBusiness,
//       this.dateOfIncorporation,
//       this.logo,
//       this.subCategoryOfBusiness,
//       this.typeOfBusiness,
//       this.address,
//       this.businessDescription,
//       this.cityStatePincode,
//       this.pincode,
//       this.categoryDetails,
//       this.subCategoryDetails,
//       this.avgRating,
//       this.totalRatings,
//       this.totalViews,
//       this.totalFollowers,
//       this.userHasRated,
//       this.userRating,
//       this.isFollowing,
//       this.businessNumber,});
//
//   Data.fromJson(dynamic json) {
//     id = json['_id'];
//     userId = json['user_id'] != null ? UserId.fromJson(json['user_id']) : null;
//     gst = json['gst'] != null ? Gst.fromJson(json['gst']) : null;
//     isActive = json['isActive'];
//     businessIsVerified = json['business_isVerified'];
//     businessLocation = json['business_location'] != null ? BusinessLocation.fromJson(json['business_location']) : null;
//     if (json['live_photos'] != null) {
//       livePhotos=json['live_photos'].cast<String>();
//
//
//     }
//     if (json['owner_details'] != null) {
//       ownerDetails = [];
//       json['owner_details'].forEach((v) {
//         ownerDetails?.add(OwnerDetails.fromJson(v));
//       });
//     }
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     v = json['__v'];
//     natureOfBusiness = json['Nature_of_Business'];
//     businessName = json['business_name'];
//     categoryOfBusiness = json['category_Of_Business'];
//     dateOfIncorporation = json['date_of_incorporation'] != null ? DateOfIncorporation.fromJson(json['date_of_incorporation']) : null;
//     logo = json['logo'];
//     subCategoryOfBusiness = json['sub_category_Of_Business'];
//     typeOfBusiness = json['type_of_business'];
//     address = json['address'];
//     businessDescription = json['business_description'];
//     cityStatePincode = json['city_state_pincode'];
//     pincode = json['pincode'];
//     categoryDetails = json['category_details'] != null ? CategoryDetails.fromJson(json['category_details']) : null;
//     subCategoryDetails = json['sub_category_details'] != null ? SubCategoryDetails.fromJson(json['sub_category_details']) : null;
//     avgRating = json['avg_rating'];
//     totalRatings = json['total_ratings'];
//     totalViews = json['total_views'];
//     totalFollowers = json['total_followers'];
//     userHasRated = json['user_has_rated'];
//     userRating = json['user_rating'];
//     isFollowing = json['is_following'];
//     businessNumber = json['business_number'] != null ? BusinessNumber.fromJson(json['business_number']) : null;
//   }
//   String? id;
//   UserId? userId;
//   Gst? gst;
//   bool? isActive;
//   bool? businessIsVerified;
//   BusinessLocation? businessLocation;
//   List<dynamic>? livePhotos;
//   List<OwnerDetails>? ownerDetails;
//   String? createdAt;
//   String? updatedAt;
//   int? v;
//   String? natureOfBusiness;
//   String? businessName;
//   String? categoryOfBusiness;
//   DateOfIncorporation? dateOfIncorporation;
//   String? logo;
//   String? subCategoryOfBusiness;
//   String? typeOfBusiness;
//   String? address;
//   String? businessDescription;
//   String? cityStatePincode;
//   int? pincode;
//   CategoryDetails? categoryDetails;
//   SubCategoryDetails? subCategoryDetails;
//   int? avgRating;
//   int? totalRatings;
//   int? totalViews;
//   int? totalFollowers;
//   bool? userHasRated;
//   dynamic userRating;
//   bool? isFollowing;
//   BusinessNumber? businessNumber;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     if (userId != null) {
//       map['user_id'] = userId?.toJson();
//     }
//     if (gst != null) {
//       map['gst'] = gst?.toJson();
//     }
//     map['isActive'] = isActive;
//     map['business_isVerified'] = businessIsVerified;
//     if (businessLocation != null) {
//       map['business_location'] = businessLocation?.toJson();
//     }
//     if (livePhotos != null) {
//       map['live_photos'] =  livePhotos?.map((v) => v).toList();
//
//     }
//     if (ownerDetails != null) {
//       map['owner_details'] = ownerDetails?.map((v) => v.toJson()).toList();
//     }
//     map['created_at'] = createdAt;
//     map['updated_at'] = updatedAt;
//     map['__v'] = v;
//     map['Nature_of_Business'] = natureOfBusiness;
//     map['business_name'] = businessName;
//     map['category_Of_Business'] = categoryOfBusiness;
//     if (dateOfIncorporation != null) {
//       map['date_of_incorporation'] = dateOfIncorporation?.toJson();
//     }
//     map['logo'] = logo;
//     map['sub_category_Of_Business'] = subCategoryOfBusiness;
//     map['type_of_business'] = typeOfBusiness;
//     map['address'] = address;
//     map['business_description'] = businessDescription;
//     map['city_state_pincode'] = cityStatePincode;
//     map['pincode'] = pincode;
//     if (categoryDetails != null) {
//       map['category_details'] = categoryDetails?.toJson();
//     }
//     if (subCategoryDetails != null) {
//       map['sub_category_details'] = subCategoryDetails?.toJson();
//     }
//     map['avg_rating'] = avgRating;
//     map['total_ratings'] = totalRatings;
//     map['total_views'] = totalViews;
//     map['total_followers'] = totalFollowers;
//     map['user_has_rated'] = userHasRated;
//     map['user_rating'] = userRating;
//     map['is_following'] = isFollowing;
//     if (businessNumber != null) {
//       map['business_number'] = businessNumber?.toJson();
//     }
//     return map;
//   }
//
// }
//
// BusinessNumber businessNumberFromJson(String str) => BusinessNumber.fromJson(json.decode(str));
// String businessNumberToJson(BusinessNumber data) => json.encode(data.toJson());
// class BusinessNumber {
//   BusinessNumber({
//       this.officeMobNo,
//       this.officeLandlineNo,});
//
//   BusinessNumber.fromJson(dynamic json) {
//     officeMobNo = json['office_mob_no'];
//     officeLandlineNo = json['office_landline_no'];
//   }
//   dynamic officeMobNo;
//   dynamic officeLandlineNo;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['office_mob_no'] = officeMobNo;
//     map['office_landline_no'] = officeLandlineNo;
//     return map;
//   }
//
// }
//
// SubCategoryDetails subCategoryDetailsFromJson(String str) => SubCategoryDetails.fromJson(json.decode(str));
// String subCategoryDetailsToJson(SubCategoryDetails data) => json.encode(data.toJson());
// class SubCategoryDetails {
//   SubCategoryDetails({
//       this.id,
//       this.name,});
//
//   SubCategoryDetails.fromJson(dynamic json) {
//     id = json['_id'];
//     name = json['name'];
//   }
//   String? id;
//   String? name;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['name'] = name;
//     return map;
//   }
//
// }
//
// CategoryDetails categoryDetailsFromJson(String str) => CategoryDetails.fromJson(json.decode(str));
// String categoryDetailsToJson(CategoryDetails data) => json.encode(data.toJson());
// class CategoryDetails {
//   CategoryDetails({
//       this.id,
//       this.name,});
//
//   CategoryDetails.fromJson(dynamic json) {
//     id = json['_id'];
//     name = json['name'];
//   }
//   String? id;
//   String? name;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['name'] = name;
//     return map;
//   }
//
// }
//
// DateOfIncorporation dateOfIncorporationFromJson(String str) => DateOfIncorporation.fromJson(json.decode(str));
// String dateOfIncorporationToJson(DateOfIncorporation data) => json.encode(data.toJson());
// class DateOfIncorporation {
//   DateOfIncorporation({
//       this.date,
//       this.month,
//       this.year,});
//
//   DateOfIncorporation.fromJson(dynamic json) {
//     date = json['date'];
//     month = json['month'];
//     year = json['year'];
//   }
//   int? date;
//   int? month;
//   int? year;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['date'] = date;
//     map['month'] = month;
//     map['year'] = year;
//     return map;
//   }
//
// }
//
// OwnerDetails ownerDetailsFromJson(String str) => OwnerDetails.fromJson(json.decode(str));
// String ownerDetailsToJson(OwnerDetails data) => json.encode(data.toJson());
// class OwnerDetails {
//   OwnerDetails({
//       this.name,
//       this.roleInBusiness,
//       this.email,
//       this.id,});
//
//   OwnerDetails.fromJson(dynamic json) {
//     name = json['name'];
//     roleInBusiness = json['role_in_business'];
//     email = json['email'];
//     id = json['_id'];
//   }
//   String? name;
//   String? roleInBusiness;
//   String? email;
//   String? id;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['name'] = name;
//     map['role_in_business'] = roleInBusiness;
//     map['email'] = email;
//     map['_id'] = id;
//     return map;
//   }
//
// }
//
// BusinessLocation businessLocationFromJson(String str) => BusinessLocation.fromJson(json.decode(str));
// String businessLocationToJson(BusinessLocation data) => json.encode(data.toJson());
// class BusinessLocation {
//   BusinessLocation({
//       this.lat,
//       this.lon,});
//
//   BusinessLocation.fromJson(dynamic json) {
//     lat = json['lat'];
//     lon = json['lon'];
//   }
//   double? lat;
//   double? lon;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['lat'] = lat;
//     map['lon'] = lon;
//     return map;
//   }
//
// }
//
// Gst gstFromJson(String str) => Gst.fromJson(json.decode(str));
// String gstToJson(Gst data) => json.encode(data.toJson());
// class Gst {
//   Gst({
//       this.have,
//       this.gstVerification,});
//
//   Gst.fromJson(dynamic json) {
//     have = json['have'];
//     gstVerification = json['gst_verification'];
//   }
//   bool? have;
//   bool? gstVerification;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['have'] = have;
//     map['gst_verification'] = gstVerification;
//     return map;
//   }
//
// }
//
// UserId userIdFromJson(String str) => UserId.fromJson(json.decode(str));
// String userIdToJson(UserId data) => json.encode(data.toJson());
// class UserId {
//   UserId({
//       this.id,
//       this.username,});
//
//   UserId.fromJson(dynamic json) {
//     id = json['_id'];
//     username = json['username'];
//   }
//   String? id;
//   String? username;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['_id'] = id;
//     map['username'] = username;
//     return map;
//   }
//
// }