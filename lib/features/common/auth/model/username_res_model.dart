import 'dart:convert';
UsernameResModel usernameResModelFromJson(String str) => UsernameResModel.fromJson(json.decode(str));
String usernameResModelToJson(UsernameResModel data) => json.encode(data.toJson());
class UsernameResModel {
  UsernameResModel({
      this.status, 
      this.message, 
      this.sampleUsername,});

  UsernameResModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    sampleUsername = json['sampleUsername'] != null ? json['sampleUsername'].cast<String>() : [];
  }
  bool? status;
  String? message;
  List<String>? sampleUsername;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    map['sampleUsername'] = sampleUsername;
    return map;
  }

}