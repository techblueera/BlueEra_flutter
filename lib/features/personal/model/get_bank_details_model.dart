class GetBankDetailsModel {
  final bool? success;
  final String? message;
  final BankDetails? data;

  GetBankDetailsModel({
     this.success,
     this.message,
     this.data,
  });

  factory GetBankDetailsModel.fromJson(Map<String, dynamic> json) {
    return GetBankDetailsModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: BankDetails.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class BankDetails {
  final String id;
  final String channel;
  final String holderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;

  BankDetails({
    required this.id,
    required this.channel,
    required this.holderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      id: json['id'] ?? '',
      channel: json['channel'] ?? '',
      holderName: json['holderName'] ?? '',
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      accountType: json['accountType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel': channel,
      'holderName': holderName,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountType': accountType,
    };
  }
}
