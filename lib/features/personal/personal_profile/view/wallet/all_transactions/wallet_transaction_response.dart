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
  // API key is `amount` (already in rupees, may be a decimal e.g. 0.25).
  num? amountInRupees;
  String? type; // CREDIT / DEBIT
  String? status; // PENDING / COMPLETED
  // API key is `purpose` (e.g. WITHDRAWAL, REFERRAL_INCOME); `source` kept as a
  // fallback for any older payloads that still send it.
  String? source;
  String? purpose;
  String? description;
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
    this.purpose,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  /// True for incoming money (referral income, etc.); false for withdrawals.
  bool get isCredit => (type ?? '').toUpperCase() == "CREDIT";

  String get _statusUpper => (status ?? '').toUpperCase();
  bool get isPending => _statusUpper == "PENDING";
  bool get isRejected => _statusUpper == "REJECTED";
  bool get isCompleted => _statusUpper == "COMPLETED";

  /// Human label for the status chip (PENDING / COMPLETED / REJECTED).
  String get statusLabel {
    if (isPending) return "Pending";
    if (isRejected) return "Rejected";
    if (isCompleted) return "Completed";
    return status ?? "";
  }

  /// Readable row title: turns `REFERRAL_INCOME` → "Referral Income". Falls
  /// back to `source`, then `description`.
  String get title {
    final raw = (purpose?.isNotEmpty ?? false)
        ? purpose
        : (source?.isNotEmpty ?? false)
            ? source
            : description;
    if (raw == null || raw.isEmpty) return "Transaction";
    if (!raw.contains("_")) return raw;
    return raw
        .split("_")
        .where((w) => w.isNotEmpty)
        .map((w) => "${w[0].toUpperCase()}${w.substring(1).toLowerCase()}")
        .join(" ");
  }

  factory WalletTransactionResponseModalClassDatum.fromJson(
      Map<String, dynamic> json) {
    return WalletTransactionResponseModalClassDatum(
      id: json["_id"],
      walletId: json["walletId"],
      amountInRupees: json["amount"] ?? json["amountInRupees"],
      type: json["type"],
      status: json["status"],
      source: json["source"],
      purpose: json["purpose"],
      description: json["description"],
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
    "amount": amountInRupees,
    "type": type,
    "status": status,
    "source": source,
    "purpose": purpose,
    "description": description,
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