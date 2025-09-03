import 'dart:convert';

GetResumeDataModel getResumeDataModelFromJson(String str) =>
    GetResumeDataModel.fromJson(json.decode(str));
String getResumeDataModelToJson(GetResumeDataModel data) =>
    json.encode(data.toJson());

class GetResumeDataModel {
  GetResumeDataModel({
    this.salaryDetails,
    this.currentJob,
    this.id,
    this.userId,
    this.name,
    this.phone,
    this.email,
    this.location,
    this.skills,
    this.portfolios,
    this.education,
    this.fullTimeExperience,
    this.partTimeExperience,
    this.awards,
    this.achievements,
    this.certifications,
    this.publications,
    this.hobbies,
    this.additionalInformation,
    this.patents,
    this.ngoOrStudentOrgs,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.profilePicture,
    this.languages,
    this.bio,
    this.careerObjective,
  });

  GetResumeDataModel.fromJson(dynamic json) {
    salaryDetails = json['salaryDetails'] != null
        ? SalaryDetails.fromJson(json['salaryDetails'])
        : null;
    currentJob = json['currentJob'] != null
        ? CurrentJob.fromJson(json['currentJob'])
        : null;
    id = json['_id'];
    userId = json['userId'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    location = json['location'];

    skills = json['skills'] != null ? json['skills'].cast<String>() : [];
    portfolios =
        json['portfolios'] != null ? json['portfolios'].cast<String>() : [];
    if (json['education'] != null) {
      education = [];
      json['education'].forEach((v) {
        education?.add(Education.fromJson(v));
      });
    }
    if (json['fullTimeExperience'] != null) {
      fullTimeExperience = [];
      json['fullTimeExperience'].forEach((v) {
        fullTimeExperience?.add(FullTimeExperience.fromJson(v));
      });
    }
    if (json['partTimeExperience'] != null) {
      partTimeExperience = [];
      json['partTimeExperience'].forEach((v) {
        partTimeExperience?.add(PartTimeExperience.fromJson(v));
      });
    }
    if (json['awards'] != null) {
      awards = [];
      json['awards'].forEach((v) {
        awards?.add(Awards.fromJson(v));
      });
    }
    if (json['achievements'] != null) {
      achievements = [];
      json['achievements'].forEach((v) {
        achievements?.add(Achievements.fromJson(v));
      });
    }
    if (json['certifications'] != null) {
      certifications = [];
      json['certifications'].forEach((v) {
        certifications?.add(Certifications.fromJson(v));
      });
    }
    if (json['publications'] != null) {
      publications = [];
      json['publications'].forEach((v) {
        publications?.add(Publications.fromJson(v));
      });
    }
    if (json['hobbies'] != null) {
      hobbies = [];
      json['hobbies'].forEach((v) {
        hobbies?.add(Hobbies.fromJson(v));
      });
    }
    if (json['additionalInformation'] != null) {
      additionalInformation = [];
      json['additionalInformation'].forEach((v) {
        additionalInformation?.add(AdditionalInformation.fromJson(v));
      });
    }
    if (json['patents'] != null) {
      patents = [];
      json['patents'].forEach((v) {
        patents?.add(Patents.fromJson(v));
      });
    }
    if (json['ngoOrStudentOrgs'] != null) {
      ngoOrStudentOrgs = [];
      json['ngoOrStudentOrgs'].forEach((v) {
        ngoOrStudentOrgs?.add(NgoOrStudentOrgs.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    profilePicture = json['profilePicture'];
    if (json['languages'] != null) {
      languages = [];
      json['languages'].forEach((v) {
        languages?.add(Languages.fromJson(v));
      });
    }
    bio = json['bio'];
    careerObjective = json['careerObjective'];
  }
  SalaryDetails? salaryDetails;
  CurrentJob? currentJob;
  String? id;
  String? userId;
  String? name;
  String? phone;
  String? email;
  String? location;

  List<String>? skills;
  List<String>? portfolios;
  List<Education>? education;
  List<FullTimeExperience>? fullTimeExperience;
  List<PartTimeExperience>? partTimeExperience;
  List<Awards>? awards;
  List<Achievements>? achievements;
  List<Certifications>? certifications;
  List<Publications>? publications;
  List<Hobbies>? hobbies;
  List<AdditionalInformation>? additionalInformation;
  List<Patents>? patents;
  List<NgoOrStudentOrgs>? ngoOrStudentOrgs;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? profilePicture;
  List<Languages>? languages;
  String? bio;
  String? careerObjective;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (salaryDetails != null) {
      map['salaryDetails'] = salaryDetails?.toJson();
    }
    if (currentJob != null) {
      map['currentJob'] = currentJob?.toJson();
    }
    map['_id'] = id;
    map['userId'] = userId;
    map['name'] = name;
    map['phone'] = phone;
    map['email'] = email;
    map['location'] = location;

    map['skills'] = skills;
    map['portfolios'] = portfolios;
    if (education != null) {
      map['education'] = education?.map((v) => v.toJson()).toList();
    }
    if (fullTimeExperience != null) {
      map['fullTimeExperience'] =
          fullTimeExperience?.map((v) => v.toJson()).toList();
    }
    if (partTimeExperience != null) {
      map['partTimeExperience'] =
          partTimeExperience?.map((v) => v.toJson()).toList();
    }
    if (awards != null) {
      map['awards'] = awards?.map((v) => v.toJson()).toList();
    }
    if (achievements != null) {
      map['achievements'] = achievements?.map((v) => v.toJson()).toList();
    }
    if (certifications != null) {
      map['certifications'] = certifications?.map((v) => v.toJson()).toList();
    }
    if (publications != null) {
      map['publications'] = publications?.map((v) => v.toJson()).toList();
    }
    if (hobbies != null) {
      map['hobbies'] = hobbies?.map((v) => v.toJson()).toList();
    }
    if (additionalInformation != null) {
      map['additionalInformation'] =
          additionalInformation?.map((v) => v.toJson()).toList();
    }
    if (patents != null) {
      map['patents'] = patents?.map((v) => v.toJson()).toList();
    }
    if (ngoOrStudentOrgs != null) {
      map['ngoOrStudentOrgs'] =
          ngoOrStudentOrgs?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['profilePicture'] = profilePicture;
    if (languages != null) {
      map['languages'] = languages?.map((v) => v.toJson()).toList();
    }
    map['bio'] = bio;
    map['careerObjective'] = careerObjective;
    return map;
  }
}

Languages languagesFromJson(String str) => Languages.fromJson(json.decode(str));
String languagesToJson(Languages data) => json.encode(data.toJson());

class Languages {
  Languages({
    this.speakAndUnderstand,
    this.write,
    this.id,
  });

  Languages.fromJson(dynamic json) {
    speakAndUnderstand = json['speakAndUnderstand'] != null
        ? json['speakAndUnderstand'].cast<String>()
        : [];
    write = json['write'] != null ? json['write'].cast<String>() : [];
    id = json['_id'];
  }
  List<String>? speakAndUnderstand;
  List<String>? write;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['speakAndUnderstand'] = speakAndUnderstand;
    map['write'] = write;
    map['_id'] = id;
    return map;
  }
}

NgoOrStudentOrgs ngoOrStudentOrgsFromJson(String str) =>
    NgoOrStudentOrgs.fromJson(json.decode(str));
String ngoOrStudentOrgsToJson(NgoOrStudentOrgs data) =>
    json.encode(data.toJson());

class NgoOrStudentOrgs {
  NgoOrStudentOrgs({
    this.certifiedDate,
    this.title,
    this.description,
    this.attachment,
    this.id,
  });

  NgoOrStudentOrgs.fromJson(dynamic json) {
    certifiedDate = json['certifiedDate'] != null
        ? CertifiedDate.fromJson(json['certifiedDate'])
        : null;
    title = json['title'];
    description = json['description'];
    attachment = json['attachment'];
    id = json['_id'];
  }
  CertifiedDate? certifiedDate;
  String? title;
  String? description;
  String? attachment;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (certifiedDate != null) {
      map['certifiedDate'] = certifiedDate?.toJson();
    }
    map['title'] = title;
    map['description'] = description;
    map['attachment'] = attachment;
    map['_id'] = id;
    return map;
  }
}

CertifiedDate certifiedDateFromJson(String str) =>
    CertifiedDate.fromJson(json.decode(str));
String certifiedDateToJson(CertifiedDate data) => json.encode(data.toJson());

class CertifiedDate {
  CertifiedDate({
    this.date,
    this.month,
    this.year,
  });

  CertifiedDate.fromJson(dynamic json) {
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

Patents patentsFromJson(String str) => Patents.fromJson(json.decode(str));
String patentsToJson(Patents data) => json.encode(data.toJson());

class Patents {
  Patents({
    this.issuedDate,
    this.title,
    this.description,
    this.patentCertification,
    this.id,
  });

  Patents.fromJson(dynamic json) {
    issuedDate = json['issuedDate'] != null
        ? IssuedDate.fromJson(json['issuedDate'])
        : null;
    title = json['title'];
    description = json['description'];
    patentCertification = json['patentCertification'];
    id = json['_id'];
  }
  IssuedDate? issuedDate;
  String? title;
  String? description;
  String? patentCertification;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (issuedDate != null) {
      map['issuedDate'] = issuedDate?.toJson();
    }
    map['title'] = title;
    map['description'] = description;
    map['patentCertification'] = patentCertification;
    map['_id'] = id;
    return map;
  }
}

IssuedDate issuedDateFromJson(String str) =>
    IssuedDate.fromJson(json.decode(str));
String issuedDateToJson(IssuedDate data) => json.encode(data.toJson());

class IssuedDate {
  IssuedDate({
    this.date,
    this.month,
    this.year,
  });

  IssuedDate.fromJson(dynamic json) {
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

AdditionalInformation additionalInformationFromJson(String str) =>
    AdditionalInformation.fromJson(json.decode(str));
String additionalInformationToJson(AdditionalInformation data) =>
    json.encode(data.toJson());

class AdditionalInformation {
  AdditionalInformation({
    this.infoDate,
    this.title,
    this.info,
    this.photoURL,
    this.additionalDesc,
    this.id,
  });

  AdditionalInformation.fromJson(dynamic json) {
    infoDate =
        json['infoDate'] != null ? InfoDate.fromJson(json['infoDate']) : null;
    title = json['title'];
    info = json['info'];
    photoURL = json['photoURL'];
    additionalDesc = json['additionalDesc'];
    id = json['_id'];
  }
  InfoDate? infoDate;
  String? title;
  String? info;
  String? photoURL;
  String? additionalDesc;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (infoDate != null) {
      map['infoDate'] = infoDate?.toJson();
    }
    map['title'] = title;
    map['info'] = info;
    map['photoURL'] = photoURL;
    map['additionalDesc'] = additionalDesc;
    map['_id'] = id;
    return map;
  }
}

InfoDate infoDateFromJson(String str) => InfoDate.fromJson(json.decode(str));
String infoDateToJson(InfoDate data) => json.encode(data.toJson());

class InfoDate {
  InfoDate({
    this.date,
    this.month,
    this.year,
  });

  InfoDate.fromJson(dynamic json) {
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

Hobbies hobbiesFromJson(String str) => Hobbies.fromJson(json.decode(str));
String hobbiesToJson(Hobbies data) => json.encode(data.toJson());

class Hobbies {
  Hobbies({
    this.name,
    this.description,
    this.id,
  });

  Hobbies.fromJson(dynamic json) {
    name = json['name'];
    description = json['description'];
    id = json['_id'];
  }
  String? name;
  String? description;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['description'] = description;
    map['_id'] = id;
    return map;
  }
}

Publications publicationsFromJson(String str) =>
    Publications.fromJson(json.decode(str));
String publicationsToJson(Publications data) => json.encode(data.toJson());

class Publications {
  Publications({
    this.publishedDate,
    this.title,
    this.link,
    this.description,
    this.id,
  });

  Publications.fromJson(dynamic json) {
    publishedDate = json['publishedDate'] != null
        ? PublishedDate.fromJson(json['publishedDate'])
        : null;
    title = json['title'];
    link = json['link'];
    description = json['description'];
    id = json['_id'];
  }
  PublishedDate? publishedDate;
  String? title;
  String? link;
  String? description;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (publishedDate != null) {
      map['publishedDate'] = publishedDate?.toJson();
    }
    map['title'] = title;
    map['link'] = link;
    map['description'] = description;
    map['_id'] = id;
    return map;
  }
}

PublishedDate publishedDateFromJson(String str) =>
    PublishedDate.fromJson(json.decode(str));
String publishedDateToJson(PublishedDate data) => json.encode(data.toJson());

class PublishedDate {
  PublishedDate({
    this.date,
    this.month,
    this.year,
  });

  PublishedDate.fromJson(dynamic json) {
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

Certifications certificationsFromJson(String str) =>
    Certifications.fromJson(json.decode(str));
String certificationsToJson(Certifications data) => json.encode(data.toJson());

class Certifications {
  Certifications({
    this.certificateDate,
    this.title,
    this.issuingOrg,
    this.id,
    this.certificateAttachment,
  });

  Certifications.fromJson(dynamic json) {
    certificateDate = json['certificateDate'] != null
        ? CertificateDate.fromJson(json['certificateDate'])
        : null;
    title = json['title'];
    issuingOrg = json['issuingOrg'];
    id = json['_id'];
    certificateAttachment = json['certificateAttachment'];
  }
  CertificateDate? certificateDate;
  String? title;
  String? issuingOrg;
  String? id;
  String? certificateAttachment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (certificateDate != null) {
      map['certificateDate'] = certificateDate?.toJson();
    }
    map['title'] = title;
    map['issuingOrg'] = issuingOrg;
    map['_id'] = id;
    map['certificateAttachment'] = certificateAttachment;
    return map;
  }
}

CertificateDate certificateDateFromJson(String str) =>
    CertificateDate.fromJson(json.decode(str));
String certificateDateToJson(CertificateDate data) =>
    json.encode(data.toJson());

class CertificateDate {
  CertificateDate({
    this.date,
    this.month,
    this.year,
  });

  CertificateDate.fromJson(dynamic json) {
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

Achievements achievementsFromJson(String str) =>
    Achievements.fromJson(json.decode(str));
String achievementsToJson(Achievements data) => json.encode(data.toJson());

class Achievements {
  Achievements({
    this.achieveDate,
    this.title,
    this.description,
    this.attachment,
    this.id,
  });

  Achievements.fromJson(dynamic json) {
    achieveDate = json['achieveDate'] != null
        ? AchieveDate.fromJson(json['achieveDate'])
        : null;
    title = json['title'];
    description = json['description'];
    attachment = json['attachment'];
    id = json['_id'];
  }
  AchieveDate? achieveDate;
  String? title;
  String? description;
  String? attachment;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (achieveDate != null) {
      map['achieveDate'] = achieveDate?.toJson();
    }
    map['title'] = title;
    map['description'] = description;
    map['attachment'] = attachment;
    map['_id'] = id;
    return map;
  }
}

AchieveDate achieveDateFromJson(String str) =>
    AchieveDate.fromJson(json.decode(str));
String achieveDateToJson(AchieveDate data) => json.encode(data.toJson());

class AchieveDate {
  AchieveDate({
    this.date,
    this.month,
    this.year,
  });

  AchieveDate.fromJson(dynamic json) {
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

Awards awardsFromJson(String str) => Awards.fromJson(json.decode(str));
String awardsToJson(Awards data) => json.encode(data.toJson());

class Awards {
  Awards({
    this.issuedDate,
    this.title,
    this.issuedBy,
    this.description,
    this.attachment,
    this.id,
  });

  Awards.fromJson(dynamic json) {
    issuedDate = json['issuedDate'] != null
        ? IssuedDate.fromJson(json['issuedDate'])
        : null;
    title = json['title'];
    issuedBy = json['issuedBy'];
    description = json['description'];
    attachment = json['attachment'];
    id = json['_id'];
  }
  IssuedDate? issuedDate;
  String? title;
  String? issuedBy;
  String? description;
  String? attachment;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (issuedDate != null) {
      map['issuedDate'] = issuedDate?.toJson();
    }
    map['title'] = title;
    map['issuedBy'] = issuedBy;
    map['description'] = description;
    map['attachment'] = attachment;
    map['_id'] = id;
    return map;
  }
}

PartTimeExperience partTimeExperienceFromJson(String str) =>
    PartTimeExperience.fromJson(json.decode(str));
String partTimeExperienceToJson(PartTimeExperience data) =>
    json.encode(data.toJson());

class PartTimeExperience {
  PartTimeExperience({
    this.startDate,
    this.endDate,
    this.previousCompanyName,
    this.designation,
    this.jobType,
    this.workMode,
    this.location,
    this.description,
    this.id,
  });

  PartTimeExperience.fromJson(dynamic json) {
    startDate = json['startDate'] != null
        ? StartDate.fromJson(json['startDate'])
        : null;
    endDate =
        json['endDate'] != null ? EndDate.fromJson(json['endDate']) : null;
    previousCompanyName = json['previousCompanyName'];
    designation = json['designation'];
    jobType = json['jobType'];
    workMode = json['workMode'];
    location = json['location'];
    description = json['description'];
    id = json['_id'];
  }
  StartDate? startDate;
  EndDate? endDate;
  String? previousCompanyName;
  String? designation;
  String? jobType;
  String? workMode;
  String? location;
  String? description;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (startDate != null) {
      map['startDate'] = startDate?.toJson();
    }
    if (endDate != null) {
      map['endDate'] = endDate?.toJson();
    }
    map['previousCompanyName'] = previousCompanyName;
    map['designation'] = designation;
    map['jobType'] = jobType;
    map['workMode'] = workMode;
    map['location'] = location;
    map['description'] = description;
    map['_id'] = id;
    return map;
  }
}

EndDate endDateFromJson(String str) => EndDate.fromJson(json.decode(str));
String endDateToJson(EndDate data) => json.encode(data.toJson());

class EndDate {
  EndDate({
    this.date,
    this.month,
    this.year,
  });

  EndDate.fromJson(dynamic json) {
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

StartDate startDateFromJson(String str) => StartDate.fromJson(json.decode(str));
String startDateToJson(StartDate data) => json.encode(data.toJson());

class StartDate {
  StartDate({
    this.date,
    this.month,
    this.year,
  });

  StartDate.fromJson(dynamic json) {
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

FullTimeExperience fullTimeExperienceFromJson(String str) =>
    FullTimeExperience.fromJson(json.decode(str));
String fullTimeExperienceToJson(FullTimeExperience data) =>
    json.encode(data.toJson());

class FullTimeExperience {
  FullTimeExperience({
    this.startDate,
    this.endDate,
    this.previousCompanyName,
    this.designation,
    this.jobType,
    this.workMode,
    this.location,
    this.description,
    this.id,
  });

  FullTimeExperience.fromJson(dynamic json) {
    startDate = json['startDate'] != null
        ? StartDate.fromJson(json['startDate'])
        : null;
    endDate =
        json['endDate'] != null ? EndDate.fromJson(json['endDate']) : null;
    previousCompanyName = json['previousCompanyName'];
    designation = json['designation'];
    jobType = json['jobType'];
    workMode = json['workMode'];
    location = json['location'];
    description = json['description'];
    id = json['_id'];
  }
  StartDate? startDate;
  EndDate? endDate;
  String? previousCompanyName;
  String? designation;
  String? jobType;
  String? workMode;
  String? location;
  String? description;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (startDate != null) {
      map['startDate'] = startDate?.toJson();
    }
    if (endDate != null) {
      map['endDate'] = endDate?.toJson();
    }
    map['previousCompanyName'] = previousCompanyName;
    map['designation'] = designation;
    map['jobType'] = jobType;
    map['workMode'] = workMode;
    map['location'] = location;
    map['description'] = description;
    map['_id'] = id;
    return map;
  }
}

Education educationFromJson(String str) => Education.fromJson(json.decode(str));
String educationToJson(Education data) => json.encode(data.toJson());

class Education {
  Education({
    this.id,
    this.highestQualification,
    this.schoolOrCollegeName,
    this.boardName,
    this.passingYear,
    this.percentage,
  });

  Education.fromJson(dynamic json) {
    id = json['_id'];
    highestQualification = json['highestQualification'];
    schoolOrCollegeName = json['schoolOrCollegeName'];
    boardName = json['boardName'];
    passingYear =
        json['passingYear'] != null ? json['passingYear'].toString() : null;
    percentage = json['percentage'];
  }

  String? id;
  String? highestQualification;
  String? schoolOrCollegeName;
  String? boardName;
  String? passingYear;
  String? percentage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['highestQualification'] = highestQualification;
    map['schoolOrCollegeName'] = schoolOrCollegeName;
    map['boardName'] = boardName;
    map['passingYear'] = passingYear;
    map['percentage'] = percentage;
    return map;
  }
}

CurrentJob currentJobFromJson(String str) =>
    CurrentJob.fromJson(json.decode(str));
String currentJobToJson(CurrentJob data) => json.encode(data.toJson());

class CurrentJob {
  CurrentJob({
    this.startDate,
    this.experience,
    this.jobType,
    this.currentCompanyName,
    this.currentlyWorkingHere,
    this.designation,
    this.workMode,
    this.location,
    this.description,
  });

  CurrentJob.fromJson(dynamic json) {
    startDate = json['startDate'] != null
        ? StartDate.fromJson(json['startDate'])
        : null;
    experience = json['experience'];
    jobType = json['jobType'];
    currentCompanyName = json['currentCompanyName'];
    currentlyWorkingHere = json['currentlyWorkingHere'];
    designation = json['designation'];
    workMode = json['workMode'];
    location = json['location'];
    description = json['description'];
  }
  StartDate? startDate;
  String? experience;
  String? jobType;
  String? currentCompanyName;
  bool? currentlyWorkingHere;
  String? designation;
  String? workMode;
  String? location;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (startDate != null) {
      map['startDate'] = startDate?.toJson();
    }
    map['experience'] = experience;
    map['jobType'] = jobType;
    map['currentCompanyName'] = currentCompanyName;
    map['currentlyWorkingHere'] = currentlyWorkingHere;
    map['designation'] = designation;
    map['workMode'] = workMode;
    map['location'] = location;
    map['description'] = description;
    return map;
  }
}

SalaryDetails salaryDetailsFromJson(String str) =>
    SalaryDetails.fromJson(json.decode(str));
String salaryDetailsToJson(SalaryDetails data) => json.encode(data.toJson());

class SalaryDetails {
  SalaryDetails({
    this.grossSalary,
    this.monthlyDeduction,
    this.monthlyEarningViaPartTime,
    this.monthlyEarningViaFreelancing,
    this.monthlyTotalEarning,
    this.annualPackage,
  });

  SalaryDetails.fromJson(dynamic json) {
    grossSalary = json['grossSalary'];
    monthlyDeduction = json['monthlyDeduction'];
    monthlyEarningViaPartTime = json['monthlyEarningViaPartTime'];
    monthlyEarningViaFreelancing = json['monthlyEarningViaFreelancing'];
    monthlyTotalEarning = json['monthlyTotalEarning'];
    annualPackage = json['annualPackage'];
  }
  int? grossSalary;
  int? monthlyDeduction;
  int? monthlyEarningViaPartTime;
  int? monthlyEarningViaFreelancing;
  int? monthlyTotalEarning;
  int? annualPackage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['grossSalary'] = grossSalary;
    map['monthlyDeduction'] = monthlyDeduction;
    map['monthlyEarningViaPartTime'] = monthlyEarningViaPartTime;
    map['monthlyEarningViaFreelancing'] = monthlyEarningViaFreelancing;
    map['monthlyTotalEarning'] = monthlyTotalEarning;
    map['annualPackage'] = annualPackage;
    return map;
  }
}
