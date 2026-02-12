import 'dart:convert';
import 'package:BlueEra/core/api/model/personal_identity_model.dart';
import 'package:BlueEra/core/api/model/social_event_model.dart';
import 'package:BlueEra/core/api/model/social_vision_mission_model.dart';
import 'package:BlueEra/core/api/model/social_activity_res_model.dart';
import 'package:BlueEra/features/me/social/model/social_activity_feed_res_model.dart';
import 'package:BlueEra/features/me/social/model/social_certification_res_model.dart';
import 'package:BlueEra/features/me/social/model/social_contact_us_res_model.dart';

SocialProfileResModel socialProfileResModelFromJson(String str) =>
    SocialProfileResModel.fromJson(json.decode(str));

String socialProfileResModelToJson(SocialProfileResModel data) =>
    json.encode(data.toJson());

class SocialProfileResModel {
  bool? success;
  SocialProfileData? data;

  SocialProfileResModel({this.success, this.data});

  SocialProfileResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? SocialProfileData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
  }
}

class SocialProfileData {
  PersonalIdentityData? identity;
  List<SocialActivityFeedData>? activities;
  List<SocialEventData>? events;
  List<SocialCertificationData>? achievements;
  SocialVisionMissionData? missionVision;
  List<SocialActivityData>? socialActivities;
  SocialContactUsData? contact;

  SocialProfileData({
    this.identity,
    this.activities,
    this.events,
    this.achievements,
    this.missionVision,
    this.socialActivities,
    this.contact,
  });

  SocialProfileData.fromJson(Map<String, dynamic> json) {
    identity = json['identity'] != null
        ? PersonalIdentityData.fromJson(json['identity'])
        : null;

    if (json['activities'] != null) {
      activities = [];
      for (final v in (json['activities'] as List)) {
        activities!.add(SocialActivityFeedData.fromJson(v));
      }
    }

    if (json['events'] != null) {
      events = [];
      for (final v in (json['events'] as List)) {
        events!.add(SocialEventData.fromJson(v));
      }
    }

    if (json['achievements'] != null) {
      achievements = [];
      for (final v in (json['achievements'] as List)) {
        achievements!.add(SocialCertificationData.fromJson(v));
      }
    }

    missionVision = json['missionVision'] != null
        ? SocialVisionMissionData.fromJson(json['missionVision'])
        : null;

    if (json['socialActivities'] != null) {
      socialActivities = [];
      for (final v in (json['socialActivities'] as List)) {
        socialActivities!.add(SocialActivityData.fromJson(v));
      }
    }

    contact = json['contact'] != null
        ? SocialContactUsData.fromJson(json['contact'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (identity != null) map['identity'] = identity!.toJson();
    if (activities != null) {
      map['activities'] = activities!.map((v) => v.toJson()).toList();
    }
    if (events != null) {
      map['events'] = events!.map((v) => v.toJson()).toList();
    }
    if (achievements != null) {
      map['achievements'] = achievements!.map((v) => v.toJson()).toList();
    }
    if (missionVision != null) {
      map['missionVision'] = missionVision!.toJson();
    }
    if (socialActivities != null) {
      map['socialActivities'] = socialActivities!.map((v) => v.toJson()).toList();
    }
    if (contact != null) map['contact'] = contact!.toJson();
    return map;
  }
}
