import 'dart:convert';
GetHospitalProfileDetailsResModel getHospitalProfileDetailsResModelFromJson(String str) => GetHospitalProfileDetailsResModel.fromJson(json.decode(str));
String getHospitalProfileDetailsResModelToJson(GetHospitalProfileDetailsResModel data) => json.encode(data.toJson());
class GetHospitalProfileDetailsResModel {
  GetHospitalProfileDetailsResModel({
      this.success, 
      this.data,});

  GetHospitalProfileDetailsResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  bool? success;
  Data? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      this.location, 
      this.id, 
      this.name, 
      this.description, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.visionMission, 
      this.history, 
      this.management, 
      this.departments, 
      this.emergencyCare, 
      this.otherFacilities, 
      this.gallery, 
      this.contacts,});

  Data.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    id = json['_id'];
    name = json['name'];
    description = json['description'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    visionMission = json['visionMission'] != null ? VisionMission.fromJson(json['visionMission']) : null;
    history = json['history'] != null ? History.fromJson(json['history']) : null;
    if (json['management'] != null) {
      management = [];
      json['management'].forEach((v) {
        management?.add(Management.fromJson(v));
      });
    }
    if (json['departments'] != null) {
      departments = [];
      json['departments'].forEach((v) {
        departments?.add(Departments.fromJson(v));
      });
    }
    emergencyCare = json['emergencyCare'] != null ? EmergencyCare.fromJson(json['emergencyCare']) : null;
    otherFacilities = json['otherFacilities'] != null ? OtherFacilities.fromJson(json['otherFacilities']) : null;
    if (json['gallery'] != null) {
      gallery = [];
      json['gallery'].forEach((v) {
        gallery?.add(Dynamic.fromJson(v));
      });
    }
    if (json['contacts'] != null) {
      contacts = [];
      json['contacts'].forEach((v) {
        contacts?.add(Contacts.fromJson(v));
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
  VisionMission? visionMission;
  History? history;
  List<Management>? management;
  List<Departments>? departments;
  EmergencyCare? emergencyCare;
  OtherFacilities? otherFacilities;
  List<dynamic>? gallery;
  List<Contacts>? contacts;

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

Contacts contactsFromJson(String str) => Contacts.fromJson(json.decode(str));
String contactsToJson(Contacts data) => json.encode(data.toJson());
class Contacts {
  Contacts({
      this.branch, 
      this.id, 
      this.departments, 
      this.hospitalId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Contacts.fromJson(dynamic json) {
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

Departments departmentsFromJson(String str) => Departments.fromJson(json.decode(str));
String departmentsToJson(Departments data) => json.encode(data.toJson());
class Departments {
  Departments({
      this.id, 
      this.name, 
      this.type, 
      this.description, 
      this.hospitalId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.opd, 
      this.ipd,});

  Departments.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
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
        ipd?.add(Dynamic.fromJson(v));
      });
    }
  }
  String? id;
  String? name;
  String? type;
  String? description;
  String? hospitalId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<Opd>? opd;
  List<dynamic>? ipd;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
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

Management managementFromJson(String str) => Management.fromJson(json.decode(str));
String managementToJson(Management data) => json.encode(data.toJson());
class Management {
  Management({
      this.id, 
      this.name, 
      this.imageUrl, 
      this.position, 
      this.hospitalId, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.updatedAt,});

  Management.fromJson(dynamic json) {
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

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
      this.name, 
      this.city, 
      this.state, 
      this.type, 
      this.coordinates,});

  Location.fromJson(dynamic json) {
    name = json['name'];
    city = json['city'];
    state = json['state'];
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }
  String? name;
  String? city;
  String? state;
  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['city'] = city;
    map['state'] = state;
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

}