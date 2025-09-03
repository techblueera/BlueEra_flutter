import 'dart:convert';

AuthResponseModel authResponseModelFromJson(String str) =>
    AuthResponseModel.fromJson(json.decode(str));

String authResponseModelToJson(AuthResponseModel data) =>
    json.encode(data.toJson());

class AuthResponseModel {
  AuthResponseModel({
    this.message,
  });

  AuthResponseModel.fromJson(dynamic json) {
    message = json['message'];
  }

  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message'] = message;
    return map;
  }
}
