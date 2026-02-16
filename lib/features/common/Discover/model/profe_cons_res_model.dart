import 'dart:convert';

import 'package:BlueEra/features/me/professionals_consultant/model/professional_profile_res_model.dart';
ProfessionalConsResModel profeConsResModelFromJson(String str) => ProfessionalConsResModel.fromJson(json.decode(str));
String profeConsResModelToJson(ProfessionalConsResModel data) => json.encode(data.toJson());
class ProfessionalConsResModel {
  ProfessionalConsResModel({
      this.success, 
      this.data, 
      this.meta,});

  ProfessionalConsResModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(ProfessionalConsData.fromJson(v));
      });
    }
    meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }
  bool? success;
  List<ProfessionalConsData>? data;
  Meta? meta;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (meta != null) {
      map['meta'] = meta?.toJson();
    }
    return map;
  }

}

Meta metaFromJson(String str) => Meta.fromJson(json.decode(str));
String metaToJson(Meta data) => json.encode(data.toJson());
class Meta {
  Meta({
      this.total, 
      this.page, 
      this.limit,});

  Meta.fromJson(dynamic json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
  }
  int? total;
  int? page;
  int? limit;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total'] = total;
    map['page'] = page;
    map['limit'] = limit;
    return map;
  }

}

ProfessionalConsData dataFromJson(String str) => ProfessionalConsData.fromJson(json.decode(str));
String dataToJson(ProfessionalConsData data) => json.encode(data.toJson());
class ProfessionalConsData {
  ProfessionalConsData({
      this.id, 
      this.userId, 
      this.basicDetails, 
      this.about, 
      this.pricing, 
      this.isActive, 
      this.isDeleted, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.userDetails, 
      this.gallery, 
      this.timings, 
      this.contact, 
      this.certificates, 
      this.portfolio,});

  ProfessionalConsData.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    basicDetails = json['basicDetails'] != null ? BasicDetails.fromJson(json['basicDetails']) : null;
    about = json['about'] != null ? About.fromJson(json['about']) : null;
    pricing = json['pricing'] != null ? Pricing.fromJson(json['pricing']) : null;
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    userDetails = json['userDetails'] != null ? UserDetails.fromJson(json['userDetails']) : null;
    gallery = json['gallery'] != null ? Gallery.fromJson(json['gallery']) : null;
    timings = json['timings'] != null ? Timings.fromJson(json['timings']) : null;
    contact = json['contact'] != null ? Contact.fromJson(json['contact']) : null;
    if (json['certificates'] != null) {
      certificates = [];
      json['certificates'].forEach((v) {
        certificates?.add(Certificates.fromJson(v));
      });
    }
    if (json['portfolio'] != null) {
      portfolio = [];
      json['portfolio'].forEach((v) {
        portfolio?.add(ProfessionalPortfolio.fromJson(v));
      });
    }
  }
  String? id;
  String? userId;
  BasicDetails? basicDetails;
  About? about;
  Pricing? pricing;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? v;
  UserDetails? userDetails;
  Gallery? gallery;
  Timings? timings;
  Contact? contact;
  List<Certificates>? certificates;
  List<ProfessionalPortfolio>? portfolio;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    if (basicDetails != null) {
      map['basicDetails'] = basicDetails?.toJson();
    }
    if (about != null) {
      map['about'] = about?.toJson();
    }
    if (pricing != null) {
      map['pricing'] = pricing?.toJson();
    }
    map['isActive'] = isActive;
    map['isDeleted'] = isDeleted;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (userDetails != null) {
      map['userDetails'] = userDetails?.toJson();
    }
    if (gallery != null) {
      map['gallery'] = gallery?.toJson();
    }
    if (timings != null) {
      map['timings'] = timings?.toJson();
    }
    if (contact != null) {
      map['contact'] = contact?.toJson();
    }
    if (certificates != null) {
      map['certificates'] = certificates?.map((v) => v.toJson()).toList();
    }
    if (portfolio != null) {
      map['portfolio'] = portfolio?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Portfolio portfolioFromJson(String str) => Portfolio.fromJson(json.decode(str));
String portfolioToJson(Portfolio data) => json.encode(data.toJson());
class Portfolio {
  Portfolio({
      this.id, 
      this.userId, 
      this.projectTitle, 
      this.category, 
      this.completionDate, 
      this.description, 
      this.mediaKeys, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.media,});

  Portfolio.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    projectTitle = json['projectTitle'];
    category = json['category'];
    completionDate = json['completionDate'];
    description = json['description'];
    if (json['mediaKeys'] != null) {
      mediaKeys = [];
      json['mediaKeys'].forEach((v) {
        mediaKeys?.add(MediaKeys.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    if (json['media'] != null) {
      media = [];
      json['media'].forEach((v) {
        media?.add(Media.fromJson(v));
      });
    }
  }
  String? id;
  String? userId;
  String? projectTitle;
  String? category;
  String? completionDate;
  String? description;
  List<MediaKeys>? mediaKeys;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<Media>? media;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['projectTitle'] = projectTitle;
    map['category'] = category;
    map['completionDate'] = completionDate;
    map['description'] = description;
    if (mediaKeys != null) {
      map['mediaKeys'] = mediaKeys?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    if (media != null) {
      map['media'] = media?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Media mediaFromJson(String str) => Media.fromJson(json.decode(str));
String mediaToJson(Media data) => json.encode(data.toJson());
class Media {
  Media({
      this.type, 
      this.url,});

  Media.fromJson(dynamic json) {
    type = json['type'];
    url = json['url'];
  }
  String? type;
  String? url;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['url'] = url;
    return map;
  }

}

MediaKeys mediaKeysFromJson(String str) => MediaKeys.fromJson(json.decode(str));
String mediaKeysToJson(MediaKeys data) => json.encode(data.toJson());
class MediaKeys {
  MediaKeys({
      this.key, 
      this.type, 
      this.id,});

  MediaKeys.fromJson(dynamic json) {
    key = json['key'];
    type = json['type'];
    id = json['_id'];
  }
  String? key;
  String? type;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['key'] = key;
    map['type'] = type;
    map['_id'] = id;
    return map;
  }

}

Certificates certificatesFromJson(String str) => Certificates.fromJson(json.decode(str));
String certificatesToJson(Certificates data) => json.encode(data.toJson());
class Certificates {
  Certificates({
      this.id, 
      this.userId, 
      this.title, 
      this.documentType, 
      this.issuedBy, 
      this.issueDate, 
      this.fileKey, 
      this.description, 
      this.createdAt, 
      this.updatedAt, 
      this.v,});

  Certificates.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    title = json['title'];
    documentType = json['documentType'];
    issuedBy = json['issuedBy'];
    issueDate = json['issueDate'];
    fileKey = json['fileUrl'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }
  String? id;
  String? userId;
  String? title;
  String? documentType;
  String? issuedBy;
  String? issueDate;
  String? fileKey;
  String? description;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['title'] = title;
    map['documentType'] = documentType;
    map['issuedBy'] = issuedBy;
    map['issueDate'] = issueDate;
    map['fileUrl'] = fileKey;
    map['description'] = description;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }

}

Contact contactFromJson(String str) => Contact.fromJson(json.decode(str));
String contactToJson(Contact data) => json.encode(data.toJson());
class Contact {
  Contact({
      this.id, 
      this.userId, 
      this.v, 
      this.address, 
      this.contactPerson, 
      this.createdAt, 
      this.email, 
      this.location, 
      this.phone, 
      this.updatedAt, 
      this.website,});

  Contact.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    address = json['address'];
    contactPerson = json['contactPerson'];
    createdAt = json['createdAt'];
    email = json['email'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    phone = json['phone'];
    updatedAt = json['updatedAt'];
    website = json['website'];
  }
  String? id;
  String? userId;
  int? v;
  String? address;
  String? contactPerson;
  String? createdAt;
  String? email;
  Location? location;
  String? phone;
  String? updatedAt;
  String? website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['__v'] = v;
    map['address'] = address;
    map['contactPerson'] = contactPerson;
    map['createdAt'] = createdAt;
    map['email'] = email;
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['phone'] = phone;
    map['updatedAt'] = updatedAt;
    map['website'] = website;
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
/*
Timings timingsFromJson(String str) => Timings.fromJson(json.decode(str));
String timingsToJson(Timings data) => json.encode(data.toJson());
class Timings {
  Timings({
      this.id, 
      this.userId, 
      this.v, 
      this.createdAt, 
      this.schedule, 
      this.updatedAt,});

  Timings.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    schedule = json['schedule'] != null ? Schedule.fromJson(json['schedule']) : null;
    updatedAt = json['updatedAt'];
  }
  String? id;
  String? userId;
  int? v;
  String? createdAt;
  Schedule? schedule;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['__v'] = v;
    map['createdAt'] = createdAt;
    if (schedule != null) {
      map['schedule'] = schedule?.toJson();
    }
    map['updatedAt'] = updatedAt;
    return map;
  }

}*/

Schedule scheduleFromJson(String str) => Schedule.fromJson(json.decode(str));
String scheduleToJson(Schedule data) => json.encode(data.toJson());
class Schedule {
  Schedule({
      this.monday, 
      this.tuesday, 
      this.wednesday, 
      this.thursday, 
      this.friday, 
      this.saturday, 
      this.sunday,});

  Schedule.fromJson(dynamic json) {
    monday = json['monday'] != null ? Monday.fromJson(json['monday']) : null;
    tuesday = json['tuesday'] != null ? Tuesday.fromJson(json['tuesday']) : null;
    wednesday = json['wednesday'] != null ? Wednesday.fromJson(json['wednesday']) : null;
    thursday = json['thursday'] != null ? Thursday.fromJson(json['thursday']) : null;
    friday = json['friday'] != null ? Friday.fromJson(json['friday']) : null;
    saturday = json['saturday'] != null ? Saturday.fromJson(json['saturday']) : null;
    sunday = json['sunday'] != null ? Sunday.fromJson(json['sunday']) : null;
  }
  Monday? monday;
  Tuesday? tuesday;
  Wednesday? wednesday;
  Thursday? thursday;
  Friday? friday;
  Saturday? saturday;
  Sunday? sunday;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (monday != null) {
      map['monday'] = monday?.toJson();
    }
    if (tuesday != null) {
      map['tuesday'] = tuesday?.toJson();
    }
    if (wednesday != null) {
      map['wednesday'] = wednesday?.toJson();
    }
    if (thursday != null) {
      map['thursday'] = thursday?.toJson();
    }
    if (friday != null) {
      map['friday'] = friday?.toJson();
    }
    if (saturday != null) {
      map['saturday'] = saturday?.toJson();
    }
    if (sunday != null) {
      map['sunday'] = sunday?.toJson();
    }
    return map;
  }

}

Sunday sundayFromJson(String str) => Sunday.fromJson(json.decode(str));
String sundayToJson(Sunday data) => json.encode(data.toJson());
class Sunday {
  Sunday({
      this.isOpen, 
      this.openTime, 
      this.closeTime,});

  Sunday.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['openTime'] = openTime;
    map['closeTime'] = closeTime;
    return map;
  }

}

Saturday saturdayFromJson(String str) => Saturday.fromJson(json.decode(str));
String saturdayToJson(Saturday data) => json.encode(data.toJson());
class Saturday {
  Saturday({
      this.isOpen, 
      this.openTime, 
      this.closeTime,});

  Saturday.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['openTime'] = openTime;
    map['closeTime'] = closeTime;
    return map;
  }

}

Friday fridayFromJson(String str) => Friday.fromJson(json.decode(str));
String fridayToJson(Friday data) => json.encode(data.toJson());
class Friday {
  Friday({
      this.isOpen, 
      this.openTime, 
      this.closeTime,});

  Friday.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['openTime'] = openTime;
    map['closeTime'] = closeTime;
    return map;
  }

}

Thursday thursdayFromJson(String str) => Thursday.fromJson(json.decode(str));
String thursdayToJson(Thursday data) => json.encode(data.toJson());
class Thursday {
  Thursday({
      this.isOpen, 
      this.openTime, 
      this.closeTime,});

  Thursday.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['openTime'] = openTime;
    map['closeTime'] = closeTime;
    return map;
  }

}

Wednesday wednesdayFromJson(String str) => Wednesday.fromJson(json.decode(str));
String wednesdayToJson(Wednesday data) => json.encode(data.toJson());
class Wednesday {
  Wednesday({
      this.isOpen, 
      this.openTime, 
      this.closeTime,});

  Wednesday.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['openTime'] = openTime;
    map['closeTime'] = closeTime;
    return map;
  }

}

Tuesday tuesdayFromJson(String str) => Tuesday.fromJson(json.decode(str));
String tuesdayToJson(Tuesday data) => json.encode(data.toJson());
class Tuesday {
  Tuesday({
      this.isOpen, 
      this.openTime, 
      this.closeTime,});

  Tuesday.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['openTime'] = openTime;
    map['closeTime'] = closeTime;
    return map;
  }

}

Monday mondayFromJson(String str) => Monday.fromJson(json.decode(str));
String mondayToJson(Monday data) => json.encode(data.toJson());
class Monday {
  Monday({
      this.isOpen, 
      this.openTime, 
      this.closeTime,});

  Monday.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    openTime = json['openTime'];
    closeTime = json['closeTime'];
  }
  bool? isOpen;
  String? openTime;
  String? closeTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['openTime'] = openTime;
    map['closeTime'] = closeTime;
    return map;
  }

}

Gallery galleryFromJson(String str) => Gallery.fromJson(json.decode(str));
String galleryToJson(Gallery data) => json.encode(data.toJson());
class Gallery {
  Gallery({
      this.id, 
      this.userId, 
      this.title, 
      this.imageKeys, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.signedUrls,});

  Gallery.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    title = json['title'];
    imageKeys = json['imageKeys'] != null ? json['imageKeys'].cast<String>() : [];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    signedUrls = json['signedUrls'] != null ? json['signedUrls'].cast<String>() : [];
  }
  String? id;
  String? userId;
  String? title;
  List<String>? imageKeys;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<String>? signedUrls;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['title'] = title;
    map['imageKeys'] = imageKeys;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['signedUrls'] = signedUrls;
    return map;
  }

}

UserDetails userDetailsFromJson(String str) => UserDetails.fromJson(json.decode(str));
String userDetailsToJson(UserDetails data) => json.encode(data.toJson());
class UserDetails {
  UserDetails({
      this.skills, 
      this.projects, 
      this.experiences, 
      this.id, 
      this.name, 
      this.gender, 
      this.pre, 
      this.contactNo, 
      this.profession, 
      this.designation, 
      this.profileImage, 
      this.isEnded, 
      this.username, 
      this.dateOfBirth, 
      this.deletedAt, 
      this.accountType, 
      this.language, 
      this.referralPoints, 
      this.referralCode, 
      this.referredBy, 
      this.deviceToken, 
      this.lastSeen, 
      this.location, 
      this.email, 
      this.highestEducation, 
      this.role, 
      this.password, 
      this.currentOrganisation, 
      this.bio, 
      this.address, 
      this.introVideo, 
      this.socialLinks, 
      this.createdAt, 
      this.updatedAt, 
      this.specialization, 
      this.department, 
      this.subDivision, 
      this.art, 
      this.schoolOrCollegeName, 
      this.sector, 
      this.qrUrl, 
      this.userLocation, 
      this.emailVerified, 
      this.objective,});

  UserDetails.fromJson(dynamic json) {
    if (json['skills'] != null) {
      skills = [];
      json['skills'].forEach((v) {
        // skills?.add(Dynamic.fromJson(v));
      });
    }
    if (json['projects'] != null) {
      projects = [];
      json['projects'].forEach((v) {
        // projects?.add(Dynamic.fromJson(v));
      });
    }
    if (json['experiences'] != null) {
      experiences = [];
      json['experiences'].forEach((v) {
        // experiences?.add(Dynamic.fromJson(v));
      });
    }
    id = json['id'];
    name = json['name'];
    gender = json['gender'];
    pre = json['pre'];
    contactNo = json['contact_no'];
    profession = json['profession'];
    designation = json['designation'];
    profileImage = json['profile_image'];
    isEnded = json['is_ended'];
    username = json['username'];
    dateOfBirth = json['date_of_birth'] != null ? DateOfBirth.fromJson(json['date_of_birth']) : null;
    deletedAt = json['deleted_at'];
    accountType = json['account_type'];
    language = json['language'];
    referralPoints = json['referral_points'];
    referralCode = json['referral_code'];
    referredBy = json['referred_by'];
    deviceToken = json['device_token'];
    lastSeen = json['last_seen'];
    location = json['location'];
    email = json['email'];
    highestEducation = json['highest_education'];
    role = json['role'];
    password = json['password'];
    currentOrganisation = json['current_organisation'];
    bio = json['bio'];
    address = json['address'];
    introVideo = json['introVideo'];
    socialLinks = json['social_links'] != null ? SocialLinks.fromJson(json['social_links']) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    specialization = json['specialization'];
    department = json['department'];
    subDivision = json['sub_division'];
    art = json['art'];
    schoolOrCollegeName = json['school_or_college_name'];
    sector = json['sector'];
    qrUrl = json['qr_url'];
    userLocation = json['user_location'] != null ? UserLocation.fromJson(json['user_location']) : null;
    emailVerified = json['email_verified'];
    objective = json['objective'];
  }
  List<dynamic>? skills;
  List<dynamic>? projects;
  List<dynamic>? experiences;
  String? id;
  String? name;
  String? gender;
  String? pre;
  String? contactNo;
  String? profession;
  String? designation;
  String? profileImage;
  bool? isEnded;
  String? username;
  DateOfBirth? dateOfBirth;
  String? deletedAt;
  String? accountType;
  String? language;
  int? referralPoints;
  String? referralCode;
  String? referredBy;
  String? deviceToken;
  String? lastSeen;
  String? location;
  String? email;
  String? highestEducation;
  String? role;
  String? password;
  String? currentOrganisation;
  String? bio;
  String? address;
  String? introVideo;
  SocialLinks? socialLinks;
  String? createdAt;
  String? updatedAt;
  String? specialization;
  String? department;
  String? subDivision;
  dynamic art;
  String? schoolOrCollegeName;
  String? sector;
  String? qrUrl;
  UserLocation? userLocation;
  bool? emailVerified;
  String? objective;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (skills != null) {
      map['skills'] = skills?.map((v) => v.toJson()).toList();
    }
    if (projects != null) {
      map['projects'] = projects?.map((v) => v.toJson()).toList();
    }
    if (experiences != null) {
      map['experiences'] = experiences?.map((v) => v.toJson()).toList();
    }
    map['id'] = id;
    map['name'] = name;
    map['gender'] = gender;
    map['pre'] = pre;
    map['contact_no'] = contactNo;
    map['profession'] = profession;
    map['designation'] = designation;
    map['profile_image'] = profileImage;
    map['is_ended'] = isEnded;
    map['username'] = username;
    if (dateOfBirth != null) {
      map['date_of_birth'] = dateOfBirth?.toJson();
    }
    map['deleted_at'] = deletedAt;
    map['account_type'] = accountType;
    map['language'] = language;
    map['referral_points'] = referralPoints;
    map['referral_code'] = referralCode;
    map['referred_by'] = referredBy;
    map['device_token'] = deviceToken;
    map['last_seen'] = lastSeen;
    map['location'] = location;
    map['email'] = email;
    map['highest_education'] = highestEducation;
    map['role'] = role;
    map['password'] = password;
    map['current_organisation'] = currentOrganisation;
    map['bio'] = bio;
    map['address'] = address;
    map['introVideo'] = introVideo;
    if (socialLinks != null) {
      map['social_links'] = socialLinks?.toJson();
    }
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['specialization'] = specialization;
    map['department'] = department;
    map['sub_division'] = subDivision;
    map['art'] = art;
    map['school_or_college_name'] = schoolOrCollegeName;
    map['sector'] = sector;
    map['qr_url'] = qrUrl;
    if (userLocation != null) {
      map['user_location'] = userLocation?.toJson();
    }
    map['email_verified'] = emailVerified;
    map['objective'] = objective;
    return map;
  }

}

UserLocation userLocationFromJson(String str) => UserLocation.fromJson(json.decode(str));
String userLocationToJson(UserLocation data) => json.encode(data.toJson());
class UserLocation {
  UserLocation({
      this.lat, 
      this.lon,});

  UserLocation.fromJson(dynamic json) {
    lat = json['lat'];
    lon = json['lon'];
  }
  var lat;
  var lon;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['lat'] = lat;
    map['lon'] = lon;
    return map;
  }

}

SocialLinks socialLinksFromJson(String str) => SocialLinks.fromJson(json.decode(str));
String socialLinksToJson(SocialLinks data) => json.encode(data.toJson());
class SocialLinks {
  SocialLinks({
      this.youtube, 
      this.twitter, 
      this.linkedin, 
      this.instagram, 
      this.website,});

  SocialLinks.fromJson(dynamic json) {
    youtube = json['youtube'];
    twitter = json['twitter'];
    linkedin = json['linkedin'];
    instagram = json['instagram'];
    website = json['website'];
  }
  String? youtube;
  String? twitter;
  String? linkedin;
  String? instagram;
  String? website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['youtube'] = youtube;
    map['twitter'] = twitter;
    map['linkedin'] = linkedin;
    map['instagram'] = instagram;
    map['website'] = website;
    return map;
  }

}

DateOfBirth dateOfBirthFromJson(String str) => DateOfBirth.fromJson(json.decode(str));
String dateOfBirthToJson(DateOfBirth data) => json.encode(data.toJson());
class DateOfBirth {
  DateOfBirth({
      this.date, 
      this.month, 
      this.year,});

  DateOfBirth.fromJson(dynamic json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
  }
  int? date;
  int? month;
  int? year;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['date'] = date;
    map['month'] = month;
    map['year'] = year;
    return map;
  }

}

Pricing pricingFromJson(String str) => Pricing.fromJson(json.decode(str));
String pricingToJson(Pricing data) => json.encode(data.toJson());
class Pricing {
  Pricing({
      this.type, 
      this.amount, 
      this.currency, 
      this.consultationMode,});

  Pricing.fromJson(dynamic json) {
    type = json['type'];
    amount = json['amount'];
    currency = json['currency'];
    consultationMode = json['consultationMode'];
  }
  String? type;
  int? amount;
  String? currency;
  String? consultationMode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['amount'] = amount;
    map['currency'] = currency;
    map['consultationMode'] = consultationMode;
    return map;
  }

}

About aboutFromJson(String str) => About.fromJson(json.decode(str));
String aboutToJson(About data) => json.encode(data.toJson());
class About {
  About({
      this.totalExperience, 
      this.description, 
      this.majorProjectsDescription,});

  About.fromJson(dynamic json) {
    totalExperience = json['totalExperience'] != null ? TotalExperience.fromJson(json['totalExperience']) : null;
    description = json['description'];
    majorProjectsDescription = json['majorProjectsDescription'];
  }
  TotalExperience? totalExperience;
  String? description;
  String? majorProjectsDescription;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (totalExperience != null) {
      map['totalExperience'] = totalExperience?.toJson();
    }
    map['description'] = description;
    map['majorProjectsDescription'] = majorProjectsDescription;
    return map;
  }

}

TotalExperience totalExperienceFromJson(String str) => TotalExperience.fromJson(json.decode(str));
String totalExperienceToJson(TotalExperience data) => json.encode(data.toJson());
class TotalExperience {
  TotalExperience({
      this.years, 
      this.months,});

  TotalExperience.fromJson(dynamic json) {
    years = json['years'];
    months = json['months'];
  }
  int? years;
  int? months;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['years'] = years;
    map['months'] = months;
    return map;
  }

}

BasicDetails basicDetailsFromJson(String str) => BasicDetails.fromJson(json.decode(str));
String basicDetailsToJson(BasicDetails data) => json.encode(data.toJson());
class BasicDetails {
  BasicDetails({
      this.languagesSpoken, 
      this.professionalTitle, 
      this.shortTagline, 
      this.fullName, 
      this.location, 
      this.profilePhotoKey, 
      this.profilePhotoUrl,});

  BasicDetails.fromJson(dynamic json) {
    languagesSpoken = json['languagesSpoken'] != null ? json['languagesSpoken'].cast<String>() : [];
    professionalTitle = json['professionalTitle'];
    shortTagline = json['shortTagline'];
    fullName = json['fullName'];
    location = json['location'];
    profilePhotoKey = json['profilePhotoKey'];
    profilePhotoUrl = json['profilePhotoUrl'];
  }
  List<String>? languagesSpoken;
  String? professionalTitle;
  String? shortTagline;
  String? fullName;
  String? location;
  String? profilePhotoKey;
  String? profilePhotoUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['languagesSpoken'] = languagesSpoken;
    map['professionalTitle'] = professionalTitle;
    map['shortTagline'] = shortTagline;
    map['fullName'] = fullName;
    map['location'] = location;
    map['profilePhotoKey'] = profilePhotoKey;
    map['profilePhotoUrl'] = profilePhotoUrl;
    return map;
  }

}