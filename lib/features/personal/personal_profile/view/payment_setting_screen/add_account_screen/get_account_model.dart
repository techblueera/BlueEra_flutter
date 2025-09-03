// To parse this JSON data, do
//
//     final getAccountResponseModalClass = getAccountResponseModalClassFromJson(jsonString);

import 'dart:convert';

GetAccountResponseModalClass getAccountResponseModalClassFromJson(String str) =>
    GetAccountResponseModalClass.fromJson(json.decode(str));

String getAccountResponseModalClassToJson(GetAccountResponseModalClass data) =>
    json.encode(data.toJson());

class GetAccountResponseModalClass {
  List<DatumGetAccountResponseModalClass>? data;

  GetAccountResponseModalClass({
    this.data,
  });

  factory GetAccountResponseModalClass.fromJson(Map<String, dynamic> json) =>
      GetAccountResponseModalClass(
        data: json["data"] == null
            ? []
            : List<DatumGetAccountResponseModalClass>.from(json["data"]!
                .map((x) => DatumGetAccountResponseModalClass.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class DatumGetAccountResponseModalClass {
  String? id;
  String? userId;
  String? type;
  String? bankName;
  String? accountNumber;
  String? ifscCode;
  String? upiId;
  bool? isDefault;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;
  String? accountHolderName;
  String? accountType;

  DatumGetAccountResponseModalClass({
    this.id,
    this.userId,
    this.type,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.accountHolderName,
    this.accountType,
  });

  factory DatumGetAccountResponseModalClass.fromJson(
          Map<String, dynamic> json) =>
      DatumGetAccountResponseModalClass(
        id: json["_id"],
        userId: json["userId"],
        type: json["type"],
        bankName: json["bank_name"],
        accountNumber: json["account_number"],
        ifscCode: json["ifsc_code"],
        upiId: json["upi_id"],
        isDefault: json["isDefault"],
        accountHolderName: json["account_holder_name"],
        accountType: json["account_type"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "userId": userId,
        "type": type,
        "bank_name": bankName,
        "account_number": accountNumber,
        "ifsc_code": ifscCode,
        "upi_id": upiId,
        "isDefault": isDefault,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
        "account_holder_name": accountHolderName,
        "account_type": accountType,
      };
}
