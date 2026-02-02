import 'dart:convert';

ProfessionalProfileResModel professionalProfileResModelFromJson(String str) =>
    ProfessionalProfileResModel.fromJson(json.decode(str));

String professionalProfileResModelToJson(ProfessionalProfileResModel data) =>
    json.encode(data.toJson());

class ProfessionalProfileResModel {
  ProfessionalProfileResModel({
    this.success,
    this.data,
  });

  ProfessionalProfileResModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null
        ? ProfessionalProfileData.fromJson(json['data'])
        : null;
  }

  bool? success;
  ProfessionalProfileData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

ProfessionalProfileData dataFromJson(String str) =>
    ProfessionalProfileData.fromJson(json.decode(str));

String dataToJson(ProfessionalProfileData data) => json.encode(data.toJson());

class ProfessionalProfileData {
  ProfessionalProfileData({
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
    this.galleryId,
    this.contactId,
    this.timingsId,
    this.gallery,
    this.timings,
    this.contact,
    this.certificates,
    this.portfolio,
  });

  ProfessionalProfileData.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    basicDetails = json['basicDetails'] != null
        ? BasicDetails.fromJson(json['basicDetails'])
        : null;
    about = json['about'] != null ? About.fromJson(json['about']) : null;
    pricing =
        json['pricing'] != null ? ProfessionalPricing.fromJson(json['pricing']) : null;
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    galleryId = json['galleryId'];
    contactId = json['contactId'];
    timingsId = json['timingsId'];
    gallery =
        json['gallery'] != null ? Gallery.fromJson(json['gallery']) : null;
    timings =
        json['timings'] != null ? Timings.fromJson(json['timings']) : null;
    contact =
        json['contact'] != null ? Contact.fromJson(json['contact']) : null;
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
  ProfessionalPricing? pricing;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? galleryId;
  String? contactId;
  String? timingsId;
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
    map['galleryId'] = galleryId;
    map['contactId'] = contactId;
    map['timingsId'] = timingsId;
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

ProfessionalPortfolio portfolioFromJson(String str) =>
    ProfessionalPortfolio.fromJson(json.decode(str));

String portfolioToJson(ProfessionalPortfolio data) =>
    json.encode(data.toJson());

class ProfessionalPortfolio {
  ProfessionalPortfolio({
    this.id,
    this.userId,
    this.projectTitle,
    this.category,
    this.teamSize,
    this.completionDate,
    this.description,
    this.projectLink,
    this.mediaKeys,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.media,
  });

  ProfessionalPortfolio.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    projectTitle = json['projectTitle'];
    category = json['category'];
    teamSize = json['teamSize'];
    completionDate = json['completionDate'];
    description = json['description'];
    projectLink = json['projectLink'];
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
        media?.add(ProfessionalMedia.fromJson(v));
      });
    }
  }

  String? id;
  String? userId;
  String? projectTitle;
  String? category;
  int? teamSize;
  String? completionDate;
  String? description;
  String? projectLink;
  List<MediaKeys>? mediaKeys;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<ProfessionalMedia>? media;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['projectTitle'] = projectTitle;
    map['category'] = category;
    map['teamSize'] = teamSize;
    map['completionDate'] = completionDate;
    map['description'] = description;
    map['projectLink'] = projectLink;
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

ProfessionalMedia mediaFromJson(String str) =>
    ProfessionalMedia.fromJson(json.decode(str));

String mediaToJson(ProfessionalMedia data) => json.encode(data.toJson());

class ProfessionalMedia {
  ProfessionalMedia({
    this.type,
    this.url,
  });

  ProfessionalMedia.fromJson(dynamic json) {
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
    this.id,
  });

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

Certificates certificatesFromJson(String str) =>
    Certificates.fromJson(json.decode(str));

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
    this.v,
    this.fileUrl,
  });

  Certificates.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    title = json['title'];
    documentType = json['documentType'];
    issuedBy = json['issuedBy'];
    issueDate = json['issueDate'];
    fileKey = json['fileKey'];
    description = json['description'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    fileUrl = json['fileUrl'];
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
  String? fileUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['userId'] = userId;
    map['title'] = title;
    map['documentType'] = documentType;
    map['issuedBy'] = issuedBy;
    map['issueDate'] = issueDate;
    map['fileKey'] = fileKey;
    map['description'] = description;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['fileUrl'] = fileUrl;
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
    this.website,
  });

  Contact.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    address = json['address'];
    contactPerson = json['contactPerson'];
    createdAt = json['createdAt'];
    email = json['email'];
    location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
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
    this.coordinates,
  });

  Location.fromJson(dynamic json) {
    type = json['type'];
    coordinates =
        json['coordinates'] != null ? json['coordinates'].cast<double>() : [];
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

Timings timingsFromJson(String str) => Timings.fromJson(json.decode(str));

String timingsToJson(Timings data) => json.encode(data.toJson());

class Timings {
  Timings({
    this.id,
    this.userId,
    this.v,
    this.createdAt,
    this.schedule,
    this.updatedAt,
  });

  Timings.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    v = json['__v'];
    createdAt = json['createdAt'];
    schedule =
        json['schedule'] != null ? Schedule.fromJson(json['schedule']) : null;
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
}

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
    this.sunday,
  });

  Schedule.fromJson(dynamic json) {
    monday = json['monday'] != null ? Monday.fromJson(json['monday']) : null;
    tuesday =
        json['tuesday'] != null ? Tuesday.fromJson(json['tuesday']) : null;
    wednesday = json['wednesday'] != null
        ? Wednesday.fromJson(json['wednesday'])
        : null;
    thursday =
        json['thursday'] != null ? Thursday.fromJson(json['thursday']) : null;
    friday = json['friday'] != null ? Friday.fromJson(json['friday']) : null;
    saturday =
        json['saturday'] != null ? Saturday.fromJson(json['saturday']) : null;
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
    this.closeTime,
  });

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
    this.closeTime,
  });

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
    this.closeTime,
  });

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
    this.closeTime,
  });

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
    this.closeTime,
  });

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
    this.closeTime,
  });

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
    this.closeTime,
  });

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
    this.signedUrls,
  });

  Gallery.fromJson(dynamic json) {
    id = json['_id'];
    userId = json['userId'];
    title = json['title'];
    imageKeys =
        json['imageKeys'] != null ? json['imageKeys'].cast<String>() : [];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    signedUrls =
        json['signedUrls'] != null ? json['signedUrls'].cast<String>() : [];
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

ProfessionalPricing pricingFromJson(String str) => ProfessionalPricing.fromJson(json.decode(str));

String pricingToJson(ProfessionalPricing data) => json.encode(data.toJson());

class ProfessionalPricing {
  ProfessionalPricing({
    this.type,
    this.amount,
    this.currency,
    this.consultationMode,
  });

  ProfessionalPricing.fromJson(dynamic json) {
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
    this.majorProjectsDescription,
  });

  About.fromJson(dynamic json) {
    totalExperience = json['totalExperience'] != null
        ? TotalExperience.fromJson(json['totalExperience'])
        : null;
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

TotalExperience totalExperienceFromJson(String str) =>
    TotalExperience.fromJson(json.decode(str));

String totalExperienceToJson(TotalExperience data) =>
    json.encode(data.toJson());

class TotalExperience {
  TotalExperience({
    this.years,
    this.months,
  });

  TotalExperience.fromJson(dynamic json) {
    years = json['years'];
    months = json['months'];
  }

  num? years;
  num? months;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['years'] = years;
    map['months'] = months;
    return map;
  }
}

BasicDetails basicDetailsFromJson(String str) =>
    BasicDetails.fromJson(json.decode(str));

String basicDetailsToJson(BasicDetails data) => json.encode(data.toJson());

class BasicDetails {
  BasicDetails({
    this.languagesSpoken,
    this.professionalTitle,
    this.shortTagline,
    this.profilePhotoKey,
    this.profilePhotoUrl,
    this.location,
    this.fullName,
  });

  BasicDetails.fromJson(dynamic json) {
    if (json['languagesSpoken'] != null) {
      languagesSpoken = json['languagesSpoken'] != null
          ? json['languagesSpoken'].cast<String>()
          : [];
    }
    professionalTitle = json['professionalTitle'];
    shortTagline = json['shortTagline'];
    fullName = json['fullName'];
    location = json['location'];
    profilePhotoUrl = json['profilePhotoUrl'];
    profilePhotoKey = json['profilePhotoKey'];
  }

  List<String>? languagesSpoken;
  String? professionalTitle;
  String? shortTagline;

  String? fullName;
  String? location;
  String? profilePhotoUrl;
  String? profilePhotoKey;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    map['fullName'] = fullName;
    map['location'] = location;
    map['profilePhotoUrl'] = profilePhotoUrl;
    map['profilePhotoKey'] = profilePhotoKey;
    map['professionalTitle'] = professionalTitle;
    map['shortTagline'] = shortTagline;
    return map;
  }
}
