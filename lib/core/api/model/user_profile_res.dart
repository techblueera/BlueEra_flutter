import 'dart:convert';

import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
UserProfileRes userProfileResFromJson(String str) => UserProfileRes.fromJson(json.decode(str));
String userProfileResToJson(UserProfileRes data) => json.encode(data.toJson());
class UserProfileRes {
  UserProfileRes({
      this.success, 
      this.user, 
      this.isFollowing, 
      this.totalPosts, 
      this.followersCount, 
      this.followingCount,});

  UserProfileRes.fromJson(dynamic json) {
    success = json['success'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    isFollowing = json['isFollowing'];
    totalPosts = json['totalPosts'];
    followersCount = json['followersCount'];
    followingCount = json['followingCount'];
  }
  bool? success;
  User? user;
  bool? isFollowing;
  int? totalPosts;
  int? followersCount;
  int? followingCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    map['isFollowing'] = isFollowing;
    map['totalPosts'] = totalPosts;
    map['followersCount'] = followersCount;
    map['followingCount'] = followingCount;
    return map;
  }

}

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());
class User {
  User({
      this.id, 
      this.name, 
      this.gender, 
      this.contactNo, 
      this.profession, 
      this.designation, 
      this.profileImage, 
      this.isEnded, 
      this.username, 
      this.dateOfBirth, 
      this.deletedAt, 
      this.accountType, 
      this.language, 
      this.referralPoints, 
      this.lastSeen, 
      this.location, 
      this.highestEducation, 
      this.role, 
      this.currentOrganisation, 
      this.bio, 
      this.socialLinks, 
      this.userLocation, 
      this.skills, 
      this.emailVerified, 
      this.objective, 
      this.projects, 
      this.experiences, 
      this.createdAt, 
      this.updatedAt, 
      this.v, 
      this.email, 
      this.introVideo,});

  User.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    gender = json['gender'];
    contactNo = json['contact_no'];
    profession = json['profession'];
    designation = json['designation'];
    profileImage = json['profile_image'];
    isEnded = json['is_ended'];
    username = json['username'];
    dateOfBirth = json['date_of_birth'] != null ? DateOfBirth.fromJson(json['date_of_birth']) : null;
    deletedAt = json['deleted_at'];
    accountType = json['account_type'];
    language = json['language'];
    referralPoints = json['referral_points'];
    lastSeen = json['last_seen'];
    location = json['location'];
    highestEducation = json['highest_education'];
    role = json['role'];
    currentOrganisation = json['current_organisation'];
    bio = json['bio'];
    socialLinks = json['social_links'] != null ? SocialLinks.fromJson(json['social_links']) : null;
    userLocation = json['user_location'] != null ? UserLocation.fromJson(json['user_location']) : null;
    skills = json['skills'] != null ? json['skills'].cast<String>() : [];
    emailVerified = json['emailVerified'];
    objective = json['objective'];
    if (json['projects'] != null) {
      projects = [];
      json['projects'].forEach((v) {
        projects?.add(Projects.fromJson(v));
      });
    }
    if (json['experiences'] != null) {
      experiences = [];
      json['experiences'].forEach((v) {
        experiences?.add(Experiences.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    v = json['__v'];
    email = json['email'];
    introVideo = json['introVideo'];
  }
  String? id;
  String? name;
  String? gender;
  String? contactNo;
  String? profession;
  String? designation;
  String? profileImage;
  bool? isEnded;
  String? username;
  DateOfBirth? dateOfBirth;
  dynamic deletedAt;
  String? accountType;
  String? language;
  int? referralPoints;
  dynamic lastSeen;
  String? location;
  String? highestEducation;
  dynamic role;
  String? currentOrganisation;
  String? bio;
  SocialLinks? socialLinks;
  UserLocation? userLocation;
  List<String>? skills;
  bool? emailVerified;
  String? objective;
  List<Projects>? projects;
  List<Experiences>? experiences;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? email;
  String? introVideo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['gender'] = gender;
    map['contact_no'] = contactNo;
    map['profession'] = profession;
    map['designation'] = designation;
    map['profile_image'] = profileImage;
    map['is_ended'] = isEnded;
    map['username'] = username;
    if (dateOfBirth != null) {
      map['date_of_birth'] = dateOfBirth?.toJson();
    }
    map['deleted_at'] = deletedAt;
    map['account_type'] = accountType;
    map['language'] = language;
    map['referral_points'] = referralPoints;
    map['last_seen'] = lastSeen;
    map['location'] = location;
    map['highest_education'] = highestEducation;
    map['role'] = role;
    map['current_organisation'] = currentOrganisation;
    map['bio'] = bio;
    if (socialLinks != null) {
      map['social_links'] = socialLinks?.toJson();
    }
    if (userLocation != null) {
      map['user_location'] = userLocation?.toJson();
    }
    map['skills'] = skills;
    map['emailVerified'] = emailVerified;
    map['objective'] = objective;
    if (projects != null) {
      map['projects'] = projects?.map((v) => v.toJson()).toList();
    }
    if (experiences != null) {
      map['experiences'] = experiences?.map((v) => v.toJson()).toList();
    }
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['__v'] = v;
    map['email'] = email;
    map['introVideo'] = introVideo;
    return map;
  }

}

UserLocation userLocationFromJson(String str) => UserLocation.fromJson(json.decode(str));
String userLocationToJson(UserLocation data) => json.encode(data.toJson());
class UserLocation {
  UserLocation({
      this.lat, 
      this.lon,});

  UserLocation.fromJson(dynamic json) {
    lat = json['lat'];
    lon = json['lon'];
  }
  dynamic lat;
  dynamic lon;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['lat'] = lat;
    map['lon'] = lon;
    return map;
  }

}

SocialLinks socialLinksFromJson(String str) => SocialLinks.fromJson(json.decode(str));
String socialLinksToJson(SocialLinks data) => json.encode(data.toJson());
class SocialLinks {
  SocialLinks({
      this.youtube, 
      this.twitter, 
      this.linkedin, 
      this.instagram, 
      this.website,});

  SocialLinks.fromJson(dynamic json) {
    youtube = json['youtube'];
    twitter = json['twitter'];
    linkedin = json['linkedin'];
    instagram = json['instagram'];
    website = json['website'];
  }
  String? youtube;
  String? twitter;
  String? linkedin;
  String? instagram;
  dynamic website;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['youtube'] = youtube;
    map['twitter'] = twitter;
    map['linkedin'] = linkedin;
    map['instagram'] = instagram;
    map['website'] = website;
    return map;
  }

}

DateOfBirth dateOfBirthFromJson(String str) => DateOfBirth.fromJson(json.decode(str));
String dateOfBirthToJson(DateOfBirth data) => json.encode(data.toJson());
class DateOfBirth {
  DateOfBirth({
      this.date, 
      this.month, 
      this.year,});

  DateOfBirth.fromJson(dynamic json) {
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