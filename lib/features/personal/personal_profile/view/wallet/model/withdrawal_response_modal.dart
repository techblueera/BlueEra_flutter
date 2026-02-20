// To parse this JSON data, do
//
//     final withdrawalResponseModalClass = withdrawalResponseModalClassFromJson(jsonString);

import 'dart:convert';

WithdrawalResponseModalClass withdrawalResponseModalClassFromJson(String str) =>
    WithdrawalResponseModalClass.fromJson(json.decode(str));

String withdrawalResponseModalClassToJson(WithdrawalResponseModalClass data) =>
    json.encode(data.toJson());

class WithdrawalResponseModalClass {
  bool? success;
  String? message;
  WithdrawalResponseModalClassData? data;

  WithdrawalResponseModalClass({
    this.success,
    this.message,
    this.data,
  });

  factory WithdrawalResponseModalClass.fromJson(Map<String, dynamic> json) =>
      WithdrawalResponseModalClass(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : WithdrawalResponseModalClassData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class WithdrawalResponseModalClassData {
  String? userId;
  String? walletId;
  String? paymentAccountId;
  int? amount;
  String? status;
  String? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  WithdrawalResponseModalClassData({
    this.userId,
    this.walletId,
    this.paymentAccountId,
    this.amount,
    this.status,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory WithdrawalResponseModalClassData.fromJson(
          Map<String, dynamic> json) =>
      WithdrawalResponseModalClassData(
        userId: json["userId"],
        walletId: json["walletId"],
        paymentAccountId: json["paymentAccountId"],
        amount: json["amount"],
        status: json["status"],
        id: json["_id"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "walletId": walletId,
        "paymentAccountId": paymentAccountId,
        "amount": amount,
        "status": status,
        "_id": id,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
      };
}
