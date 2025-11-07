/// orderId : "68e382198604e2801d0abc3a"
/// status : "pending"
/// createdAt : "2025-11-06T09:54:11.991Z"
/// updatedAt : "2025-11-06T09:54:11.991Z"
/// pickupLocation : {"location":{"type":"Point","coordinates":[80.9078124,26.7864581]}}
/// dropLocation : {"location":{"type":"Point","coordinates":[80.9499432,26.7495261]}}
/// fare : 89
/// distanceToPickup : "10.05 km"
/// distancePickupToDrop : "7.86 km"
/// user : {"id":"689e28a878385d314533ec64","name":"","profile_image":"https://be-user-bkt.s3.ap-south-1.amazonaws.com/Business/689e28a978385d314533ec66/logo/1755401519197_cropped_image_01755401379816.png","contact_no":"9494985993"}
/// receiverUser : {"id":"68e380caefe88c3e2afc61f3","name":"Guest8691","profile_image":"","contact_no":"9670778691"}

class RiderOrdersDetailsModel {
  RiderOrdersDetailsModel({
      this.orderId, 
      this.id,
      this.status,
      this.createdAt, 
      this.updatedAt, 
      this.pickupLocation, 
      this.dropLocation, 
      this.fare, 
      this.distanceToPickup, 
      this.distancePickupToDrop, 
      this.user, 
      this.receiverUser,});

  RiderOrdersDetailsModel.fromJson(dynamic json) {
    orderId = json['orderId'];
    id = json['_id'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    pickupLocation = json['pickupLocation'] != null ? PickupLocation.fromJson(json['pickupLocation']) : null;
    dropLocation = json['dropLocation'] != null ? DropLocation.fromJson(json['dropLocation']) : null;
    fare = json['fare'];
    distanceToPickup = json['distanceToPickup'];
    distancePickupToDrop = json['distancePickupToDrop'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    receiverUser = json['receiverUser'] != null ? ReceiverUser.fromJson(json['receiverUser']) : null;
  }
  String? orderId;
  String? id;
  String? status;
  String? createdAt;
  String? updatedAt;
  PickupLocation? pickupLocation;
  DropLocation? dropLocation;
  num? fare;
  String? distanceToPickup;
  String? distancePickupToDrop;
  User? user;
  ReceiverUser? receiverUser;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['orderId'] = orderId;
    map['_id'] = id;
    map['status'] = status;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    if (pickupLocation != null) {
      map['pickupLocation'] = pickupLocation?.toJson();
    }
    if (dropLocation != null) {
      map['dropLocation'] = dropLocation?.toJson();
    }
    map['fare'] = fare;
    map['distanceToPickup'] = distanceToPickup;
    map['distancePickupToDrop'] = distancePickupToDrop;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    if (receiverUser != null) {
      map['receiverUser'] = receiverUser?.toJson();
    }
    return map;
  }

}

/// id : "68e380caefe88c3e2afc61f3"
/// name : "Guest8691"
/// profile_image : ""
/// contact_no : "9670778691"

class ReceiverUser {
  ReceiverUser({
      this.id, 
      this.name, 
      this.profileImage, 
      this.contactNo,});

  ReceiverUser.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profileImage = json['profile_image'];
    contactNo = json['contact_no'];
  }
  String? id;
  String? name;
  String? profileImage;
  String? contactNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_image'] = profileImage;
    map['contact_no'] = contactNo;
    return map;
  }

}

/// id : "689e28a878385d314533ec64"
/// name : ""
/// profile_image : "https://be-user-bkt.s3.ap-south-1.amazonaws.com/Business/689e28a978385d314533ec66/logo/1755401519197_cropped_image_01755401379816.png"
/// contact_no : "9494985993"

class User {
  User({
      this.id, 
      this.name, 
      this.profileImage, 
      this.contactNo,});

  User.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profileImage = json['profile_image'];
    contactNo = json['contact_no'];
  }
  String? id;
  String? name;
  String? profileImage;
  String? contactNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_image'] = profileImage;
    map['contact_no'] = contactNo;
    return map;
  }

}

/// location : {"type":"Point","coordinates":[80.9499432,26.7495261]}

class DropLocation {
  DropLocation({
      this.location,});

  DropLocation.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
  }
  Location? location;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    return map;
  }

}

/// type : "Point"
/// coordinates : [80.9499432,26.7495261]

class Location {
  Location({
      this.type, 
      this.coordinates,});

  Location.fromJson(dynamic json) {
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

/// location : {"type":"Point","coordinates":[80.9078124,26.7864581]}

class PickupLocation {
  PickupLocation({
      this.location,});

  PickupLocation.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
  }
  Location? location;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    return map;
  }

}
