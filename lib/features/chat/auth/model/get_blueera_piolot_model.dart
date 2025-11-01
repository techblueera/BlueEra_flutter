/// users : [{"user_id":"68bfd4caed36b188b6657e92","location":{"latitude":23.2667415,"longitude":77.4592507},"last_seen":"2025-11-01T10:55:17.110Z","user":null,"riderData":{"currentLocation":{"type":"Point"},"ratings":{"average":0,"count":0},"personalInformation":{"name":"Puneet Bhardwaj","gender":"Male","dob":"2003-08-30T00:00:00.000Z","email":"ssbeyonder@gmail.com","contactNo":"7869088589"},"address":{"homeLocation":{"type":"Point","coordinates":[77.459306,23.266583]},"streetAddress":"test","houseNo":"50","landmark":"test","pincode":"481001","city":"Balaghat","state":"Madhya Pradesh","locationPermission":true},"personalIdentification":{"aadharImages":{"front":null,"back":null},"panImages":{"front":null,"back":null},"isAadharVerified":"pending","isPanVerified":"pending","userPicture":[null],"aadharNo":"123456789123","panNo":"FVXPB5443P"},"drivingVerification":{"rcImages":{"front":null,"back":null},"dlImages":{"front":null,"back":null},"isRcVerified":"pending","isDlVerified":"pending","rcNo":"1234567890","dlNo":""},"vehicleImages":{"vehicleNoPlateImg":null,"vehicleRightHandSideImage":[null],"vehicleLeftSideImage":[null],"vehicleFrontImage":null,"vehicleBackImage":null},"vehicleInformation":{"registrationNo":"","vehicleName":""},"_id":"6905e292c94a53647f002013","userId":"68bfd4caed36b188b6657e92","__v":0,"createdAt":"2025-11-01T10:36:02.536Z","earnings":0,"isOnboardingComplete":true,"onboardingStep":6,"status":"offline","updatedAt":"2025-11-01T10:48:10.671Z"}}]

class GetBlueeraPiolotModel {
  GetBlueeraPiolotModel({
      this.users,});

  GetBlueeraPiolotModel.fromJson(dynamic json) {
    if (json['users'] != null) {
      users = [];
      json['users'].forEach((v) {
        users?.add(Riders.fromJson(v));
      });
    }
  }
  List<Riders>? users;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (users != null) {
      map['users'] = users?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// user_id : "68bfd4caed36b188b6657e92"
/// location : {"latitude":23.2667415,"longitude":77.4592507}
/// last_seen : "2025-11-01T10:55:17.110Z"
/// user : null
/// riderData : {"currentLocation":{"type":"Point"},"ratings":{"average":0,"count":0},"personalInformation":{"name":"Puneet Bhardwaj","gender":"Male","dob":"2003-08-30T00:00:00.000Z","email":"ssbeyonder@gmail.com","contactNo":"7869088589"},"address":{"homeLocation":{"type":"Point","coordinates":[77.459306,23.266583]},"streetAddress":"test","houseNo":"50","landmark":"test","pincode":"481001","city":"Balaghat","state":"Madhya Pradesh","locationPermission":true},"personalIdentification":{"aadharImages":{"front":null,"back":null},"panImages":{"front":null,"back":null},"isAadharVerified":"pending","isPanVerified":"pending","userPicture":[null],"aadharNo":"123456789123","panNo":"FVXPB5443P"},"drivingVerification":{"rcImages":{"front":null,"back":null},"dlImages":{"front":null,"back":null},"isRcVerified":"pending","isDlVerified":"pending","rcNo":"1234567890","dlNo":""},"vehicleImages":{"vehicleNoPlateImg":null,"vehicleRightHandSideImage":[null],"vehicleLeftSideImage":[null],"vehicleFrontImage":null,"vehicleBackImage":null},"vehicleInformation":{"registrationNo":"","vehicleName":""},"_id":"6905e292c94a53647f002013","userId":"68bfd4caed36b188b6657e92","__v":0,"createdAt":"2025-11-01T10:36:02.536Z","earnings":0,"isOnboardingComplete":true,"onboardingStep":6,"status":"offline","updatedAt":"2025-11-01T10:48:10.671Z"}

class Riders {
  Riders({
      this.userId, 
      this.location, 
      this.lastSeen, 
      this.user, 
      this.riderData,});

  Riders.fromJson(dynamic json) {
    userId = json['user_id'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    lastSeen = json['last_seen'];
    user = json['user'];
    riderData = json['riderData'] != null ? RiderData.fromJson(json['riderData']) : null;
  }
  String? userId;
  Location? location;
  String? lastSeen;
  dynamic user;
  RiderData? riderData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = userId;
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['last_seen'] = lastSeen;
    map['user'] = user;
    if (riderData != null) {
      map['riderData'] = riderData?.toJson();
    }
    return map;
  }

}

/// currentLocation : {"type":"Point"}
/// ratings : {"average":0,"count":0}
/// personalInformation : {"name":"Puneet Bhardwaj","gender":"Male","dob":"2003-08-30T00:00:00.000Z","email":"ssbeyonder@gmail.com","contactNo":"7869088589"}
/// address : {"homeLocation":{"type":"Point","coordinates":[77.459306,23.266583]},"streetAddress":"test","houseNo":"50","landmark":"test","pincode":"481001","city":"Balaghat","state":"Madhya Pradesh","locationPermission":true}
/// personalIdentification : {"aadharImages":{"front":null,"back":null},"panImages":{"front":null,"back":null},"isAadharVerified":"pending","isPanVerified":"pending","userPicture":[null],"aadharNo":"123456789123","panNo":"FVXPB5443P"}
/// drivingVerification : {"rcImages":{"front":null,"back":null},"dlImages":{"front":null,"back":null},"isRcVerified":"pending","isDlVerified":"pending","rcNo":"1234567890","dlNo":""}
/// vehicleImages : {"vehicleNoPlateImg":null,"vehicleRightHandSideImage":[null],"vehicleLeftSideImage":[null],"vehicleFrontImage":null,"vehicleBackImage":null}
/// vehicleInformation : {"registrationNo":"","vehicleName":""}
/// _id : "6905e292c94a53647f002013"
/// userId : "68bfd4caed36b188b6657e92"
/// __v : 0
/// createdAt : "2025-11-01T10:36:02.536Z"
/// earnings : 0
/// isOnboardingComplete : true
/// onboardingStep : 6
/// status : "offline"
/// updatedAt : "2025-11-01T10:48:10.671Z"

class RiderData {
  RiderData({
      this.currentLocation, 
      this.ratings, 
      this.personalInformation, 
      this.address, 
      this.personalIdentification, 
      this.drivingVerification, 
      this.vehicleImages, 
      this.vehicleInformation, 
      this.id, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.earnings, 
      this.isOnboardingComplete, 
      this.onboardingStep, 
      this.status, 
      this.updatedAt,});

  RiderData.fromJson(dynamic json) {
    currentLocation = json['currentLocation'] != null ? CurrentLocation.fromJson(json['currentLocation']) : null;
    ratings = json['ratings'] != null ? Ratings.fromJson(json['ratings']) : null;
    personalInformation = json['personalInformation'] != null ? PersonalInformation.fromJson(json['personalInformation']) : null;
    address = json['address'] != null ? Address.fromJson(json['address']) : null;
    personalIdentification = json['personalIdentification'] != null ? PersonalIdentification.fromJson(json['personalIdentification']) : null;
    drivingVerification = json['drivingVerification'] != null ? DrivingVerification.fromJson(json['drivingVerification']) : null;
    vehicleImages = json['vehicleImages'] != null ? VehicleImages.fromJson(json['vehicleImages']) : null;
    vehicleInformation = json['vehicleInformation'] != null ? VehicleInformation.fromJson(json['vehicleInformation']) : null;
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    earnings = json['earnings'];
    isOnboardingComplete = json['isOnboardingComplete'];
    onboardingStep = json['onboardingStep'];
    status = json['status'];
    updatedAt = json['updatedAt'];
  }
  CurrentLocation? currentLocation;
  Ratings? ratings;
  PersonalInformation? personalInformation;
  Address? address;
  PersonalIdentification? personalIdentification;
  DrivingVerification? drivingVerification;
  VehicleImages? vehicleImages;
  VehicleInformation? vehicleInformation;
  String? id;
  String? userId;
  num? v;
  String? createdAt;
  num? earnings;
  bool? isOnboardingComplete;
  num? onboardingStep;
  String? status;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (currentLocation != null) {
      map['currentLocation'] = currentLocation?.toJson();
    }
    if (ratings != null) {
      map['ratings'] = ratings?.toJson();
    }
    if (personalInformation != null) {
      map['personalInformation'] = personalInformation?.toJson();
    }
    if (address != null) {
      map['address'] = address?.toJson();
    }
    if (personalIdentification != null) {
      map['personalIdentification'] = personalIdentification?.toJson();
    }
    if (drivingVerification != null) {
      map['drivingVerification'] = drivingVerification?.toJson();
    }
    if (vehicleImages != null) {
      map['vehicleImages'] = vehicleImages?.toJson();
    }
    if (vehicleInformation != null) {
      map['vehicleInformation'] = vehicleInformation?.toJson();
    }
    map['_id'] = id;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['earnings'] = earnings;
    map['isOnboardingComplete'] = isOnboardingComplete;
    map['onboardingStep'] = onboardingStep;
    map['status'] = status;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

/// registrationNo : ""
/// vehicleName : ""

class VehicleInformation {
  VehicleInformation({
      this.registrationNo, 
      this.vehicleName,});

  VehicleInformation.fromJson(dynamic json) {
    registrationNo = json['registrationNo'];
    vehicleName = json['vehicleName'];
  }
  String? registrationNo;
  String? vehicleName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['registrationNo'] = registrationNo;
    map['vehicleName'] = vehicleName;
    return map;
  }

}

/// vehicleNoPlateImg : null
/// vehicleRightHandSideImage : [null]
/// vehicleLeftSideImage : [null]
/// vehicleFrontImage : null
/// vehicleBackImage : null

class VehicleImages {
  VehicleImages({
      this.vehicleNoPlateImg, 
      this.vehicleRightHandSideImage, 
      this.vehicleLeftSideImage, 
      this.vehicleFrontImage, 
      this.vehicleBackImage,});

  VehicleImages.fromJson(dynamic json) {
    vehicleNoPlateImg = json['vehicleNoPlateImg'];
    if (json['vehicleRightHandSideImage'] != null) {
      vehicleRightHandSideImage = [];
      json['vehicleRightHandSideImage'].forEach((v) {
        vehicleRightHandSideImage?.add(v);
      });
    }
    if (json['vehicleLeftSideImage'] != null) {
      vehicleLeftSideImage = [];
      json['vehicleLeftSideImage'].forEach((v) {
        vehicleLeftSideImage?.add(v);
      });
    }
    vehicleFrontImage = json['vehicleFrontImage'];
    vehicleBackImage = json['vehicleBackImage'];
  }
  dynamic vehicleNoPlateImg;
  List<dynamic>? vehicleRightHandSideImage;
  List<dynamic>? vehicleLeftSideImage;
  dynamic vehicleFrontImage;
  dynamic vehicleBackImage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['vehicleNoPlateImg'] = vehicleNoPlateImg;
    if (vehicleRightHandSideImage != null) {
      map['vehicleRightHandSideImage'] = vehicleRightHandSideImage?.map((v) => v.toJson()).toList();
    }
    if (vehicleLeftSideImage != null) {
      map['vehicleLeftSideImage'] = vehicleLeftSideImage?.map((v) => v.toJson()).toList();
    }
    map['vehicleFrontImage'] = vehicleFrontImage;
    map['vehicleBackImage'] = vehicleBackImage;
    return map;
  }

}

/// rcImages : {"front":null,"back":null}
/// dlImages : {"front":null,"back":null}
/// isRcVerified : "pending"
/// isDlVerified : "pending"
/// rcNo : "1234567890"
/// dlNo : ""

class DrivingVerification {
  DrivingVerification({
      this.rcImages, 
      this.dlImages, 
      this.isRcVerified, 
      this.isDlVerified, 
      this.rcNo, 
      this.dlNo,});

  DrivingVerification.fromJson(dynamic json) {
    rcImages = json['rcImages'] != null ? RcImages.fromJson(json['rcImages']) : null;
    dlImages = json['dlImages'] != null ? DlImages.fromJson(json['dlImages']) : null;
    isRcVerified = json['isRcVerified'];
    isDlVerified = json['isDlVerified'];
    rcNo = json['rcNo'];
    dlNo = json['dlNo'];
  }
  RcImages? rcImages;
  DlImages? dlImages;
  String? isRcVerified;
  String? isDlVerified;
  String? rcNo;
  String? dlNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (rcImages != null) {
      map['rcImages'] = rcImages?.toJson();
    }
    if (dlImages != null) {
      map['dlImages'] = dlImages?.toJson();
    }
    map['isRcVerified'] = isRcVerified;
    map['isDlVerified'] = isDlVerified;
    map['rcNo'] = rcNo;
    map['dlNo'] = dlNo;
    return map;
  }

}

/// front : null
/// back : null

class DlImages {
  DlImages({
      this.front, 
      this.back,});

  DlImages.fromJson(dynamic json) {
    front = json['front'];
    back = json['back'];
  }
  dynamic front;
  dynamic back;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['front'] = front;
    map['back'] = back;
    return map;
  }

}

/// front : null
/// back : null

class RcImages {
  RcImages({
      this.front, 
      this.back,});

  RcImages.fromJson(dynamic json) {
    front = json['front'];
    back = json['back'];
  }
  dynamic front;
  dynamic back;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['front'] = front;
    map['back'] = back;
    return map;
  }

}

/// aadharImages : {"front":null,"back":null}
/// panImages : {"front":null,"back":null}
/// isAadharVerified : "pending"
/// isPanVerified : "pending"
/// userPicture : [null]
/// aadharNo : "123456789123"
/// panNo : "FVXPB5443P"

class PersonalIdentification {
  PersonalIdentification({
      this.aadharImages, 
      this.panImages, 
      this.isAadharVerified, 
      this.isPanVerified, 
      this.userPicture, 
      this.aadharNo, 
      this.panNo,});

  PersonalIdentification.fromJson(dynamic json) {
    aadharImages = json['aadharImages'] != null ? AadharImages.fromJson(json['aadharImages']) : null;
    panImages = json['panImages'] != null ? PanImages.fromJson(json['panImages']) : null;
    isAadharVerified = json['isAadharVerified'];
    isPanVerified = json['isPanVerified'];
    if (json['userPicture'] != null) {
      userPicture = [];
      json['userPicture'].forEach((v) {
        userPicture?.add(v);
      });
    }
    aadharNo = json['aadharNo'];
    panNo = json['panNo'];
  }
  AadharImages? aadharImages;
  PanImages? panImages;
  String? isAadharVerified;
  String? isPanVerified;
  List<dynamic>? userPicture;
  String? aadharNo;
  String? panNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (aadharImages != null) {
      map['aadharImages'] = aadharImages?.toJson();
    }
    if (panImages != null) {
      map['panImages'] = panImages?.toJson();
    }
    map['isAadharVerified'] = isAadharVerified;
    map['isPanVerified'] = isPanVerified;
    if (userPicture != null) {
      map['userPicture'] = userPicture?.map((v) => v.toJson()).toList();
    }
    map['aadharNo'] = aadharNo;
    map['panNo'] = panNo;
    return map;
  }

}

/// front : null
/// back : null

class PanImages {
  PanImages({
      this.front, 
      this.back,});

  PanImages.fromJson(dynamic json) {
    front = json['front'];
    back = json['back'];
  }
  dynamic front;
  dynamic back;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['front'] = front;
    map['back'] = back;
    return map;
  }

}

/// front : null
/// back : null

class AadharImages {
  AadharImages({
      this.front, 
      this.back,});

  AadharImages.fromJson(dynamic json) {
    front = json['front'];
    back = json['back'];
  }
  dynamic front;
  dynamic back;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['front'] = front;
    map['back'] = back;
    return map;
  }

}

/// homeLocation : {"type":"Point","coordinates":[77.459306,23.266583]}
/// streetAddress : "test"
/// houseNo : "50"
/// landmark : "test"
/// pincode : "481001"
/// city : "Balaghat"
/// state : "Madhya Pradesh"
/// locationPermission : true

class Address {
  Address({
      this.homeLocation, 
      this.streetAddress, 
      this.houseNo, 
      this.landmark, 
      this.pincode, 
      this.city, 
      this.state, 
      this.locationPermission,});

  Address.fromJson(dynamic json) {
    homeLocation = json['homeLocation'] != null ? HomeLocation.fromJson(json['homeLocation']) : null;
    streetAddress = json['streetAddress'];
    houseNo = json['houseNo'];
    landmark = json['landmark'];
    pincode = json['pincode'];
    city = json['city'];
    state = json['state'];
    locationPermission = json['locationPermission'];
  }
  HomeLocation? homeLocation;
  String? streetAddress;
  String? houseNo;
  String? landmark;
  String? pincode;
  String? city;
  String? state;
  bool? locationPermission;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (homeLocation != null) {
      map['homeLocation'] = homeLocation?.toJson();
    }
    map['streetAddress'] = streetAddress;
    map['houseNo'] = houseNo;
    map['landmark'] = landmark;
    map['pincode'] = pincode;
    map['city'] = city;
    map['state'] = state;
    map['locationPermission'] = locationPermission;
    return map;
  }

}

/// type : "Point"
/// coordinates : [77.459306,23.266583]

class HomeLocation {
  HomeLocation({
      this.type, 
      this.coordinates,});

  HomeLocation.fromJson(dynamic json) {
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<num>() : [];
  }
  String? type;
  List<num>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

}

/// name : "Puneet Bhardwaj"
/// gender : "Male"
/// dob : "2003-08-30T00:00:00.000Z"
/// email : "ssbeyonder@gmail.com"
/// contactNo : "7869088589"

class PersonalInformation {
  PersonalInformation({
      this.name, 
      this.gender, 
      this.dob, 
      this.email, 
      this.contactNo,});

  PersonalInformation.fromJson(dynamic json) {
    name = json['name'];
    gender = json['gender'];
    dob = json['dob'];
    email = json['email'];
    contactNo = json['contactNo'];
  }
  String? name;
  String? gender;
  String? dob;
  String? email;
  String? contactNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['gender'] = gender;
    map['dob'] = dob;
    map['email'] = email;
    map['contactNo'] = contactNo;
    return map;
  }

}

/// average : 0
/// count : 0

class Ratings {
  Ratings({
      this.average, 
      this.count,});

  Ratings.fromJson(dynamic json) {
    average = json['average'];
    count = json['count'];
  }
  num? average;
  num? count;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['average'] = average;
    map['count'] = count;
    return map;
  }

}

/// type : "Point"

class CurrentLocation {
  CurrentLocation({
      this.type,});

  CurrentLocation.fromJson(dynamic json) {
    type = json['type'];
  }
  String? type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    return map;
  }

}

/// latitude : 23.2667415
/// longitude : 77.4592507

class Location {
  Location({
      this.latitude, 
      this.longitude,});

  Location.fromJson(dynamic json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }
  num? latitude;
  num? longitude;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    return map;
  }

}