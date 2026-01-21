class HospitalHomePageDetailsModel {
  HospitalInfoModel? hospitalInfo;
  List<DoctorModel>? doctors;
  List<IpdModel>? ipd;
  List<EmergencyModel>? emergency;
  List<OtherServiceModel>? otherServices;
  AboutUsModel? aboutUs;
  List<String>? gallery;
  List<TestimonialModel>? testimonials;
  ContactUsModel? contactUs;

  HospitalHomePageDetailsModel({
    this.hospitalInfo,
    this.doctors,
    this.ipd,
    this.emergency,
    this.otherServices,
    this.aboutUs,
    this.gallery,
    this.testimonials,
    this.contactUs,
  });

  factory HospitalHomePageDetailsModel.fromJson(Map<String, dynamic> json) {
    return HospitalHomePageDetailsModel(
      hospitalInfo: json['hospitalInfo'] != null
          ? HospitalInfoModel.fromJson(json['hospitalInfo'])
          : null,
      doctors: (json['doctors'] as List?)
          ?.map((e) => DoctorModel.fromJson(e))
          .toList(),
      ipd: (json['ipd'] as List?)
          ?.map((e) => IpdModel.fromJson(e))
          .toList(),
      emergency: (json['emergency'] as List?)
          ?.map((e) => EmergencyModel.fromJson(e))
          .toList(),
      otherServices: (json['otherServices'] as List?)
          ?.map((e) => OtherServiceModel.fromJson(e))
          .toList(),
      aboutUs: json['aboutUs'] != null
          ? AboutUsModel.fromJson(json['aboutUs'])
          : null,
      gallery: (json['gallery'] as List?)?.cast<String>(),
      testimonials: (json['testimonials'] as List?)
          ?.map((e) => TestimonialModel.fromJson(e))
          .toList(),
      contactUs: json['contactUs'] != null
          ? ContactUsModel.fromJson(json['contactUs'])
          : null,
    );
  }
}
class HospitalInfoModel {
  String? name;
  String? tagline;
  String? coverImage;
  String? logo;

  HospitalInfoModel({this.name, this.tagline, this.coverImage, this.logo});

  factory HospitalInfoModel.fromJson(Map<String, dynamic> json) {
    return HospitalInfoModel(
      name: json['name'],
      tagline: json['tagline'],
      coverImage: json['coverImage'],
      logo: json['logo'],
    );
  }
}
class DoctorModel {
  String? id;
  String? name;
  String? photo;
  String? specialization;
  String? departmentName;
  String? availability;

  DoctorModel({
    this.id,
    this.name,
    this.photo,
    this.specialization,
    this.departmentName,
    this.availability,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['_id'],
      name: json['name'],
      photo: json['photo'],
      specialization: json['specialization'],
      departmentName: json['departmentName'],
      availability: json['availability'],
    );
  }
}
class IpdModel {
  String? id;
  String? name;
  String? type;
  String? photo;
  int? totalBeds;
  int? availableBeds;
  int? fees;

  IpdModel({
    this.id,
    this.name,
    this.type,
    this.totalBeds,
    this.photo,
    this.availableBeds,
    this.fees,
  });

  factory IpdModel.fromJson(Map<String, dynamic> json) {
    return IpdModel(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      photo: json['photo'],
      totalBeds: json['totalBeds'],
      availableBeds: json['availableBeds'],
      fees: json['fees'],
    );
  }
}
class EmergencyModel {
  String? id;
  String? name;
  String? type;
  String? description;

  EmergencyModel({this.id, this.name, this.type, this.description});

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
    );
  }
}
class OtherServiceModel {
  String? id;
  String? name;
  String? type;
  String? description;

  OtherServiceModel({this.id, this.name, this.type, this.description});

  factory OtherServiceModel.fromJson(Map<String, dynamic> json) {
    return OtherServiceModel(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
    );
  }
}
class AboutUsModel {
  String? visionMission;
  String? history;
  List<ManagementModel>? management;
  String? hospitalImage;

  AboutUsModel({
    this.visionMission,
    this.history,
    this.management,
    this.hospitalImage,
  });

  factory AboutUsModel.fromJson(Map<String, dynamic> json) {
    return AboutUsModel(
      visionMission: json['visionMission'],
      history: json['history'],
      hospitalImage: json['hospitalImage'],
      management: (json['management'] as List?)
          ?.map((e) => ManagementModel.fromJson(e))
          .toList(),
    );
  }
}
class ManagementModel {
  String? name;
  String? designation;
  String? photo;

  ManagementModel({this.name, this.designation, this.photo});

  factory ManagementModel.fromJson(Map<String, dynamic> json) {
    return ManagementModel(
      name: json['name'],
      designation: json['designation'],
      photo: json['photo'],
    );
  }
}
class TestimonialModel {
  String? id;
  String? name;
  String? image;
  int? rating;
  String? message;
  String? designation;

  TestimonialModel({
    this.id,
    this.name,
    this.image,
    this.rating,
    this.message,
    this.designation,
  });

  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    return TestimonialModel(
      id: json['_id'],
      name: json['name'],
      image: json['image'],
      rating: json['rating'],
      message: json['message'],
      designation: json['designation'],
    );
  }
}
class ContactUsModel {
  String? hospitalName;
  String? address;
  String? email;
  String? phone;
  String? emergencyPhone;
  String? website;

  ContactUsModel({
    this.hospitalName,
    this.address,
    this.email,
    this.phone,
    this.emergencyPhone,
    this.website,
  });

  factory ContactUsModel.fromJson(Map<String, dynamic> json) {
    return ContactUsModel(
      hospitalName: json['hospitalName'],
      address: json['address'],
      email: json['email'],
      phone: json['phone'],
      emergencyPhone: json['emergencyPhone'],
      website: json['website'],
    );
  }
}
