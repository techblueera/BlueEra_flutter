// To parse this JSON data, do
//
//     final walletResponseModalClass = walletResponseModalClassFromJson(jsonString);

import 'dart:convert';

WalletResponseModalClass walletResponseModalClassFromJson(String str) =>
    WalletResponseModalClass.fromJson(json.decode(str));

String walletResponseModalClassToJson(WalletResponseModalClass data) =>
    json.encode(data.toJson());

class WalletResponseModalClass {
  bool? success;
  WalletResponseModalClassData? data;

  WalletResponseModalClass({
    this.success,
    this.data,
  });

  factory WalletResponseModalClass.fromJson(Map<String, dynamic> json) =>
      WalletResponseModalClass(
        success: json["success"],
        data: json["data"] == null
            ? null
            : WalletResponseModalClassData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data?.toJson(),
      };
}

class WalletResponseModalClassData {
  String? id;
  String? userId;
  int? withdrawableAmount;
  int? totalRewardAmount;
  int? totalWithdrawalAmount;

  WalletResponseModalClassData({
    this.id,
    this.userId,
    this.withdrawableAmount,
    this.totalRewardAmount,
    this.totalWithdrawalAmount,
  });

  factory WalletResponseModalClassData.fromJson(Map<String, dynamic> json) =>
      WalletResponseModalClassData(
        id: json["_id"],
        userId: json["userId"],
        withdrawableAmount: json["withdrawableAmount"],
        totalRewardAmount: json["totalRewardAmount"],
        totalWithdrawalAmount: json["totalWithdrawalAmount"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "userId": userId,
        "withdrawableAmount": withdrawableAmount,
        "totalRewardAmount": totalRewardAmount,
        "totalWithdrawalAmount": totalWithdrawalAmount,
      };
}
