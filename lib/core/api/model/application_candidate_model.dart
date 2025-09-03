import 'dart:convert';
ApplicationCandidateModel applicationCandidateModelFromJson(String str) => ApplicationCandidateModel.fromJson(json.decode(str));
String applicationCandidateModelToJson(ApplicationCandidateModel data) => json.encode(data.toJson());
class ApplicationCandidateModel {
  ApplicationCandidateModel({
      this.message, 
      this.applications, 
      this.jobDetails,});

  ApplicationCandidateModel.fromJson(dynamic json) {
    message = json['message'];
    if (json['applications'] != null) {
      applications = [];
      json['applications'].forEach((v) {
        applications?.add(ApplicationsCandidateList.fromJson(v));
      });
    }
    jobDetails = json['jobDetails'] != null ? JobDetails.fromJson(json['jobDetails']) : null;
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

JobDetails jobDetailsFromJson(String str) => JobDetails.fromJson(json.decode(str));
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
      this.businessDetails,});

  JobDetails.fromJson(dynamic json) {
    compensation = json['compensation'] != null ? Compensation.fromJson(json['compensation']) : null;
    interviewDetails = json['interviewDetails'] != null ? InterviewDetails.fromJson(json['interviewDetails']) : null;
    id = json['_id'];
    jobTitle = json['jobTitle'];
    companyName = json['companyName'];
    jobType = json['jobType'];
    workMode = json['workMode'];
    department = json['department'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    jobPostImage = json['jobPostImage'];
    benefits = json['benefits'] != null ? json['benefits'].cast<String>() : [];
    jobDescription = json['jobDescription'];
    jobHighlights = json['jobHighlights'] != null ? json['jobHighlights'].cast<String>() : [];
    experience = json['experience'];
    skills = json['skills'] != null ? json['skills'].cast<String>() : [];
    languages = json['languages'] != null ? json['languages'].cast<String>() : [];
    postedBy = json['postedBy'];
    status = json['status'];
    applications = json['applications'] != null ? json['applications'].cast<String>() : [];
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
    businessDetails = json['businessDetails'] != null ? BusinessDetails.fromJson(json['businessDetails']) : null;
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

BusinessDetails businessDetailsFromJson(String str) => BusinessDetails.fromJson(json.decode(str));
String businessDetailsToJson(BusinessDetails data) => json.encode(data.toJson());
class BusinessDetails {
  BusinessDetails({
      this.businessDescription, 
      this.businessName, 
      this.dateOfIncorporation, 
      this.buisnessLogo, 
      this.id,});

  BusinessDetails.fromJson(dynamic json) {
    businessDescription = json['business_description'];
    businessName = json['business_name'];
    dateOfIncorporation = json['date_of_incorporation'] != null ? DateOfIncorporation.fromJson(json['date_of_incorporation']) : null;
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

DateOfIncorporation dateOfIncorporationFromJson(String str) => DateOfIncorporation.fromJson(json.decode(str));
String dateOfIncorporationToJson(DateOfIncorporation data) => json.encode(data.toJson());
class DateOfIncorporation {
  DateOfIncorporation({
      this.date, 
      this.month, 
      this.year,});

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

CustomQuestions customQuestionsFromJson(String str) => CustomQuestions.fromJson(json.decode(str));
String customQuestionsToJson(CustomQuestions data) => json.encode(data.toJson());
class CustomQuestions {
  CustomQuestions({
      this.question, 
      this.answerType, 
      this.options, 
      this.isMandatory, 
      this.id,});

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
      this.addressString,});

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

InterviewDetails interviewDetailsFromJson(String str) => InterviewDetails.fromJson(json.decode(str));
String interviewDetailsToJson(InterviewDetails data) => json.encode(data.toJson());
class InterviewDetails {
  InterviewDetails({
      this.communicationPreferences, 
      this.isWalkIn, 
      this.interviewAddress, 
      this.walkInStartDate, 
      this.walkInEndDate, 
      this.walkInStartTime, 
      this.walkInEndTime, 
      this.otherInstructions,});

  InterviewDetails.fromJson(dynamic json) {
    communicationPreferences = json['communicationPreferences'] != null ? CommunicationPreferences.fromJson(json['communicationPreferences']) : null;
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

CommunicationPreferences communicationPreferencesFromJson(String str) => CommunicationPreferences.fromJson(json.decode(str));
String communicationPreferencesToJson(CommunicationPreferences data) => json.encode(data.toJson());
class CommunicationPreferences {
  CommunicationPreferences({
      this.chat, 
      this.call, 
      this.both, 
      this.weContact,});

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

Compensation compensationFromJson(String str) => Compensation.fromJson(json.decode(str));
String compensationToJson(Compensation data) => json.encode(data.toJson());
class Compensation {
  Compensation({
      this.type, 
      this.minSalary, 
      this.maxSalary,});

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

ApplicationsCandidateList applicationsFromJson(String str) => ApplicationsCandidateList.fromJson(json.decode(str));
String applicationsToJson(ApplicationsCandidateList data) => json.encode(data.toJson());
class ApplicationsCandidateList {
  ApplicationsCandidateList({
      this.address, 
      this.id, 
      this.jobId, 
      this.candidateId, 
      this.candidateName, 
      this.candidateEmail, 
      this.candidatePhone, 
      this.resumeId, 
      this.status, 
      this.statusHistory, 
      this.answersToCustomQuestions, 
      this.isClearedByCandidate, 
      this.applicationDate, 
      this.recruiterNotes, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.userAge,
      this.totalExperience,
      this.interviewId,
      this.resumeData,});

  ApplicationsCandidateList.fromJson(dynamic json) {
    address = json['address'] != null ? Address.fromJson(json['address']) : null;
    id = json['_id'];
    jobId = json['jobId'];
    candidateId = json['candidateId'];
    candidateName = json['candidateName'];
    candidateEmail = json['candidateEmail'];
    candidatePhone = json['candidatePhone'];
    resumeId = json['resumeId'];
    status = json['status'];
    if (json['statusHistory'] != null) {
      statusHistory = [];
      json['statusHistory'].forEach((v) {
        statusHistory?.add(StatusHistory.fromJson(v));
      });
    }
    if (json['answersToCustomQuestions'] != null) {
      answersToCustomQuestions = [];
      json['answersToCustomQuestions'].forEach((v) {
        answersToCustomQuestions?.add(AnswersToCustomQuestions.fromJson(v));
      });
    }
    isClearedByCandidate = json['isClearedByCandidate'];
    applicationDate = json['applicationDate'];

    interviewId = json['interviewId'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    totalExperience = json['totalExperience'];
    userAge = json['userAge'];
    v = json['__v'];
    resumeData = json['resumeData'] != null ? ResumeData.fromJson(json['resumeData']) : null;
  }
  Address? address;
  String? id;
  String? jobId;
  String? candidateId;
  String? candidateName;
  String? candidateEmail;
  String? candidatePhone;
  String? resumeId;
  String? status;
  List<StatusHistory>? statusHistory;
  List<AnswersToCustomQuestions>? answersToCustomQuestions;
  bool? isClearedByCandidate;
  String? applicationDate;
  List<dynamic>? recruiterNotes;
  String? createdAt;
  String? updatedAt;
  String? interviewId;
  String? totalExperience;
  int? userAge;
  int? v;
  ResumeData? resumeData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (address != null) {
      map['address'] = address?.toJson();
    }
    map['_id'] = id;
    map['jobId'] = jobId;
    map['candidateId'] = candidateId;
    map['candidateName'] = candidateName;
    map['candidateEmail'] = candidateEmail;
    map['candidatePhone'] = candidatePhone;
    map['resumeId'] = resumeId;
    map['status'] = status;
    if (statusHistory != null) {
      map['statusHistory'] = statusHistory?.map((v) => v.toJson()).toList();
    }
    if (answersToCustomQuestions != null) {
      map['answersToCustomQuestions'] = answersToCustomQuestions?.map((v) => v.toJson()).toList();
    }
    map['isClearedByCandidate'] = isClearedByCandidate;
    map['applicationDate'] = applicationDate;
    if (recruiterNotes != null) {
      map['recruiterNotes'] = recruiterNotes?.map((v) => v.toJson()).toList();
    }
    map['interviewId'] = interviewId;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['userAge'] = userAge;
    map['totalExperience'] = totalExperience;
    map['__v'] = v;
    if (resumeData != null) {
      map['resumeData'] = resumeData?.toJson();
    }
    return map;
  }

}

ResumeData resumeDataFromJson(String str) => ResumeData.fromJson(json.decode(str));
String resumeDataToJson(ResumeData data) => json.encode(data.toJson());
class ResumeData {
  ResumeData({
      this.education, 
      this.fullTimeExperience, 
      this.partTimeExperience, 
      this.skills, 
      this.languages, 
      this.portfolios, 
      this.awards, 
      this.achievements, 
      this.certifications, 
      this.publications, 
      this.hobbies, 
      this.additionalInformation, 
      this.patents, 
      this.ngoOrStudentOrgs, 
      this.id, 
      this.userId, 
      this.name, 
      this.email, 
      this.phone, 
      this.location, 
      this.profilePicture, 
      this.bio, 
      this.salaryDetails, 
      this.currentJob, 
      this.careerObjective, 
      this.createdAt, 
      this.updatedAt,});

  ResumeData.fromJson(dynamic json) {
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
    skills = json['skills'] != null ? json['skills'].cast<String>() : [];
    languages = json['languages'] != null ? json['languages'].cast<String>() : [];
    portfolios = json['portfolios'] != null ? json['portfolios'].cast<String>() : [];
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
    id = json['id'];
    userId = json['userId'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    location = json['location'];
    profilePicture = json['profilePicture'];
    bio = json['bio'];
    salaryDetails = json['salaryDetails'] != null ? SalaryDetails.fromJson(json['salaryDetails']) : null;
    currentJob = json['currentJob'] != null ? CurrentJob.fromJson(json['currentJob']) : null;
    careerObjective = json['careerObjective'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }
  List<Education>? education;
  List<FullTimeExperience>? fullTimeExperience;
  List<PartTimeExperience>? partTimeExperience;
  List<String>? skills;
  List<String>? languages;
  List<String>? portfolios;
  List<Awards>? awards;
  List<Achievements>? achievements;
  List<Certifications>? certifications;
  List<Publications>? publications;
  List<Hobbies>? hobbies;
  List<AdditionalInformation>? additionalInformation;
  List<Patents>? patents;
  List<NgoOrStudentOrgs>? ngoOrStudentOrgs;
  String? id;
  String? userId;
  String? name;
  String? email;
  String? phone;
  String? location;
  String? profilePicture;
  String? bio;
  SalaryDetails? salaryDetails;
  CurrentJob? currentJob;
  String? careerObjective;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (education != null) {
      map['education'] = education?.map((v) => v.toJson()).toList();
    }
    if (fullTimeExperience != null) {
      map['fullTimeExperience'] = fullTimeExperience?.map((v) => v.toJson()).toList();
    }
    if (partTimeExperience != null) {
      map['partTimeExperience'] = partTimeExperience?.map((v) => v.toJson()).toList();
    }
    map['skills'] = skills;
    map['languages'] = languages;
    map['portfolios'] = portfolios;
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
      map['additionalInformation'] = additionalInformation?.map((v) => v.toJson()).toList();
    }
    if (patents != null) {
      map['patents'] = patents?.map((v) => v.toJson()).toList();
    }
    if (ngoOrStudentOrgs != null) {
      map['ngoOrStudentOrgs'] = ngoOrStudentOrgs?.map((v) => v.toJson()).toList();
    }
    map['id'] = id;
    map['userId'] = userId;
    map['name'] = name;
    map['email'] = email;
    map['phone'] = phone;
    map['location'] = location;
    map['profilePicture'] = profilePicture;
    map['bio'] = bio;
    if (salaryDetails != null) {
      map['salaryDetails'] = salaryDetails?.toJson();
    }
    if (currentJob != null) {
      map['currentJob'] = currentJob?.toJson();
    }
    map['careerObjective'] = careerObjective;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

}

CurrentJob currentJobFromJson(String str) => CurrentJob.fromJson(json.decode(str));
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
      this.description,});

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

SalaryDetails salaryDetailsFromJson(String str) => SalaryDetails.fromJson(json.decode(str));
String salaryDetailsToJson(SalaryDetails data) => json.encode(data.toJson());
class SalaryDetails {
  SalaryDetails({
      this.grossSalary, 
      this.monthlyDeduction, 
      this.monthlyEarningViaPartTime, 
      this.monthlyEarningViaFreelancing, 
      this.monthlyTotalEarning, 
      this.annualPackage,});

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

NgoOrStudentOrgs ngoOrStudentOrgsFromJson(String str) => NgoOrStudentOrgs.fromJson(json.decode(str));
String ngoOrStudentOrgsToJson(NgoOrStudentOrgs data) => json.encode(data.toJson());
class NgoOrStudentOrgs {
  NgoOrStudentOrgs({
      this.title, 
      this.certifiedDate, 
      this.description, 
      this.attachment,});

  NgoOrStudentOrgs.fromJson(dynamic json) {
    title = json['title'];
    certifiedDate = json['certifiedDate'];
    description = json['description'];
    attachment = json['attachment'];
  }
  String? title;
  String? certifiedDate;
  String? description;
  String? attachment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['certifiedDate'] = certifiedDate;
    map['description'] = description;
    map['attachment'] = attachment;
    return map;
  }

}

Patents patentsFromJson(String str) => Patents.fromJson(json.decode(str));
String patentsToJson(Patents data) => json.encode(data.toJson());
class Patents {
  Patents({
      this.title, 
      this.issuedDate, 
      this.description, 
      this.patentCertification,});

  Patents.fromJson(dynamic json) {
    title = json['title'];
    issuedDate = json['issuedDate'];
    description = json['description'];
    patentCertification = json['patentCertification'];
  }
  String? title;
  String? issuedDate;
  String? description;
  String? patentCertification;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['issuedDate'] = issuedDate;
    map['description'] = description;
    map['patentCertification'] = patentCertification;
    return map;
  }

}

AdditionalInformation additionalInformationFromJson(String str) => AdditionalInformation.fromJson(json.decode(str));
String additionalInformationToJson(AdditionalInformation data) => json.encode(data.toJson());
class AdditionalInformation {
  AdditionalInformation({
      this.title, 
      this.info, 
      this.date, 
      this.photoURL,});

  AdditionalInformation.fromJson(dynamic json) {
    title = json['title'];
    info = json['info'];
    date = json['date'];
    photoURL = json['photoURL'];
  }
  String? title;
  String? info;
  String? date;
  String? photoURL;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['info'] = info;
    map['date'] = date;
    map['photoURL'] = photoURL;
    return map;
  }

}

Hobbies hobbiesFromJson(String str) => Hobbies.fromJson(json.decode(str));
String hobbiesToJson(Hobbies data) => json.encode(data.toJson());
class Hobbies {
  Hobbies({
      this.name, 
      this.description,});

  Hobbies.fromJson(dynamic json) {
    name = json['name'];
    description = json['description'];
  }
  String? name;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['description'] = description;
    return map;
  }

}

Publications publicationsFromJson(String str) => Publications.fromJson(json.decode(str));
String publicationsToJson(Publications data) => json.encode(data.toJson());
class Publications {
  Publications({
      this.title, 
      this.link, 
      this.publishedDate, 
      this.description,});

  Publications.fromJson(dynamic json) {
    title = json['title'];
    link = json['link'];
    publishedDate = json['publishedDate'];
    description = json['description'];
  }
  String? title;
  String? link;
  String? publishedDate;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['link'] = link;
    map['publishedDate'] = publishedDate;
    map['description'] = description;
    return map;
  }

}

Certifications certificationsFromJson(String str) => Certifications.fromJson(json.decode(str));
String certificationsToJson(Certifications data) => json.encode(data.toJson());
class Certifications {
  Certifications({
      this.title, 
      this.issuingOrg, 
      this.certificateDate, 
      this.certificateAttachment,});

  Certifications.fromJson(dynamic json) {
    title = json['title'];
    issuingOrg = json['issuingOrg'];
    certificateDate = json['certificateDate'];
    certificateAttachment = json['certificateAttachment'];
  }
  String? title;
  String? issuingOrg;
  String? certificateDate;
  String? certificateAttachment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['issuingOrg'] = issuingOrg;
    map['certificateDate'] = certificateDate;
    map['certificateAttachment'] = certificateAttachment;
    return map;
  }

}

Achievements achievementsFromJson(String str) => Achievements.fromJson(json.decode(str));
String achievementsToJson(Achievements data) => json.encode(data.toJson());
class Achievements {
  Achievements({
      this.title, 
      this.date, 
      this.description, 
      this.attachment,});

  Achievements.fromJson(dynamic json) {
    title = json['title'];
    date = json['date'];
    description = json['description'];
    attachment = json['attachment'];
  }
  String? title;
  String? date;
  String? description;
  String? attachment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['date'] = date;
    map['description'] = description;
    map['attachment'] = attachment;
    return map;
  }

}

Awards awardsFromJson(String str) => Awards.fromJson(json.decode(str));
String awardsToJson(Awards data) => json.encode(data.toJson());
class Awards {
  Awards({
      this.title, 
      this.issuedBy, 
      this.issuedDate, 
      this.description, 
      this.attachment,});

  Awards.fromJson(dynamic json) {
    title = json['title'];
    issuedBy = json['issuedBy'];
    issuedDate = json['issuedDate'];
    description = json['description'];
    attachment = json['attachment'];
  }
  String? title;
  String? issuedBy;
  String? issuedDate;
  String? description;
  String? attachment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['issuedBy'] = issuedBy;
    map['issuedDate'] = issuedDate;
    map['description'] = description;
    map['attachment'] = attachment;
    return map;
  }

}

PartTimeExperience partTimeExperienceFromJson(String str) => PartTimeExperience.fromJson(json.decode(str));
String partTimeExperienceToJson(PartTimeExperience data) => json.encode(data.toJson());
class PartTimeExperience {
  PartTimeExperience({
      this.previousCompanyName, 
      this.designation, 
      this.jobType, 
      this.workMode, 
      this.location, 
      this.startDate, 
      this.endDate, 
      this.description,});

  PartTimeExperience.fromJson(dynamic json) {
    previousCompanyName = json['previousCompanyName'];
    designation = json['designation'];
    jobType = json['jobType'];
    workMode = json['workMode'];
    location = json['location'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    description = json['description'];
  }
  String? previousCompanyName;
  String? designation;
  String? jobType;
  String? workMode;
  String? location;
  String? startDate;
  String? endDate;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['previousCompanyName'] = previousCompanyName;
    map['designation'] = designation;
    map['jobType'] = jobType;
    map['workMode'] = workMode;
    map['location'] = location;
    map['startDate'] = startDate;
    map['endDate'] = endDate;
    map['description'] = description;
    return map;
  }

}

FullTimeExperience fullTimeExperienceFromJson(String str) => FullTimeExperience.fromJson(json.decode(str));
String fullTimeExperienceToJson(FullTimeExperience data) => json.encode(data.toJson());
class FullTimeExperience {
  FullTimeExperience({
      this.previousCompanyName, 
      this.designation, 
      this.jobType, 
      this.workMode, 
      this.location, 
      this.startDate, 
      this.endDate, 
      this.description,});

  FullTimeExperience.fromJson(dynamic json) {
    previousCompanyName = json['previousCompanyName'];
    designation = json['designation'];
    jobType = json['jobType'];
    workMode = json['workMode'];
    location = json['location'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    description = json['description'];
  }
  String? previousCompanyName;
  String? designation;
  String? jobType;
  String? workMode;
  String? location;
  String? startDate;
  String? endDate;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['previousCompanyName'] = previousCompanyName;
    map['designation'] = designation;
    map['jobType'] = jobType;
    map['workMode'] = workMode;
    map['location'] = location;
    map['startDate'] = startDate;
    map['endDate'] = endDate;
    map['description'] = description;
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
      this.percentage,});

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

AnswersToCustomQuestions answersToCustomQuestionsFromJson(String str) => AnswersToCustomQuestions.fromJson(json.decode(str));
String answersToCustomQuestionsToJson(AnswersToCustomQuestions data) => json.encode(data.toJson());
class AnswersToCustomQuestions {
  AnswersToCustomQuestions({
      this.question, 
      this.answer, 
      this.id,});

  AnswersToCustomQuestions.fromJson(dynamic json) {
    question = json['question'];
    answer = json['answer'];
    id = json['_id'];
  }
  String? question;
  String? answer;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['question'] = question;
    map['answer'] = answer;
    map['_id'] = id;
    return map;
  }

}

StatusHistory statusHistoryFromJson(String str) => StatusHistory.fromJson(json.decode(str));
String statusHistoryToJson(StatusHistory data) => json.encode(data.toJson());
class StatusHistory {
  StatusHistory({
      this.status, 
      this.id, 
      this.changedOn,});

  StatusHistory.fromJson(dynamic json) {
    status = json['status'];
    id = json['_id'];
    changedOn = json['changedOn'];
  }
  String? status;
  String? id;
  String? changedOn;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['_id'] = id;
    map['changedOn'] = changedOn;
    return map;
  }

}

Address addressFromJson(String str) => Address.fromJson(json.decode(str));
String addressToJson(Address data) => json.encode(data.toJson());
class Address {
  Address({
      this.city,});

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