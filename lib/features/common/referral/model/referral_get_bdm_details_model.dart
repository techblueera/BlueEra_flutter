class ReferralGetBdmDetailsModel {
  bool? success;
  String? status;
  Data? data;

  ReferralGetBdmDetailsModel({this.success, this.status, this.data});

  ReferralGetBdmDetailsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    status = json['status'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? id;
  String? userId;
  String? walletId;
  String? fullName;
  String? email;
  Dob? dob;
  String? alternateMobileNo;
  String? education;
  Location? location;
  Documents? documents;
  String? status;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
        this.userId,
        this.walletId,
        this.fullName,
        this.email,
        this.dob,
        this.alternateMobileNo,
        this.education,
        this.location,
        this.documents,
        this.status,
        this.createdAt,
        this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    walletId = json['walletId'];
    fullName = json['fullName'];
    email = json['email'];
    dob = json['dob'] != null ? new Dob.fromJson(json['dob']) : null;
    alternateMobileNo = json['alternateMobileNo'];
    education = json['education'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    documents = json['documents'] != null
        ? new Documents.fromJson(json['documents'])
        : null;
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['userId'] = this.userId;
    data['walletId'] = this.walletId;
    data['fullName'] = this.fullName;
    data['email'] = this.email;
    if (this.dob != null) {
      data['dob'] = this.dob!.toJson();
    }
    data['alternateMobileNo'] = this.alternateMobileNo;
    data['education'] = this.education;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    if (this.documents != null) {
      data['documents'] = this.documents!.toJson();
    }
    data['status'] = this.status;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}

class Dob {
  int? day;
  int? month;
  int? year;

  Dob({this.day, this.month, this.year});

  Dob.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    month = json['month'];
    year = json['year'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['day'] = this.day;
    data['month'] = this.month;
    data['year'] = this.year;
    return data;
  }
}

class Location {
  String? pincode;
  String? state;
  String? city;
  String? addressString;

  Location({this.pincode, this.state, this.city, this.addressString});

  Location.fromJson(Map<String, dynamic> json) {
    pincode = json['pincode'];
    state = json['state'];
    city = json['city'];
    addressString = json['addressString'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pincode'] = this.pincode;
    data['state'] = this.state;
    data['city'] = this.city;
    data['addressString'] = this.addressString;
    return data;
  }
}

class Documents {
  String? aadharCard;
  String? panCard;
  String? addressProof;
  String? bankDetails;

  Documents(
      {this.aadharCard, this.panCard, this.addressProof, this.bankDetails});

  Documents.fromJson(Map<String, dynamic> json) {
    aadharCard = json['aadharCard'];
    panCard = json['panCard'];
    addressProof = json['addressProof'];
    bankDetails = json['bankDetails'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['aadharCard'] = this.aadharCard;
    data['panCard'] = this.panCard;
    data['addressProof'] = this.addressProof;
    data['bankDetails'] = this.bankDetails;
    return data;
  }
}