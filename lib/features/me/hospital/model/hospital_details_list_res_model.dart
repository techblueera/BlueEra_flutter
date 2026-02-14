import 'dart:convert';
HospitalDetailsListResModel hospitalDetailsListResModelFromJson(String str) => HospitalDetailsListResModel.fromJson(json.decode(str));
String hospitalDetailsListResModelToJson(HospitalDetailsListResModel data) => json.encode(data.toJson());
class HospitalDetailsListResModel {
  HospitalDetailsListResModel({
      this.success, 
      this.count, 
      this.data,});

  HospitalDetailsListResModel.fromJson(dynamic json) {
    success = json['success'];
    count = json['count'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(HospitalDetailsData.fromJson(v));
      });
    }
  }
  bool? success;
  int? count;
  List<HospitalDetailsData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['count'] = count;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

HospitalDetailsData dataFromJson(String str) => HospitalDetailsData.fromJson(json.decode(str));
String dataToJson(HospitalDetailsData data) => json.encode(data.toJson());
class HospitalDetailsData {
  HospitalDetailsData({
      this.id, 
      this.address, 
      this.hospitalName, 
      this.emergencyNumber, 
      this.pincode, 
      this.beds, 
      this.branches, 
      this.careers, 
      this.doctors, 
      this.emergencyServices, 
      this.wards, 
      this.averageRating, 
      this.numberOfReviews, 
      this.logoImage, 
      this.facilities,});

  HospitalDetailsData.fromJson(dynamic json) {
    id = json['_id'];
    address = json['address'];
    hospitalName = json['hospitalName'];
    emergencyNumber = json['emergencyNumber'];
    pincode = json['pincode'];
    if (json['beds'] != null) {
      beds = [];
      json['beds'].forEach((v) {
        beds?.add(Beds.fromJson(v));
      });
    }
    if (json['branches'] != null) {
      branches = [];
      json['branches'].forEach((v) {
        // branches?.add(Dynamic.fromJson(v));
      });
    }
    if (json['careers'] != null) {
      careers = [];
      json['careers'].forEach((v) {
        careers?.add(Careers.fromJson(v));
      });
    }
    if (json['doctors'] != null) {
      doctors = [];
      json['doctors'].forEach((v) {
        doctors?.add(Doctors.fromJson(v));
      });
    }
    if (json['emergencyServices'] != null) {
      emergencyServices = [];
      json['emergencyServices'].forEach((v) {
        emergencyServices?.add(EmergencyServices.fromJson(v));
      });
    }
    if (json['wards'] != null) {
      wards = [];
      json['wards'].forEach((v) {
        wards?.add(Wards.fromJson(v));
      });
    }
    averageRating = json['averageRating'];
    numberOfReviews = json['numberOfReviews'];
    logoImage = json['logoImage'];
    facilities = json['facilities'] != null ? json['facilities'].cast<String>() : [];
  }
  String? id;
  String? address;
  String? hospitalName;
  int? emergencyNumber;
  String? pincode;
  List<Beds>? beds;
  List<dynamic>? branches;
  List<Careers>? careers;
  List<Doctors>? doctors;
  List<EmergencyServices>? emergencyServices;
  List<Wards>? wards;
  int? averageRating;
  int? numberOfReviews;
  String? logoImage;
  List<String>? facilities;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['address'] = address;
    map['hospitalName'] = hospitalName;
    map['emergencyNumber'] = emergencyNumber;
    map['pincode'] = pincode;
    if (beds != null) {
      map['beds'] = beds?.map((v) => v.toJson()).toList();
    }
    if (branches != null) {
      map['branches'] = branches?.map((v) => v.toJson()).toList();
    }
    if (careers != null) {
      map['careers'] = careers?.map((v) => v.toJson()).toList();
    }
    if (doctors != null) {
      map['doctors'] = doctors?.map((v) => v.toJson()).toList();
    }
    if (emergencyServices != null) {
      map['emergencyServices'] = emergencyServices?.map((v) => v.toJson()).toList();
    }
    if (wards != null) {
      map['wards'] = wards?.map((v) => v.toJson()).toList();
    }
    map['averageRating'] = averageRating;
    map['numberOfReviews'] = numberOfReviews;
    map['logoImage'] = logoImage;
    map['facilities'] = facilities;
    return map;
  }

}

Wards wardsFromJson(String str) => Wards.fromJson(json.decode(str));
String wardsToJson(Wards data) => json.encode(data.toJson());
class Wards {
  Wards({
      this.id, 
      this.departmentId, 
      this.businessId, 
      this.v, 
      this.availableBeds, 
      this.createdAt, 
      this.fees, 
      this.isActive, 
      this.name, 
      this.totalBeds, 
      this.type, 
      this.updatedAt,});

  Wards.fromJson(dynamic json) {
    id = json['_id'];
    departmentId = json['departmentId'];
    businessId = json['businessId'];
    v = json['__v'];
    availableBeds = json['availableBeds'];
    createdAt = json['createdAt'];
    fees = json['fees'];
    isActive = json['isActive'];
    name = json['name'];
    totalBeds = json['totalBeds'];
    type = json['type'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? departmentId;
  String? businessId;
  int? v;
  int? availableBeds;
  String? createdAt;
  int? fees;
  bool? isActive;
  String? name;
  int? totalBeds;
  String? type;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['departmentId'] = departmentId;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['availableBeds'] = availableBeds;
    map['createdAt'] = createdAt;
    map['fees'] = fees;
    map['isActive'] = isActive;
    map['name'] = name;
    map['totalBeds'] = totalBeds;
    map['type'] = type;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

EmergencyServices emergencyServicesFromJson(String str) => EmergencyServices.fromJson(json.decode(str));
String emergencyServicesToJson(EmergencyServices data) => json.encode(data.toJson());
class EmergencyServices {
  EmergencyServices({
      this.id, 
      this.departmentId, 
      this.businessId, 
      this.v, 
      this.createdAt, 
      this.isActive, 
      this.name, 
      this.type, 
      this.updatedAt,});

  EmergencyServices.fromJson(dynamic json) {
    id = json['_id'];
    departmentId = json['departmentId'];
    businessId = json['businessId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    isActive = json['isActive'];
    name = json['name'];
    type = json['type'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? departmentId;
  String? businessId;
  int? v;
  String? createdAt;
  bool? isActive;
  String? name;
  String? type;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['departmentId'] = departmentId;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['isActive'] = isActive;
    map['name'] = name;
    map['type'] = type;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

Doctors doctorsFromJson(String str) => Doctors.fromJson(json.decode(str));
String doctorsToJson(Doctors data) => json.encode(data.toJson());
class Doctors {
  Doctors({
      this.id, 
      this.departmentId, 
      this.name, 
      this.businessId, 
      this.v, 
      this.availability, 
      this.createdAt, 
      this.isOnLeave, 
      this.specialization, 
      this.updatedAt,});

  Doctors.fromJson(dynamic json) {
    id = json['_id'];
    departmentId = json['departmentId'];
    name = json['name'];
    businessId = json['businessId'];
    v = json['__v'];
    availability = json['availability'];
    createdAt = json['createdAt'];
    isOnLeave = json['isOnLeave'];
    specialization = json['specialization'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? departmentId;
  String? name;
  String? businessId;
  int? v;
  String? availability;
  String? createdAt;
  bool? isOnLeave;
  String? specialization;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['departmentId'] = departmentId;
    map['name'] = name;
    map['businessId'] = businessId;
    map['__v'] = v;
    map['availability'] = availability;
    map['createdAt'] = createdAt;
    map['isOnLeave'] = isOnLeave;
    map['specialization'] = specialization;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

Careers careersFromJson(String str) => Careers.fromJson(json.decode(str));
String careersToJson(Careers data) => json.encode(data.toJson());
class Careers {
  Careers({
      this.id, 
      this.businessId, 
      this.position, 
      this.v, 
      this.createdAt, 
      this.description, 
      this.isActive, 
      this.requirements, 
      this.updatedAt,});

  Careers.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    position = json['position'];
    v = json['__v'];
    createdAt = json['createdAt'];
    description = json['description'];
    isActive = json['isActive'];
    requirements = json['requirements'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? businessId;
  String? position;
  int? v;
  String? createdAt;
  String? description;
  bool? isActive;
  String? requirements;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['position'] = position;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['description'] = description;
    map['isActive'] = isActive;
    map['requirements'] = requirements;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

Beds bedsFromJson(String str) => Beds.fromJson(json.decode(str));
String bedsToJson(Beds data) => json.encode(data.toJson());
class Beds {
  Beds({
      this.id, 
      this.businessId, 
      this.wardId, 
      this.bedNumber, 
      this.name, 
      this.image, 
      this.description, 
      this.fees, 
      this.isOccupied, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Beds.fromJson(dynamic json) {
    id = json['_id'];
    businessId = json['businessId'];
    wardId = json['wardId'];
    bedNumber = json['bedNumber'];
    name = json['name'];
    image = json['image'];
    description = json['description'];
    fees = json['fees'];
    isOccupied = json['isOccupied'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? businessId;
  String? wardId;
  String? bedNumber;
  String? name;
  String? image;
  String? description;
  int? fees;
  bool? isOccupied;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['businessId'] = businessId;
    map['wardId'] = wardId;
    map['bedNumber'] = bedNumber;
    map['name'] = name;
    map['image'] = image;
    map['description'] = description;
    map['fees'] = fees;
    map['isOccupied'] = isOccupied;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}