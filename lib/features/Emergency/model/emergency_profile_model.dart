class EmergencyProfileModel {
  BasicInfo? basicInfo;
  List<EmergencyContacts>? emergencyContacts;
  PrivacyAlert? privacyAlert;

  EmergencyProfileModel({this.basicInfo, this.emergencyContacts, this.privacyAlert});

  EmergencyProfileModel.fromJson(Map<String, dynamic> json) {
    basicInfo = json['basicInfo'] != null ? BasicInfo.fromJson(json['basicInfo']) : null;
    if (json['emergencyContacts'] != null) {
      emergencyContacts = <EmergencyContacts>[];
      json['emergencyContacts'].forEach((v) {
        emergencyContacts!.add(EmergencyContacts.fromJson(v));
      });
    }
    privacyAlert = json['privacyAlert'] != null ? PrivacyAlert.fromJson(json['privacyAlert']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (basicInfo != null) {
      data['basicInfo'] = basicInfo!.toJson();
    }
    if (emergencyContacts != null) {
      data['emergencyContacts'] = emergencyContacts!.map((v) => v.toJson()).toList();
    }
    if (privacyAlert != null) {
      data['privacyAlert'] = privacyAlert!.toJson();
    }
    return data;
  }
}

class BasicInfo {
  String? sId;
  String? fullName;
  String? mobileNumber;
  String? alternateNumber;
  String? emailId;
  String? vehicleNumber;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? bloodGroup;
  String? knownAllergies;
  String? knownDisease;

  BasicInfo(
      {this.sId,
      this.fullName,
      this.mobileNumber,
      this.alternateNumber,
      this.emailId,
      this.vehicleNumber,
      this.userId,
      this.createdAt,
      this.updatedAt,
      this.iV,
      this.bloodGroup,
      this.knownAllergies,
      this.knownDisease});

  BasicInfo.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    fullName = json['fullName'];
    mobileNumber = json['mobileNumber'];
    alternateNumber = json['alternateNumber'];
    emailId = json['emailId'];
    vehicleNumber = json['vehicleNumber'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    bloodGroup = json['bloodGroup'];
    knownAllergies = json['knownAllergies'];
    knownDisease = json['knownDisease'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['fullName'] = fullName;
    data['mobileNumber'] = mobileNumber;
    data['alternateNumber'] = alternateNumber;
    data['emailId'] = emailId;
    data['vehicleNumber'] = vehicleNumber;
    data['userId'] = userId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['bloodGroup'] = bloodGroup;
    data['knownAllergies'] = knownAllergies;
    data['knownDisease'] = knownDisease;
    return data;
  }
}

class EmergencyContacts {
  String? sId;
  String? name;
  String? mobileNumber;
  String? relationship;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  EmergencyContacts({this.sId, this.name, this.mobileNumber, this.relationship, this.userId, this.createdAt, this.updatedAt, this.iV});

  EmergencyContacts.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    mobileNumber = json['mobileNumber'];
    relationship = json['relationship'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['mobileNumber'] = mobileNumber;
    data['relationship'] = relationship;
    data['userId'] = userId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class PrivacyAlert {
  String? sId;
  bool? maskPhoneNumber;
  bool? sendSmsAlertWithLocation;
  bool? shareMedicalInfo;
  bool? sendChatAlertWithGps;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  PrivacyAlert(
      {this.sId,
      this.maskPhoneNumber,
      this.sendSmsAlertWithLocation,
      this.shareMedicalInfo,
      this.sendChatAlertWithGps,
      this.userId,
      this.createdAt,
      this.updatedAt,
      this.iV});

  PrivacyAlert.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    maskPhoneNumber = json['maskPhoneNumber'];
    sendSmsAlertWithLocation = json['sendSmsAlertWithLocation'];
    shareMedicalInfo = json['shareMedicalInfo'];
    sendChatAlertWithGps = json['sendChatAlertWithGps'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['maskPhoneNumber'] = maskPhoneNumber;
    data['sendSmsAlertWithLocation'] = sendSmsAlertWithLocation;
    data['shareMedicalInfo'] = shareMedicalInfo;
    data['sendChatAlertWithGps'] = sendChatAlertWithGps;
    data['userId'] = userId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
