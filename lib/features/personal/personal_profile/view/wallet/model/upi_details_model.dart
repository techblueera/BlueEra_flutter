class UpiListModel {
  final bool? success;
  final int? count;
  final List<UpiData>? data;

  UpiListModel({
    this.success,
    this.count,
    this.data,
  });

  factory UpiListModel.fromJson(Map<String, dynamic> json) {
    return UpiListModel(
      success: json['success'] as bool?,
      count: json['count'] as int?,
      data: (json['data'] as List?)
          ?.map((e) => UpiData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "count": count,
      "data": data?.map((e) => e.toJson()).toList(),
    };
  }
}

class UpiData {
  final String? id;
  final String? userId;
  final String? methodType;
  final bool? isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final UpiDetails? upiDetails;

  UpiData({
    this.id,
    this.userId,
    this.methodType,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.upiDetails,
  });

  factory UpiData.fromJson(Map<String, dynamic> json) {
    return UpiData(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      methodType: json['methodType'] as String?,
      isDefault: json['isDefault'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      v: json['__v'] as int?,
      upiDetails: json['upiDetails'] != null
          ? UpiDetails.fromJson(json['upiDetails'] as Map<String, dynamic>)
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
      "upiDetails": upiDetails?.toJson(),
    };
  }
}

class UpiDetails {
  final String? upiId;
  final String? bankName;

  /// Mobile number linked to this UPI (collected on the add-UPI form in place
  /// of bank name).
  final String? mobileNumber;

  UpiDetails({
    this.upiId,
    this.bankName,
    this.mobileNumber,
  });

  factory UpiDetails.fromJson(Map<String, dynamic> json) {
    return UpiDetails(
      upiId: json['upiId'] as String?,
      bankName: json['bankName'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "upiId": upiId,
      "bankName": bankName,
      "mobileNumber": mobileNumber,
    };
  }
}