import 'dart:convert';
LabFullDetailsResModel newLabFullDetailsResModelFromJson(String str) => LabFullDetailsResModel.fromJson(json.decode(str));
String newLabFullDetailsResModelToJson(LabFullDetailsResModel data) => json.encode(data.toJson());
class LabFullDetailsResModel {
  LabFullDetailsResModel({
      this.success, 
      this.data,});

  LabFullDetailsResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? LabDetailsData.fromJson(json['data']) : null;
  }
  bool? success;
  LabDetailsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

LabDetailsData dataFromJson(String str) => LabDetailsData.fromJson(json.decode(str));
String dataToJson(LabDetailsData data) => json.encode(data.toJson());
class LabDetailsData {
  LabDetailsData({
      this.profile, 
      this.tests, 
      this.contactInfo, 
      this.galleries, 
      this.healthCamps, 
      this.facility,});

  LabDetailsData.fromJson(dynamic json) {
    profile = json['profile'] != null ? Profile.fromJson(json['profile']) : null;
    if (json['tests'] != null) {
      tests = [];
      json['tests'].forEach((v) {
        tests?.add(Tests.fromJson(v));
      });
    }
    contactInfo = json['contactInfo'] != null ? ContactInfo.fromJson(json['contactInfo']) : null;
    if (json['galleries'] != null) {
      galleries = [];
      json['galleries'].forEach((v) {
        galleries?.add(Galleries.fromJson(v));
      });
    }
    if (json['healthCamps'] != null) {
      healthCamps = [];
      json['healthCamps'].forEach((v) {
        healthCamps?.add(HealthCamps.fromJson(v));
      });
    }
    facility = json['facility'] != null ? Facility.fromJson(json['facility']) : null;
  }
  Profile? profile;
  List<Tests>? tests;
  ContactInfo? contactInfo;
  List<Galleries>? galleries;
  List<HealthCamps>? healthCamps;
  Facility? facility;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (profile != null) {
      map['profile'] = profile?.toJson();
    }
    if (tests != null) {
      map['tests'] = tests?.map((v) => v.toJson()).toList();
    }
    if (contactInfo != null) {
      map['contactInfo'] = contactInfo?.toJson();
    }
    if (galleries != null) {
      map['galleries'] = galleries?.map((v) => v.toJson()).toList();
    }
    if (healthCamps != null) {
      map['healthCamps'] = healthCamps?.map((v) => v.toJson()).toList();
    }
    if (facility != null) {
      map['facility'] = facility?.toJson();
    }
    return map;
  }

}

Facility facilityFromJson(String str) => Facility.fromJson(json.decode(str));
String facilityToJson(Facility data) => json.encode(data.toJson());
class Facility {
  Facility({
      this.id, 
      this.laboratoryId, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.digitalReport, 
      this.doctorConsultationTieUp, 
      this.homeSampleCollection, 
      this.insuranceCashlessSupport, 
      this.other, 
      this.updatedAt, 
      this.wheelchairAssistance, 
      this.creditCardPayment, 
      this.healthCheckupPkg, 
      this.upiOnline,});

  Facility.fromJson(dynamic json) {
    id = json['_id'];
    laboratoryId = json['laboratoryId'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    digitalReport = json['digitalReport'];
    doctorConsultationTieUp = json['doctorConsultationTieUp'];
    homeSampleCollection = json['homeSampleCollection'];
    insuranceCashlessSupport = json['insuranceCashlessSupport'];
    if (json['other'] != null) {
      other = [];
      json['other'].forEach((v) {
        other?.add(Other.fromJson(v));
      });
    }
    updatedAt = json['updatedAt'];
    wheelchairAssistance = json['wheelchairAssistance'];
    creditCardPayment = json['credit_card_payment'];
    healthCheckupPkg = json['health_checkup_pkg'];
    upiOnline = json['upi_online'];
  }
  String? id;
  String? laboratoryId;
  String? userId;
  int? v;
  String? createdAt;
  bool? digitalReport;
  bool? doctorConsultationTieUp;
  bool? homeSampleCollection;
  bool? insuranceCashlessSupport;
  List<Other>? other;
  String? updatedAt;
  bool? wheelchairAssistance;
  bool? creditCardPayment;
  bool? healthCheckupPkg;
  bool? upiOnline;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['laboratoryId'] = laboratoryId;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['digitalReport'] = digitalReport;
    map['doctorConsultationTieUp'] = doctorConsultationTieUp;
    map['homeSampleCollection'] = homeSampleCollection;
    map['insuranceCashlessSupport'] = insuranceCashlessSupport;
    if (other != null) {
      map['other'] = other?.map((v) => v.toJson()).toList();
    }
    map['updatedAt'] = updatedAt;
    map['wheelchairAssistance'] = wheelchairAssistance;
    map['credit_card_payment'] = creditCardPayment;
    map['health_checkup_pkg'] = healthCheckupPkg;
    map['upi_online'] = upiOnline;
    return map;
  }

}
Other otherFromJson(String str) => Other.fromJson(json.decode(str));
String otherToJson(Other data) => json.encode(data.toJson());
class Other {
  Other({
    this.label,
    this.isActive,
    this.details,
    this.id,});

  Other.fromJson(dynamic json) {
    label = json['label'];
    isActive = json['isActive'];
    details = json['details'];
    id = json['_id'];
  }
  String? label;
  bool? isActive;
  String? details;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['label'] = label;
    map['isActive'] = isActive;
    map['details'] = details;
    map['_id'] = id;
    return map;
  }

}
HealthCamps healthCampsFromJson(String str) => HealthCamps.fromJson(json.decode(str));
String healthCampsToJson(HealthCamps data) => json.encode(data.toJson());
class HealthCamps {
  HealthCamps({
      this.location, 
      this.id, 
      this.sqFoot, 
      this.title, 
      this.description, 
      this.price, 
      this.startDate, 
      this.endDate, 
      this.startTime, 
      this.laboratoryId, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.testDiscounts,});

  HealthCamps.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    id = json['_id'];
    sqFoot = json['sqFoot'];
    title = json['title'];
    description = json['description'];
    price = json['price'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    startTime = json['startTime'];
    laboratoryId = json['laboratoryId'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['testDiscounts'] != null) {
      testDiscounts = [];
      json['testDiscounts'].forEach((v) {
        // testDiscounts?.add(Dynamic.fromJson(v));
      });
    }
  }
  Location? location;
  String? id;
  int? sqFoot;
  String? title;
  String? description;
  int? price;
  String? startDate;
  String? endDate;
  String? startTime;
  String? laboratoryId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<dynamic>? testDiscounts;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['_id'] = id;
    map['sqFoot'] = sqFoot;
    map['title'] = title;
    map['description'] = description;
    map['price'] = price;
    map['startDate'] = startDate;
    map['endDate'] = endDate;
    map['startTime'] = startTime;
    map['laboratoryId'] = laboratoryId;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (testDiscounts != null) {
      map['testDiscounts'] = testDiscounts?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}


Galleries galleriesFromJson(String str) => Galleries.fromJson(json.decode(str));
String galleriesToJson(Galleries data) => json.encode(data.toJson());
class Galleries {
  Galleries({
      this.id, 
      this.laboratoryId, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.imageUrls, 
      this.title, 
      this.updatedAt,});

  Galleries.fromJson(dynamic json) {
    id = json['_id'];
    laboratoryId = json['laboratoryId'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    imageUrls = json['imageUrls'] != null ? json['imageUrls'].cast<String>() : [];
    title = json['title'];
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? laboratoryId;
  String? userId;
  int? v;
  String? createdAt;
  List<String>? imageUrls;
  String? title;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['laboratoryId'] = laboratoryId;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['imageUrls'] = imageUrls;
    map['title'] = title;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

ContactInfo contactInfoFromJson(String str) => ContactInfo.fromJson(json.decode(str));
String contactInfoToJson(ContactInfo data) => json.encode(data.toJson());
class ContactInfo {
  ContactInfo({
      this.location, 
      this.id, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.email, 
      this.laboratoryId, 
      this.name, 
      this.phoneNo, 
      this.updatedAt, 
      this.websiteUrl,});

  ContactInfo.fromJson(dynamic json) {
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    email = json['email'];
    laboratoryId = json['laboratoryId'];
    name = json['name'];
    phoneNo = json['phoneNo'];
    updatedAt = json['updatedAt'];
    websiteUrl = json['websiteUrl'];
  }
  Location? location;
  String? id;
  String? userId;
  int? v;
  String? createdAt;
  String? email;
  String? laboratoryId;
  String? name;
  String? phoneNo;
  String? updatedAt;
  String? websiteUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['_id'] = id;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    map['email'] = email;
    map['laboratoryId'] = laboratoryId;
    map['name'] = name;
    map['phoneNo'] = phoneNo;
    map['updatedAt'] = updatedAt;
    map['websiteUrl'] = websiteUrl;
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

Tests testsFromJson(String str) => Tests.fromJson(json.decode(str));
String testsToJson(Tests data) => json.encode(data.toJson());
class Tests {
  Tests({
      this.source, 
      this.catalogTestId, 
      this.id, 
      this.testName, 
      this.laboratoryId, 
      this.v, 
      this.applicableForChild, 
      this.createdAt, 
      this.customerPrice, 
      this.description, 
      this.estimatedReportHours, 
      this.gender, 
      this.prescriptionRequired, 
      this.specimen, 
      this.specimenCollectionMethod, 
      this.testCategory, 
      this.testFees, 
      this.testParameters, 
      this.updatedAt, 
      this.userId,});

  Tests.fromJson(dynamic json) {
    source = json['source'];
    catalogTestId = json['catalogTestId'];
    id = json['_id'];
    testName = json['testName'];
    laboratoryId = json['laboratoryId'];
    v = json['__v'];
    applicableForChild = json['applicableForChild'];
    createdAt = json['createdAt'];
    customerPrice = json['customerPrice'];
    description = json['description'];
    estimatedReportHours = json['estimatedReportHours'];
    gender = json['gender'];
    prescriptionRequired = json['prescriptionRequired'];
    specimen = json['specimen'];
    specimenCollectionMethod = json['specimenCollectionMethod'];
    testCategory = json['testCategory'] != null ? TestCategory.fromJson(json['testCategory']) : null;
    testFees = json['testFees'];
    if (json['testParameters'] != null) {
      testParameters = [];
      json['testParameters'].forEach((v) {
        testParameters?.add(TestParameters.fromJson(v));
      });
    }
    updatedAt = json['updatedAt'];
    userId = json['userId'];
  }
  String? source;
  dynamic catalogTestId;
  String? id;
  String? testName;
  String? laboratoryId;
  int? v;
  bool? applicableForChild;
  String? createdAt;
  int? customerPrice;
  String? description;
  int? estimatedReportHours;
  String? gender;
  bool? prescriptionRequired;
  String? specimen;
  String? specimenCollectionMethod;
  TestCategory? testCategory;
  int? testFees;
  List<TestParameters>? testParameters;
  String? updatedAt;
  String? userId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['source'] = source;
    map['catalogTestId'] = catalogTestId;
    map['_id'] = id;
    map['testName'] = testName;
    map['laboratoryId'] = laboratoryId;
    map['__v'] = v;
    map['applicableForChild'] = applicableForChild;
    map['createdAt'] = createdAt;
    map['customerPrice'] = customerPrice;
    map['description'] = description;
    map['estimatedReportHours'] = estimatedReportHours;
    map['gender'] = gender;
    map['prescriptionRequired'] = prescriptionRequired;
    map['specimen'] = specimen;
    map['specimenCollectionMethod'] = specimenCollectionMethod;
    if (testCategory != null) {
      map['testCategory'] = testCategory?.toJson();
    }
    map['testFees'] = testFees;
    if (testParameters != null) {
      map['testParameters'] = testParameters?.map((v) => v.toJson()).toList();
    }
    map['updatedAt'] = updatedAt;
    map['userId'] = userId;
    return map;
  }

}

TestParameters testParametersFromJson(String str) => TestParameters.fromJson(json.decode(str));
String testParametersToJson(TestParameters data) => json.encode(data.toJson());
class TestParameters {
  TestParameters({
      this.id, 
      this.name, 
      this.userId, 
      this.laboratoryId, 
      this.unit, 
      this.referenceRange, 
      this.description, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  TestParameters.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    userId = json['userId'];
    laboratoryId = json['laboratoryId'];
    unit = json['unit'];
    referenceRange = json['referenceRange'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? name;
  String? userId;
  String? laboratoryId;
  String? unit;
  String? referenceRange;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['userId'] = userId;
    map['laboratoryId'] = laboratoryId;
    map['unit'] = unit;
    map['referenceRange'] = referenceRange;
    map['description'] = description;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

TestCategory testCategoryFromJson(String str) => TestCategory.fromJson(json.decode(str));
String testCategoryToJson(TestCategory data) => json.encode(data.toJson());
class TestCategory {
  TestCategory({
      this.id, 
      this.name, 
      this.userId, 
      this.laboratoryId, 
      this.description, 
      this.iconUrl, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  TestCategory.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    userId = json['userId'];
    laboratoryId = json['laboratoryId'];
    description = json['description'];
    iconUrl = json['iconUrl'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? name;
  String? userId;
  String? laboratoryId;
  String? description;
  String? iconUrl;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['userId'] = userId;
    map['laboratoryId'] = laboratoryId;
    map['description'] = description;
    map['iconUrl'] = iconUrl;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Profile profileFromJson(String str) => Profile.fromJson(json.decode(str));
String profileToJson(Profile data) => json.encode(data.toJson());
class Profile {
  Profile({
      this.id, 
      this.coverUrl, 
      this.name, 
      this.description, 
      this.logoUrl, 
      this.userId, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Profile.fromJson(dynamic json) {
    id = json['_id'];
    coverUrl = json['coverUrl'];
    logoUrl = json['logoUrl'];
    name = json['name'];
    description = json['description'];
    userId = json['userId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? coverUrl;
  String? logoUrl;
  String? name;
  String? description;
  String? userId;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['coverUrl'] = coverUrl;
    map['logoUrl'] = logoUrl;
    map['name'] = name;
    map['description'] = description;
    map['userId'] = userId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}