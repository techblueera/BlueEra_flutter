class GetJobDetailsByIdModel {
  String? message;
  Job? job;
  bool? isSavedByUser;
  bool? isApplied;

  GetJobDetailsByIdModel({this.message, this.job, this.isSavedByUser, this.isApplied});

  GetJobDetailsByIdModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    isApplied = json['isApplied'];
    isSavedByUser = json['isSavedByUser'];
    job = json['job'] != null ? new Job.fromJson(json['job']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    data['isApplied'] = this.isApplied;
    data['isSavedByUser'] = this.isSavedByUser;
    if (this.job != null) {
      data['job'] = this.job!.toJson();
    }
    return data;
  }
}

class Job {
  Compensation? compensation;
  InterviewDetails? interviewDetails;
  String? sId;
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
  int? iV;
  String? gender;
  String? qualifications;
  BusinessDetails? businessDetails;

  Job(
      {this.compensation,
        this.interviewDetails,
        this.sId,
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
        this.iV,
        this.gender,
        this.businessDetails,
        this.qualifications});

  Job.fromJson(Map<String, dynamic> json) {
    try {
      compensation = json['compensation'] != null
          ? new Compensation.fromJson(json['compensation'])
          : null;
    } catch (e) {
      print("Error parsing compensation: $e");
      compensation = null;
    }
    
    try {
      interviewDetails = json['interviewDetails'] != null
          ? new InterviewDetails.fromJson(json['interviewDetails'])
          : null;
    } catch (e) {
      print("Error parsing interviewDetails: $e");
      interviewDetails = null;
    }
    
    sId = json['_id'];
    
    // Handle cases where API returns "string" as literal value instead of actual data
    jobTitle = json['jobTitle'] != null && json['jobTitle'] != "string" 
        ? json['jobTitle'] 
        : null;
    companyName = json['companyName'] != null && json['companyName'] != "string" 
        ? json['companyName'] 
        : null;
    jobType = json['jobType'];
    workMode = json['workMode'];
    department = json['department'] != null && json['department'] != "string" 
        ? json['department'] 
        : null;
    
    try {
      location = json['location'] != null
          ? new Location.fromJson(json['location'])
          : null;
    } catch (e) {
      print("Error parsing location: $e");
      location = null;
    }
    
    jobPostImage = json['jobPostImage'];
    
    // Safe casting for arrays with null checks
    benefits = json['benefits'] != null ? List<String>.from(json['benefits'].map((e) => e?.toString() ?? '')) : null;
    jobDescription = json['jobDescription'] != null && json['jobDescription'] != "string" 
        ? json['jobDescription'] 
        : null;
    jobHighlights = json['jobHighlights'] != null ? List<String>.from(json['jobHighlights'].map((e) => e?.toString() ?? '')) : null;
    applications = json['applications'] != null ? List<String>.from(json['applications'].map((e) => e?.toString() ?? '')) : null;
    experience = json['experience'];
    skills = json['skills'] != null ? List<String>.from(json['skills'].map((e) => e?.toString() ?? '')) : null;
    languages = json['languages'] != null ? List<String>.from(json['languages'].map((e) => e?.toString() ?? '')) : null;
    postedBy = json['postedBy'];
    status = json['status'];

    if (json['customQuestions'] != null) {
      try {
        customQuestions = <CustomQuestions>[];
        json['customQuestions'].forEach((v) {
          try {
            customQuestions!.add(new CustomQuestions.fromJson(v));
          } catch (e) {
            print("Error parsing custom question: $e");
            // Skip this question if it fails to parse
          }
        });
      } catch (e) {
        print("Error parsing customQuestions array: $e");
        customQuestions = null;
      }
    }
    postedOn = json['postedOn'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    gender = json['gender'];
    qualifications = json['qualifications'] != null && json['qualifications'] != "string" 
        ? json['qualifications'] 
        : null;
    businessDetails = json['businessDetails'] != null
        ? new BusinessDetails.fromJson(json['businessDetails'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.compensation != null) {
      data['compensation'] = this.compensation!.toJson();
    }
    if (this.interviewDetails != null) {
      data['interviewDetails'] = this.interviewDetails!.toJson();
    }
    data['_id'] = this.sId;
    data['jobTitle'] = this.jobTitle;
    data['companyName'] = this.companyName;
    data['jobType'] = this.jobType;
    data['workMode'] = this.workMode;
    data['department'] = this.department;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['jobPostImage'] = this.jobPostImage;
    data['benefits'] = this.benefits;
    data['jobDescription'] = this.jobDescription;
    data['jobHighlights'] = this.jobHighlights;
    data['experience'] = this.experience;
    data['applications'] = this.applications;
    data['skills'] = this.skills;
    data['languages'] = this.languages;
    data['postedBy'] = this.postedBy;
    data['status'] = this.status;

    if (this.customQuestions != null) {
      data['customQuestions'] =
          this.customQuestions!.map((v) => v.toJson()).toList();
    }
    data['postedOn'] = this.postedOn;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['gender'] = this.gender;
    data['qualifications'] = this.qualifications;
    if (this.businessDetails != null) {
      data['businessDetails'] = this.businessDetails!.toJson();
    }
    return data;
  }
}

class Compensation {
  String? type;
  int? minSalary;
  int? maxSalary;

  Compensation({this.type, this.minSalary, this.maxSalary});

  Compensation.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    minSalary = json['minSalary'];
    maxSalary = json['maxSalary'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['minSalary'] = this.minSalary;
    data['maxSalary'] = this.maxSalary;
    return data;
  }
}

class InterviewDetails {
  CommunicationPreferences? communicationPreferences;
  bool? isWalkIn;
  String? interviewAddress;
  String? walkInStartDate;
  String? walkInEndDate;
  String? walkInStartTime;
  String? walkInEndTime;
  String? otherInstructions;

  InterviewDetails(
      {this.communicationPreferences,
        this.isWalkIn,
        this.interviewAddress,
        this.walkInStartDate,
        this.walkInEndDate,
        this.walkInStartTime,
        this.walkInEndTime,
        this.otherInstructions});

  InterviewDetails.fromJson(Map<String, dynamic> json) {
    communicationPreferences = json['communicationPreferences'] != null
        ? new CommunicationPreferences.fromJson(
        json['communicationPreferences'])
        : null;
    isWalkIn = json['isWalkIn'];
    
    // Handle cases where API returns "string" as literal value instead of actual data
    interviewAddress = json['interviewAddress'] != null && json['interviewAddress'] != "string" 
        ? json['interviewAddress'] 
        : null;
    walkInStartDate = json['walkInStartDate'];
    walkInEndDate = json['walkInEndDate'];
    walkInStartTime = json['walkInStartTime'] != null && json['walkInStartTime'] != "string" 
        ? json['walkInStartTime'] 
        : null;
    walkInEndTime = json['walkInEndTime'] != null && json['walkInEndTime'] != "string" 
        ? json['walkInEndTime'] 
        : null;
    otherInstructions = json['otherInstructions'] != null && json['otherInstructions'] != "string" 
        ? json['otherInstructions'] 
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.communicationPreferences != null) {
      data['communicationPreferences'] =
          this.communicationPreferences!.toJson();
    }
    data['isWalkIn'] = this.isWalkIn;
    data['interviewAddress'] = this.interviewAddress;
    data['walkInStartDate'] = this.walkInStartDate;
    data['walkInEndDate'] = this.walkInEndDate;
    data['walkInStartTime'] = this.walkInStartTime;
    data['walkInEndTime'] = this.walkInEndTime;
    data['otherInstructions'] = this.otherInstructions;
    return data;
  }
}

class CommunicationPreferences {
  bool? both;
  bool? call;
  bool? chat;
  bool? weContact;

  CommunicationPreferences({this.both, this.call, this.chat, this.weContact});

  CommunicationPreferences.fromJson(Map<String, dynamic> json) {
    both = json['both'];
    call = json['call'];
    chat = json['chat'];
    weContact = json['weContact'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['both'] = this.both;
    data['call'] = this.call;
    data['chat'] = this.chat;
    data['weContact'] = this.weContact;
    return data;
  }
}

class Location {
  String? latitude;
  String? longitude;
  String? addressString;

  Location({this.latitude, this.longitude, this.addressString});

  Location.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
    addressString = json['addressString'] != null && json['addressString'] != "string" 
        ? json['addressString'] 
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['addressString'] = this.addressString;
    return data;
  }
}

class CustomQuestions {
  String? question;
  String? answerType;
  List<String>? options;
  bool? isMandatory;
  String? sId;

  CustomQuestions(
      {this.question,
        this.answerType,
        this.options,
        this.isMandatory,
        this.sId});

  CustomQuestions.fromJson(Map<String, dynamic> json) {
    question = json['question'] != null && json['question'] != "string" 
        ? json['question'] 
        : null;
    answerType = json['answerType'];
    options = json['options'] != null ? List<String>.from(json['options'].map((e) => e?.toString() ?? '')) : null;
    isMandatory = json['isMandatory'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['question'] = this.question;
    data['answerType'] = this.answerType;
    data['options'] = this.options;
    data['isMandatory'] = this.isMandatory;
    data['_id'] = this.sId;
    return data;
  }
}

class BusinessDetails {
  String? businessDescription;
  String? businessName;
  String? buisness_logo;
  String? id;
  DateOfIncorporation? dateOfIncorporation;

  BusinessDetails(
      {this.id,this.businessDescription, this.businessName, this.buisness_logo, this.dateOfIncorporation});

  BusinessDetails.fromJson(Map<String, dynamic> json) {
    buisness_logo = json['buisness_logo'];
    id = json['id'];
    businessDescription = json['business_description'];
    businessName = json['business_name'];
    dateOfIncorporation = json['date_of_incorporation'] != null
        ? new DateOfIncorporation.fromJson(json['date_of_incorporation'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['business_description'] = this.businessDescription;
    data['id'] = this.id;
    data['business_name'] = this.businessName;
    data['buisness_logo'] = this.buisness_logo;
    if (this.dateOfIncorporation != null) {
      data['date_of_incorporation'] = this.dateOfIncorporation!.toJson();
    }
    return data;
  }
}

class DateOfIncorporation {
  int? date;
  int? month;
  int? year;

  DateOfIncorporation({this.date, this.month, this.year});

  DateOfIncorporation.fromJson(Map<String, dynamic> json) {
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