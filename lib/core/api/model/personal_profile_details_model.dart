import 'dart:convert';

import 'package:BlueEra/core/api/model/marketing_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/earn_service_model_response.dart';

PersonalProfileDetailsModel personalProfileDetailsModelFromJson(String str) =>
    PersonalProfileDetailsModel.fromJson(json.decode(str));

String personalProfileDetailsModelToJson(PersonalProfileDetailsModel data) =>
    json.encode(data.toJson());

class PersonalProfileDetailsModel {
  PersonalProfileDetailsModel({
    this.status,
    this.message,
    this.user,
    this.isProfileCreated,
    this.isRiderServiceUser,
    this.isEarnServiceUser,
    this.securityDeposit,
    this.freeServiceUsed,
    this.earnProfileType = const <String>[],
  });

  PersonalProfileDetailsModel.fromJson(dynamic json)
      : earnProfileType = _parseEarnProfileTypes(
            json['earnProfileTypes'] ?? json['earnProfileType']) {
    status = json['status'];
    message = json['message'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    isProfileCreated = json['isProfileCreated'];
    isRiderServiceUser = json['isRiderServiceUser'];
    isEarnServiceUser = json['isEarnServiceUser'];
    // Security-deposit go-live gate — a sibling field on the individual profile
    // (mirrors the business profile). Null / absent → treated as "allowed"
    // (fail-open). See docs/backend/SELF_WORK_GO_LIVE_GUIDE.md.
    final sd = json['securityDeposit'];
    securityDeposit = sd is Map
        ? SecurityDepositStatus.fromJson(Map<String, dynamic>.from(sd))
        : null;
    // First service free: the security-deposit gate is WAIVED until the
    // provider completes their first paid service/booking. Backend sends
    // `freeServiceUsed:false` while the free go-live is still available and
    // flips it to true afterwards. `freeRideUsed` is still accepted as an alias
    // because some payloads use that name — note the RIDER waiver it was named
    // after has been removed, so this is a self-work-only concept now. Absent
    // (old backend) → null → treated as "not free" so the deposit stays
    // enforced (safe default). See docs/backend/SELF_WORK_GO_LIVE_GUIDE.md.
    freeServiceUsed =
        json['freeServiceUsed'] as bool? ?? json['freeRideUsed'] as bool?;
    // Referral promo clip — a TOP-LEVEL sibling of `user` / `securityDeposit`,
    // NOT part of `marketing_card` (that object is poster-only). The backend
    // key really is spelled `referal_video`, with one 'r'; `referral_video` is
    // accepted too so a future spelling fix doesn't silently drop the video.
    referalVideo = (json['referal_video'] ?? json['referral_video'])?.toString();
  }

  /// Tolerates the API returning a list, a single string (legacy), or null.
  static List<String> _parseEarnProfileTypes(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) return [raw];
    return <String>[];
  }

  bool? status;
  String? message;
  User? user;
  bool? isProfileCreated;
  bool? isRiderServiceUser;
  bool? isEarnServiceUser;
  SecurityDepositStatus? securityDeposit;
  // First-service-free flag. `false` → the free first go-live is still
  // available (skip the deposit gate); `true`/null → not available (enforce the
  // deposit). See [isFirstServiceFree].
  bool? freeServiceUsed;
  List<String> earnProfileType;

  /// Referral promo clip URL (`referal_video`), or null when the profile has
  /// none. Top-level on the response — nothing to do with `marketing_card`.
  String? referalVideo;

  /// The clip to play, or null when there isn't one — trimmed and
  /// empty-checked so `""` never reaches a video player.
  String? get referalVideoUrl =>
      (referalVideo?.trim().isNotEmpty ?? false) ? referalVideo!.trim() : null;

  /// Go-live decision for the individual/self-employed provider: allowed when
  /// there's no deposit info or the deposit is paid / not required; blocked
  /// ONLY when the backend explicitly reports `required && !paid`.
  bool get canGoLive => securityDeposit?.canGoLive ?? true;

  /// The provider's FIRST service go-live is free — the security-deposit gate is
  /// waived until they use it. `freeServiceUsed == false` → still free. Absent
  /// (`null`, old backend) → treated as NOT free, so the deposit stays enforced
  /// — a safe default that never hands out free go-live by accident.
  ///
  /// Self-work only. The rider side had an equivalent waiver and no longer
  /// does: a rider's deposit is now checked with no exceptions.
  bool get isFirstServiceFree => freeServiceUsed == false;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    map['isProfileCreated'] = isProfileCreated;
    map['isRiderServiceUser'] = isRiderServiceUser;
    map['isEarnServiceUser'] = isEarnServiceUser;
    // securityDeposit + freeServiceUsed are read-only, server-computed go-live
    // signals — not serialized back. On a cache replay they're absent, which is
    // safe: canGoLive fail-opens (true) so go-live isn't blocked from cache, and
    // the fresh read re-populates both.
    map['earnProfileTypes'] = earnProfileType;
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
    this.sector,
    this.profileImage,
    this.coverPicture,
    this.username,
    this.dateOfBirth,
    this.bio,
    this.email,
    this.highestEducation,
    this.specilization,
    this.subDivision,
    this.department,
    this.emailVerified,
    this.introVideo,
    this.objective,
    this.skills,
    this.art,
    this.userLocation,
    this.referral_points,
    this.referral_code,
    this.referralCodeEditable,
    this.profileType,
    this.schoolOrCollegeName,
    this.pincode,
    this.address,
    this.createdAt,
    this.marketingCard,
  });

  User.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    gender = json['gender'];
    contactNo = json['contact_no'];
    profession = json['profession'];
    designation = json['designation'];
    sector = json['sector'];
    profileImage = json['profile_image'];
    coverPicture = json['coverPicture'];
    username = json['username'];
    dateOfBirth = json['date_of_birth'] != null
        ? DateOfBirth.fromJson(json['date_of_birth'])
        : null;

    bio = json['bio'];
    email = json['email'];
    highestEducation = json['highest_education'];
    specilization = json['specilization'];
    department = json['department'];
    subDivision = json['subDivision'];
    location = json['location'];
    emailVerified = json['emailVerified'];
    introVideo = json['introVideo'];
    referral_code = json['referral_code'];
    referral_points = json['referral_points'].toString();
    referralCodeEditable = json['referralCodeEditable'];
    objective = json['objective'];
    skills = json['skills'] != null ? json['skills'].cast<String>() : [];
    art = json['art'] != null ? new Art.fromJson(json['art']) : null;
    userLocation = json['user_location'] != null ? new UserLocation.fromJson(json['user_location']) : null;
    profileType = json['profileType'];
    schoolOrCollegeName = json['schoolOrCollegeName'];
    pincode = json['pincode'];
    address = json['address'];
    createdAt = json['created_at'];
    // Backend nests the share poster INSIDE the user object (not top-level).
    marketingCard = MarketingCard.fromRaw(json['marketing_card']);
  }

  String? id;
  String? name;
  String? gender;
  String? contactNo;
  String? profession;
  String? designation;
  String? referral_points;
  String? referral_code;

  /// When true the user is allowed to change their referral code once
  /// (drives the "Update Referral Code" affordance on the referral
  /// dashboard). Sourced from `GET user-service/user/get`.
  bool? referralCodeEditable;
  String? sector;
  String? profileImage;
  String? coverPicture;
  String? username;
  DateOfBirth? dateOfBirth;
  String? bio;
  String? objective;
  String? email;
  bool? emailVerified;
  String? highestEducation;
  String? specilization;
  String? department;
  String? subDivision;
  String? location;
  String? introVideo;
  List<String>? skills;
  Art? art;
  UserLocation? userLocation;
  String? profileType;
  String? schoolOrCollegeName;
  num? pincode;
  String? address;
  String? createdAt;
  MarketingCard? marketingCard;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['gender'] = gender;
    map['contact_no'] = contactNo;
    map['profession'] = profession;
    map['designation'] = designation;
    map['referral_code'] = referral_code;
    map['referral_points'] = referral_points;
    map['referralCodeEditable'] = referralCodeEditable;
    map['sector'] = sector;
    map['profile_image'] = profileImage;
    map['coverPicture'] = coverPicture;
    map['username'] = username;
    if (dateOfBirth != null) {
      map['date_of_birth'] = dateOfBirth?.toJson();
    }

    map['bio'] = bio;
    map['objective'] = objective;
    map['email'] = email;
    map['emailVerified'] = emailVerified;
    map['specilization'] = specilization;
    map['department'] = department;
    map['subDivision'] = subDivision;
    map['highest_education'] = highestEducation;
    map['location'] = location;
    map['introVideo'] = introVideo;
    map['skills'] = skills;
    if (this.art != null) {
      map['art'] = this.art!.toJson();
    }
    if (this.userLocation != null) {
      map['user_location'] = this.userLocation!.toJson();
    }
    map['profileType'] = profileType;
    map['schoolOrCollegeName'] = schoolOrCollegeName;
    map['pincode'] = pincode;
    map['address'] = address;
    map['created_at'] = createdAt;
    return map;
  }
}

DateOfBirth dateOfBirthFromJson(String str) =>
    DateOfBirth.fromJson(json.decode(str));

String dateOfBirthToJson(DateOfBirth data) => json.encode(data.toJson());

class DateOfBirth {
  DateOfBirth({
    this.date,
    this.month,
    this.year,
  });

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

UserLocation userLocationFromJson(String str) =>
    UserLocation.fromJson(json.decode(str));

String userLocationToJson(UserLocation data) =>
    json.encode(data.toJson());

class UserLocation {
  final double? lat;
  final double? lon;

  const UserLocation({
    this.lat,
    this.lon,
  });

  factory UserLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserLocation();

    return UserLocation(
      lat: _parseDouble(json['lat']),
      lon: _parseDouble(json['lon']),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
  };

  // Safely parse dynamic → double?
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}


// class Projects {
//   String? title;
//   String? description;
//   String? sId;
//
//   Projects({this.title, this.description, this.sId});
//
//   Projects.fromJson(Map<String, dynamic> json) {
//     title = json['title'];
//     description = json['description'];
//     sId = json['_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['title'] = this.title;
//     data['description'] = this.description;
//     data['_id'] = this.sId;
//     return data;
//   }
// }
//
// class Experiences {
//   String? companyName;
//   String? rolesAndResponsibility;
//   String? sId;
//
//   Experiences({this.companyName, this.rolesAndResponsibility, this.sId});
//
//   Experiences.fromJson(Map<String, dynamic> json) {
//     companyName = json['companyName'];
//     rolesAndResponsibility = json['rolesAndResponsibility'];
//     sId = json['_id'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['companyName'] = this.companyName;
//     data['rolesAndResponsibility'] = this.rolesAndResponsibility;
//     data['_id'] = this.sId;
//     return data;
//   }
// }

class Art {
  String? artName;
  String? artType;

  Art({this.artName, this.artType});

  Art.fromJson(Map<String, dynamic> json) {
    artName = json['artName'];
    artType = json['artType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['artName'] = this.artName;
    data['artType'] = this.artType;
    return data;
  }
}
