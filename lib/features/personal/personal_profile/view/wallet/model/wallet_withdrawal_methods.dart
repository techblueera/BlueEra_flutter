import 'package:BlueEra/features/personal/personal_profile/view/wallet/model/upi_details_model.dart';
import 'bank_details_model.dart';

class WalletWithdrawalMethod {
  bool? success;
  int? count;
  List<WithdrawalMethodData>? data;

  WalletWithdrawalMethod({this.success, this.count, this.data});

  factory WalletWithdrawalMethod.fromJson(Map<String, dynamic> json) {
    return WalletWithdrawalMethod(
      success: json['success'],
      count: json['count'],
      data: json['data'] != null
          ? List<WithdrawalMethodData>.from(
          json['data'].map((x) => WithdrawalMethodData.fromJson(x)))
          : [],
    );
  }
}

class WithdrawalMethodData {
  String? id;
  String? userId;
  String? methodType;
  bool? isDefault;
  BankDetails? bankDetails;
  UpiDetails? upiDetails;

  WithdrawalMethodData({
    this.id,
    this.userId,
    this.methodType,
    this.isDefault,
    this.bankDetails,
    this.upiDetails,
  });

  factory WithdrawalMethodData.fromJson(Map<String, dynamic> json) {
    return WithdrawalMethodData(
      id: json['_id'],
      userId: json['userId'],
      methodType: json['methodType'],
      isDefault: json['isDefault'],
      bankDetails: json['bankDetails'] != null
          ? BankDetails.fromJson(json['bankDetails'])
          : null,
      upiDetails: json['upiDetails'] != null
          ? UpiDetails.fromJson(json['upiDetails'])
          : null,
    );
  }
}
