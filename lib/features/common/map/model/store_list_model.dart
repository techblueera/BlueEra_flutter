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

  /// Takes `dynamic` rather than `Map<String, dynamic>`: the call site passes
  /// a raw JSON value, so a non-map failed at the parameter as
  /// `type 'String' is not a subtype of type 'Map<String, dynamic>'` — the
  /// same crash as viewBusinessProfileModel.dart's, just reported one frame
  /// earlier. Callers pass positionally, so the signature change is invisible
  /// to them.
  DateOfIncorporation.fromJson(dynamic json) {
    if (json is Map) {
      date = _asInt(json['date']);
      month = _asInt(json['month']);
      year = _asInt(json['year']);
      return;
    }
    if (json is String) {
      // Unambiguous formats only — `11/07/2000` is left unparsed rather than
      // guessing day-first vs month-first and recording the wrong date.
      final parsed = DateTime.tryParse(json.trim());
      if (parsed == null) return;
      date = parsed.day;
      month = parsed.month;
      year = parsed.year;
    }
  }

  /// The parts arrive as ints, as `"11"`, and occasionally as `11.0`.
  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
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
  /// `num?`, not `int?`. These held `int?` while coordinates are decimals, so
  /// any real `lat` decoded as a `double` and threw
  /// `type 'double' is not a subtype of type 'int?'` on assignment — the field
  /// could only ever have been populated by a whole-number coordinate.
  /// Widening is safe here: nothing reads either field (checked across
  /// getstore_list_controller.dart and store_list_widget.dart).
  num? lat;
  num? lon;

  BusinessLocation({this.lat, this.lon});

  /// `dynamic` parameter for the same reason as [DateOfIncorporation] above.
  BusinessLocation.fromJson(dynamic json) {
    if (json is! Map) return;
    lat = _asNum(json['lat']);
    lon = _asNum(json['lon']);
  }

  /// Coordinates arrive as numbers and as strings like `"28.61"`.
  static num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    return data;
  }
}