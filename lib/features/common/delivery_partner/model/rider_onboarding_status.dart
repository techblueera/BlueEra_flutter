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
    this.dlNo,
    this.aadharImage,
    this.panImage,
    this.dlImage,
    this.rcImage,
  });

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
    vehicleNo = json['vehicleInformationData']?['registrationNo'] ?? '';
    // Document image URLs — the rider screen renders a thumbnail +
    // pinch-zoom view dialog when these are present. The keys here
    // accept either a flat top-level field (e.g. `aadharImage`) or
    // the nested `{front, back}` shape the upload payload uses; the
    // front image is preferred when both are available.
    aadharImage = (json['aadharImageFront'] as String?) ??
        (json['aadharImages'] is Map
            ? (json['aadharImages']['front'] as String?)
            : null) ??
        (json['aadharImage'] as String?);
    panImage = (json['panImageFront'] as String?) ??
        (json['panImages'] is Map
            ? (json['panImages']['front'] as String?)
            : null) ??
        (json['panImage'] as String?);
    dlImage = (json['dlImageFront'] as String?) ??
        (json['dlImages'] is Map
            ? (json['dlImages']['front'] as String?)
            : null) ??
        (json['dlImage'] as String?);
    rcImage = (json['rcImageFront'] as String?) ??
        (json['rcImages'] is Map
            ? (json['rcImages']['front'] as String?)
            : null) ??
        (json['rcImage'] as String?);
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
  // Front-side image URLs for the four ID documents that have a
  // single-image preview slot. Vehicle Information (just text) and
  // Vehicle Images (multiple images, separate flow) deliberately
  // don't get a single-URL field here.
  String? aadharImage;
  String? panImage;
  String? dlImage;
  String? rcImage;

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
    map['aadharImage'] = aadharImage;
    map['panImage'] = panImage;
    map['dlImage'] = dlImage;
    map['rcImage'] = rcImage;
    return map;
  }

}
