import 'dart:convert';

import 'package:BlueEra/features/common/auth/model/get_all_jobs_model.dart';
UserCandidateScheduleRes userCandidateScheduleResFromJson(String str) => UserCandidateScheduleRes.fromJson(json.decode(str));
String userCandidateScheduleResToJson(UserCandidateScheduleRes data) => json.encode(data.toJson());
class UserCandidateScheduleRes {
  UserCandidateScheduleRes({
      this.message, 
      this.interviews,});

  UserCandidateScheduleRes.fromJson(dynamic json) {
    message = json['message'];
    if (json['interviews'] != null) {
      interviews = [];
      json['interviews'].forEach((v) {
        interviews?.add(Jobs.fromJson(v));
      });
    }
  }
  String? message;
  List<Jobs>? interviews;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    if (interviews != null) {
      map['interviews'] = interviews?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

