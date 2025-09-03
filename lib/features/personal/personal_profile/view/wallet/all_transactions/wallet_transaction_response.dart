// To parse this JSON data, do
//
//     final walletTransactionResponseModalClass = walletTransactionResponseModalClassFromJson(jsonString);

import 'dart:convert';

WalletTransactionResponseModalClass walletTransactionResponseModalClassFromJson(
        String str) =>
    WalletTransactionResponseModalClass.fromJson(json.decode(str));

String walletTransactionResponseModalClassToJson(
        WalletTransactionResponseModalClass data) =>
    json.encode(data.toJson());

class WalletTransactionResponseModalClass {
  bool? success;
  int? count;
  Pagination? pagination;
  List<WalletTransactionResponseModalClassDatum>? data;

  WalletTransactionResponseModalClass({
    this.success,
    this.count,
    this.pagination,
    this.data,
  });

  factory WalletTransactionResponseModalClass.fromJson(
          Map<String, dynamic> json) =>
      WalletTransactionResponseModalClass(
        success: json["success"],
        count: json["count"],
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
        data: json["data"] == null
            ? []
            : List<WalletTransactionResponseModalClassDatum>.from(json["data"]!
                .map((x) =>
                    WalletTransactionResponseModalClassDatum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "count": count,
        "pagination": pagination?.toJson(),
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class WalletTransactionResponseModalClassDatum {
  String? id;
  String? walletId;
  int? amountInRupees;
  String? type;
  String? status;
  String? source;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  WalletTransactionResponseModalClassDatum({
    this.id,
    this.walletId,
    this.amountInRupees,
    this.type,
    this.status,
    this.source,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory WalletTransactionResponseModalClassDatum.fromJson(
          Map<String, dynamic> json) =>
      WalletTransactionResponseModalClassDatum(
        id: json["_id"],
        walletId: json["walletId"],
        amountInRupees: json["amountInRupees"],
        type: json["type"],
        status: json["status"],
        source: json["source"],
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
        "walletId": walletId,
        "amountInRupees": amountInRupees,
        "type": type,
        "status": status,
        "source": source,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
      };
}

class Pagination {
  int? total;
  int? page;
  int? pages;

  Pagination({
    this.total,
    this.page,
    this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        total: json["total"],
        page: json["page"],
        pages: json["pages"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "page": page,
        "pages": pages,
      };
}
