import 'dart:convert';
OtpVerifyModel otpVerifyModelFromJson(String str) => OtpVerifyModel.fromJson(json.decode(str));
String otpVerifyModelToJson(OtpVerifyModel data) => json.encode(data.toJson());
class OtpVerifyModel {
  OtpVerifyModel({
    this.success,
    this.message,
    this.token,
    this.data,
    this.isBlocked,
    this.blockedType,});

  OtpVerifyModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    token = json['token'];
    data = json['data'] != null ? User.fromJson(json['data']) : null;
    isBlocked = json['isBlocked'];
    blockedType = json['blockedType'];
  }
  bool? success;
  String? message;
  String? token;
  User? data;

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
    map['isBlocked'] = isBlocked;
    map['blockedType'] = blockedType;
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
  });

  User.fromJson(dynamic json) {
    id = json['_id'];
    contactNo = json['contact_no'];
    username = json['username'];
    accountType = json['account_type'];
    business = json['business'];
  }
  String? id;
  String? accountType;
  String? contactNo;
  String? business;///business ID
  String? username;


  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['contact_no'] = contactNo;
    map['username'] = username;
    map['account_type'] = accountType;
    map['business'] = business;
    return map;
  }

}
