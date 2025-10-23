class BusinessRatingsModel {
  bool? status;
  List<BusinessRatingsData>? data;
  Pagination? pagination;

  BusinessRatingsModel({this.status, this.data, this.pagination});

  BusinessRatingsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <BusinessRatingsData>[];
      json['data'].forEach((v) {
        data!.add(new BusinessRatingsData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class BusinessRatingsData {
  String? sId;
  String? rateableId;
  String? rateableType;
  User? user;
  int? iV;
  String? comment;
  String? createdAt;
  int? rating;

  BusinessRatingsData(
      {this.sId,
        this.rateableId,
        this.rateableType,
        this.user,
        this.iV,
        this.comment,
        this.createdAt,
        this.rating});

  BusinessRatingsData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    rateableId = json['rateableId'];
    rateableType = json['rateableType'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    iV = json['__v'];
    comment = json['comment'];
    createdAt = json['created_at'];
    rating = json['rating'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['rateableId'] = this.rateableId;
    data['rateableType'] = this.rateableType;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    data['__v'] = this.iV;
    data['comment'] = this.comment;
    data['created_at'] = this.createdAt;
    data['rating'] = this.rating;
    return data;
  }
}

class User {
  String? sId;
  String? username;
  String? accountType;
  String? profileImage;
  List<BusinessDetails>? businessDetails;

  User(
      {this.sId,
        this.username,
        this.accountType,
        this.profileImage,
        this.businessDetails});

  User.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    username = json['username'];
    accountType = json['account_type'];
    profileImage = json['profile_image'];
    if (json['business_details'] != null) {
      businessDetails = <BusinessDetails>[];
      json['business_details'].forEach((v) {
        businessDetails!.add(new BusinessDetails.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['username'] = this.username;
    data['account_type'] = this.accountType;
    data['profile_image'] = this.profileImage;
    if (this.businessDetails != null) {
      data['business_details'] =
          this.businessDetails!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BusinessDetails {
  String? sId;
  String? businessName;
  String? logo;
  bool? businessIsVerified;

  BusinessDetails(
      {this.sId, this.businessName, this.logo, this.businessIsVerified});

  BusinessDetails.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    businessName = json['business_name'];
    logo = json['logo'];
    businessIsVerified = json['business_isVerified'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['business_name'] = this.businessName;
    data['logo'] = this.logo;
    data['business_isVerified'] = this.businessIsVerified;
    return data;
  }
}

class Pagination {
  int? totalRecords;
  int? totalPages;
  int? currentPage;

  Pagination({this.totalRecords, this.totalPages, this.currentPage});

  Pagination.fromJson(Map<String, dynamic> json) {
    totalRecords = json['totalRecords'];
    totalPages = json['totalPages'];
    currentPage = json['currentPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalRecords'] = this.totalRecords;
    data['totalPages'] = this.totalPages;
    data['currentPage'] = this.currentPage;
    return data;
  }
}