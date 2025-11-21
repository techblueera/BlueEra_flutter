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
  String? sId;
  String? jobTitle;
  String? companyName;
  String? jobType;
  String? workMode;
  Location? location;
  String? jobPostImage;
  List<String>? jobHighlights;
  int? experience;
  String? status;
  bool? isApplied;
  List<String>? applications;
  String? createdAt;
  BusinessDetails? businessDetails;

  Jobs({
    this.compensation,
    this.sId,
    this.jobTitle,
    this.companyName,
    this.jobType,
    this.workMode,
    this.location,
    this.jobPostImage,
    this.jobHighlights,
    this.experience,
    this.status,
    this.isApplied,
    this.applications,
    this.createdAt,
    this.businessDetails,
  });

  Jobs.fromJson(Map<String, dynamic> json) {
    try {
      compensation = json['compensation'] != null
          ? new Compensation.fromJson(json['compensation'])
          : null;

      sId = json['_id'];
      jobTitle = json['jobTitle'];
      companyName = json['companyName'];
      jobType = json['jobType'];
      workMode = json['workMode'];
      location = json['location'] != null
          ? new Location.fromJson(json['location'])
          : null;
      jobPostImage = json['jobPostImage'];
      applications = json['applications'] != null
          ? List<String>.from(
              json['applications'].map((e) => e?.toString() ?? ''))
          : null;

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

      status = json['status'];
      isApplied = json['isApplied'];

      createdAt = json['createdAt'];
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

    data['_id'] = this.sId;
    data['jobTitle'] = this.jobTitle;
    data['companyName'] = this.companyName;
    data['jobType'] = this.jobType;
    data['workMode'] = this.workMode;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['jobPostImage'] = this.jobPostImage;
    data['jobHighlights'] = this.jobHighlights;
    data['experience'] = this.experience;
    data['status'] = this.status;
    data['isApplied'] = this.isApplied;
    data['applications'] = this.applications;
    data['createdAt'] = this.createdAt;
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
