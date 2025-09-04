import 'ReleatedStoresList.dart';

/// status : true
/// data : {"date_of_incorporation":{"date":11,"month":7,"year":2000},"gst":{"have":false,"number":null,"gst_verification":false},"business_location":{"lat":0,"lon":0},"_id":"687212566013a2041ce48a25","user_id":"687212566013a2041ce48a23","business_name":"Manitory factory","type_of_business":"Product","logo":"https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/687212566013a2041ce48a23/logo/1752306262309_cropped_image_01752306209154.png","category_Of_Business":"686e4aba60024f8e3765784e","Nature_of_Business":"Agency","isActive":true,"business_isVerified":false,"live_photos":[],"owner_details":[{"name":"Boopathi ","email":"boopathi9092@gmail.com","_id":"6874c3cfa9e7c440b6622a11"}],"created_at":"2025-07-12T07:44:22.432Z","updated_at":"2025-07-14T08:46:07.169Z","__v":0,"address":"Jjsk jsoos. Kslaohs. Nsksisbsnsb.","business_description":"Good and quality product ","city_state_pincode":"Salem","sub_category_Of_Business":"6874bb082205959d281dfdbe","website_url":"https://testing.com"}

class ViewBusinessProfileModel {
  ViewBusinessProfileModel({
      this.status, 
      this.data,});

  ViewBusinessProfileModel.fromJson(dynamic json) {
    status = json['status'];
    data = json['data'] != null ? BusinessProfileDetails.fromJson(json['data']) : null;
    if (json['relatedStores'] != null) {
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

/// date_of_incorporation : {"date":11,"month":7,"year":2000}
/// gst : {"have":false,"number":null,"gst_verification":false}
/// business_location : {"lat":0,"lon":0}
/// _id : "687212566013a2041ce48a25"
/// user_id : "687212566013a2041ce48a23"
/// business_name : "Manitory factory"
/// type_of_business : "Product"
/// logo : "https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/687212566013a2041ce48a23/logo/1752306262309_cropped_image_01752306209154.png"
/// category_Of_Business : "686e4aba60024f8e3765784e"
/// Nature_of_Business : "Agency"
/// isActive : true
/// business_isVerified : false
/// live_photos : []
/// owner_details : [{"name":"Boopathi ","email":"boopathi9092@gmail.com","_id":"6874c3cfa9e7c440b6622a11"}]
/// created_at : "2025-07-12T07:44:22.432Z"
/// updated_at : "2025-07-14T08:46:07.169Z"
/// __v : 0
/// address : "Jjsk jsoos. Kslaohs. Nsksisbsnsb."
/// business_description : "Good and quality product "
/// city_state_pincode : "Salem"
/// sub_category_Of_Business : "6874bb082205959d281dfdbe"
/// website_url : "https://testing.com"

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
      this.businessNumber,
      this.is_following,
      this.category_other,
      this.pincode,
      this.userContactNo,
      this.rating
  });

  BusinessProfileDetails.fromJson(dynamic json) {
    dateOfIncorporation = json['date_of_incorporation'] != null ? DateOfIncorporation.fromJson(json['date_of_incorporation']) : null;
    gst = json['gst'] != null ? Gst.fromJson(json['gst']) : null;
    businessLocation = json['business_location'] != null ? BusinessLocation.fromJson(json['business_location']) : null;
    id = json['_id'];
    userId = json['user_id'];
    businessName = json['business_name'];
    typeOfBusiness = json['type_of_business'];
    logo = json['logo'];
    categoryOfBusiness = json['category_Of_Business'];
    natureOfBusiness = json['Nature_of_Business'];
    isActive = json['isActive'];
    businessIsVerified = json['business_isVerified'];
    livePhotos=json['live_photos'].cast<String>();
    rating=json['rating'];
    is_following=json['is_following'];
    businessNumber = json['business_number'] != null
        ? new BusinessNumber.fromJson(json['business_number'])
        : null;

    // if (json['live_photos'] != null) {
    //   livePhotos = [];
    //   json['live_photos'].forEach((v) {
    //     livePhotos?.add('');
    //   });
    // }
    if (json['owner_details'] != null) {
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
    businessDescription = json['business_description'];
    cityStatePincode = json['city_state_pincode'];
    subCategoryOfBusiness = json['sub_category_Of_Business'];
    websiteUrl = json['website_url'];
    categoryDetails = json['category_details'] != null ? CategoryDetails.fromJson(json['category_details']) : null;
    userContactNo = json['userContactNo'] != null ? UserContactNo.fromJson(json['userContactNo']) : null;
    subCategoryDetails = json['sub_category_details'] != null ? SubCategoryDetails.fromJson(json['sub_category_details']) : null;
    pincode = json['pincode'];

  }
  DateOfIncorporation? dateOfIncorporation;
  Gst? gst;
  BusinessLocation? businessLocation;
  String? id;
  String? userId;
  String? businessName;
  String? typeOfBusiness;
  String? logo;
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
  dynamic pincode;
  CategoryDetails? categoryDetails;
  UserContactNo? userContactNo;
  SubCategoryDetails? subCategoryDetails;
  int?rating;
  BusinessNumber? businessNumber;
  String? category_other;


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
    map['user_id'] = userId;
    map['pincode'] = pincode;
    map['category_other'] = category_other;
    map['business_name'] = businessName;
    map['type_of_business'] = typeOfBusiness;
    map['logo'] = logo;
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
    map['__v'] = v;
    map['address'] = address;
    map['business_description'] = businessDescription;
    map['city_state_pincode'] = cityStatePincode;
    map['sub_category_Of_Business'] = subCategoryOfBusiness;
    map['website_url'] = websiteUrl;
    map['rating']=rating;
    if (categoryDetails != null) {
      map['category_details'] = categoryDetails?.toJson();
    }
    if (subCategoryDetails != null) {
      map['sub_category_details'] = subCategoryDetails?.toJson();
    }
    if (this.businessNumber != null) {
      map['business_number'] = this.businessNumber!.toJson();
    }
    if (this.userContactNo != null) {
      map['userContactNo'] = this.userContactNo!.toJson();
    }
    return map;
  }

}

/// name : "Boopathi "
/// email : "boopathi9092@gmail.com"
/// _id : "6874c3cfa9e7c440b6622a11"
///
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
// UserContactNo
class UserContactNo {
  UserContactNo({
    this.contact_no,
  });

  UserContactNo.fromJson(dynamic json) {
    contact_no = json['contact_no'];
  }

  String? contact_no;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['contact_no'] = contact_no;
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
  int? pre;
  int? number;

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