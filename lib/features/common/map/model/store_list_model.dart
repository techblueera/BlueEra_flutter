class StoreDataModel {
  List<String>? ownerDetails;
  List<String>? livePhotos;
  String? id;
  String? userId;
  String? businessName;
  DateOfIncorporation? dateOfIncorporation;
  String? typeOfBusiness;
  String? logo;
  CategoryOfBusiness? categoryOfBusiness;
  // Null subCategoryOfBusiness;
  String? businessDescription;
  BusinessNumber? businessNumber;
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

  StoreDataModel(
      {this.ownerDetails,
        this.livePhotos,
        this.id,
        this.userId,
        this.businessName,
        this.dateOfIncorporation,
        this.typeOfBusiness,
        this.logo,
        this.categoryOfBusiness,
        // this.subCategoryOfBusiness,
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
        this.totalRatings});

  StoreDataModel.fromJson(Map<String, dynamic> json) {
    ownerDetails = json['owner_details'].cast<String>();
    livePhotos = json['live_photos'].cast<String>();
    id = json['id'];
    userId = json['user_id'];
    businessName = json['business_name'];
    dateOfIncorporation = json['date_of_incorporation'] != null
        ? new DateOfIncorporation.fromJson(json['date_of_incorporation'])
        : null;
    typeOfBusiness = json['type_of_business'];
    logo = json['logo'];
    categoryOfBusiness = json['category_of_business'] != null
        ? new CategoryOfBusiness.fromJson(json['category_of_business'])
        : null;
    // subCategoryOfBusiness = json['sub_category_of_business'];
    businessDescription = json['business_description'];
    businessNumber = json['business_number'] != null
        ? new BusinessNumber.fromJson(json['business_number'])
        : null;
    natureOfBusiness = json['Nature_of_Business'];
    cityStatePincode = json['city_state_pincode'];
    address = json['address'];
    gst = json['gst'] != null ? new Gst.fromJson(json['gst']) : null;
    isActive = json['isActive'];
    businessIsVerified = json['business_isVerified'];
    businessLocation = json['business_location'] != null
        ? new BusinessLocation.fromJson(json['business_location'])
        : null;
    websiteUrl = json['website_url'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    avgRating = json['avg_rating'];
    totalRatings = json['total_ratings'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['owner_details'] = this.ownerDetails;
    data['live_photos'] = this.livePhotos;
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['business_name'] = this.businessName;
    if (this.dateOfIncorporation != null) {
      data['date_of_incorporation'] = this.dateOfIncorporation!.toJson();
    }
    data['type_of_business'] = this.typeOfBusiness;
    data['logo'] = this.logo;
    if (this.categoryOfBusiness != null) {
      data['category_of_business'] = this.categoryOfBusiness!.toJson();
    }
    // data['sub_category_of_business'] = this.subCategoryOfBusiness;
    data['business_description'] = this.businessDescription;
    if (this.businessNumber != null) {
      data['business_number'] = this.businessNumber!.toJson();
    }
    data['Nature_of_Business'] = this.natureOfBusiness;
    data['city_state_pincode'] = this.cityStatePincode;
    data['address'] = this.address;
    if (this.gst != null) {
      data['gst'] = this.gst!.toJson();
    }
    data['isActive'] = this.isActive;
    data['business_isVerified'] = this.businessIsVerified;
    if (this.businessLocation != null) {
      data['business_location'] = this.businessLocation!.toJson();
    }
    data['website_url'] = this.websiteUrl;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['avg_rating'] = this.avgRating;
    data['total_ratings'] = this.totalRatings;
    return data;
  }
}

class DateOfIncorporation {
  int? date;
  int? month;
  int? year;

  DateOfIncorporation({this.date, this.month, this.year});

  DateOfIncorporation.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['month'] = this.month;
    data['year'] = this.year;
    return data;
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

class Gst {
  bool? have;
  String? number;
  bool? gstVerification;

  Gst({this.have, this.number, this.gstVerification});

  Gst.fromJson(Map<String, dynamic> json) {
    have = json['have'];
    number = json['number'];
    gstVerification = json['gst_verification'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['have'] = this.have;
    data['number'] = this.number;
    data['gst_verification'] = this.gstVerification;
    return data;
  }
}

class BusinessLocation {
  int? lat;
  int? lon;

  BusinessLocation({this.lat, this.lon});

  BusinessLocation.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lon = json['lon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    return data;
  }
}