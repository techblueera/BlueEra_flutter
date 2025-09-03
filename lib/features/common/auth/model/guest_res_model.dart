import 'dart:convert';
GuestResModel guestResModelFromJson(String str) => GuestResModel.fromJson(json.decode(str));
String guestResModelToJson(GuestResModel data) => json.encode(data.toJson());
class GuestResModel {
  GuestResModel({
      this.success, 
      this.message, 
      this.data, 
      this.token,});

  GuestResModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    token = json['token'];
  }
  bool? success;
  String? message;
  Data? data;
  String? token;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    map['token'] = token;
    return map;
  }

}

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      this.id, 
      this.name, 
      this.contactNo, 
      this.referralCode, 
      this.username, 
      this.accountType,});

  Data.fromJson(dynamic json) {
    id = json['_id'];
    name = json['name'];
    contactNo = json['contact_no'];
    referralCode = json['referral_code'];
    username = json['username'];
    accountType = json['account_type'];
  }
  String? id;
  String? name;
  String? contactNo;
  String? referralCode;
  String? username;
  String? accountType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['name'] = name;
    map['contact_no'] = contactNo;
    map['referral_code'] = referralCode;
    map['username'] = username;
    map['account_type'] = accountType;
    return map;
  }

}