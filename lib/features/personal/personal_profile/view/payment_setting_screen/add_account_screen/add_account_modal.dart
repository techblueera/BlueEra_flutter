// To parse this JSON data, do
//
//     final addAccountResponseModalClass = addAccountResponseModalClassFromJson(jsonString);

import 'dart:convert';

AddAccountResponseModalClass addAccountResponseModalClassFromJson(String str) => AddAccountResponseModalClass.fromJson(json.decode(str));

String addAccountResponseModalClassToJson(AddAccountResponseModalClass data) => json.encode(data.toJson());

class AddAccountResponseModalClass {
    String? message;
    Data? data;

    AddAccountResponseModalClass({
        this.message,
        this.data,
    });

    factory AddAccountResponseModalClass.fromJson(Map<String, dynamic> json) => AddAccountResponseModalClass(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "data": data?.toJson(),
    };
}

class Data {
    String? userId;
    String? type;
    String? bankName;
    String? accountNumber;
    String? ifscCode;
    String? upiId;
    bool? isDefault;
    String? id;
    DateTime? createdAt;
    DateTime? updatedAt;
    int? v;

    Data({
        this.userId,
        this.type,
        this.bankName,
        this.accountNumber,
        this.ifscCode,
        this.upiId,
        this.isDefault,
        this.id,
        this.createdAt,
        this.updatedAt,
        this.v,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        userId: json["userId"],
        type: json["type"],
        bankName: json["bank_name"],
        accountNumber: json["account_number"],
        ifscCode: json["ifsc_code"],
        upiId: json["upi_id"],
        isDefault: json["isDefault"],
        id: json["_id"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
    );

    Map<String, dynamic> toJson() => {
        "userId": userId,
        "type": type,
        "bank_name": bankName,
        "account_number": accountNumber,
        "ifsc_code": ifscCode,
        "upi_id": upiId,
        "isDefault": isDefault,
        "_id": id,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
    };
}
