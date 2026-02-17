import 'dart:convert';
HospitalAiDetailsResModel hospitalAiDetailsResModelFromJson(String str) => HospitalAiDetailsResModel.fromJson(json.decode(str));
String hospitalAiDetailsResModelToJson(HospitalAiDetailsResModel data) => json.encode(data.toJson());
class HospitalAiDetailsResModel {
  HospitalAiDetailsResModel({
      this.success, 
      this.data,});

  HospitalAiDetailsResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? HospitalAiData.fromJson(json['data']) : null;
  }
  bool? success;
  HospitalAiData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

HospitalAiData dataFromJson(String str) => HospitalAiData.fromJson(json.decode(str));
String dataToJson(HospitalAiData data) => json.encode(data.toJson());
class HospitalAiData {
  HospitalAiData({
      this.optoutpatientdepartment, 
      this.aboutus, 
      this.ipdinpatientdepartment, 
      this.emergencyandcriticalcare, 
      this.diagnosticdepartments, 
      this.medicalstore, 
      this.career, 
      this.contactus, 
      this.otherfacilities,});

  HospitalAiData.fromJson(dynamic json) {
    optoutpatientdepartment = json['OPT_OUTPATIENT_DEPARTMENT'] != null ? OptOutpatientDepartment.fromJson(json['OPT_OUTPATIENT_DEPARTMENT']) : null;
    aboutus = json['ABOUT_US'] != null ? HospitalAboutUs.fromJson(json['ABOUT_US']) : null;
    ipdinpatientdepartment = json['IPD_INPATIENT_DEPARTMENT'] != null ? IpdInpatientDepartment.fromJson(json['IPD_INPATIENT_DEPARTMENT']) : null;
    emergencyandcriticalcare = json['EMERGENCY_AND_CRITICAL_CARE'] != null ? EmergencyAndCriticalCare.fromJson(json['EMERGENCY_AND_CRITICAL_CARE']) : null;
    diagnosticdepartments = json['DIAGNOSTIC_DEPARTMENTS'] != null ? DiagnosticDepartments.fromJson(json['DIAGNOSTIC_DEPARTMENTS']) : null;
    medicalstore = json['MEDICAL_STORE'] != null ? MedicalStore.fromJson(json['MEDICAL_STORE']) : null;
    if (json['CAREER'] != null) {
      career = [];
      json['CAREER'].forEach((v) {
        career?.add(Career.fromJson(v));
      });
    }
    contactus = json['CONTACT_US'] != null ? ContactUs.fromJson(json['CONTACT_US']) : null;
    otherfacilities = json['OTHER_FACILITIES'] != null ? OtherFacilities.fromJson(json['OTHER_FACILITIES']) : null;
  }
  OptOutpatientDepartment? optoutpatientdepartment;
  HospitalAboutUs? aboutus;
  IpdInpatientDepartment? ipdinpatientdepartment;
  EmergencyAndCriticalCare? emergencyandcriticalcare;
  DiagnosticDepartments? diagnosticdepartments;
  MedicalStore? medicalstore;
  List<Career>? career;
  ContactUs? contactus;
  OtherFacilities? otherfacilities;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (optoutpatientdepartment != null) {
      map['OPT_OUTPATIENT_DEPARTMENT'] = optoutpatientdepartment?.toJson();
    }
    if (aboutus != null) {
      map['ABOUT_US'] = aboutus?.toJson();
    }
    if (ipdinpatientdepartment != null) {
      map['IPD_INPATIENT_DEPARTMENT'] = ipdinpatientdepartment?.toJson();
    }
    if (emergencyandcriticalcare != null) {
      map['EMERGENCY_AND_CRITICAL_CARE'] = emergencyandcriticalcare?.toJson();
    }
    if (diagnosticdepartments != null) {
      map['DIAGNOSTIC_DEPARTMENTS'] = diagnosticdepartments?.toJson();
    }
    if (medicalstore != null) {
      map['MEDICAL_STORE'] = medicalstore?.toJson();
    }
    if (career != null) {
      map['CAREER'] = career?.map((v) => v.toJson()).toList();
    }
    if (contactus != null) {
      map['CONTACT_US'] = contactus?.toJson();
    }
    if (otherfacilities != null) {
      map['OTHER_FACILITIES'] = otherfacilities?.toJson();
    }
    return map;
  }

}

OtherFacilities otherFacilitiesFromJson(String str) => OtherFacilities.fromJson(json.decode(str));
String otherFacilitiesToJson(OtherFacilities data) => json.encode(data.toJson());
class OtherFacilities {
  OtherFacilities({
      this.cashlessinsurance, 
      this.ambulance, 
      this.pmswasthyabimayojana, 
      this.bloodbank,});

  OtherFacilities.fromJson(dynamic json) {
    cashlessinsurance = json['CASH_LESS_INSURANCE'] != null ? CashLessInsurance.fromJson(json['CASH_LESS_INSURANCE']) : null;
    ambulance = json['AMBULANCE'] != null ? Ambulance.fromJson(json['AMBULANCE']) : null;
    pmswasthyabimayojana = json['PM_SWASTHYA_BIMA_YOJANA'] != null ? PmSwasthyaBimaYojana.fromJson(json['PM_SWASTHYA_BIMA_YOJANA']) : null;
    bloodbank = json['BLOOD_BANK'] != null ? BloodBank.fromJson(json['BLOOD_BANK']) : null;
  }
  CashLessInsurance? cashlessinsurance;
  Ambulance? ambulance;
  PmSwasthyaBimaYojana? pmswasthyabimayojana;
  BloodBank? bloodbank;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (cashlessinsurance != null) {
      map['CASH_LESS_INSURANCE'] = cashlessinsurance?.toJson();
    }
    if (ambulance != null) {
      map['AMBULANCE'] = ambulance?.toJson();
    }
    if (pmswasthyabimayojana != null) {
      map['PM_SWASTHYA_BIMA_YOJANA'] = pmswasthyabimayojana?.toJson();
    }
    if (bloodbank != null) {
      map['BLOOD_BANK'] = bloodbank?.toJson();
    }
    return map;
  }

}

BloodBank bloodBankFromJson(String str) => BloodBank.fromJson(json.decode(str));
String bloodBankToJson(BloodBank data) => json.encode(data.toJson());
class BloodBank {
  BloodBank({
      this.description,});

  BloodBank.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

PmSwasthyaBimaYojana pmSwasthyaBimaYojanaFromJson(String str) => PmSwasthyaBimaYojana.fromJson(json.decode(str));
String pmSwasthyaBimaYojanaToJson(PmSwasthyaBimaYojana data) => json.encode(data.toJson());
class PmSwasthyaBimaYojana {
  PmSwasthyaBimaYojana({
      this.description,});

  PmSwasthyaBimaYojana.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

Ambulance ambulanceFromJson(String str) => Ambulance.fromJson(json.decode(str));
String ambulanceToJson(Ambulance data) => json.encode(data.toJson());
class Ambulance {
  Ambulance({
      this.description,});

  Ambulance.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

CashLessInsurance cashLessInsuranceFromJson(String str) => CashLessInsurance.fromJson(json.decode(str));
String cashLessInsuranceToJson(CashLessInsurance data) => json.encode(data.toJson());
class CashLessInsurance {
  CashLessInsurance({
      this.description,});

  CashLessInsurance.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

ContactUs contactUsFromJson(String str) => ContactUs.fromJson(json.decode(str));
String contactUsToJson(ContactUs data) => json.encode(data.toJson());
class ContactUs {
  ContactUs({
      this.address, 
      this.email, 
      this.phone, 
      this.emergencyPhone, 
      this.website, 
      this.location,});

  ContactUs.fromJson(dynamic json) {
    address = json['address'];
    email = json['email'];
    phone = json['phone'];
    emergencyPhone = json['emergencyPhone'];
    website = json['website'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
  }
  String? address;
  String? email;
  String? phone;
  String? emergencyPhone;
  String? website;
  Location? location;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['address'] = address;
    map['email'] = email;
    map['phone'] = phone;
    map['emergencyPhone'] = emergencyPhone;
    map['website'] = website;
    if (location != null) {
      map['location'] = location?.toJson();
    }
    return map;
  }

}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));
String locationToJson(Location data) => json.encode(data.toJson());
class Location {
  Location({
      this.type, 
      this.coordinates,});

  Location.fromJson(dynamic json) {
    type = json['type'];
    coordinates = json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
  }
  String? type;
  List<double>? coordinates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['coordinates'] = coordinates;
    return map;
  }

}

Career careerFromJson(String str) => Career.fromJson(json.decode(str));
String careerToJson(Career data) => json.encode(data.toJson());
class Career {
  Career({
      this.position, 
      this.department, 
      this.qualification,});

  Career.fromJson(dynamic json) {
    position = json['position'];
    department = json['department'];
    qualification = json['qualification'];
  }
  String? position;
  String? department;
  String? qualification;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['position'] = position;
    map['department'] = department;
    map['qualification'] = qualification;
    return map;
  }

}

MedicalStore medicalStoreFromJson(String str) => MedicalStore.fromJson(json.decode(str));
String medicalStoreToJson(MedicalStore data) => json.encode(data.toJson());
class MedicalStore {
  MedicalStore({
      this.availability, 
      this.contact, 
      this.location,});

  MedicalStore.fromJson(dynamic json) {
    availability = json['availability'];
    contact = json['contact'];
    location = json['location'];
  }
  String? availability;
  String? contact;
  String? location;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['availability'] = availability;
    map['contact'] = contact;
    map['location'] = location;
    return map;
  }

}

DiagnosticDepartments diagnosticDepartmentsFromJson(String str) => DiagnosticDepartments.fromJson(json.decode(str));
String diagnosticDepartmentsToJson(DiagnosticDepartments data) => json.encode(data.toJson());
class DiagnosticDepartments {
  DiagnosticDepartments({
      this.services,});

  DiagnosticDepartments.fromJson(dynamic json) {
    if (json['services'] != null) {
      services = [];
      json['services'].forEach((v) {
        services?.add(Services.fromJson(v));
      });
    }
  }
  List<Services>? services;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (services != null) {
      map['services'] = services?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Services servicesFromJson(String str) => Services.fromJson(json.decode(str));
String servicesToJson(Services data) => json.encode(data.toJson());
class Services {
  Services({
      this.name, 
      this.description, 
      this.timing,});

  Services.fromJson(dynamic json) {
    name = json['name'];
    description = json['description'];
    timing = json['timing'];
  }
  String? name;
  String? description;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['description'] = description;
    map['timing'] = timing;
    return map;
  }

}

EmergencyAndCriticalCare emergencyAndCriticalCareFromJson(String str) => EmergencyAndCriticalCare.fromJson(json.decode(str));
String emergencyAndCriticalCareToJson(EmergencyAndCriticalCare data) => json.encode(data.toJson());
class EmergencyAndCriticalCare {
  EmergencyAndCriticalCare({
      this.emergentcycasualty, 
      this.icuintensivecareunit, 
      this.ccucriticalcareunit, 
      this.nicuneonatalintensivecareunit, 
      this.traumacare, 
      this.picupediatricintensivecareunit,});

  EmergencyAndCriticalCare.fromJson(dynamic json) {
    emergentcycasualty = json['EMERGENTCY_CASUALTY'] != null ? EmergentcyCasualty.fromJson(json['EMERGENTCY_CASUALTY']) : null;
    icuintensivecareunit = json['ICU_INTENSIVE_CARE_UNIT'] != null ? IcuIntensiveCareUnit.fromJson(json['ICU_INTENSIVE_CARE_UNIT']) : null;
    ccucriticalcareunit = json['CCU_CRITICAL_CARE_UNIT'] != null ? CcuCriticalCareUnit.fromJson(json['CCU_CRITICAL_CARE_UNIT']) : null;
    nicuneonatalintensivecareunit = json['NICU_NEONATAL_INTENSIVE_CARE_UNIT'] != null ? NicuNeonatalIntensiveCareUnit.fromJson(json['NICU_NEONATAL_INTENSIVE_CARE_UNIT']) : null;
    traumacare = json['TRAUMA_CARE'] != null ? TraumaCare.fromJson(json['TRAUMA_CARE']) : null;
    picupediatricintensivecareunit = json['PICU_PEDIATRIC_INTENSIVE_CARE_UNIT'] != null ? PicuPediatricIntensiveCareUnit.fromJson(json['PICU_PEDIATRIC_INTENSIVE_CARE_UNIT']) : null;
  }
  EmergentcyCasualty? emergentcycasualty;
  IcuIntensiveCareUnit? icuintensivecareunit;
  CcuCriticalCareUnit? ccucriticalcareunit;
  NicuNeonatalIntensiveCareUnit? nicuneonatalintensivecareunit;
  TraumaCare? traumacare;
  PicuPediatricIntensiveCareUnit? picupediatricintensivecareunit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (emergentcycasualty != null) {
      map['EMERGENTCY_CASUALTY'] = emergentcycasualty?.toJson();
    }
    if (icuintensivecareunit != null) {
      map['ICU_INTENSIVE_CARE_UNIT'] = icuintensivecareunit?.toJson();
    }
    if (ccucriticalcareunit != null) {
      map['CCU_CRITICAL_CARE_UNIT'] = ccucriticalcareunit?.toJson();
    }
    if (nicuneonatalintensivecareunit != null) {
      map['NICU_NEONATAL_INTENSIVE_CARE_UNIT'] = nicuneonatalintensivecareunit?.toJson();
    }
    if (traumacare != null) {
      map['TRAUMA_CARE'] = traumacare?.toJson();
    }
    if (picupediatricintensivecareunit != null) {
      map['PICU_PEDIATRIC_INTENSIVE_CARE_UNIT'] = picupediatricintensivecareunit?.toJson();
    }
    return map;
  }

}

PicuPediatricIntensiveCareUnit picuPediatricIntensiveCareUnitFromJson(String str) => PicuPediatricIntensiveCareUnit.fromJson(json.decode(str));
String picuPediatricIntensiveCareUnitToJson(PicuPediatricIntensiveCareUnit data) => json.encode(data.toJson());
class PicuPediatricIntensiveCareUnit {
  PicuPediatricIntensiveCareUnit({
      this.description,});

  PicuPediatricIntensiveCareUnit.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

TraumaCare traumaCareFromJson(String str) => TraumaCare.fromJson(json.decode(str));
String traumaCareToJson(TraumaCare data) => json.encode(data.toJson());
class TraumaCare {
  TraumaCare({
      this.description,});

  TraumaCare.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

NicuNeonatalIntensiveCareUnit nicuNeonatalIntensiveCareUnitFromJson(String str) => NicuNeonatalIntensiveCareUnit.fromJson(json.decode(str));
String nicuNeonatalIntensiveCareUnitToJson(NicuNeonatalIntensiveCareUnit data) => json.encode(data.toJson());
class NicuNeonatalIntensiveCareUnit {
  NicuNeonatalIntensiveCareUnit({
      this.description,});

  NicuNeonatalIntensiveCareUnit.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

CcuCriticalCareUnit ccuCriticalCareUnitFromJson(String str) => CcuCriticalCareUnit.fromJson(json.decode(str));
String ccuCriticalCareUnitToJson(CcuCriticalCareUnit data) => json.encode(data.toJson());
class CcuCriticalCareUnit {
  CcuCriticalCareUnit({
      this.description,});

  CcuCriticalCareUnit.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

IcuIntensiveCareUnit icuIntensiveCareUnitFromJson(String str) => IcuIntensiveCareUnit.fromJson(json.decode(str));
String icuIntensiveCareUnitToJson(IcuIntensiveCareUnit data) => json.encode(data.toJson());
class IcuIntensiveCareUnit {
  IcuIntensiveCareUnit({
      this.description,});

  IcuIntensiveCareUnit.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

EmergentcyCasualty emergentcyCasualtyFromJson(String str) => EmergentcyCasualty.fromJson(json.decode(str));
String emergentcyCasualtyToJson(EmergentcyCasualty data) => json.encode(data.toJson());
class EmergentcyCasualty {
  EmergentcyCasualty({
      this.description,});

  EmergentcyCasualty.fromJson(dynamic json) {
    description = json['description'];
  }
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    return map;
  }

}

IpdInpatientDepartment ipdInpatientDepartmentFromJson(String str) => IpdInpatientDepartment.fromJson(json.decode(str));
String ipdInpatientDepartmentToJson(IpdInpatientDepartment data) => json.encode(data.toJson());
class IpdInpatientDepartment {
  IpdInpatientDepartment({
      this.generalward, 
      this.semiprivateward, 
      this.privateward, 
      this.isolationward, 
      this.pedriatricward, 
      this.maternityward,});

  IpdInpatientDepartment.fromJson(dynamic json) {
    generalward = json['GENERAL_WARD'] != null ? GeneralWard.fromJson(json['GENERAL_WARD']) : null;
    semiprivateward = json['SEMI_PRIVATE_WARD'] != null ? SemiPrivateWard.fromJson(json['SEMI_PRIVATE_WARD']) : null;
    privateward = json['PRIVATE_WARD'] != null ? PrivateWard.fromJson(json['PRIVATE_WARD']) : null;
    isolationward = json['ISOLATION_WARD'] != null ? IsolationWard.fromJson(json['ISOLATION_WARD']) : null;
    pedriatricward = json['PEDRIATRIC_WARD'] != null ? PedriatricWard.fromJson(json['PEDRIATRIC_WARD']) : null;
    maternityward = json['MATERNITY_WARD'] != null ? MaternityWard.fromJson(json['MATERNITY_WARD']) : null;
  }
  GeneralWard? generalward;
  SemiPrivateWard? semiprivateward;
  PrivateWard? privateward;
  IsolationWard? isolationward;
  PedriatricWard? pedriatricward;
  MaternityWard? maternityward;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (generalward != null) {
      map['GENERAL_WARD'] = generalward?.toJson();
    }
    if (semiprivateward != null) {
      map['SEMI_PRIVATE_WARD'] = semiprivateward?.toJson();
    }
    if (privateward != null) {
      map['PRIVATE_WARD'] = privateward?.toJson();
    }
    if (isolationward != null) {
      map['ISOLATION_WARD'] = isolationward?.toJson();
    }
    if (pedriatricward != null) {
      map['PEDRIATRIC_WARD'] = pedriatricward?.toJson();
    }
    if (maternityward != null) {
      map['MATERNITY_WARD'] = maternityward?.toJson();
    }
    return map;
  }

}

MaternityWard maternityWardFromJson(String str) => MaternityWard.fromJson(json.decode(str));
String maternityWardToJson(MaternityWard data) => json.encode(data.toJson());
class MaternityWard {
  MaternityWard({
      this.bedCount, 
      this.charges, 
      this.features,});

  MaternityWard.fromJson(dynamic json) {
    bedCount = json['bedCount'];
    charges = json['charges'];
    features = json['features'] != null ? json['features'].cast<String>() : [];
  }
  String? bedCount;
  String? charges;
  List<String>? features;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bedCount'] = bedCount;
    map['charges'] = charges;
    map['features'] = features;
    return map;
  }

}

PedriatricWard pedriatricWardFromJson(String str) => PedriatricWard.fromJson(json.decode(str));
String pedriatricWardToJson(PedriatricWard data) => json.encode(data.toJson());
class PedriatricWard {
  PedriatricWard({
      this.bedCount, 
      this.charges, 
      this.features,});

  PedriatricWard.fromJson(dynamic json) {
    bedCount = json['bedCount'];
    charges = json['charges'];
    features = json['features'] != null ? json['features'].cast<String>() : [];
  }
  String? bedCount;
  String? charges;
  List<String>? features;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bedCount'] = bedCount;
    map['charges'] = charges;
    map['features'] = features;
    return map;
  }

}

IsolationWard isolationWardFromJson(String str) => IsolationWard.fromJson(json.decode(str));
String isolationWardToJson(IsolationWard data) => json.encode(data.toJson());
class IsolationWard {
  IsolationWard({
      this.bedCount, 
      this.charges, 
      this.features,});

  IsolationWard.fromJson(dynamic json) {
    bedCount = json['bedCount'];
    charges = json['charges'];
    features = json['features'] != null ? json['features'].cast<String>() : [];
  }
  String? bedCount;
  String? charges;
  List<String>? features;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bedCount'] = bedCount;
    map['charges'] = charges;
    map['features'] = features;
    return map;
  }

}

PrivateWard privateWardFromJson(String str) => PrivateWard.fromJson(json.decode(str));
String privateWardToJson(PrivateWard data) => json.encode(data.toJson());
class PrivateWard {
  PrivateWard({
      this.bedCount, 
      this.charges, 
      this.features,});

  PrivateWard.fromJson(dynamic json) {
    bedCount = json['bedCount'];
    charges = json['charges'];
    features = json['features'] != null ? json['features'].cast<String>() : [];
  }
  String? bedCount;
  String? charges;
  List<String>? features;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bedCount'] = bedCount;
    map['charges'] = charges;
    map['features'] = features;
    return map;
  }

}

SemiPrivateWard semiPrivateWardFromJson(String str) => SemiPrivateWard.fromJson(json.decode(str));
String semiPrivateWardToJson(SemiPrivateWard data) => json.encode(data.toJson());
class SemiPrivateWard {
  SemiPrivateWard({
      this.bedCount, 
      this.charges, 
      this.features,});

  SemiPrivateWard.fromJson(dynamic json) {
    bedCount = json['bedCount'];
    charges = json['charges'];
    features = json['features'] != null ? json['features'].cast<String>() : [];
  }
  String? bedCount;
  String? charges;
  List<String>? features;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bedCount'] = bedCount;
    map['charges'] = charges;
    map['features'] = features;
    return map;
  }

}

GeneralWard generalWardFromJson(String str) => GeneralWard.fromJson(json.decode(str));
String generalWardToJson(GeneralWard data) => json.encode(data.toJson());
class GeneralWard {
  GeneralWard({
      this.bedCount, 
      this.charges, 
      this.features,});

  GeneralWard.fromJson(dynamic json) {
    bedCount = json['bedCount'];
    charges = json['charges'];
    features = json['features'] != null ? json['features'].cast<String>() : [];
  }
  String? bedCount;
  String? charges;
  List<String>? features;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bedCount'] = bedCount;
    map['charges'] = charges;
    map['features'] = features;
    return map;
  }

}

HospitalAboutUs aboutUsFromJson(String str) => HospitalAboutUs.fromJson(json.decode(str));
String aboutUsToJson(HospitalAboutUs data) => json.encode(data.toJson());
class HospitalAboutUs {
  HospitalAboutUs({
      this.history, 
      this.missionandvision, 
      this.team,});

  HospitalAboutUs.fromJson(dynamic json) {
    history = json['HISTORY'];
    missionandvision = json['MISSION_AND_VISION'];
    if (json['TEAM'] != null) {
      team = [];
      json['TEAM'].forEach((v) {
        team?.add(Team.fromJson(v));
      });
    }
  }
  String? history;
  String? missionandvision;
  List<Team>? team;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['HISTORY'] = history;
    map['MISSION_AND_VISION'] = missionandvision;
    if (team != null) {
      map['TEAM'] = team?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Team teamFromJson(String str) => Team.fromJson(json.decode(str));
String teamToJson(Team data) => json.encode(data.toJson());
class Team {
  Team({
      this.name, 
      this.designation, 
      this.photo,});

  Team.fromJson(dynamic json) {
    name = json['name'];
    designation = json['designation'];
    photo = json['photo'];
  }
  String? name;
  String? designation;
  String? photo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['designation'] = designation;
    map['photo'] = photo;
    return map;
  }

}

OptOutpatientDepartment optOutpatientDepartmentFromJson(String str) => OptOutpatientDepartment.fromJson(json.decode(str));
String optOutpatientDepartmentToJson(OptOutpatientDepartment data) => json.encode(data.toJson());
class OptOutpatientDepartment {
  OptOutpatientDepartment({
      this.generalmedicine, 
      this.generalsurgery, 
      this.orthopedics, 
      this.obstetricsandgynecology, 
      this.pediatrics, 
      this.entearnosethroat, 
      this.ophthalmologyeye, 
      this.dermatology, 
      this.psychiatry, 
      this.dentalopd,});

  OptOutpatientDepartment.fromJson(dynamic json) {
    generalmedicine = json['GENERAL_MEDICINE'] != null ? GeneralMedicine.fromJson(json['GENERAL_MEDICINE']) : null;
    generalsurgery = json['GENERAL_SURGERY'] != null ? GeneralSurgery.fromJson(json['GENERAL_SURGERY']) : null;
    orthopedics = json['ORTHOPEDICS'] != null ? Orthopedics.fromJson(json['ORTHOPEDICS']) : null;
    obstetricsandgynecology = json['OBSTETRICS_AND_GYNECOLOGY'] != null ? ObstetricsAndGynecology.fromJson(json['OBSTETRICS_AND_GYNECOLOGY']) : null;
    pediatrics = json['PEDIATRICS'] != null ? Pediatrics.fromJson(json['PEDIATRICS']) : null;
    entearnosethroat = json['ENT_EAR_NOSE_THROAT'] != null ? EntEarNoseThroat.fromJson(json['ENT_EAR_NOSE_THROAT']) : null;
    ophthalmologyeye = json['OPHTHALMOLOGY_EYE'] != null ? OphthalmologyEye.fromJson(json['OPHTHALMOLOGY_EYE']) : null;
    dermatology = json['DERMATOLOGY'] != null ? Dermatology.fromJson(json['DERMATOLOGY']) : null;
    psychiatry = json['PSYCHIATRY'] != null ? Psychiatry.fromJson(json['PSYCHIATRY']) : null;
    dentalopd = json['DENTAL_OPD'] != null ? DentalOpd.fromJson(json['DENTAL_OPD']) : null;
  }
  GeneralMedicine? generalmedicine;
  GeneralSurgery? generalsurgery;
  Orthopedics? orthopedics;
  ObstetricsAndGynecology? obstetricsandgynecology;
  Pediatrics? pediatrics;
  EntEarNoseThroat? entearnosethroat;
  OphthalmologyEye? ophthalmologyeye;
  Dermatology? dermatology;
  Psychiatry? psychiatry;
  DentalOpd? dentalopd;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (generalmedicine != null) {
      map['GENERAL_MEDICINE'] = generalmedicine?.toJson();
    }
    if (generalsurgery != null) {
      map['GENERAL_SURGERY'] = generalsurgery?.toJson();
    }
    if (orthopedics != null) {
      map['ORTHOPEDICS'] = orthopedics?.toJson();
    }
    if (obstetricsandgynecology != null) {
      map['OBSTETRICS_AND_GYNECOLOGY'] = obstetricsandgynecology?.toJson();
    }
    if (pediatrics != null) {
      map['PEDIATRICS'] = pediatrics?.toJson();
    }
    if (entearnosethroat != null) {
      map['ENT_EAR_NOSE_THROAT'] = entearnosethroat?.toJson();
    }
    if (ophthalmologyeye != null) {
      map['OPHTHALMOLOGY_EYE'] = ophthalmologyeye?.toJson();
    }
    if (dermatology != null) {
      map['DERMATOLOGY'] = dermatology?.toJson();
    }
    if (psychiatry != null) {
      map['PSYCHIATRY'] = psychiatry?.toJson();
    }
    if (dentalopd != null) {
      map['DENTAL_OPD'] = dentalopd?.toJson();
    }
    return map;
  }

}

DentalOpd dentalOpdFromJson(String str) => DentalOpd.fromJson(json.decode(str));
String dentalOpdToJson(DentalOpd data) => json.encode(data.toJson());
class DentalOpd {
  DentalOpd({
      this.description, 
      this.doctors, 
      this.timing,});

  DentalOpd.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

Psychiatry psychiatryFromJson(String str) => Psychiatry.fromJson(json.decode(str));
String psychiatryToJson(Psychiatry data) => json.encode(data.toJson());
class Psychiatry {
  Psychiatry({
      this.description, 
      this.doctors, 
      this.timing,});

  Psychiatry.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

Dermatology dermatologyFromJson(String str) => Dermatology.fromJson(json.decode(str));
String dermatologyToJson(Dermatology data) => json.encode(data.toJson());
class Dermatology {
  Dermatology({
      this.description, 
      this.doctors, 
      this.timing,});

  Dermatology.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

OphthalmologyEye ophthalmologyEyeFromJson(String str) => OphthalmologyEye.fromJson(json.decode(str));
String ophthalmologyEyeToJson(OphthalmologyEye data) => json.encode(data.toJson());
class OphthalmologyEye {
  OphthalmologyEye({
      this.description, 
      this.doctors, 
      this.timing,});

  OphthalmologyEye.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

EntEarNoseThroat entEarNoseThroatFromJson(String str) => EntEarNoseThroat.fromJson(json.decode(str));
String entEarNoseThroatToJson(EntEarNoseThroat data) => json.encode(data.toJson());
class EntEarNoseThroat {
  EntEarNoseThroat({
      this.description, 
      this.doctors, 
      this.timing,});

  EntEarNoseThroat.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

Pediatrics pediatricsFromJson(String str) => Pediatrics.fromJson(json.decode(str));
String pediatricsToJson(Pediatrics data) => json.encode(data.toJson());
class Pediatrics {
  Pediatrics({
      this.description, 
      this.doctors, 
      this.timing,});

  Pediatrics.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

ObstetricsAndGynecology obstetricsAndGynecologyFromJson(String str) => ObstetricsAndGynecology.fromJson(json.decode(str));
String obstetricsAndGynecologyToJson(ObstetricsAndGynecology data) => json.encode(data.toJson());
class ObstetricsAndGynecology {
  ObstetricsAndGynecology({
      this.description, 
      this.doctors, 
      this.timing,});

  ObstetricsAndGynecology.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

Orthopedics orthopedicsFromJson(String str) => Orthopedics.fromJson(json.decode(str));
String orthopedicsToJson(Orthopedics data) => json.encode(data.toJson());
class Orthopedics {
  Orthopedics({
      this.description, 
      this.doctors, 
      this.timing,});

  Orthopedics.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

GeneralSurgery generalSurgeryFromJson(String str) => GeneralSurgery.fromJson(json.decode(str));
String generalSurgeryToJson(GeneralSurgery data) => json.encode(data.toJson());
class GeneralSurgery {
  GeneralSurgery({
      this.description, 
      this.doctors, 
      this.timing,});

  GeneralSurgery.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}

GeneralMedicine generalMedicineFromJson(String str) => GeneralMedicine.fromJson(json.decode(str));
String generalMedicineToJson(GeneralMedicine data) => json.encode(data.toJson());
class GeneralMedicine {
  GeneralMedicine({
      this.description, 
      this.doctors, 
      this.timing,});

  GeneralMedicine.fromJson(dynamic json) {
    description = json['description'];
    doctors = json['doctors'] != null ? json['doctors'].cast<String>() : [];
    timing = json['timing'];
  }
  String? description;
  List<String>? doctors;
  String? timing;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['description'] = description;
    map['doctors'] = doctors;
    map['timing'] = timing;
    return map;
  }

}