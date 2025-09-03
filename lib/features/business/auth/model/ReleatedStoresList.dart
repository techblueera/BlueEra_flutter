/// date_of_incorporation : {"date":1,"month":7,"year":2017}
/// gst : {"have":true,"number":"07AADCD4946L1ZC","gst_verification":false}
/// business_location : {"lat":0,"lon":0}
/// _id : "6881ebef8382bdd6d8dcaa38"
/// user_id : "6881ebef8382bdd6d8dcaa36"
/// business_name : "ETERNAL LIMITED"
/// type_of_business : "Both"
/// logo : "https://bluehr-public-prod.s3.ap-south-1.amazonaws.com/user/6881ebef8382bdd6d8dcaa36/logo/1753345007267_cropped_image_01753344980243.png"
/// category_Of_Business : "686e4e53748d3b52e605c604"
/// Nature_of_Business : "MANUFACTURERS"
/// isActive : true
/// business_isVerified : false
/// live_photos : []
/// owner_details : []
/// created_at : "2025-07-24T08:16:47.402Z"
/// updated_at : "2025-07-24T08:16:47.402Z"
/// __v : 0

class RelatedStoresList {
  RelatedStoresList({
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
      this.v,});

  RelatedStoresList.fromJson(dynamic json) {
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
    if (json['live_photos'] != null) {
      livePhotos = [];
      json['live_photos'].forEach((v) {
        livePhotos?.add(v);
      });
    }
    if (json['owner_details'] != null) {
      ownerDetails = [];
      json['owner_details'].forEach((v) {
        ownerDetails?.add(v);
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    avg_rating = json['avg_rating'];
    v = json['__v'];
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
  bool? businessIsVerified;
  List<dynamic>? livePhotos;
  List<dynamic>? ownerDetails;
  String? createdAt;
  String? updatedAt;
  int? avg_rating;
  num? v;

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
    map['business_name'] = businessName;
    map['type_of_business'] = typeOfBusiness;
    map['logo'] = logo;
    map['category_Of_Business'] = categoryOfBusiness;
    map['Nature_of_Business'] = natureOfBusiness;
    map['isActive'] = isActive;
    map['business_isVerified'] = businessIsVerified;
    if (livePhotos != null) {
      map['live_photos'] = livePhotos?.map((v) => v.toJson()).toList();
    }
    if (ownerDetails != null) {
      map['owner_details'] = ownerDetails?.map((v) => v.toJson()).toList();
    }
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['avg_rating'] = avg_rating;
    map['__v'] = v;
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

/// have : true
/// number : "07AADCD4946L1ZC"
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

/// date : 1
/// month : 7
/// year : 2017

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
  num? date;
  num? month;
  num? year;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['date'] = date;
    map['month'] = month;
    map['year'] = year;
    return map;
  }

}