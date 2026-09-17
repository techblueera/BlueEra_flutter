import 'dart:convert';
OtpVerifyModel otpVerifyModelFromJson(String str) => OtpVerifyModel.fromJson(json.decode(str));
String otpVerifyModelToJson(OtpVerifyModel data) => json.encode(data.toJson());
class OtpVerifyModel {
  OtpVerifyModel({
    this.success,
    this.message,
    this.token,
    this.data,
    this.userExists,
    this.accountType,
    this.needsOnboarding,
    this.isBlocked,
    this.blockedType,
    this.accountDeletionCancelled,
  });

  OtpVerifyModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    token = json['token'];
    data = json['data'] != null ? User.fromJson(json['data']) : null;
    // `user` answers ONE question: does an account exist for this number?
    // It is NOT a statement about the account type, and the controller must
    // not read it as one. Parsed here so the login path stops reaching past
    // the model into the raw map (`response.data[ApiKeys.user]`).
    userExists = json['user'] == true || json['user'] == 'true';
    // Top-level `account_type`, which the backend guarantees non-null when
    // `user` is true — unlike `data.account_type`, which pre-enum rows can
    // still come back without. Only ever a LABEL for picking a profile
    // screen: never a login gate, and never a whitelist. Production holds
    // values outside the schema enum (`Admin`, the literal string `NULL`).
    accountType = json['account_type']?.toString();
    // The backend's verdict on whether this person still has to finish
    // signup. The ONLY onboarding signal — do not infer it from
    // `account_type`.
    needsOnboarding = json['needs_onboarding'] == true ||
        json['needs_onboarding'] == 'true';
    isBlocked = json['isBlocked'];
    blockedType = json['blockedType'];
    accountDeletionCancelled = json['account_deletion_cancelled'];
  }
  bool? success;
  String? message;
  String? token;
  User? data;
  bool? userExists;
  String? accountType;
  bool? needsOnboarding;

  bool? isBlocked;
  dynamic blockedType;
  bool? accountDeletionCancelled;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    map['token'] = token;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    map['user'] = userExists;
    map['account_type'] = accountType;
    map['needs_onboarding'] = needsOnboarding;
    map['isBlocked'] = isBlocked;
    map['blockedType'] = blockedType;
    map['account_deletion_cancelled'] = accountDeletionCancelled;
    return map;
  }

}
User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());
class User {
  User({
    this.id,
    this.contactNo,
    this.username,
    this.accountType,
    this.business,
    this.name,
    this.profileImage,
  });

  User.fromJson(dynamic json) {
    id = json['_id'];
    contactNo = json['contact_no'];
    username = json['username'];
    accountType = json['account_type'];
    // `business` OR `business_id` — verify-otp is not consistent about which
    // key carries the shop id, and the same user object embedded in the JWT's
    // `_id` claim uses `business_id`. Reading only `business` silently parsed
    // null, so `_persistLoginIdentity` had nothing to store: `businessId` came
    // up empty for the whole session, `viewBusinessProfile` bailed before its
    // request (view_business_details_controller.dart:311), and the profile
    // fetch that would otherwise have re-saved the id could never run — the id
    // it needed was the one that was missing.
    business = json['business'] ?? json['business_id'];
    name = json['name'];
    profileImage = json['profile_image'];
  }
  String? id;
  String? accountType;
  String? contactNo;
  String? business;///business ID
  String? username;
  String? name;
  String? profileImage;


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['contact_no'] = contactNo;
    map['username'] = username;
    map['account_type'] = accountType;
    map['business'] = business;
    map['name'] = name;
    map['profile_image'] = profileImage;
    return map;
  }

}
