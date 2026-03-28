// ================= ROOT RESPONSE =================

class VehicleAllResponse {
  VehicleData? twoWheelerRider;
  VehicleData? autoTempo;
  VehicleData? eRickshaw;
  VehicleData? carMini;
  VehicleData? carSedan;
  VehicleData? suvCar;
  VehicleData? miniBus;
  VehicleData? pickupGoods;
  VehicleData? miniTruckGoods;
  VehicleData? largeTruckGoods;

  VehicleAllResponse({
    this.twoWheelerRider,
    this.autoTempo,
    this.eRickshaw,
    this.carMini,
    this.carSedan,
    this.suvCar,
    this.miniBus,
    this.pickupGoods,
    this.miniTruckGoods,
    this.largeTruckGoods,
  });

  factory VehicleAllResponse.fromJson(Map<String, dynamic> json) {
    return VehicleAllResponse(
      twoWheelerRider: json['twoWheelerRider'] != null
          ? VehicleData.fromJson(json['twoWheelerRider'])
          : null,
      autoTempo: json['autoTempo'] != null
          ? VehicleData.fromJson(json['autoTempo'])
          : null,
      eRickshaw: json['eRickshaw'] != null
          ? VehicleData.fromJson(json['eRickshaw'])
          : null,
      carMini: json['carMini'] != null
          ? VehicleData.fromJson(json['carMini'])
          : null,
      carSedan: json['carSedan'] != null
          ? VehicleData.fromJson(json['carSedan'])
          : null,
      suvCar: json['suvCar'] != null
          ? VehicleData.fromJson(json['suvCar'])
          : null,
      miniBus: json['miniBus'] != null
          ? VehicleData.fromJson(json['miniBus'])
          : null,
      pickupGoods: json['pickupGoods'] != null
          ? VehicleData.fromJson(json['pickupGoods'])
          : null,
      miniTruckGoods: json['miniTruckGoods'] != null
          ? VehicleData.fromJson(json['miniTruckGoods'])
          : null,
      largeTruckGoods: json['largeTruckGoods'] != null
          ? VehicleData.fromJson(json['largeTruckGoods'])
          : null,
    );
  }
}

// ================= COMMON VEHICLE DATA =================

class VehicleData {
  List<RiderUser>? users;
  double? fare;

  VehicleData({this.users, this.fare});

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      users: (json['users'] as List?)
          ?.map((e) => RiderUser.fromJson(e))
          .toList(),
      fare: double.tryParse(json['fare']?.toString() ?? ''),
    );
  }
}

// ================= USER =================

class RiderUser {
  String? riderId;
  String? name;
  String? profileImage;
  String? distance;
  int? rating;
  VehicleInformation? vehicleInformation;
  int? totalOrders;

  RiderUser({
    this.riderId,
    this.name,
    this.profileImage,
    this.distance,
    this.rating,
    this.vehicleInformation,
    this.totalOrders,
  });

  factory RiderUser.fromJson(Map<String, dynamic> json) {
    return RiderUser(
      riderId: json['riderId'],
      name: json['name'],
      profileImage: json['profile_image'],
      distance: json['distance'],
      rating: json['rating'],
      vehicleInformation: json['vehicleInformation'] != null
          ? VehicleInformation.fromJson(json['vehicleInformation'])
          : null,
      totalOrders: json['totalOrders'],
    );
  }
}

// ================= VEHICLE INFO =================

class VehicleInformation {
  String? vehicleType;
  String? vehicleModelYear;
  String? vehicleName;

  VehicleInformation({
    this.vehicleType,
    this.vehicleModelYear,
    this.vehicleName,
  });

  factory VehicleInformation.fromJson(Map<String, dynamic> json) {
    return VehicleInformation(
      vehicleType: json['vehicleType'],
      vehicleModelYear: json['vehicleModelYear'],
      vehicleName: json['vehicleName'],
    );
  }
}
