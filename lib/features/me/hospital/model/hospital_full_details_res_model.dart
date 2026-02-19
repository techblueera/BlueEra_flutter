import 'dart:convert';
HospitalFullDetailsResModel hospitalFullDetailsResModelFromJson(String str) => HospitalFullDetailsResModel.fromJson(json.decode(str));
String hospitalFullDetailsResModelToJson(HospitalFullDetailsResModel data) => json.encode(data.toJson());
class HospitalFullDetailsResModel {
  HospitalFullDetailsResModel({
      this.success, 
      this.data,});

  HospitalFullDetailsResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? HospitalFullData.fromJson(json['data']) : null;
  }
  bool? success;
  HospitalFullData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

HospitalFullData dataFromJson(String str) => HospitalFullData.fromJson(json.decode(str));
String dataToJson(HospitalFullData data) => json.encode(data.toJson());
class HospitalFullData {
  HospitalFullData({
      this.location, 
      this.id, 
      this.name, 
      this.description, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.coverUrl, 
      this.logoUrl, 
      this.visionMission, 
      this.history, 
      this.management, 
      this.departments, 
      this.emergencyCare, 
      this.otherFacilities, 
      this.gallery, 
      this.contacts,});

  HospitalFullData.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    coverUrl = json['coverUrl'];
    logoUrl = json['logoUrl'];
    visionMission = json['visionMission'] != null ? VisionMission.fromJson(json['visionMission']) : null;
    history = json['history'] != null ? History.fromJson(json['history']) : null;
    if (json['management'] != null) {
      management = [];
      json['management'].forEach((v) {
        management?.add(HospitalManagement.fromJson(v));
      });
    }
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments?.add(IpdOpdDepartments.fromJson(v));
      });
    }
    emergencyCare = json['emergencyCare'] != null ? EmergencyCare.fromJson(json['emergencyCare']) : null;
    otherFacilities = json['otherFacilities'] != null ? OtherFacilities.fromJson(json['otherFacilities']) : null;
    if (json['gallery'] != null) {
      gallery = [];
      json['gallery'].forEach((v) {
        gallery?.add(HospitalGallery.fromJson(v));
      });
    }
    // if (json['gallery'] != null) {
    //   gallery = [];
    //   json['gallery'].forEach((v) {
    //     // gallery?.add(Dynamic.fromJson(v));
    //   });
    // }
    if (json['contacts'] != null) {
      contacts = [];
      json['contacts'].forEach((v) {
        contacts?.add(HospitalContacts.fromJson(v));
      });
    }
  }
  Location? location;
  String? id;
  String? name;
  String? description;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? coverUrl;
  String? logoUrl;
  VisionMission? visionMission;
  History? history;
  List<HospitalManagement>? management;
  List<IpdOpdDepartments>? departments;
  EmergencyCare? emergencyCare;
  OtherFacilities? otherFacilities;
  List<HospitalGallery>? gallery;
  List<HospitalContacts>? contacts;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['_id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['coverUrl'] = coverUrl;
    map['logoUrl'] = logoUrl;
    if (visionMission != null) {
      map['visionMission'] = visionMission?.toJson();
    }
    if (history != null) {
      map['history'] = history?.toJson();
    }
    if (management != null) {
      map['management'] = management?.map((v) => v.toJson()).toList();
    }
    if (departments != null) {
      map['departments'] = departments?.map((v) => v.toJson()).toList();
    }
    if (emergencyCare != null) {
      map['emergencyCare'] = emergencyCare?.toJson();
    }
    if (otherFacilities != null) {
      map['otherFacilities'] = otherFacilities?.toJson();
    }
    if (gallery != null) {
      map['gallery'] = gallery?.map((v) => v.toJson()).toList();
    }

    if (contacts != null) {
      map['contacts'] = contacts?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}
HospitalGallery galleryFromJson(String str) => HospitalGallery.fromJson(json.decode(str));
String galleryToJson(HospitalGallery data) => json.encode(data.toJson());
class HospitalGallery {
  HospitalGallery({
    this.id,
    this.title,
    this.images,
    this.hospitalId,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.v,});

  HospitalGallery.fromJson(dynamic json) {
    id = json['_id'];
    title = json['title'];
    images = json['images'] != null ? json['images'].cast<String>() : [];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? title;
  List<String>? images;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['title'] = title;
    map['images'] = images;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

HospitalContacts contactsFromJson(String str) => HospitalContacts.fromJson(json.decode(str));
String contactsToJson(HospitalContacts data) => json.encode(data.toJson());
class HospitalContacts {
  HospitalContacts({
      this.branch, 
      this.id, 
      this.departments, 
      this.hospitalId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  HospitalContacts.fromJson(dynamic json) {
    branch = json['branch'] != null ? Branch.fromJson(json['branch']) : null;
    id = json['_id'];
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments?.add(Departments.fromJson(v));
      });
    }
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  Branch? branch;
  String? id;
  List<Departments>? departments;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (branch != null) {
      map['branch'] = branch?.toJson();
    }
    map['_id'] = id;
    if (departments != null) {
      map['departments'] = departments?.map((v) => v.toJson()).toList();
    }
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Departments departmentsFromJson(String str) => Departments.fromJson(json.decode(str));
String departmentsToJson(Departments data) => json.encode(data.toJson());
class Departments {
  Departments({
      this.department, 
      this.email, 
      this.phone, 
      this.id,});

  Departments.fromJson(dynamic json) {
    department = json['department'];
    email = json['email'];
    phone = json['phone'];
    id = json['_id'];
  }
  String? department;
  String? email;
  String? phone;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['department'] = department;
    map['email'] = email;
    map['phone'] = phone;
    map['_id'] = id;
    return map;
  }

}

Branch branchFromJson(String str) => Branch.fromJson(json.decode(str));
String branchToJson(Branch data) => json.encode(data.toJson());
class Branch {
  Branch({
      this.location, 
      this.website,});

  Branch.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    website = json['website'];
  }
  Location? location;
  String? website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['website'] = website;
    return map;
  }

}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
      this.name, 
      this.type, 
      this.coordinates,});

  Location.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }
  String? name;
  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

}

OtherFacilities otherFacilitiesFromJson(String str) => OtherFacilities.fromJson(json.decode(str));
String otherFacilitiesToJson(OtherFacilities data) => json.encode(data.toJson());
class OtherFacilities {
  OtherFacilities({
      this.id, 
      this.ambulance, 
      this.pmSwasthyaBimaYojana, 
      this.bloodBank, 
      this.diagnosticDepartments, 
      this.medicalStore, 
      this.cashlessInsurance, 
      this.hospitalId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  OtherFacilities.fromJson(dynamic json) {
    id = json['_id'];
    ambulance = json['ambulance'];
    pmSwasthyaBimaYojana = json['pmSwasthyaBimaYojana'];
    bloodBank = json['bloodBank'];
    diagnosticDepartments = json['diagnosticDepartments'];
    medicalStore = json['medicalStore'];
    cashlessInsurance = json['cashlessInsurance'] != null ? json['cashlessInsurance'].cast<String>() : [];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  bool? ambulance;
  bool? pmSwasthyaBimaYojana;
  bool? bloodBank;
  bool? diagnosticDepartments;
  bool? medicalStore;
  List<String>? cashlessInsurance;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['ambulance'] = ambulance;
    map['pmSwasthyaBimaYojana'] = pmSwasthyaBimaYojana;
    map['bloodBank'] = bloodBank;
    map['diagnosticDepartments'] = diagnosticDepartments;
    map['medicalStore'] = medicalStore;
    map['cashlessInsurance'] = cashlessInsurance;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

EmergencyCare emergencyCareFromJson(String str) => EmergencyCare.fromJson(json.decode(str));
String emergencyCareToJson(EmergencyCare data) => json.encode(data.toJson());
class EmergencyCare {
  EmergencyCare({
      this.id, 
      this.emergencyCasualty, 
      this.traumaCare, 
      this.icu, 
      this.ccu, 
      this.nicu, 
      this.picu, 
      this.hospitalId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  EmergencyCare.fromJson(dynamic json) {
    id = json['_id'];
    emergencyCasualty = json['emergencyCasualty'];
    traumaCare = json['traumaCare'];
    icu = json['icu'];
    ccu = json['ccu'];
    nicu = json['nicu'];
    picu = json['picu'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  bool? emergencyCasualty;
  bool? traumaCare;
  bool? icu;
  bool? ccu;
  bool? nicu;
  bool? picu;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['emergencyCasualty'] = emergencyCasualty;
    map['traumaCare'] = traumaCare;
    map['icu'] = icu;
    map['ccu'] = ccu;
    map['nicu'] = nicu;
    map['picu'] = picu;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

IpdOpdDepartments departmentsIpdFromJson(String str) => IpdOpdDepartments.fromJson(json.decode(str));
String departmentsIpdToJson(IpdOpdDepartments data) => json.encode(data.toJson());
class IpdOpdDepartments {
  IpdOpdDepartments({
      this.id,
      this.name,
      this.key,
      this.type,
      this.description,
      this.hospitalId,
      this.userId,
      this.createdAt,
      this.updatedAt,
      this.v,
      this.opd,
      this.ipd,});

  IpdOpdDepartments.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    key = json['key'];
    type = json['type'];
    description = json['description'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['opd'] != null) {
      opd = [];
      json['opd'].forEach((v) {
        opd?.add(Opd.fromJson(v));
      });
    }
    if (json['ipd'] != null) {
      ipd = [];
      json['ipd'].forEach((v) {
        ipd?.add(Ipd.fromJson(v));
      });
    }
    // if (json['ipd'] != null) {
    //   ipd = [];
    //   json['ipd'].forEach((v) {
    //     // ipd?.add(Dynamic.fromJson(v));
    //   });
    // }
  }
  String? id;
  String? name;
  String? key;
  String? type;
  String? description;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<Opd>? opd;
  List<Ipd>? ipd;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['key'] = key;
    map['type'] = type;
    map['description'] = description;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (opd != null) {
      map['opd'] = opd?.map((v) => v.toJson()).toList();
    }
    if (ipd != null) {
      map['ipd'] = ipd?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Opd opdFromJson(String str) => Opd.fromJson(json.decode(str));
String opdToJson(Opd data) => json.encode(data.toJson());
class Opd {
  Opd({
      this.id, 
      this.name, 
      this.description, 
      this.departmentId, 
      this.timing, 
      this.hospitalId, 
      this.imageUrl,
      this.userId,
      this.v, 
      this.createdAt, 
      this.updatedAt,});

  Opd.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    departmentId = json['departmentId'];
    timing = json['timing'];
    imageUrl = json['imageUrl'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? name;
  String? description;
  String? departmentId;
  String? imageUrl;
  String? timing;
  String? hospitalId;
  String? userId;
  int? v;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['imageUrl'] = imageUrl;
    map['description'] = description;
    map['departmentId'] = departmentId;
    map['timing'] = timing;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}


Ipd ipdFromJson(String str) => Ipd.fromJson(json.decode(str));
String ipdToJson(Opd data) => json.encode(data.toJson());
class Ipd {
  Ipd({
      this.id,
      this.name,
      this.description,
      this.departmentId,
      this.timing,
      this.hospitalId,
      this.imageUrl,
      this.userId,
      this.v,
      this.createdAt,
      this.fees,
      this.bedCount,
      this.updatedAt,});

  Ipd.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    departmentId = json['departmentId'];
    fees = json['fees'];
    timing = json['timing'];
    imageUrl = json['imageUrl'];
    bedCount = json['bedCount'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? name;
  dynamic bedCount;
  dynamic fees;
  String? imageUrl;
  String? description;
  String? departmentId;
  String? timing;
  String? hospitalId;
  String? userId;
  int? v;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['bedCount'] = bedCount;
    map['description'] = description;
    map['imageUrl'] = imageUrl;
    map['fees'] = fees;
    map['departmentId'] = departmentId;
    map['timing'] = timing;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

HospitalManagement managementFromJson(String str) => HospitalManagement.fromJson(json.decode(str));
String managementToJson(HospitalManagement data) => json.encode(data.toJson());
class HospitalManagement {
  HospitalManagement({
      this.id, 
      this.name, 
      this.imageUrl, 
      this.position, 
      this.hospitalId, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.updatedAt,});

  HospitalManagement.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    imageUrl = json['imageUrl'];
    position = json['position'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? name;
  String? imageUrl;
  String? position;
  String? hospitalId;
  String? userId;
  int? v;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['imageUrl'] = imageUrl;
    map['position'] = position;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

History historyFromJson(String str) => History.fromJson(json.decode(str));
String historyToJson(History data) => json.encode(data.toJson());
class History {
  History({
      this.id, 
      this.history, 
      this.hospitalId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  History.fromJson(dynamic json) {
    id = json['_id'];
    history = json['history'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? history;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['history'] = history;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

VisionMission visionMissionFromJson(String str) => VisionMission.fromJson(json.decode(str));
String visionMissionToJson(VisionMission data) => json.encode(data.toJson());
class VisionMission {
  VisionMission({
      this.id, 
      this.visionAndMission, 
      this.hospitalId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  VisionMission.fromJson(dynamic json) {
    id = json['_id'];
    visionAndMission = json['visionAndMission'];
    hospitalId = json['hospitalId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? visionAndMission;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['visionAndMission'] = visionAndMission;
    map['hospitalId'] = hospitalId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

