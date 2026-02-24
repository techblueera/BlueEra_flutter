import 'package:BlueEra/features/subscription/auth/model/subscription_list_details_model.dart';

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionPlanData subscriptionPlanData;
  final bool autoPay;
  final String status;
  final bool isSubscribed;
  final int totalCount;
  final int paidCount;
  final int remainingCount;
  final String subscriptionId;
  final bool cancelAtCycleEnd;
  final bool isTrial;
  final String trialStart;
  final String trialEnd;
  final bool trialPaid;
  final String validUpto;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.subscriptionPlanData,
    required this.autoPay,
    required this.status,
    required this.isSubscribed,
    required this.totalCount,
    required this.paidCount,
    required this.remainingCount,
    required this.subscriptionId,
    required this.cancelAtCycleEnd,
    required this.isTrial,
    required this.trialStart,
    required this.trialEnd,
    required this.trialPaid,
    required this.validUpto,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      planId: json['plan_id'] ?? '',
      subscriptionPlanData: SubscriptionPlanData.fromJson(json['subscriptionPlanId'] ?? {}),
      autoPay: json['auto_pay'] ?? false,
      status: json['status'] ?? '',
      isSubscribed: json['isSubscribed'] ?? false,
      totalCount: json['total_count'] ?? 0,
      paidCount: json['paid_count'] ?? 0,
      remainingCount: json['remaining_count'] ?? 0,
      subscriptionId: json['subscription_id'] ?? '',
      cancelAtCycleEnd: json['cancel_at_cycle_end'] ?? false,
      isTrial: json['is_trial'] ?? false,
      trialStart: json['trial_start'] ?? '',
      trialEnd: json['trial_end'] ?? '',
      trialPaid: json['trial_paid'] ?? false,
      validUpto: json['valid_upto'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'plan_id': planId,
      'subscriptionPlanId': subscriptionPlanData.toJson(),
      'auto_pay': autoPay,
      'status': status,
      'isSubscribed': isSubscribed,
      'total_count': totalCount,
      'paid_count': paidCount,
      'remaining_count': remainingCount,
      'subscription_id': subscriptionId,
      'cancel_at_cycle_end': cancelAtCycleEnd,
      'is_trial': isTrial,
      'trial_start': trialStart,
      'trial_end': trialEnd,
      'trial_paid': trialPaid,
      'valid_upto': validUpto,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}
