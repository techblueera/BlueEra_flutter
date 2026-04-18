class WalletReferralStatsResponse {
  bool? success;
  WalletRefferalStatsData? data;

  WalletReferralStatsResponse({this.success, this.data});

  WalletReferralStatsResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new WalletRefferalStatsData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class WalletRefferalStatsData {
  String? referralCode;
  String? serialCode;
  num? balance;
  num? totalIncome;
  num? estimatedEarning;
  int? totalReferralCount;
  Breakdown? breakdown;

  WalletRefferalStatsData(
      {this.referralCode,
        this.serialCode,
        this.balance,
        this.totalIncome,
        this.estimatedEarning,
        this.totalReferralCount,
        this.breakdown});

  WalletRefferalStatsData.fromJson(Map<String, dynamic> json) {
    referralCode = json['referralCode'];
    serialCode = json['serialCode'] ?? json['serial_code'];
    balance = json['balance'];
    totalIncome = json['totalIncome'];
    estimatedEarning = json['estimatedEarning'];
    totalReferralCount = json['totalReferralCount'];
    breakdown = json['breakdown'] != null
        ? new Breakdown.fromJson(json['breakdown'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['referralCode'] = this.referralCode;
    data['serialCode'] = this.serialCode;
    data['balance'] = this.balance;
    data['totalIncome'] = this.totalIncome;
    data['estimatedEarning'] = this.estimatedEarning;
    data['totalReferralCount'] = this.totalReferralCount;
    if (this.breakdown != null) {
      data['breakdown'] = this.breakdown!.toJson();
    }
    return data;
  }
}

class Breakdown {
  int? subscribed;
  int? nonSubscribed;
  int? expired;

  Breakdown({this.subscribed, this.nonSubscribed, this.expired});

  Breakdown.fromJson(Map<String, dynamic> json) {
    subscribed = json['subscribed'];
    nonSubscribed = json['nonSubscribed'];
    expired = json['expired'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['subscribed'] = this.subscribed;
    data['nonSubscribed'] = this.nonSubscribed;
    data['expired'] = this.expired;
    return data;
  }
}