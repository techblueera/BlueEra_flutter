class SubscriptionPlanDetailsNewModel {
  bool? success;
  String? message;
  List<SubscriptionPlanData>? data;

  SubscriptionPlanDetailsNewModel({
    this.success,
    this.message,
    this.data,
  });

  factory SubscriptionPlanDetailsNewModel.fromJson(
      Map<String, dynamic> json) {
    return SubscriptionPlanDetailsNewModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null && json['data'] is List
          ? List<SubscriptionPlanData>.from(
        json['data']
            .map((e) => SubscriptionPlanData.fromJson(e ?? {})),
      )
          : <SubscriptionPlanData>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

/// 🔹 Individual Subscription Plan
class SubscriptionPlanData {
  String? id;
  String? planId;
  int? interval;
  String? period;
  bool? active;
  String? name;
  String? description;
  int? amount;
  String? currency;
  String? createdBy;
  String? createdAt;
  String? updatedAt;

  SubscriptionPlanData({
    this.id,
    this.planId,
    this.interval,
    this.period,
    this.active,
    this.name,
    this.description,
    this.amount,
    this.currency,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanData.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanData(
      id: json['_id'],
      planId: json['plan_id'],
      interval: json['interval'] is int
          ? json['interval']
          : int.tryParse('${json['interval']}'),
      period: json['period'],
      active: json['active'],
      name: json['name'],
      description: json['description'],
      amount: json['amount'] is int
          ? json['amount']
          : int.tryParse('${json['amount']}'),
      currency: json['currency'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'plan_id': planId,
      'interval': interval,
      'period': period,
      'active': active,
      'name': name,
      'description': description,
      'amount': amount,
      'currency': currency,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}