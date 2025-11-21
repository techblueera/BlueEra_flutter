import 'dart:convert';

ApplicationCandidateModel applicationCandidateModelFromJson(String str) =>
    ApplicationCandidateModel.fromJson(json.decode(str));

String applicationCandidateModelToJson(ApplicationCandidateModel data) =>
    json.encode(data.toJson());

class ApplicationCandidateModel {
  ApplicationCandidateModel({
    this.message,
    this.applications,
    this.jobDetails,
  });

  ApplicationCandidateModel.fromJson(dynamic json) {
    message = json['message'];
    if (json['applications'] != null) {
      applications = [];
      json['applications'].forEach((v) {
        applications?.add(ApplicationsCandidateList.fromJson(v));
      });
    }
    jobDetails = json['jobDetails'] != null
        ? JobDetails.fromJson(json['jobDetails'])
        : null;
  }

  String? message;
  List<ApplicationsCandidateList>? applications;
  JobDetails? jobDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    if (applications != null) {
      map['applications'] = applications?.map((v) => v.toJson()).toList();
    }
    if (jobDetails != null) {
      map['jobDetails'] = jobDetails?.toJson();
    }
    return map;
  }
}

JobDetails jobDetailsFromJson(String str) =>
    JobDetails.fromJson(json.decode(str));

String jobDetailsToJson(JobDetails data) => json.encode(data.toJson());

class JobDetails {
  JobDetails({
    this.compensation,
    this.interviewDetails,
    this.id,
    this.jobTitle,
    this.companyName,
    this.jobType,
    this.workMode,
    this.department,
    this.location,
    this.jobPostImage,
    this.benefits,
    this.jobDescription,
    this.jobHighlights,
    this.experience,
    this.skills,
    this.languages,
    this.postedBy,
    this.status,
    this.applications,
    this.customQuestions,
    this.postedOn,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.gender,
    this.qualifications,
    this.businessDetails,
  });

  JobDetails.fromJson(dynamic json) {
    compensation = json['compensation'] != null
        ? Compensation.fromJson(json['compensation'])
        : null;
    interviewDetails = json['interviewDetails'] != null
        ? InterviewDetails.fromJson(json['interviewDetails'])
        : null;
    id = json['_id'];
    jobTitle = json['jobTitle'];
    companyName = json['companyName'];
    jobType = json['jobType'];
    workMode = json['workMode'];
    department = json['department'];
    location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
    jobPostImage = json['jobPostImage'];
    benefits = json['benefits'] != null ? json['benefits'].cast<String>() : [];
    jobDescription = json['jobDescription'];
    jobHighlights = json['jobHighlights'] != null
        ? json['jobHighlights'].cast<String>()
        : [];
    experience = json['experience'];
    skills = json['skills'] != null ? json['skills'].cast<String>() : [];
    languages =
        json['languages'] != null ? json['languages'].cast<String>() : [];
    postedBy = json['postedBy'];
    status = json['status'];
    applications =
        json['applications'] != null ? json['applications'].cast<String>() : [];
    if (json['customQuestions'] != null) {
      customQuestions = [];
      json['customQuestions'].forEach((v) {
        customQuestions?.add(CustomQuestions.fromJson(v));
      });
    }
    postedOn = json['postedOn'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
    gender = json['gender'];
    qualifications = json['qualifications'];
    businessDetails = json['businessDetails'] != null
        ? BusinessDetails.fromJson(json['businessDetails'])
        : null;
  }

  Compensation? compensation;
  InterviewDetails? interviewDetails;
  String? id;
  String? jobTitle;
  String? companyName;
  String? jobType;
  String? workMode;
  String? department;
  Location? location;
  String? jobPostImage;
  List<String>? benefits;
  String? jobDescription;
  List<String>? jobHighlights;
  int? experience;
  List<String>? skills;
  List<String>? languages;
  String? postedBy;
  String? status;
  List<String>? applications;
  List<CustomQuestions>? customQuestions;
  String? postedOn;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? gender;
  String? qualifications;
  BusinessDetails? businessDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (compensation != null) {
      map['compensation'] = compensation?.toJson();
    }
    if (interviewDetails != null) {
      map['interviewDetails'] = interviewDetails?.toJson();
    }
    map['_id'] = id;
    map['jobTitle'] = jobTitle;
    map['companyName'] = companyName;
    map['jobType'] = jobType;
    map['workMode'] = workMode;
    map['department'] = department;
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['jobPostImage'] = jobPostImage;
    map['benefits'] = benefits;
    map['jobDescription'] = jobDescription;
    map['jobHighlights'] = jobHighlights;
    map['experience'] = experience;
    map['skills'] = skills;
    map['languages'] = languages;
    map['postedBy'] = postedBy;
    map['status'] = status;
    map['applications'] = applications;
    if (customQuestions != null) {
      map['customQuestions'] = customQuestions?.map((v) => v.toJson()).toList();
    }
    map['postedOn'] = postedOn;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    map['gender'] = gender;
    map['qualifications'] = qualifications;
    if (businessDetails != null) {
      map['businessDetails'] = businessDetails?.toJson();
    }
    return map;
  }
}

BusinessDetails businessDetailsFromJson(String str) =>
    BusinessDetails.fromJson(json.decode(str));

String businessDetailsToJson(BusinessDetails data) =>
    json.encode(data.toJson());

class BusinessDetails {
  BusinessDetails({
    this.businessDescription,
    this.businessName,
    this.dateOfIncorporation,
    this.buisnessLogo,
    this.id,
  });

  BusinessDetails.fromJson(dynamic json) {
    businessDescription = json['business_description'];
    businessName = json['business_name'];
    dateOfIncorporation = json['date_of_incorporation'] != null
        ? DateOfIncorporation.fromJson(json['date_of_incorporation'])
        : null;
    buisnessLogo = json['buisness_logo'];
    id = json['id'];
  }

  String? businessDescription;
  String? businessName;
  DateOfIncorporation? dateOfIncorporation;
  String? buisnessLogo;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['business_description'] = businessDescription;
    map['business_name'] = businessName;
    if (dateOfIncorporation != null) {
      map['date_of_incorporation'] = dateOfIncorporation?.toJson();
    }
    map['buisness_logo'] = buisnessLogo;
    map['id'] = id;
    return map;
  }
}

DateOfIncorporation dateOfIncorporationFromJson(String str) =>
    DateOfIncorporation.fromJson(json.decode(str));

String dateOfIncorporationToJson(DateOfIncorporation data) =>
    json.encode(data.toJson());

class DateOfIncorporation {
  DateOfIncorporation({
    this.date,
    this.month,
    this.year,
  });

  DateOfIncorporation.fromJson(dynamic json) {
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

CustomQuestions customQuestionsFromJson(String str) =>
    CustomQuestions.fromJson(json.decode(str));

String customQuestionsToJson(CustomQuestions data) =>
    json.encode(data.toJson());

class CustomQuestions {
  CustomQuestions({
    this.question,
    this.answerType,
    this.options,
    this.isMandatory,
    this.id,
  });

  CustomQuestions.fromJson(dynamic json) {
    question = json['question'];
    answerType = json['answerType'];
    options = json['options'] != null ? json['options'].cast<String>() : [];
    isMandatory = json['isMandatory'];
    id = json['_id'];
  }

  String? question;
  String? answerType;
  List<String>? options;
  bool? isMandatory;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['question'] = question;
    map['answerType'] = answerType;
    map['options'] = options;
    map['isMandatory'] = isMandatory;
    map['_id'] = id;
    return map;
  }
}

Location locationFromJson(String str) => Location.fromJson(json.decode(str));

String locationToJson(Location data) => json.encode(data.toJson());

class Location {
  Location({
    this.latitude,
    this.longitude,
    this.addressString,
  });

  Location.fromJson(dynamic json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
    addressString = json['addressString'];
  }

  String? latitude;
  String? longitude;
  String? addressString;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['addressString'] = addressString;
    return map;
  }
}

InterviewDetails interviewDetailsFromJson(String str) =>
    InterviewDetails.fromJson(json.decode(str));

String interviewDetailsToJson(InterviewDetails data) =>
    json.encode(data.toJson());

class InterviewDetails {
  InterviewDetails({
    this.communicationPreferences,
    this.isWalkIn,
    this.interviewAddress,
    this.walkInStartDate,
    this.walkInEndDate,
    this.walkInStartTime,
    this.walkInEndTime,
    this.otherInstructions,
  });

  InterviewDetails.fromJson(dynamic json) {
    communicationPreferences = json['communicationPreferences'] != null
        ? CommunicationPreferences.fromJson(json['communicationPreferences'])
        : null;
    isWalkIn = json['isWalkIn'];
    interviewAddress = json['interviewAddress'];
    walkInStartDate = json['walkInStartDate'];
    walkInEndDate = json['walkInEndDate'];
    walkInStartTime = json['walkInStartTime'];
    walkInEndTime = json['walkInEndTime'];
    otherInstructions = json['otherInstructions'];
  }

  CommunicationPreferences? communicationPreferences;
  bool? isWalkIn;
  dynamic interviewAddress;
  dynamic walkInStartDate;
  dynamic walkInEndDate;
  dynamic walkInStartTime;
  dynamic walkInEndTime;
  dynamic otherInstructions;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (communicationPreferences != null) {
      map['communicationPreferences'] = communicationPreferences?.toJson();
    }
    map['isWalkIn'] = isWalkIn;
    map['interviewAddress'] = interviewAddress;
    map['walkInStartDate'] = walkInStartDate;
    map['walkInEndDate'] = walkInEndDate;
    map['walkInStartTime'] = walkInStartTime;
    map['walkInEndTime'] = walkInEndTime;
    map['otherInstructions'] = otherInstructions;
    return map;
  }
}

CommunicationPreferences communicationPreferencesFromJson(String str) =>
    CommunicationPreferences.fromJson(json.decode(str));

String communicationPreferencesToJson(CommunicationPreferences data) =>
    json.encode(data.toJson());

class CommunicationPreferences {
  CommunicationPreferences({
    this.chat,
    this.call,
    this.both,
    this.weContact,
  });

  CommunicationPreferences.fromJson(dynamic json) {
    chat = json['chat'];
    call = json['call'];
    both = json['both'];
    weContact = json['weContact'];
  }

  bool? chat;
  bool? call;
  bool? both;
  bool? weContact;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['chat'] = chat;
    map['call'] = call;
    map['both'] = both;
    map['weContact'] = weContact;
    return map;
  }
}

Compensation compensationFromJson(String str) =>
    Compensation.fromJson(json.decode(str));

String compensationToJson(Compensation data) => json.encode(data.toJson());

class Compensation {
  Compensation({
    this.type,
    this.minSalary,
    this.maxSalary,
  });

  Compensation.fromJson(dynamic json) {
    type = json['type'];
    minSalary = json['minSalary'];
    maxSalary = json['maxSalary'];
  }

  String? type;
  int? minSalary;
  int? maxSalary;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['minSalary'] = minSalary;
    map['maxSalary'] = maxSalary;
    return map;
  }
}

ApplicationsCandidateList applicationsFromJson(String str) =>
    ApplicationsCandidateList.fromJson(json.decode(str));

String applicationsToJson(ApplicationsCandidateList data) =>
    json.encode(data.toJson());

class ApplicationsCandidateList {
  ApplicationsCandidateList({
    this.address,
    this.id,
    this.jobId,
    this.candidateName,
    this.status,
    this.userAge,
    this.totalExperience,
    this.interviewId,
    this.resumeData,
  });

  ApplicationsCandidateList.fromJson(dynamic json) {
    address =
        json['address'] != null ? Address.fromJson(json['address']) : null;
    id = json['_id'];
    jobId = json['jobId'];
    candidateName = json['candidateName'];

    status = json['status'];

    interviewId = json['interviewId'];
    totalExperience = json['totalExperience'];
    userAge = json['userAge'];
    resumeData = json['resumeData'] != null
        ? ResumeData.fromJson(json['resumeData'])
        : null;
  }

  Address? address;
  String? id;
  String? jobId;
  String? candidateName;
  String? status;
  String? interviewId;
  String? totalExperience;
  int? userAge;
  ResumeData? resumeData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (address != null) {
      map['address'] = address?.toJson();
    }
    map['_id'] = id;
    map['jobId'] = jobId;
    map['candidateName'] = candidateName;
    map['status'] = status;

    map['interviewId'] = interviewId;
    map['userAge'] = userAge;
    map['totalExperience'] = totalExperience;
    if (resumeData != null) {
      map['resumeData'] = resumeData?.toJson();
    }
    return map;
  }
}

ResumeData resumeDataFromJson(String str) =>
    ResumeData.fromJson(json.decode(str));

String resumeDataToJson(ResumeData data) => json.encode(data.toJson());

class ResumeData {
  ResumeData({
    this.education,
    this.id,
    this.userId,
    this.location,
    this.profilePicture,
    this.salaryDetails,
    this.currentJob,
  });

  ResumeData.fromJson(dynamic json) {
    if (json['education'] != null) {
      education = [];
      json['education'].forEach((v) {
        education?.add(Education.fromJson(v));
      });
    }

    id = json['id'];
    userId = json['userId'];
    location = json['location'];
    profilePicture = json['profilePicture'];
    salaryDetails = json['salaryDetails'] != null
        ? SalaryDetails.fromJson(json['salaryDetails'])
        : null;
    currentJob = json['currentJob'] != null
        ? CurrentJob.fromJson(json['currentJob'])
        : null;
  }

  List<Education>? education;
  String? id;
  String? userId;
  String? location;
  String? profilePicture;
  SalaryDetails? salaryDetails;
  CurrentJob? currentJob;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (education != null) {
      map['education'] = education?.map((v) => v.toJson()).toList();
    }

    map['id'] = id;
    map['userId'] = userId;

    map['location'] = location;
    map['profilePicture'] = profilePicture;
    if (salaryDetails != null) {
      map['salaryDetails'] = salaryDetails?.toJson();
    }
    if (currentJob != null) {
      map['currentJob'] = currentJob?.toJson();
    }
    return map;
  }
}

CurrentJob currentJobFromJson(String str) =>
    CurrentJob.fromJson(json.decode(str));

String currentJobToJson(CurrentJob data) => json.encode(data.toJson());

class CurrentJob {
  CurrentJob({
    this.isExperienced,
    this.experience,
    this.jobType,
    this.currentCompanyName,
    this.currentlyWorkingHere,
    this.designation,
    this.workMode,
    this.location,
    this.startDate,
    this.endDate,
    this.description,
  });

  CurrentJob.fromJson(dynamic json) {
    isExperienced = json['isExperienced'];
    experience = json['experience'];
    jobType = json['jobType'];
    currentCompanyName = json['currentCompanyName'];
    currentlyWorkingHere = json['currentlyWorkingHere'];
    designation = json['designation'];
    workMode = json['workMode'];
    location = json['location'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    description = json['description'];
  }

  bool? isExperienced;
  String? experience;
  String? jobType;
  String? currentCompanyName;
  bool? currentlyWorkingHere;
  String? designation;
  String? workMode;
  String? location;
  String? startDate;
  String? endDate;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isExperienced'] = isExperienced;
    map['experience'] = experience;
    map['jobType'] = jobType;
    map['currentCompanyName'] = currentCompanyName;
    map['currentlyWorkingHere'] = currentlyWorkingHere;
    map['designation'] = designation;
    map['workMode'] = workMode;
    map['location'] = location;
    map['startDate'] = startDate;
    map['endDate'] = endDate;
    map['description'] = description;
    return map;
  }
}

SalaryDetails salaryDetailsFromJson(String str) =>
    SalaryDetails.fromJson(json.decode(str));

String salaryDetailsToJson(SalaryDetails data) => json.encode(data.toJson());

class SalaryDetails {
  SalaryDetails({
    this.monthlyTotalEarning,
  });

  SalaryDetails.fromJson(dynamic json) {
    monthlyTotalEarning = json['monthlyTotalEarning'];
  }

  int? monthlyTotalEarning;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['monthlyTotalEarning'] = monthlyTotalEarning;
    return map;
  }
}

Education educationFromJson(String str) => Education.fromJson(json.decode(str));

String educationToJson(Education data) => json.encode(data.toJson());

class Education {
  Education({
    this.highestQualification,
    this.schoolOrCollegeName,
    this.boardName,
    this.passingYear,
    this.percentage,
  });

  Education.fromJson(dynamic json) {
    highestQualification = json['highestQualification'];
    schoolOrCollegeName = json['schoolOrCollegeName'];
    boardName = json['boardName'];
    passingYear = json['passingYear'];
    percentage = json['percentage'];
  }

  String? highestQualification;
  String? schoolOrCollegeName;
  String? boardName;
  int? passingYear;
  String? percentage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['highestQualification'] = highestQualification;
    map['schoolOrCollegeName'] = schoolOrCollegeName;
    map['boardName'] = boardName;
    map['passingYear'] = passingYear;
    map['percentage'] = percentage;
    return map;
  }
}

Address addressFromJson(String str) => Address.fromJson(json.decode(str));

String addressToJson(Address data) => json.encode(data.toJson());

class Address {
  Address({
    this.city,
  });

  Address.fromJson(dynamic json) {
    city = json['city'];
  }

  String? city;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['city'] = city;
    return map;
  }
}
