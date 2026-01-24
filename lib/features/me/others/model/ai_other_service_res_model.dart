import 'dart:convert';

AiOtherServiceResModel aiOtherServiceResModelFromJson(String str) =>
    AiOtherServiceResModel.fromJson(json.decode(str));

String aiOtherServiceResModelToJson(AiOtherServiceResModel data) =>
    json.encode(data.toJson());

class AiOtherServiceResModel {
  AiOtherServiceResModel({
    this.success,
    this.message,
    this.data,
  });

  AiOtherServiceResModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null
        ? AiOtherServiceResData.fromJson(json['data'])
        : null;
  }

  bool? success;
  String? message;
  AiOtherServiceResData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

AiOtherServiceResData dataFromJson(String str) =>
    AiOtherServiceResData.fromJson(json.decode(str));

String dataToJson(AiOtherServiceResData data) => json.encode(data.toJson());

class AiOtherServiceResData {
  AiOtherServiceResData({
    this.name,
    this.address,
    this.websiteUrl,
    this.rating,
    this.timing,
    this.description,
    this.contactInfo,
    this.aboutUs,
    this.services,
    this.gallery,
    this.privacyPolicy,
    this.termsConditions,
    this.careers,
    this.locationReq,
    this.announcements,
    this.profileName,
  });

  AiOtherServiceResData.fromJson(dynamic json) {
    profileName = json['profileName'];
    name = json['name'];
    address = json['address'];
    websiteUrl = json['websiteUrl'];
    rating = json['rating'];
    timing = json['timing'];
    description = json['description'];
    contactInfo = json['contactInfo'] != null
        ? ContactInfo.fromJson(json['contactInfo'])
        : null;
    aboutUs =
        json['aboutUs'] != null ? AboutUs.fromJson(json['aboutUs']) : null;
    if (json['services'] != null) {
      services = [];
      json['services'].forEach((v) {
        services?.add(Services.fromJson(v));
      });
    }
    gallery = json['gallery'] != null ? json['gallery'].cast<String>() : [];
    privacyPolicy = json['privacyPolicy'];
    termsConditions = json['termsConditions'];
    locationReq = json['location'];
    if (json['careers'] != null) {
      careers = [];
      json['careers'].forEach((v) {
        careers?.add(Careers.fromJson(v));
      });
    }
    if (json['announcements'] != null) {
      announcements = [];
      json['announcements'].forEach((v) {
        announcements?.add(Announcements.fromJson(v));
      });
    }
  }

  String? name;
  String? address;
  String? websiteUrl;
  double? rating;
  String? timing;
  String? description;
  ContactInfo? contactInfo;
  AboutUs? aboutUs;
  List<Services>? services;
  List<String>? gallery;
  String? privacyPolicy;
  String? termsConditions;
  List<Careers>? careers;
  List<Announcements>? announcements;
  dynamic locationReq;
  dynamic profileName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['location'] = locationReq;

    map['name'] = name;
    map['profileName'] = profileName;
    map['address'] = address;
    map['websiteUrl'] = websiteUrl;
    map['rating'] = rating;
    map['timing'] = timing;
    map['description'] = description;
    if (contactInfo != null) {
      map['contactInfo'] = contactInfo?.toJson();
    }
    if (aboutUs != null) {
      map['aboutUs'] = aboutUs?.toJson();
    }
    if (services != null) {
      map['services'] = services?.map((v) => v.toJson()).toList();
    }
    map['gallery'] = gallery;
    map['privacyPolicy'] = privacyPolicy;
    map['termsConditions'] = termsConditions;
    if (careers != null) {
      map['careers'] = careers?.map((v) => v.toJson()).toList();
    }
    if (announcements != null) {
      map['announcements'] = announcements?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

Announcements announcementsFromJson(String str) =>
    Announcements.fromJson(json.decode(str));

String announcementsToJson(Announcements data) => json.encode(data.toJson());

class Announcements {
  Announcements({
    this.title,
    this.date,
    this.content,
  });

  Announcements.fromJson(dynamic json) {
    title = json['title'];
    date = json['date'];
    content = json['content'];
  }

  String? title;
  String? date;
  String? content;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['date'] = date;
    map['content'] = content;
    return map;
  }
}

Careers careersFromJson(String str) => Careers.fromJson(json.decode(str));

String careersToJson(Careers data) => json.encode(data.toJson());

class Careers {
  Careers({
    this.title,
    this.type,
    this.description,
  });

  Careers.fromJson(dynamic json) {
    title = json['title'];
    type = json['type'];
    description = json['description'];
  }

  String? title;
  String? type;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['type'] = type;
    map['description'] = description;
    return map;
  }
}

Services servicesFromJson(String str) => Services.fromJson(json.decode(str));

String servicesToJson(Services data) => json.encode(data.toJson());

class Services {
  Services({
    this.title,
    this.price,
    this.description,
  });

  Services.fromJson(dynamic json) {
    title = json['title'];
    price = json['price'];
    description = json['description'];
  }

  String? title;
  String? price;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['price'] = price;
    map['description'] = description;
    return map;
  }
}

AboutUs aboutUsFromJson(String str) => AboutUs.fromJson(json.decode(str));

String aboutUsToJson(AboutUs data) => json.encode(data.toJson());

class AboutUs {
  AboutUs({
    this.organisation,
    this.management,
    this.staffs,
    this.officeFacility,
  });

  AboutUs.fromJson(dynamic json) {
    organisation = json['organisation'];
    if (json['management'] != null) {
      management = [];
      json['management'].forEach((v) {
        management?.add(Management.fromJson(v));
      });
    }
    if (json['staffs'] != null) {
      staffs = [];
      json['staffs'].forEach((v) {
        staffs?.add(Staffs.fromJson(v));
      });
    }
    officeFacility = json['officeFacility'] != null
        ? json['officeFacility'].cast<String>()
        : [];
  }

  String? organisation;
  List<Management>? management;
  List<Staffs>? staffs;
  List<String>? officeFacility;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['organisation'] = organisation;
    if (management != null) {
      map['management'] = management?.map((v) => v.toJson()).toList();
    }
    if (staffs != null) {
      map['staffs'] = staffs?.map((v) => v.toJson()).toList();
    }
    map['officeFacility'] = officeFacility;
    return map;
  }
}

Staffs staffsFromJson(String str) => Staffs.fromJson(json.decode(str));

String staffsToJson(Staffs data) => json.encode(data.toJson());

class Staffs {
  Staffs({
    this.name,
    this.role,
  });

  Staffs.fromJson(dynamic json) {
    name = json['name'];
    role = json['role'];
  }

  String? name;
  String? role;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['role'] = role;
    return map;
  }
}

Management managementFromJson(String str) =>
    Management.fromJson(json.decode(str));

String managementToJson(Management data) => json.encode(data.toJson());

class Management {
  Management({
    this.name,
    this.designation,
    this.bio,
  });

  Management.fromJson(dynamic json) {
    name = json['name'];
    designation = json['designation'];
    bio = json['bio'];
  }

  String? name;
  String? designation;
  String? bio;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['designation'] = designation;
    map['bio'] = bio;
    return map;
  }
}

ContactInfo contactInfoFromJson(String str) =>
    ContactInfo.fromJson(json.decode(str));

String contactInfoToJson(ContactInfo data) => json.encode(data.toJson());

class ContactInfo {
  ContactInfo({
    this.phone,
    this.email,
  });

  ContactInfo.fromJson(dynamic json) {
    phone = json['phone'];
    email = json['email'];
  }

  String? phone;
  String? email;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phone'] = phone;
    map['email'] = email;
    return map;
  }
}
