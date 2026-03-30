import 'package:BlueEra/features/business/auth/model/ReleatedStoresList.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';

class ViewBusinessProfileModel {
  ViewBusinessProfileModel({
      this.status, 
      this.data,});

  ViewBusinessProfileModel.fromJson(dynamic json) {
    status = json['status'];
    data = json['data'] != null ? BusinessProfileDetails.fromJson(json['data']) : null;
    if (json['relatedStores'] != null&&json['relatedStores'].isNotEmpty) {
      relatedStoresList = [];
      json['relatedStores'].forEach((v) {
        relatedStoresList?.add(RelatedStoresList.fromJson(v));
      });
    }
  }
  bool? status;
  BusinessProfileDetails? data;
  List<RelatedStoresList>? relatedStoresList;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    if (relatedStoresList != null) {
      map['relatedStores'] = relatedStoresList?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}


class BusinessProfileDetails {
  BusinessProfileDetails({
      this.dateOfIncorporation, 
      this.gst, 
      this.businessLocation, 
      this.id, 
      this.userId, 
      this.businessName, 
      this.typeOfBusiness, 
      this.logo, 
      this.coverimage,
      this.categoryOfBusiness,
      this.natureOfBusiness, 
      this.isActive, 
      this.businessIsVerified, 
      this.livePhotos, 
      this.ownerDetails, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.address, 
      this.businessDescription, 
      this.cityStatePincode, 
      this.subCategoryOfBusiness, 
      this.websiteUrl,
      this.openTime,
      this.closeTime,
      this.businessNumber,
      this.is_following,
      this.referral_code,
      this.referral_points,
      this.category_other,
      this.pincode,
      this.total_views,
      this.username,
      this.total_followers,
      this.total_following,
      this.total_ratings,
      this.specification,
      this.avg_rating,
      this.userContactNo,
      this.availability,
  });

  BusinessProfileDetails.fromJson(dynamic json) {
    dateOfIncorporation = json['date_of_incorporation'] != null ? DateOfIncorporation.fromJson(json['date_of_incorporation']) : null;
    gst = json['gst'] != null ? Gst.fromJson(json['gst']) : null;
    businessLocation = json['business_location'] != null ? BusinessLocation.fromJson(json['business_location']) : null;
    id = json['_id'] ?? json['id'];
    businessName = json['business_name'];
    referral_code = json['referral_code'];
    referral_points = json['referral_points'].toString();
    typeOfBusiness = json['type_of_business'];
    logo = json['logo'];
    coverimage = json['coverPicture'];
    categoryOfBusiness = json['category_Of_Business'] ?? json['category_of_business'];
    natureOfBusiness = json['Nature_of_Business']=='false'? '' : json['Nature_of_Business'];
    isActive = json['isActive'];
    businessIsVerified = json['business_isVerified'];
    livePhotos=json['live_photos'].cast<String>();
    if (json['live_photos'] != null&&json['live_photos'].isNotEmpty) {
      livePhotos=json['live_photos'].cast<String>();
    }
    total_views=json['total_views'];
    total_followers=json['total_followers'];
    total_following=json['total_following'];
    is_following=json['is_following'];
    businessNumber = json['business_number'] != null
        ? new BusinessNumber.fromJson(json['business_number'])
        : null;
    if (json['owner_details'] != null&&json['owner_details'].isNotEmpty) {
      ownerDetails = [];
      json['owner_details'].forEach((v) {
        ownerDetails?.add(OwnerDetails.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    v = json['__v'];
    address = json['address'];
    category_other = json['category_other'];
    userId = json['user_id'];
    businessDescription = json['business_description'];
    cityStatePincode = json['city_state_pincode'];
    subCategoryOfBusiness = json['sub_category_Of_Business'] ;
    websiteUrl = json['website_url'];
    openTime = json['opening_time'];
    closeTime = json['closing_time'];
    categoryDetails = json['category_details'] != null ? CategoryDetails.fromJson(json['category_details']) : null;
    subCategoryDetails = json['sub_category_details'] != null ? SubCategoryDetails.fromJson(json['sub_category_details']) : null;
    // final categoryJson = json['category_details'] ?? json['category_of_business'];
    // categoryDetails = categoryJson != null ? CategoryDetails.fromJson(categoryJson) : null;
    // final subCategoryJson = json['sub_category_details'] ?? json['sub_category_of_business'];
    // subCategoryDetails = subCategoryJson != null ? SubCategoryDetails.fromJson(subCategoryJson) : null;
    pincode = json['pincode'];
    username = json['username'];
    avg_rating = json['avg_rating'];
    if (json['total_ratings'] != null) {
      total_ratings = num.tryParse(json['total_ratings'].toString()) ?? 0;
    } else {
      total_ratings = 0;
    }
    specification = json['specification'];
    userContactNo = json['userContactNo'];
    availability = json['availability'] != null ? AvailabilityData.fromJson(json['availability']) : null;
    dietaryType = json['dietaryType'];
  }

  DateOfIncorporation? dateOfIncorporation;
  Gst? gst;
  BusinessLocation? businessLocation;
  String? id;
  String? userId;
  String? businessName;
  String? conversationId;
  String? typeOfBusiness;
  String? referral_code;
  String? referral_points;
  String? logo;
  String? coverimage;
  String? categoryOfBusiness;
  String? natureOfBusiness;
  bool? isActive;
  bool? is_following;
  bool? businessIsVerified;
  List<String>? livePhotos;
  List<OwnerDetails>? ownerDetails;
  String? createdAt;
  String? updatedAt;
  num? v;
  String? address;
  String? businessDescription;
  String? cityStatePincode;
  String? subCategoryOfBusiness;
  String? websiteUrl;
  String? openTime;
  String? closeTime;
  num? pincode;
  CategoryDetails? categoryDetails;
  SubCategoryDetails? subCategoryDetails;
  int? total_views;
  int? total_followers;
  int? total_following;
  BusinessNumber? businessNumber;
  String? category_other;
  String? username;
  String? specification;
  num? avg_rating;
  num? total_ratings;
  String? userContactNo;
  AvailabilityData? availability;
  String? dietaryType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (dateOfIncorporation != null) {
      map['date_of_incorporation'] = dateOfIncorporation?.toJson();
    }
    if (gst != null) {
      map['gst'] = gst?.toJson();
    }
    if (businessLocation != null) {
      map['business_location'] = businessLocation?.toJson();
    }
    map['_id'] = id;
    map['pincode'] = pincode;
    map['referral_points'] = referral_points;
    map['referral_code'] = referral_code;
    map['username'] = username;
    map['category_other'] = category_other;
    map['business_name'] = businessName;
    map['type_of_business'] = typeOfBusiness;
    map['logo'] = logo;
    map['coverPicture'] = coverimage;
    map['category_Of_Business'] = categoryOfBusiness;
    map['Nature_of_Business'] = natureOfBusiness;
    map['isActive'] = isActive;
    map['is_following'] = is_following;
    map['business_isVerified'] = businessIsVerified;
    if (livePhotos != null) {
      map['live_photos'] =  livePhotos?.map((v) => v).toList();
    }
    if (ownerDetails != null) {
      map['owner_details'] = ownerDetails?.map((v) => v.toJson()).toList();
    }
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['user_id'] = userId;
    map['__v'] = v;
    map['address'] = address;
    map['business_description'] = businessDescription;
    map['city_state_pincode'] = cityStatePincode;
    map['sub_category_of_Business'] = subCategoryOfBusiness;
    map['website_url'] = websiteUrl;
    map['opening_time'] = openTime;
    map['closing_time'] = closeTime;
    map['total_views']=total_views;
    map['total_followers']=total_followers;
    map['total_following']=total_following;
    map['total_ratings']=total_ratings;
    map['avg_rating']=avg_rating;
    map['specification']=specification;
    if (categoryDetails != null) {
      map['category_details'] = categoryDetails?.toJson();
    }
    if (subCategoryDetails != null) {
      map['sub_category_details'] = subCategoryDetails?.toJson();
    }
    if (this.businessNumber != null) {
      map['business_number'] = this.businessNumber!.toJson();
    }
    map['userContactNo']=userContactNo;
    map['dietaryType']=dietaryType;
    if (availability != null) {
      map['availability'] = availability?.toJson();
    }
    return map;
  }

}

class CategoryDetails {
  CategoryDetails({
    this.id,
    this.name,
  });

  CategoryDetails.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
  }

  String? id;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    return map;
  }
}

class SubCategoryDetails {
  SubCategoryDetails({
    this.id,
    this.name,
  });

  SubCategoryDetails.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
  }

  String? id;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    return map;
  }
}

class OwnerDetails {
  OwnerDetails({
      this.name, 
      this.email, 
      this.role_in_business,
      this.id,});

  OwnerDetails.fromJson(dynamic json) {
    name = json['name'];
    email = json['email'];
    role_in_business = json['role_in_business'];
    id = json['_id'];
  }
  String? name;
  String? email;
  String? role_in_business;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['email'] = email;
    map['role_in_business'] = role_in_business;
    map['_id'] = id;
    return map;
  }

}

/// lat : 0
/// lon : 0

class BusinessLocation {
  BusinessLocation({
      this.lat, 
      this.lon,});

  BusinessLocation.fromJson(dynamic json) {
    lat = double.parse((json['lat']??'0.0').toString());
    lon = double.parse((json['lon']??'0.0').toString());
  }
  double? lat;
  double? lon;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['lat'] = lat;
    map['lon'] = lon;
    return map;
  }

}

/// have : false
/// number : null
/// gst_verification : false

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
  dynamic number;
  bool? gstVerification;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['have'] = have;
    map['number'] = number;
    map['gst_verification'] = gstVerification;
    return map;
  }

}

/// date : 11
/// month : 7
/// year : 2000

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
class BusinessNumber {
  OfficeMobNo? officeMobNo;
  OfficeMobNo? officeLandlineNo;

  BusinessNumber({this.officeMobNo, this.officeLandlineNo});

  BusinessNumber.fromJson(Map<String, dynamic> json) {
    officeMobNo = json['office_mob_no'] != null
        ? new OfficeMobNo.fromJson(json['office_mob_no'])
        : null;
    officeLandlineNo = json['office_landline_no'] != null
        ? new OfficeMobNo.fromJson(json['office_landline_no'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.officeMobNo != null) {
      data['office_mob_no'] = this.officeMobNo!.toJson();
    }
    if (this.officeLandlineNo != null) {
      data['office_landline_no'] = this.officeLandlineNo!.toJson();
    }
    return data;
  }
}

class OfficeMobNo {
  String? pre;
  String? number;

  OfficeMobNo({this.pre, this.number});

  OfficeMobNo.fromJson(Map<String, dynamic> json) {
    pre = json['pre'];
    number = json['number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pre'] = this.pre;
    data['number'] = this.number;
    return data;
  }
}