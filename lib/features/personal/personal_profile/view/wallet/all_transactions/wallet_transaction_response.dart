import 'dart:convert';

WalletTransactionResponseModalClass
walletTransactionResponseModalClassFromJson(String str) =>
    WalletTransactionResponseModalClass.fromJson(json.decode(str));

String walletTransactionResponseModalClassToJson(
    WalletTransactionResponseModalClass data) =>
    json.encode(data.toJson());

class WalletTransactionResponseModalClass {
  bool? success;
  int? count;
  int? total; // NEW FIELD (from API)
  Pagination? pagination;
  List<WalletTransactionResponseModalClassDatum>? data;

  WalletTransactionResponseModalClass({
    this.success,
    this.count,
    this.total,
    this.pagination,
    this.data,
  });

  factory WalletTransactionResponseModalClass.fromJson(
      Map<String, dynamic> json) {
    return WalletTransactionResponseModalClass(
      success: json["success"],
      count: json["count"],
      total: json["total"], // ADDED
      pagination: json["pagination"] == null
          ? null
          : Pagination.fromJson(json["pagination"]),
      data: json["data"] == null
          ? []
          : List<WalletTransactionResponseModalClassDatum>.from(
        json["data"].map(
              (x) => WalletTransactionResponseModalClassDatum.fromJson(x),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "count": count,
    "total": total,
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
      Map<String, dynamic> json) {
    return WalletTransactionResponseModalClassDatum(
      id: json["_id"],
      walletId: json["walletId"],
      amountInRupees: json["amountInRupees"],
      type: json["type"],
      status: json["status"],
      source: json["source"],
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"])
          : null,
      updatedAt: json["updatedAt"] != null
          ? DateTime.tryParse(json["updatedAt"])
          : null,
      v: json["__v"],
    );
  }

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
  int? page;
  int? limit; // NEW FIELD
  int? totalPages; // CHANGED from pages -> totalPages

  Pagination({
    this.page,
    this.limit,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json["page"],
      limit: json["limit"], // NEW
      totalPages: json["totalPages"], // UPDATED KEY
    );
  }

  Map<String, dynamic> toJson() => {
    "page": page,
    "limit": limit,
    "totalPages": totalPages,
  };
}