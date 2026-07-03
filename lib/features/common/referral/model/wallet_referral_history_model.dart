class WalletReferralHistoryResponse {
  final bool? success;
  final List<WalletReferralHistoryItem>? data;

  WalletReferralHistoryResponse({this.success, this.data});

  factory WalletReferralHistoryResponse.fromJson(Map<String, dynamic> json) {
    return WalletReferralHistoryResponse(
      success: json['success'],
      data: (json['data'] as List?)
          ?.map((v) => WalletReferralHistoryItem.fromJson(v))
          .toList(),
    );
  }
}

class WalletReferralHistoryItem {
  final String? userId;
  final String? name;
  final String? profileImage;
  final String? profession;
  final String? subscriptionStatus;
  final String? rawStatus;
  final num? planCost;
  final num? referralIncome;
  final num? directIncome;
  final num? indirectIncome;
  final num? totalIncome;
  final num? upcomingIncome;
  final num? upcomingIncomeRatePct;
  final int? level;
  final String? accountType;
  final String? createdAt;
  // Nested downline referrals (recursive). Shown in the details bottom sheet.
  final List<WalletReferralHistoryItem>? children;

  WalletReferralHistoryItem({
    this.userId,
    this.name,
    this.profileImage,
    this.profession,
    this.subscriptionStatus,
    this.rawStatus,
    this.planCost,
    this.referralIncome,
    this.directIncome,
    this.indirectIncome,
    this.totalIncome,
    this.upcomingIncome,
    this.upcomingIncomeRatePct,
    this.level,
    this.accountType,
    this.createdAt,
    this.children,
  });

  factory WalletReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    return WalletReferralHistoryItem(
      userId: json['userId'],
      name: json['name'],
      profileImage: json['profileImage'],
      profession: json['profession'],
      subscriptionStatus: json['subscriptionStatus'],
      rawStatus: json['rawStatus'],
      planCost: json['planCost'],
      referralIncome: json['referralIncome'],
      directIncome: json['directIncome'],
      indirectIncome: json['indirectIncome'],
      totalIncome: json['totalIncome'],
      upcomingIncome: json['upcomingIncome'],
      upcomingIncomeRatePct: json['upcomingIncomeRatePct'],
      level: json['level'],
      accountType: json['accountType'],
      createdAt:
          json['createdAt'] ?? json['subscribedAt'] ?? json['date'],
      children: (json['children'] as List?)
          ?.map((v) => WalletReferralHistoryItem.fromJson(
              v as Map<String, dynamic>))
          .toList(),
    );
  }
}
