class BankListModel {
  final bool? success;
  final int? count;
  final List<BankData>? data;

  BankListModel({
    this.success,
    this.count,
    this.data,
  });

  factory BankListModel.fromJson(Map<String, dynamic> json) {
    return BankListModel(
      success: json['success'],
      count: json['count'],
      data: json['data'] != null
          ? List<BankData>.from(
          json['data'].map((x) => BankData.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "count": count,
      "data": data?.map((x) => x.toJson()).toList(),
    };
  }
}

class BankData {
  final String? id;
  final String? userId;
  final String? methodType;
  final bool? isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final BankDetails? bankDetails;

  BankData({
    this.id,
    this.userId,
    this.methodType,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.bankDetails,
  });

  factory BankData.fromJson(Map<String, dynamic> json) {
    return BankData(
      id: json['_id'],
      userId: json['userId'],
      methodType: json['methodType'],
      isDefault: json['isDefault'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      v: json['__v'],
      bankDetails: json['bankDetails'] != null
          ? BankDetails.fromJson(json['bankDetails'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "userId": userId,
      "methodType": methodType,
      "isDefault": isDefault,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
      "__v": v,
      "bankDetails": bankDetails?.toJson(),
    };
  }
}

class BankDetails {
  final String? bankName;
  final String? accountNo;
  final String? ifscCode;
  final String? holderName;

  BankDetails({
    this.bankName,
    this.accountNo,
    this.ifscCode,
    this.holderName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'],
      accountNo: json['accountNo'],
      ifscCode: json['ifscCode'],
      holderName: json['holderName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "bankName": bankName,
      "accountNo": accountNo,
      "ifscCode": ifscCode,
      "holderName": holderName,
    };
  }
}