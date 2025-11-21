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
    this.v,
  });

  SavedJobs.fromJson(dynamic json) {
    id = json['_id'];
    jobId = json['jobId'] != null ? Jobs.fromJson(json['jobId']) : null;
    v = json['__v'];
  }

  String? id;
  Jobs? jobId;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    if (jobId != null) {
      map['jobId'] = jobId?.toJson();
    }
    map['__v'] = v;
    return map;
  }
}

JobId jobIdFromJson(String str) => JobId.fromJson(json.decode(str));

String jobIdToJson(JobId data) => json.encode(data.toJson());

class JobId {
  JobId({
    this.id,

    this.jobType,
    this.workMode,
    this.location,

  });

  JobId.fromJson(dynamic json) {

    id = json['_id'];

    jobType = json['jobType'];
    workMode = json['workMode'];
    location =
        json['location'] != null ? Location.fromJson(json['location']) : null;

  }

  String? id;
  String? jobType;
  String? workMode;
  Location? location;


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    map['_id'] = id;
    map['jobType'] = jobType;
    map['workMode'] = workMode;
    if (location != null) {
      map['location'] = location?.toJson();
    }

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
