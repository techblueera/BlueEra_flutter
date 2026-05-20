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
  final String? createdAt;

  WalletReferralHistoryItem({
    this.userId,
    this.name,
    this.profileImage,
    this.profession,
    this.subscriptionStatus,
    this.rawStatus,
    this.planCost,
    this.referralIncome,
    this.createdAt,
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
      createdAt:
          json['createdAt'] ?? json['subscribedAt'] ?? json['date'],
    );
  }
}
