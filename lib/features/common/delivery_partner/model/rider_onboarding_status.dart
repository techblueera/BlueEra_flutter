class RiderOnboardingStatusResponse {
  Data? data;

  RiderOnboardingStatusResponse({this.data});

  RiderOnboardingStatusResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  bool? personalInformation;
  bool? address;
  bool? personalIdentification;
  bool? drivingVerification;
  bool? vehicleImages;
  bool? vehicleInformation;
  bool? isOnboardingComplete;

  Data(
      {this.personalInformation,
        this.address,
        this.personalIdentification,
        this.drivingVerification,
        this.vehicleImages,
        this.vehicleInformation,
        this.isOnboardingComplete});

  Data.fromJson(Map<String, dynamic> json) {
    personalInformation = json['personalInformation'];
    address = json['address'];
    personalIdentification = json['personalIdentification'];
    drivingVerification = json['drivingVerification'];
    vehicleImages = json['vehicleImages'];
    vehicleInformation = json['vehicleInformation'];
    isOnboardingComplete = json['isOnboardingComplete'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['personalInformation'] = this.personalInformation;
    data['address'] = this.address;
    data['personalIdentification'] = this.personalIdentification;
    data['drivingVerification'] = this.drivingVerification;
    data['vehicleImages'] = this.vehicleImages;
    data['vehicleInformation'] = this.vehicleInformation;
    data['isOnboardingComplete'] = this.isOnboardingComplete;
    return data;
  }
}
