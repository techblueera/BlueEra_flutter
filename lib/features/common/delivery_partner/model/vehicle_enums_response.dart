class VehicleEnumResponse {
  List<String>? vehicleUsesType;
  List<String>? vehicleType;
  List<String>? fuelType;
  List<String>? registrationType;

  VehicleEnumResponse(
      {this.vehicleUsesType,
        this.vehicleType,
        this.fuelType,
        this.registrationType});

  VehicleEnumResponse.fromJson(Map<String, dynamic> json) {
    vehicleUsesType = json['vehicleUsesType'].cast<String>();
    vehicleType = json['vehicleType'].cast<String>();
    fuelType = json['fuelType'].cast<String>();
    registrationType = json['registrationType'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['vehicleUsesType'] = this.vehicleUsesType;
    data['vehicleType'] = this.vehicleType;
    data['fuelType'] = this.fuelType;
    data['registrationType'] = this.registrationType;
    return data;
  }
}