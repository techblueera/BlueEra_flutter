import 'package:BlueEra/features/chat/auth/model/base_ai_chat_model.dart';

class HealthCareAskAiModel extends BaseAiChatModel {
  List<String>? suggestions;
  Data? data;

  HealthCareAskAiModel(
      {
        super.conversationId,
        super.role,
        super.timestamp,
        super.message,
        this.suggestions,
        this.data,
        });

  HealthCareAskAiModel.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    message = json['reply'] ?? json['content'];
    conversationId = json['conversationId'];
    suggestions = json['suggestions'] != null
        ? List<String>.from(json['suggestions'])
        : null;
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role'] = this.role;
    data['reply'] = this.message;
    data['conversationId'] = this.conversationId;
    data['suggestions'] = this.suggestions;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['timestamp'] = this.timestamp;
    return data;
  }
}

class Data {
  bool? success;
  List<HealthCareData>? healthCareData;

  Data({this.success, this.healthCareData});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      healthCareData = <HealthCareData>[];
      json['data'].forEach((v) {
        healthCareData!.add(new HealthCareData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.healthCareData != null) {
      data['data'] = this.healthCareData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HealthCareData {
  String? sId;
  String? businessId;
  String? departmentId;
  String? name;
  String? specialization;
  String? qualification;
  String? photo;
  String? availability;
  int? fees;
  bool? isOnLeave;
  String? createdAt;
  String? updatedAt;
  int? iV;
  HospitalInfo? hospitalInfo;
  BusinessDetails? businessDetails;

  HealthCareData(
      {this.sId,
        this.businessId,
        this.departmentId,
        this.name,
        this.specialization,
        this.qualification,
        this.photo,
        this.availability,
        this.fees,
        this.isOnLeave,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.hospitalInfo,
        this.businessDetails,
      });

  HealthCareData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    businessId = json['businessId'];
    departmentId = json['departmentId'];
    name = json['name'];
    specialization = json['specialization'];
    qualification = json['qualification'];
    photo = json['photo'];
    availability = json['availability'];
    fees = json['fees'];
    isOnLeave = json['isOnLeave'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    hospitalInfo = json['hospitalInfo'] != null
        ? new HospitalInfo.fromJson(json['hospitalInfo'])
        : null;
    businessDetails = json['businessDetails'] != null
        ? new BusinessDetails.fromJson(json['businessDetails'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['businessId'] = this.businessId;
    data['departmentId'] = this.departmentId;
    data['name'] = this.name;
    data['specialization'] = this.specialization;
    data['qualification'] = this.qualification;
    data['photo'] = this.photo;
    data['availability'] = this.availability;
    data['fees'] = this.fees;
    data['isOnLeave'] = this.isOnLeave;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.hospitalInfo != null) {
      data['hospitalInfo'] = this.hospitalInfo!.toJson();
    }
    if (this.businessDetails != null) {
      data['businessDetails'] = this.businessDetails!.toJson();
    }
    return data;
  }
}

class HospitalInfo {
  String? hospitalName;
  String? address;
  String? email;

  HospitalInfo({this.hospitalName, this.address, this.email});

  HospitalInfo.fromJson(Map<String, dynamic> json) {
    hospitalName = json['hospitalName'];
    address = json['address'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['hospitalName'] = this.hospitalName;
    data['address'] = this.address;
    data['email'] = this.email;
    return data;
  }
}

class BusinessDetails {
  Business? business;

  BusinessDetails({this.business});

  BusinessDetails.fromJson(Map<String, dynamic> json) {
    business = json['business'] != null
        ? new Business.fromJson(json['business'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.business != null) {
      data['business'] = this.business!.toJson();
    }
    return data;
  }
}

class Business {
  List<OwnerDetails>? ownerDetails;
  List<String>? livePhotos;
  List<num>? ratings;
  String? id;
  String? userId;
  String? businessName;
  DateOfIncorporation? dateOfIncorporation;
  String? typeOfBusiness;
  String? logo;
  CategoryOfBusiness? categoryOfBusiness;
  SubCategoryOfBusiness? subCategoryOfBusiness;
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
  String? totalRatings;

  Business(
      {this.ownerDetails,
        this.livePhotos,
        this.ratings,
        this.id,
        this.userId,
        this.businessName,
        this.dateOfIncorporation,
        this.typeOfBusiness,
        this.logo,
        this.categoryOfBusiness,
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
        this.totalRatings});

  Business.fromJson(Map<String, dynamic> json) {
    if (json['owner_details'] != null) {
      ownerDetails = <OwnerDetails>[];
      json['owner_details'].forEach((v) {
        ownerDetails!.add(new OwnerDetails.fromJson(v));
      });
    }
    if (json['live_photos'] != null) {
      livePhotos = List<String>.from(json['live_photos']);
    }
    if (json['ratings'] != null) {
      ratings = List<num>.from(json['ratings']);
    }
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
    subCategoryOfBusiness = json['sub_category_of_business'] != null
        ? new SubCategoryOfBusiness.fromJson(json['sub_category_of_business'])
        : null;
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
    if (this.ownerDetails != null) {
      data['owner_details'] =
          this.ownerDetails!.map((v) => v.toJson()).toList();
    }
    if (this.livePhotos != null) {
      data['live_photos'] = this.livePhotos;
    }
    if (this.ratings != null) {
      data['ratings'] = this.ratings;
    }
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
    if (this.subCategoryOfBusiness != null) {
      data['sub_category_of_business'] = this.subCategoryOfBusiness!.toJson();
    }
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

class OwnerDetails {
  String? name;
  String? roleInBusiness;
  String? email;

  OwnerDetails({this.name, this.roleInBusiness, this.email});

  OwnerDetails.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    roleInBusiness = json['role_in_business'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['role_in_business'] = this.roleInBusiness;
    data['email'] = this.email;
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

class SubCategoryOfBusiness {
  String? id;
  String? name;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? createdBy;
  String? updatedBy;
  String? categoryId;
  bool? active;

  SubCategoryOfBusiness(
      {this.id,
        this.name,
        this.createdAt,
        this.updatedAt,
        this.deletedAt,
        this.createdBy,
        this.updatedBy,
        this.categoryId,
        this.active});

  SubCategoryOfBusiness.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    categoryId = json['category_id'];
    active = json['active'];
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
    data['category_id'] = this.categoryId;
    data['active'] = this.active;
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
  double? lat;
  double? lon;

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