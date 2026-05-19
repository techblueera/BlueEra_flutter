class WalletReferralStatsResponse {
  final bool? success;
  final WalletReferralStats? data;

  WalletReferralStatsResponse({this.success, this.data});

  factory WalletReferralStatsResponse.fromJson(Map<String, dynamic> json) {
    return WalletReferralStatsResponse(
      success: json['success'],
      data:
          json['data'] != null ? WalletReferralStats.fromJson(json['data']) : null,
    );
  }
}

class WalletReferralStats {
  final String? referralCode;
  final String? serialCode;
  final num? balance;
  final num? totalIncome;
  final num? estimatedEarning;
  final int? totalReferralCount;
  final Breakdown? breakdown;

  WalletReferralStats({
    this.referralCode,
    this.serialCode,
    this.balance,
    this.totalIncome,
    this.estimatedEarning,
    this.totalReferralCount,
    this.breakdown,
  });

  factory WalletReferralStats.fromJson(Map<String, dynamic> json) {
    return WalletReferralStats(
      referralCode: json['referralCode'],
      serialCode: json['serialCode'] ?? json['serial_code'],
      balance: json['balance'],
      totalIncome: json['totalIncome'],
      estimatedEarning: json['estimatedEarning'],
      totalReferralCount: json['totalReferralCount'],
      breakdown: json['breakdown'] != null
          ? Breakdown.fromJson(json['breakdown'])
          : null,
    );
  }
}

class Breakdown {
  final int? subscribed;
  final int? nonSubscribed;
  final int? expired;
  final int? pending;

  Breakdown({this.subscribed, this.nonSubscribed, this.expired, this.pending});

  factory Breakdown.fromJson(Map<String, dynamic> json) => Breakdown(
        subscribed: json['subscribed'],
        nonSubscribed: json['nonSubscribed'],
        expired: json['expired'],
        pending: json['pending'],
      );
}
