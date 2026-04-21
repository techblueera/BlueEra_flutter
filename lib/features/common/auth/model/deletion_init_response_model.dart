import 'dart:convert';

DeletionInitResponseModel deletionInitResponseModelFromJson(String str) =>
    DeletionInitResponseModel.fromJson(json.decode(str));

String deletionInitResponseModelToJson(DeletionInitResponseModel data) =>
    json.encode(data.toJson());

class DeletionInitResponseModel {
  DeletionInitResponseModel({
    this.success,
    this.initToken,
    this.deletionUrl,
    this.expiresAt,
  });

  DeletionInitResponseModel.fromJson(dynamic json) {
    success = json['success'];
    initToken = json['init_token'];
    deletionUrl = json['deletion_url'];
    final rawExpiresAt = json['expires_at'];
    expiresAt = rawExpiresAt is String ? DateTime.tryParse(rawExpiresAt) : null;
  }

  bool? success;
  String? initToken;
  String? deletionUrl;
  DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['init_token'] = initToken;
    map['deletion_url'] = deletionUrl;
    map['expires_at'] = expiresAt?.toIso8601String();
    return map;
  }
}