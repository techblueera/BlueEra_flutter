/// Response from `GET wallet-service/wallet/direct-referral-income`.
///
/// The endpoint is named after one card but the payload powers every
/// card on the Statics tab — joining bonus, direct referral, order
/// income, content creation income.
class WalletStaticsResponse {
  final bool? success;
  final WalletStaticsModel? data;

  WalletStaticsResponse({this.success, this.data});

  factory WalletStaticsResponse.fromJson(Map<String, dynamic> json) {
    return WalletStaticsResponse(
      success: json['success'] as bool?,
      data: json['data'] is Map<String, dynamic>
          ? WalletStaticsModel.fromJson(json['data'])
          : null,
    );
  }
}

class WalletStaticsModel {
  final String? referralCode;
  final JoiningBonus? joiningBonus;
  final DirectReferralIncome? directReferralIncome;
  final OrderIncome? orderIncome;
  final ContentCreationIncome? contentCreationIncome;

  WalletStaticsModel({
    this.referralCode,
    this.joiningBonus,
    this.directReferralIncome,
    this.orderIncome,
    this.contentCreationIncome,
  });

  factory WalletStaticsModel.fromJson(Map<String, dynamic> json) {
    return WalletStaticsModel(
      referralCode: json['referralCode'] as String?,
      joiningBonus: json['joiningBonus'] is Map<String, dynamic>
          ? JoiningBonus.fromJson(json['joiningBonus'])
          : null,
      directReferralIncome: json['directReferralIncome'] is Map<String, dynamic>
          ? DirectReferralIncome.fromJson(json['directReferralIncome'])
          : null,
      orderIncome: json['orderIncome'] is Map<String, dynamic>
          ? OrderIncome.fromJson(json['orderIncome'])
          : null,
      contentCreationIncome:
          json['contentCreationIncome'] is Map<String, dynamic>
              ? ContentCreationIncome.fromJson(json['contentCreationIncome'])
              : null,
    );
  }
}

// ─── Joining bonus ───────────────────────────────────────────────────

class JoiningBonus {
  final num? totalBonus;
  final String? currency;
  final JoiningProgress? progress;
  final num? balance;
  final bool? isPlaceholder;

  JoiningBonus({
    this.totalBonus,
    this.currency,
    this.progress,
    this.balance,
    this.isPlaceholder,
  });

  factory JoiningBonus.fromJson(Map<String, dynamic> json) {
    return JoiningBonus(
      totalBonus: json['totalBonus'] as num?,
      currency: json['currency'] as String?,
      progress: json['progress'] is Map<String, dynamic>
          ? JoiningProgress.fromJson(json['progress'])
          : null,
      balance: json['balance'] as num?,
      isPlaceholder: json['isPlaceholder'] as bool?,
    );
  }
}

class JoiningProgress {
  final ProgressMetric? days;
  final ProgressMetric? workHours;
  final ProgressMetric? assignTask;

  JoiningProgress({this.days, this.workHours, this.assignTask});

  factory JoiningProgress.fromJson(Map<String, dynamic> json) {
    return JoiningProgress(
      days: json['days'] is Map<String, dynamic>
          ? ProgressMetric.fromJson(json['days'])
          : null,
      workHours: json['workHours'] is Map<String, dynamic>
          ? ProgressMetric.fromJson(json['workHours'])
          : null,
      assignTask: json['assignTask'] is Map<String, dynamic>
          ? ProgressMetric.fromJson(json['assignTask'])
          : null,
    );
  }
}

class ProgressMetric {
  final num? current;
  final num? target;

  ProgressMetric({this.current, this.target});

  factory ProgressMetric.fromJson(Map<String, dynamic> json) => ProgressMetric(
        current: json['current'] as num?,
        target: json['target'] as num?,
      );
}

// ─── Direct referral income ──────────────────────────────────────────

class DirectReferralIncome {
  final num? referralCount;
  final ReferralBreakdown? breakdown;
  final ReferralEarnings? earnings;

  DirectReferralIncome({this.referralCount, this.breakdown, this.earnings});

  factory DirectReferralIncome.fromJson(Map<String, dynamic> json) {
    return DirectReferralIncome(
      referralCount: json['referralCount'] as num?,
      breakdown: json['breakdown'] is Map<String, dynamic>
          ? ReferralBreakdown.fromJson(json['breakdown'])
          : null,
      earnings: json['earnings'] is Map<String, dynamic>
          ? ReferralEarnings.fromJson(json['earnings'])
          : null,
    );
  }
}

class ReferralBreakdown {
  final num? subscribed;
  final num? pending;
  final num? unsubscribed;
  final num? expired;

  ReferralBreakdown({
    this.subscribed,
    this.pending,
    this.unsubscribed,
    this.expired,
  });

  factory ReferralBreakdown.fromJson(Map<String, dynamic> json) =>
      ReferralBreakdown(
        subscribed: json['subscribed'] as num?,
        pending: json['pending'] as num?,
        unsubscribed: json['unsubscribed'] as num?,
        expired: json['expired'] as num?,
      );
}

class ReferralEarnings {
  final num? estimatedEarning;
  final num? totalEarn;
  final num? balance;
  final String? currency;

  ReferralEarnings({
    this.estimatedEarning,
    this.totalEarn,
    this.balance,
    this.currency,
  });

  factory ReferralEarnings.fromJson(Map<String, dynamic> json) =>
      ReferralEarnings(
        estimatedEarning: json['estimatedEarning'] as num?,
        totalEarn: json['totalEarn'] as num?,
        balance: json['balance'] as num?,
        currency: json['currency'] as String?,
      );
}

// ─── Order income ────────────────────────────────────────────────────

class OrderIncome {
  final num? totalAmount;
  final String? currency;
  final OrderBreakdown? breakdown;
  final num? balance;
  final bool? isPlaceholder;

  OrderIncome({
    this.totalAmount,
    this.currency,
    this.breakdown,
    this.balance,
    this.isPlaceholder,
  });

  factory OrderIncome.fromJson(Map<String, dynamic> json) {
    return OrderIncome(
      totalAmount: json['totalAmount'] as num?,
      currency: json['currency'] as String?,
      breakdown: json['breakdown'] is Map<String, dynamic>
          ? OrderBreakdown.fromJson(json['breakdown'])
          : null,
      balance: json['balance'] as num?,
      isPlaceholder: json['isPlaceholder'] as bool?,
    );
  }
}

class OrderBreakdown {
  final num? myOrder;
  final num? referralOrder;
  final num? bonus;

  OrderBreakdown({this.myOrder, this.referralOrder, this.bonus});

  factory OrderBreakdown.fromJson(Map<String, dynamic> json) => OrderBreakdown(
        myOrder: json['myOrder'] as num?,
        referralOrder: json['referralOrder'] as num?,
        bonus: json['bonus'] as num?,
      );
}

// ─── Content creation income ────────────────────────────────────────

class ContentCreationIncome {
  final num? totalIncome;
  final String? currency;
  final num? totalVideo;
  final num? viewCount;
  final num? bonus;
  final num? balance;
  final bool? isPlaceholder;

  ContentCreationIncome({
    this.totalIncome,
    this.currency,
    this.totalVideo,
    this.viewCount,
    this.bonus,
    this.balance,
    this.isPlaceholder,
  });

  factory ContentCreationIncome.fromJson(Map<String, dynamic> json) {
    return ContentCreationIncome(
      totalIncome: json['totalIncome'] as num?,
      currency: json['currency'] as String?,
      totalVideo: json['totalVideo'] as num?,
      viewCount: json['viewCount'] as num?,
      bonus: json['bonus'] as num?,
      balance: json['balance'] as num?,
      isPlaceholder: json['isPlaceholder'] as bool?,
    );
  }
}
