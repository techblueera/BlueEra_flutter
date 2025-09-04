import 'dart:convert';
OtpVerifyModel otpVerifyModelFromJson(String str) => OtpVerifyModel.fromJson(json.decode(str));
String otpVerifyModelToJson(OtpVerifyModel data) => json.encode(data.toJson());
class OtpVerifyModel {
  OtpVerifyModel({
      this.success, 
      this.message, 
      this.token, 
      this.data,
      // this.role,
      // this.business,
      // this.chatToken,
      this.isBlocked, 
      this.blockedType,});

  OtpVerifyModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    token = json['token'];
    data = json['data'] != null ? User.fromJson(json['data']) : null;
    // role = json['role'];
    // business = json['business'] != null ? Business.fromJson(json['business']) : null;
    // chatToken = json['chat_token'];
    isBlocked = json['isBlocked'];
    blockedType = json['blockedType'];
  }
  bool? success;
  String? message;
  String? token;
  User? data;
  // dynamic role;
  // Business? business;
  // dynamic chatToken;
  bool? isBlocked;
  dynamic blockedType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    map['token'] = token;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    // map['role'] = role;
    // if (business != null) {
    //   map['business'] = business?.toJson();
    // }
    // map['chat_token'] = chatToken;
    map['isBlocked'] = isBlocked;
    map['blockedType'] = blockedType;
    return map;
  }

}

Business businessFromJson(String str) => Business.fromJson(json.decode(str));
String businessToJson(Business data) => json.encode(data.toJson());
class Business {
  Business({
      this.id, 
      this.businessName, 
      this.logo, 
      this.isVerified, 
      this.gst,});

  Business.fromJson(dynamic json) {
    id = json['_id'];
    businessName = json['business_name'];
    logo = json['logo'];
    isVerified = json['isVerified'];

    gst = json['gst'] != null ? Gst.fromJson(json['gst']) : null;
  }
  String? id;
  String? businessName;
  String? logo;
  bool? isVerified;
  Gst? gst;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['business_name'] = businessName;
    map['logo'] = logo;
    map['isVerified'] = isVerified;

    if (gst != null) {
      map['gst'] = gst?.toJson();
    }
    return map;
  }

}

Gst gstFromJson(String str) => Gst.fromJson(json.decode(str));
String gstToJson(Gst data) => json.encode(data.toJson());
class Gst {
  Gst({
      this.have, 
      this.number, 
      this.gstVerification,});

  Gst.fromJson(dynamic json) {
    have = json['have'];
    number = json['number'];
    gstVerification = json['gst_verification'];
  }
  bool? have;
  String? number;
  bool? gstVerification;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['have'] = have;
    map['number'] = number;
    map['gst_verification'] = gstVerification;
    return map;
  }

}

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());
class User {
  User({
      this.id, 
      this.contactNo, 
      // this.name,
      this.username, 
      // this.profileImage,
      // this.introVideo,
      // this.socialLinks,
      this.accountType, 
      // this.referralCode,
      // this.language,
      // this.designation,
      this.business,
      // this.profession
  });

  User.fromJson(dynamic json) {
    id = json['_id'];
    contactNo = json['contact_no'];
    // name = json['name'];
    username = json['username'];
    // profileImage = json['profile_image'];
    // introVideo = json['introVideo'];
    // socialLinks = json['social_links'] != null ? SocialLinks.fromJson(json['social_links']) : null;
    accountType = json['account_type'];
    // referralCode = json['referral_code'];
    // language = json['language'];
    // designation = json['designation'];
    // profession = json['profession'];
    business = json['business'];
  }
  String? id;
  String? accountType;
  String? contactNo;
  String? business;///business ID


  // dynamic name;
  String? username;
  // dynamic profileImage;
  // dynamic introVideo;
  // SocialLinks? socialLinks;
  // dynamic referralCode;
  // String? language;
  // String? designation;
  // String? profession;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['contact_no'] = contactNo;
    // map['name'] = name;
    map['username'] = username;
    // map['profile_image'] = profileImage;
    // map['introVideo'] = introVideo;
    // if (socialLinks != null) {
    //   map['social_links'] = socialLinks?.toJson();
    // }
    map['account_type'] = accountType;
    // map['referral_code'] = referralCode;
    // map['language'] = language;
    // map['designation'] = designation;
    // map['profession'] = profession;
    map['business'] = business;
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
  String? website;

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