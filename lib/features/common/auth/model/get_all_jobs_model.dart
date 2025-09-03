import 'package:BlueEra/features/common/auth/model/get_job_details_byId_model.dart';

class GetAllJobPostsModel {
  String? message;
  List<Jobs>? jobs;

  GetAllJobPostsModel({this.message, this.jobs});

  GetAllJobPostsModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];

    if (json['jobs'] != null) {
      jobs = <Jobs>[];
      json['jobs'].forEach((v) {
        try {
          jobs!.add(new Jobs.fromJson(v));
        } catch (e) {
          print("Error processing job: $e");
        }
      });
    } else {
      jobs = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['message'] = this.message;
    if (this.jobs != null) {
      data['jobs'] = this.jobs!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  @override
  String toString() {
    return 'GetAllJobPostsModel{message: $message, jobsCount: ${jobs?.length ?? 0}}';
  }
}

class Jobs {
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
  bool? isApplied;
  List<String>? applications;
  List<CustomQuestions>? customQuestions;
  String? postedOn;
  String? createdAt;
  String? updatedAt;
  int? iV;
  String? gender;
  String? qualifications;
  BusinessDetails? businessDetails;

  Jobs(
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
        this.isApplied,
        this.applications,
        this.customQuestions,
        this.postedOn,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.gender,
        this.businessDetails,

        this.qualifications});

  Jobs.fromJson(Map<String, dynamic> json) {
    try {
      compensation = json['compensation'] != null
          ? new Compensation.fromJson(json['compensation'])
          : null;
      interviewDetails = json['interviewDetails'] != null
          ? new InterviewDetails.fromJson(json['interviewDetails'])
          : null;
      sId = json['_id'];
      jobTitle = json['jobTitle'];
      companyName = json['companyName'];
      jobType = json['jobType'];
      workMode = json['workMode'];
      department = json['department'];
      location = json['location'] != null
          ? new Location.fromJson(json['location'])
          : null;
      jobPostImage = json['jobPostImage'];
      applications = json['applications'] != null ? List<String>.from(json['applications'].map((e) => e?.toString() ?? '')) : null;

      // Handle benefits safely
      if (json['benefits'] != null) {
        try {
          benefits = List<String>.from(json['benefits']);
        } catch (e) {
          benefits = null;
        }
      } else {
        benefits = null;
      }
      
      jobDescription = json['jobDescription'];
      
      // Handle jobHighlights safely
      if (json['jobHighlights'] != null) {
        try {
          jobHighlights = List<String>.from(json['jobHighlights']);
        } catch (e) {
          jobHighlights = null;
        }
      } else {
        jobHighlights = null;
      }
      
      experience = json['experience'];
      
      // Handle skills safely
      if (json['skills'] != null) {
        try {
          skills = List<String>.from(json['skills']);
        } catch (e) {
          skills = null;
        }
      } else {
        skills = null;
      }
      
      // Handle languages safely
      if (json['languages'] != null) {
        try {
          languages = List<String>.from(json['languages']);
        } catch (e) {
          languages = null;
        }
      } else {
        languages = null;
      }
      
      postedBy = json['postedBy'];
      status = json['status'];
      isApplied = json['isApplied'];

      if (json['customQuestions'] != null) {
        customQuestions = <CustomQuestions>[];
        json['customQuestions'].forEach((v) {
          customQuestions!.add(new CustomQuestions.fromJson(v));
        });
      }
      postedOn = json['postedOn'];
      createdAt = json['createdAt'];
      updatedAt = json['updatedAt'];
      iV = json['__v'];
      gender = json['gender'];
      qualifications = json['qualifications'];
      businessDetails = json['businessDetails'] != null
          ? new BusinessDetails.fromJson(json['businessDetails'])
          : null;
    } catch (e) {
      print("Error parsing Jobs.fromJson: $e");
      rethrow;
    }
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
    data['skills'] = this.skills;
    data['languages'] = this.languages;
    data['postedBy'] = this.postedBy;
    data['status'] = this.status;
    data['isApplied'] = this.isApplied;
    data['applications'] = this.applications;
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

  @override
  String toString() {
    return 'Jobs{jobTitle: $jobTitle, companyName: $companyName, jobType: $jobType, workMode: $workMode, experience: $experience, sId: $sId}';
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
    interviewAddress = json['interviewAddress'];
    walkInStartDate = json['walkInStartDate'];
    walkInEndDate = json['walkInEndDate'];
    walkInStartTime = json['walkInStartTime'];
    walkInEndTime = json['walkInEndTime'];
    otherInstructions = json['otherInstructions'];
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
  bool? whatsApp;

  CommunicationPreferences(
      {this.both, this.call, this.chat, this.weContact, this.whatsApp});

  CommunicationPreferences.fromJson(Map<String, dynamic> json) {
    both = json['both'];
    call = json['call'];
    chat = json['chat'];
    weContact = json['weContact'];
    whatsApp = json['whatsApp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['both'] = this.both;
    data['call'] = this.call;
    data['chat'] = this.chat;
    data['weContact'] = this.weContact;
    data['whatsApp'] = this.whatsApp;
    return data;
  }
}

class Location {
  String? latitude;
  String? longitude;
  String? addressString;
  String? altitude;

  Location({this.latitude, this.longitude, this.addressString, this.altitude});

  Location.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'].toString();
    longitude = json['longitude'].toString();
    addressString = json['addressString'].toString();
    altitude = json['altitude'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['addressString'] = this.addressString;
    data['altitude'] = this.altitude;
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
    question = json['question'];
    answerType = json['answerType'];
    
    // Handle options safely
    if (json['options'] != null) {
      try {
        options = List<String>.from(json['options']);
      } catch (e) {
        options = null;
      }
    } else {
      options = null;
    }
    
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
