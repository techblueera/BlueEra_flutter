// ================= ROOT MODEL =================

class HospitalPreviewResponse {
  bool? success;
  HospitalData? data;

  HospitalPreviewResponse({this.success, this.data});

  factory HospitalPreviewResponse.fromJson(Map<String, dynamic> json) {
    return HospitalPreviewResponse(
      success: json['success'],
      data: json['data'] != null
          ? HospitalData.fromJson(json['data'])
          : null,
    );
  }
}

// ================= MAIN DATA =================

class HospitalData {
  Map<String, OpdDepartment>? opdDepartments;
  AboutUs? aboutUs;
  Map<String, IpdWard>? ipdWards;
  EmergencyCare? emergencyCare;
  List<DiagnosticService>? diagnostics;
  MedicalStore? medicalStore;
  List<Career>? careers;
  ContactUs? contactUs;
  OtherFacilities? otherFacilities;

  HospitalData({
    this.opdDepartments,
    this.aboutUs,
    this.ipdWards,
    this.emergencyCare,
    this.diagnostics,
    this.medicalStore,
    this.careers,
    this.contactUs,
    this.otherFacilities,
  });

  factory HospitalData.fromJson(Map<String, dynamic> json) {
    return HospitalData(
      opdDepartments: json['OPT_OUTPATIENT_DEPARTMENT'] != null
          ? (json['OPT_OUTPATIENT_DEPARTMENT'] as Map<String, dynamic>)
          .map((k, v) =>
          MapEntry(k, OpdDepartment.fromJson(v)))
          : null,
      aboutUs: json['ABOUT_US'] != null
          ? AboutUs.fromJson(json['ABOUT_US'])
          : null,
      ipdWards: json['IPD_INPATIENT_DEPARTMENT'] != null
          ? (json['IPD_INPATIENT_DEPARTMENT'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, IpdWard.fromJson(v)))
          : null,
      emergencyCare: json['EMERGENCY_AND_CRITICAL_CARE'] != null
          ? EmergencyCare.fromJson(json['EMERGENCY_AND_CRITICAL_CARE'])
          : null,
      diagnostics: json['DIAGNOSTIC_DEPARTMENTS']?['services'] != null
          ? (json['DIAGNOSTIC_DEPARTMENTS']['services'] as List)
          .map((e) => DiagnosticService.fromJson(e))
          .toList()
          : null,
      medicalStore: json['MEDICAL_STORE'] != null
          ? MedicalStore.fromJson(json['MEDICAL_STORE'])
          : null,
      careers: json['CAREER'] != null
          ? (json['CAREER'] as List)
          .map((e) => Career.fromJson(e))
          .toList()
          : null,
      contactUs: json['CONTACT_US'] != null
          ? ContactUs.fromJson(json['CONTACT_US'])
          : null,
      otherFacilities: json['OTHER_FACILITIES'] != null
          ? OtherFacilities.fromJson(json['OTHER_FACILITIES'])
          : null,
    );
  }
}

// ================= OPD =================

class OpdDepartment {
  String? description;
  List<String>? doctors;
  String? timing;

  OpdDepartment({this.description, this.doctors, this.timing});

  factory OpdDepartment.fromJson(Map<String, dynamic> json) {
    return OpdDepartment(
      description: json['description'],
      doctors:
      json['doctors'] != null ? List<String>.from(json['doctors']) : null,
      timing: json['timing'],
    );
  }
}

// ================= ABOUT =================

class AboutUs {
  String? history;
  String? missionVision;
  List<TeamMember>? team;

  AboutUs({this.history, this.missionVision, this.team});

  factory AboutUs.fromJson(Map<String, dynamic> json) {
    return AboutUs(
      history: json['HISTORY'],
      missionVision: json['MISSION_AND_VISION'],
      team: json['TEAM'] != null
          ? (json['TEAM'] as List)
          .map((e) => TeamMember.fromJson(e))
          .toList()
          : null,
    );
  }
}

class TeamMember {
  String? name;
  String? designation;
  String? photo;

  TeamMember({this.name, this.designation, this.photo});

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'],
      designation: json['designation'],
      photo: json['photo'],
    );
  }
}

// ================= IPD =================

class IpdWard {
  String? bedCount;
  String? charges;
  List<String>? features;

  IpdWard({this.bedCount, this.charges, this.features});

  factory IpdWard.fromJson(Map<String, dynamic> json) {
    return IpdWard(
      bedCount: json['bedCount'],
      charges: json['charges'],
      features:
      json['features'] != null ? List<String>.from(json['features']) : null,
    );
  }
}

// ================= EMERGENCY =================

class EmergencyCare {
  SimpleDescription? emergency;
  SimpleDescription? icu;
  SimpleDescription? ccu;
  SimpleDescription? nicu;
  SimpleDescription? trauma;
  SimpleDescription? picu;

  EmergencyCare({
    this.emergency,
    this.icu,
    this.ccu,
    this.nicu,
    this.trauma,
    this.picu,
  });

  factory EmergencyCare.fromJson(Map<String, dynamic> json) {
    return EmergencyCare(
      emergency: json['EMERGENTCY_CASUALTY'] != null
          ? SimpleDescription.fromJson(json['EMERGENTCY_CASUALTY'])
          : null,
      icu: json['ICU_INTENSIVE_CARE_UNIT'] != null
          ? SimpleDescription.fromJson(json['ICU_INTENSIVE_CARE_UNIT'])
          : null,
      ccu: json['CCU_CRITICAL_CARE_UNIT'] != null
          ? SimpleDescription.fromJson(json['CCU_CRITICAL_CARE_UNIT'])
          : null,
      nicu: json['NICU_NEONATAL_INTENSIVE_CARE_UNIT'] != null
          ? SimpleDescription.fromJson(
          json['NICU_NEONATAL_INTENSIVE_CARE_UNIT'])
          : null,
      trauma: json['TRAUMA_CARE'] != null
          ? SimpleDescription.fromJson(json['TRAUMA_CARE'])
          : null,
      picu: json['PICU_PEDIATRIC_INTENSIVE_CARE_UNIT'] != null
          ? SimpleDescription.fromJson(
          json['PICU_PEDIATRIC_INTENSIVE_CARE_UNIT'])
          : null,
    );
  }
}

class SimpleDescription {
  String? description;

  SimpleDescription({this.description});

  factory SimpleDescription.fromJson(Map<String, dynamic> json) {
    return SimpleDescription(description: json['description']);
  }
}

// ================= DIAGNOSTICS =================

class DiagnosticService {
  String? name;
  String? description;
  String? timing;

  DiagnosticService({this.name, this.description, this.timing});

  factory DiagnosticService.fromJson(Map<String, dynamic> json) {
    return DiagnosticService(
      name: json['name'],
      description: json['description'],
      timing: json['timing'],
    );
  }
}

// ================= MEDICAL STORE =================

class MedicalStore {
  String? availability;
  String? contact;
  String? location;

  MedicalStore({this.availability, this.contact, this.location});

  factory MedicalStore.fromJson(Map<String, dynamic> json) {
    return MedicalStore(
      availability: json['availability'],
      contact: json['contact'],
      location: json['location'],
    );
  }
}

// ================= CAREER =================

class Career {
  String? position;
  String? department;
  String? qualification;

  Career({this.position, this.department, this.qualification});

  factory Career.fromJson(Map<String, dynamic> json) {
    return Career(
      position: json['position'],
      department: json['department'],
      qualification: json['qualification'],
    );
  }
}

// ================= CONTACT =================

class ContactUs {
  String? address;
  String? email;
  String? phone;
  String? emergencyPhone;
  String? website;

  ContactUs({
    this.address,
    this.email,
    this.phone,
    this.emergencyPhone,
    this.website,
  });

  factory ContactUs.fromJson(Map<String, dynamic> json) {
    return ContactUs(
      address: json['address'],
      email: json['email'],
      phone: json['phone'],
      emergencyPhone: json['emergencyPhone'],
      website: json['website'],
    );
  }
}

// ================= OTHER FACILITIES =================

class OtherFacilities {
  SimpleDescription? insurance;
  SimpleDescription? ambulance;
  SimpleDescription? pmjay;
  SimpleDescription? bloodBank;

  OtherFacilities({
    this.insurance,
    this.ambulance,
    this.pmjay,
    this.bloodBank,
  });

  factory OtherFacilities.fromJson(Map<String, dynamic> json) {
    return OtherFacilities(
      insurance: json['CASH_LESS_INSURANCE'] != null
          ? SimpleDescription.fromJson(json['CASH_LESS_INSURANCE'])
          : null,
      ambulance: json['AMBULANCE'] != null
          ? SimpleDescription.fromJson(json['AMBULANCE'])
          : null,
      pmjay: json['PM_SWASTHYA_BIMA_YOJANA'] != null
          ? SimpleDescription.fromJson(
          json['PM_SWASTHYA_BIMA_YOJANA'])
          : null,
      bloodBank: json['BLOOD_BANK'] != null
          ? SimpleDescription.fromJson(json['BLOOD_BANK'])
          : null,
    );
  }
}
