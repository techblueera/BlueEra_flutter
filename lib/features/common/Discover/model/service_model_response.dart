class ServiceModelResponse {
  List<Services>? services;
  List<String>? professions;

  ServiceModelResponse({this.services, this.professions});

  ServiceModelResponse.fromJson(Map<String, dynamic> json) {
    if (json['services'] != null) {
      services = <Services>[];
      json['services'].forEach((v) {
        services!.add(new Services.fromJson(v));
      });
    }
    professions = json['professions'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.services != null) {
      data['services'] = this.services!.map((v) => v.toJson()).toList();
    }
    data['professions'] = this.professions;
    return data;
  }
}

class Services {
  String? profession;
  List<ServiceData>? data;

  Services({this.profession, this.data});

  Services.fromJson(Map<String, dynamic> json) {
    profession = json['profession'];
    if (json['data'] != null) {
      data = <ServiceData>[];
      json['data'].forEach((v) {
        data!.add(new ServiceData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['profession'] = this.profession;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ServiceData {
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
  String? schoolOrCollegeName;
  String? sector;
  String? qrUrl;
  UserLocation? userLocation;
  bool? emailVerified;
  String? objective;
  num? distance;
  num? rating;
  int? reviewCount;
  ServiceMedia? serviceMedia;
  PriceData? priceData;
  ServiceInfo? service;
  String? category;
  List<String>? skills;
  List<String>? projects;
  List<String>? experiences;
  String? experienceStartDate;

  ServiceData(
      {
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
        this.schoolOrCollegeName,
        this.sector,
        this.qrUrl,
        this.userLocation,
        this.emailVerified,
        this.objective,
        this.distance,
        this.rating,
        this.reviewCount,
        this.serviceMedia,
        this.priceData,
        this.service,
        this.category,
        this.skills,
        this.projects,
        this.experiences,
      });

  ServiceData.fromJson(Map<String, dynamic> json) {
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
    dateOfBirth = json['date_of_birth'] != null
        ? new DateOfBirth.fromJson(json['date_of_birth'])
        : null;
    deletedAt = json['deleted_at'];
    accountType = json['account_type'];
    language = json['language'];
    referralPoints = json['referral_points'];
    referralCode = json['referral_code'];
    referredBy = json['referred_by'];
    deviceToken = json['device_token'];
    lastSeen = json['last_seen'];
    location = json['location_'];
    email = json['email'];
    highestEducation = json['highest_education'];
    role = json['role'];
    password = json['password'];
    currentOrganisation = json['current_organisation'];
    bio = json['bio'];
    address = json['address'];
    introVideo = json['introVideo'];
    socialLinks = json['social_links'] != null
        ? new SocialLinks.fromJson(json['social_links'])
        : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    specialization = json['specialization'];
    department = json['department'];
    subDivision = json['sub_division'];
    schoolOrCollegeName = json['school_or_college_name'];
    sector = json['sector'];
    qrUrl = json['qr_url'];
    userLocation = json['user_location'] != null
        ? new UserLocation.fromJson(json['user_location'])
        : null;
    emailVerified = json['email_verified'];
    objective = json['objective'];
    distance = json['distance'];
    rating = json['rating'];
    reviewCount = json['reviewCount'];
    category = json['category'];
    serviceMedia = json['serviceMedia'] != null
        ? new ServiceMedia.fromJson(json['serviceMedia'])
        : null;
    priceData = json['priceData'] != null
        ? new PriceData.fromJson(json['priceData'])
        : null;
    service = json['service'] != null
        ? new ServiceInfo.fromJson(json['service'])
        : null;
    if (json['skills'] != null) {
      skills = List<String>.from(json['skills']);
    }
    if (json['projects'] != null) {
      projects = List<String>.from(json['projects']);
    }
    if (json['experiences'] != null) {
      experiences = List<String>.from(json['experiences']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['gender'] = this.gender;
    data['pre'] = this.pre;
    data['contact_no'] = this.contactNo;
    data['profession'] = this.profession;
    data['designation'] = this.designation;
    data['profile_image'] = this.profileImage;
    data['is_ended'] = this.isEnded;
    data['username'] = this.username;
    if (this.dateOfBirth != null) {
      data['date_of_birth'] = this.dateOfBirth!.toJson();
    }
    data['deleted_at'] = this.deletedAt;
    data['account_type'] = this.accountType;
    data['language'] = this.language;
    data['referral_points'] = this.referralPoints;
    data['referral_code'] = this.referralCode;
    data['referred_by'] = this.referredBy;
    data['device_token'] = this.deviceToken;
    data['last_seen'] = this.lastSeen;
    data['location'] = this.location;
    data['email'] = this.email;
    data['highest_education'] = this.highestEducation;
    data['role'] = this.role;
    data['password'] = this.password;
    data['current_organisation'] = this.currentOrganisation;
    data['bio'] = this.bio;
    data['address'] = this.address;
    data['introVideo'] = this.introVideo;
    if (this.socialLinks != null) {
      data['social_links'] = this.socialLinks!.toJson();
    }
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['specialization'] = this.specialization;
    data['department'] = this.department;
    data['sub_division'] = this.subDivision;
    data['school_or_college_name'] = this.schoolOrCollegeName;
    data['sector'] = this.sector;
    data['qr_url'] = this.qrUrl;
    if (this.userLocation != null) {
      data['user_location'] = this.userLocation!.toJson();
    }
    data['email_verified'] = this.emailVerified;
    data['objective'] = this.objective;
    data['distance'] = this.distance;
    data['rating'] = this.rating;
    data['reviewCount'] = this.reviewCount;
    data['category'] = this.category;
    if (this.serviceMedia != null) {
      data['serviceMedia'] = this.serviceMedia!.toJson();
    }
    if (this.priceData != null) {
      data['priceData'] = this.priceData!.toJson();
    }
    if (this.service != null) {
      data['service'] = this.service!.toJson();
    }
    if (skills != null) {
      data['skills'] = skills;
    }
    if (projects != null) {
      data['projects'] = projects;
    }
    if (experiences != null) {
      data['experiences'] = experiences;
    }

    return data;
  }
}

class DateOfBirth {
  int? date;
  int? month;
  int? year;

  DateOfBirth({this.date, this.month, this.year});

  DateOfBirth.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    month = json['month'];
    year = json['year'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['month'] = this.month;
    data['year'] = this.year;
    return data;
  }
}

class SocialLinks {
  String? youtube;
  String? twitter;
  String? linkedin;
  String? instagram;
  String? website;

  SocialLinks(
      {this.youtube,
        this.twitter,
        this.linkedin,
        this.instagram,
        this.website});

  SocialLinks.fromJson(Map<String, dynamic> json) {
    youtube = json['youtube'];
    twitter = json['twitter'];
    linkedin = json['linkedin'];
    instagram = json['instagram'];
    website = json['website'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['youtube'] = this.youtube;
    data['twitter'] = this.twitter;
    data['linkedin'] = this.linkedin;
    data['instagram'] = this.instagram;
    data['website'] = this.website;
    return data;
  }
}

class UserLocation {
  num? lat;
  num? lon;

  UserLocation({this.lat, this.lon});

  UserLocation.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lon = json['lon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    return data;
  }
}

class ServiceMedia {
  List<String>? photos;
  String? demoVideo;

  ServiceMedia({this.photos, this.demoVideo});

  ServiceMedia.fromJson(Map<String, dynamic> json) {
    photos = json['photos'].cast<String>();
    demoVideo = json['demoVideo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['photos'] = this.photos;
    data['demoVideo'] = this.demoVideo;
    return data;
  }
}

class PriceData {
  String? priceType;
  int? singlePrice;
  PriceRange? priceRange;
  String? perUnit;
  int? minimumBookingAmount;

  PriceData(
      {this.priceType,
        this.singlePrice,
        this.priceRange,
        this.perUnit,
        this.minimumBookingAmount});

  PriceData.fromJson(Map<String, dynamic> json) {
    priceType = json['priceType'];
    singlePrice = json['singlePrice'];

    priceRange = json['priceRange'] != null
        ? new PriceRange.fromJson(json['priceRange'])
        : null;
    perUnit = json['perUnit'];
    minimumBookingAmount = json['minimumBookingAmount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['priceType'] = this.priceType;
    data['singlePrice'] = this.singlePrice;

    if (this.priceRange != null) {
      data['priceRange'] = this.priceRange!.toJson();
    }
    data['perUnit'] = this.perUnit;
    data['minimumBookingAmount'] = this.minimumBookingAmount;
    return data;
  }
}

class ServiceInfo {
  List<Timings>? timings;
  List<String>? facilities;
  List<String>? expertise;
  List<String>? serviceOffered;
  List<String>? typesOfWork;
  List<String>? workCategories;
  List<String>? whyChooseMe;
  List<String>? serviceType;

  ServiceInfo({
    this.timings,
    this.facilities,
    this.expertise,
    this.serviceOffered,
    this.typesOfWork,
    this.workCategories,
    this.whyChooseMe,
    this.serviceType,
  });

  ServiceInfo.fromJson(Map<String, dynamic> json) {
    if (json['timings'] != null) {
      timings = <Timings>[];
      json['timings'].forEach((v) {
        timings!.add(Timings.fromJson(v));
      });
    }
    if (json['facilities'] != null) {
      facilities = List<String>.from(json['facilities']);
    }
    if (json['expertise'] != null) {
      expertise = List<String>.from(json['expertise']);
    }
    if(json['serviceOffered'] != null){
      serviceOffered = List<String>.from(json['serviceOffered']);
    }
    if(json['typesOfWork'] != null){
      typesOfWork = List<String>.from(json['typesOfWork']);
    }
    if(json['workCategories'] != null){
      workCategories = List<String>.from(json['workCategories']);
    }
    if(json['whyChooseMe'] != null){
      whyChooseMe = List<String>.from(json['whyChooseMe']);
    }
    if(json['serviceType'] != null){
      serviceType = List<String>.from(json['serviceType']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (timings != null) {
      data['timings'] = timings!.map((v) => v.toJson()).toList();
    }
    if (facilities != null) {
      data['facilities'] = facilities;
    }
    if (expertise != null) {
      data['expertise'] = expertise;
    }
    if (serviceOffered != null) {
      data['serviceOffered'] = serviceOffered;
    }
    if (typesOfWork != null) {
      data['typesOfWork'] = typesOfWork;
    }
    if (workCategories != null) {
      data['workCategories'] = workCategories;
    }
    if (whyChooseMe != null) {
      data['whyChooseMe'] = whyChooseMe;
    }
    if (serviceType != null) {
      data['serviceType'] = serviceType;
    }
    return data;
  }
}

class Timings {
  String? start;
  String? end;
  bool? special;

  Timings({this.start, this.end, this.special});

  Timings.fromJson(Map<String, dynamic> json) {
    start = json['start'];
    end = json['end'];
    special = json['special'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['start'] = start;
    data['end'] = end;
    data['special'] = special;
    return data;
  }
}

class PriceRange {
  int? min;
  int? max;

  PriceRange({this.min, this.max});

  PriceRange.fromJson(Map<String, dynamic> json) {
    min = json['min'];
    max = json['max'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['min'] = this.min;
    data['max'] = this.max;
    return data;
  }
}