class RiderOnboardingStatusResponse {
  RiderOnboardingStatusData? data;

  RiderOnboardingStatusResponse({this.data});

  RiderOnboardingStatusResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new RiderOnboardingStatusData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class RiderOnboardingStatusData {
  RiderOnboardingStatusData({
    this.personalInformation,
    this.address,
    this.personalIdentification,
    this.drivingVerification,
    this.vehicleImages,
    this.vehicleInformation,
    this.isOnboardingComplete,
    this.verificationStatus,
    this.aadhar,
    this.pan,
    this.rc,
    this.dl,
    this.aadharNo,
    this.panNo,
    this.rcNo,
    this.vehicleNo,
    this.dlNo,});

  RiderOnboardingStatusData.fromJson(dynamic json) {
    personalInformation = json['personalInformation'];
    address = json['address'];
    personalIdentification = json['personalIdentification'];
    drivingVerification = json['drivingVerification'];
    vehicleImages = json['vehicleImages'];
    vehicleInformation = json['vehicleInformation'];
    isOnboardingComplete = json['isOnboardingComplete'];
    verificationStatus = json['verificationStatus'];
    aadhar = json['aadhar'];
    pan = json['pan'];
    rc = json['rc'];
    dl = json['dl'];
    aadharNo = json['aadharNo'];
    panNo = json['panNo'];
    rcNo = json['rcNo'];
    dlNo = json['dlNo'];
    vehicleNo = json['vehicleInformationData']['registrationNo'];
  }
  bool? personalInformation;
  bool? address;
  bool? personalIdentification;
  bool? drivingVerification;
  bool? vehicleImages;
  bool? vehicleInformation;
  bool? isOnboardingComplete;
  String? verificationStatus;
  bool? aadhar;
  bool? pan;
  bool? rc;
  bool? dl;
  String? aadharNo;
  String? panNo;
  String? rcNo;
  String? dlNo;
  String? vehicleNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['personalInformation'] = personalInformation;
    map['address'] = address;
    map['personalIdentification'] = personalIdentification;
    map['drivingVerification'] = drivingVerification;
    map['vehicleImages'] = vehicleImages;
    map['vehicleInformation'] = vehicleInformation;
    map['isOnboardingComplete'] = isOnboardingComplete;
    map['verificationStatus'] = verificationStatus;
    map['aadhar'] = aadhar;
    map['pan'] = pan;
    map['rc'] = rc;
    map['dl'] = dl;
    map['aadharNo'] = aadharNo;
    map['panNo'] = panNo;
    map['rcNo'] = rcNo;
    map['dlNo'] = dlNo;
    return map;
  }

}
