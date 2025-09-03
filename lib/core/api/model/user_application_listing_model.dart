import 'dart:convert';
UserApplicationListingModel userApplicationListingModelFromJson(String str) => UserApplicationListingModel.fromJson(json.decode(str));
String userApplicationListingModelToJson(UserApplicationListingModel data) => json.encode(data.toJson());
class UserApplicationListingModel {
  UserApplicationListingModel({
      this.message, 
      this.applications,});

  UserApplicationListingModel.fromJson(dynamic json) {
    message = json['message'];
    if (json['applications'] != null) {
      applications = [];
      json['applications'].forEach((v) {
        applications?.add(UserApplications.fromJson(v));
      });
    }
  }
  String? message;
  List<UserApplications>? applications;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    if (applications != null) {
      map['applications'] = applications?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

UserApplications applicationsFromJson(String str) => UserApplications.fromJson(json.decode(str));
String applicationsToJson(UserApplications data) => json.encode(data.toJson());
class UserApplications {
  UserApplications({
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
      this.applicationDate,
      this.recruiterNotes, 
      this.createdAt, 
      this.updatedAt, 
      this.hasSubmittedFeedback,
      this.v,
   });

  UserApplications.fromJson(dynamic json) {
    address = json['address'] != null ? Address.fromJson(json['address']) : null;
    id = json['_id'];
    jobId = json['jobId'] != null ? JobId.fromJson(json['jobId']) : null;
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

    applicationDate = json['applicationDate'];

    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    hasSubmittedFeedback = json['hasSubmittedFeedback'];
    v = json['__v'];
  }
  Address? address;
  String? id;
  JobId? jobId;
  String? candidateId;
  String? candidateName;
  String? candidateEmail;
  String? candidatePhone;
  String? resumeId;
  String? status;
  List<StatusHistory>? statusHistory;
  String? applicationDate;
  List<dynamic>? recruiterNotes;
  String? createdAt;
  String? updatedAt;
  bool? hasSubmittedFeedback;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (address != null) {
      map['address'] = address?.toJson();
    }
    map['_id'] = id;
    if (jobId != null) {
      map['jobId'] = jobId?.toJson();
    }
    map['hasSubmittedFeedback'] = hasSubmittedFeedback;
    map['candidateId'] = candidateId;
    map['candidateName'] = candidateName;
    map['candidateEmail'] = candidateEmail;
    map['candidatePhone'] = candidatePhone;
    map['resumeId'] = resumeId;
    map['status'] = status;
    if (statusHistory != null) {
      map['statusHistory'] = statusHistory?.map((v) => v.toJson()).toList();
    }

    map['applicationDate'] = applicationDate;
    if (recruiterNotes != null) {
      map['recruiterNotes'] = recruiterNotes?.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['__v'] = v;

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

JobId jobIdFromJson(String str) => JobId.fromJson(json.decode(str));
String jobIdToJson(JobId data) => json.encode(data.toJson());
class JobId {
  JobId({
      this.id, 
      this.jobTitle, 
      this.companyName, 
      this.jobType, 
      this.location, 
      this.workMode,
      this.jobPostImage,
      this.postedBy, 
      this.compensation,
      this.businessDetails,});

  JobId.fromJson(dynamic json) {
    id = json['_id'];
    jobTitle = json['jobTitle'];
    companyName = json['companyName'];
    jobType = json['jobType'];
    workMode = json['workMode'];
    location = json['location'] != null ? Location.fromJson(json['location']) : null;
    jobPostImage = json['jobPostImage'];
    postedBy = json['postedBy'];
    businessDetails = json['businessDetails'] != null ? BusinessDetails.fromJson(json['businessDetails']) : null;
    compensation = json['compensation'] != null ? Compensation.fromJson(json['compensation']) : null;

  }
  String? id;
  String? jobTitle;
  String? companyName;
  String? jobType;
  String? workMode;
  Location? location;
  String? jobPostImage;
  String? postedBy;
  BusinessDetails? businessDetails;
  Compensation? compensation;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['jobTitle'] = jobTitle;
    map['companyName'] = companyName;
    map['jobType'] = jobType;
    map['workMode'] = workMode;
    if (location != null) {
      map['location'] = location?.toJson();
    }
    map['jobPostImage'] = jobPostImage;
    map['postedBy'] = postedBy;
    if (businessDetails != null) {
      map['businessDetails'] = businessDetails?.toJson();
    }
    if (compensation != null) {
      map['compensation'] = compensation?.toJson();
    }
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