import 'dart:convert';

import 'package:BlueEra/features/common/auth/model/get_all_jobs_model.dart';
import 'package:BlueEra/features/common/auth/model/get_job_details_byId_model.dart';

GetSavedJobModel getSavedJobModelFromJson(String str) =>
    GetSavedJobModel.fromJson(json.decode(str));

String getSavedJobModelToJson(GetSavedJobModel data) =>
    json.encode(data.toJson());

class GetSavedJobModel {
  GetSavedJobModel({
    this.message,
    this.savedJobs,
  });

  GetSavedJobModel.fromJson(dynamic json) {
    message = json['message'];
    if (json['savedJobs'] != null) {
      savedJobs = [];
      json['savedJobs'].forEach((v) {
        savedJobs?.add(SavedJobs.fromJson(v));
      });
    }
  }

  String? message;
  List<SavedJobs>? savedJobs;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    if (savedJobs != null) {
      map['savedJobs'] = savedJobs?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

SavedJobs savedJobsFromJson(String str) => SavedJobs.fromJson(json.decode(str));

String savedJobsToJson(SavedJobs data) => json.encode(data.toJson());

class SavedJobs {
  SavedJobs({
    this.id,
    this.jobId,
    this.userId,
    this.savedAt,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  SavedJobs.fromJson(dynamic json) {
    id = json['_id'];
    jobId = json['jobId'] != null ? Jobs.fromJson(json['jobId']) : null;
    userId = json['userId'];
    savedAt = json['savedAt'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    v = json['__v'];
  }

  String? id;
  Jobs? jobId;
  String? userId;
  String? savedAt;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    if (jobId != null) {
      map['jobId'] = jobId?.toJson();
    }
    map['userId'] = userId;
    map['savedAt'] = savedAt;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;
    return map;
  }
}

JobId jobIdFromJson(String str) => JobId.fromJson(json.decode(str));

String jobIdToJson(JobId data) => json.encode(data.toJson());

class JobId {
  JobId({
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

  JobId.fromJson(dynamic json) {
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
    applications =
        json['applications'] != null ? json['applications'].cast<String>() : [];
    languages =
        json['languages'] != null ? json['languages'].cast<String>() : [];
    postedBy = json['postedBy'];
    status = json['status'];

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
        ? new BusinessDetails.fromJson(json['businessDetails'])
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
    if (this.businessDetails != null) {
      map['businessDetails'] = this.businessDetails!.toJson();
    }
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
