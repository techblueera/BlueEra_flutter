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
  String? tier;
  List<String>? perks;
  int? rangeInKm;
  String? createdAt;
  String? updatedAt;
  int? v;

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
    this.tier,
    this.perks,
    this.rangeInKm,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory SubscriptionPlanData.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanData(
      id: json['_id']?.toString(),
      planId: json['plan_id']?.toString(),
      interval: json['interval'] is int
          ? json['interval']
          : int.tryParse('${json['interval']}'),
      period: json['period']?.toString(),
      active: json['active'] is bool
          ? json['active']
          : json['active'] == true,
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      amount: json['amount'] is int
          ? json['amount']
          : int.tryParse('${json['amount']}'),
      currency: json['currency']?.toString(),
      createdBy: json['created_by']?.toString(),
      tier: json['tier']?.toString(),
      perks: json['perks'] != null
          ? List<String>.from(json['perks'])
          : [],
      rangeInKm: json['rangeInKm'] is int
          ? json['rangeInKm']
          : int.tryParse('${json['rangeInKm']}'),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      v: json['__v'] is int
          ? json['__v']
          : int.tryParse('${json['__v']}'),
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
      'tier': tier,
      'perks': perks,
      'rangeInKm': rangeInKm,
      'created_at': createdAt,
      'updated_at': updatedAt,
      '__v': v,
    };
  }

  SubscriptionPlanData copyWith({
    String? id,
    String? planId,
    int? interval,
    String? period,
    bool? active,
    String? name,
    String? description,
    int? amount,
    String? currency,
    String? createdBy,
    String? tier,
    List<String>? perks,
    int? rangeInKm,
    String? createdAt,
    String? updatedAt,
    int? v,
  }) {
    return SubscriptionPlanData(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      interval: interval ?? this.interval,
      period: period ?? this.period,
      active: active ?? this.active,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      createdBy: createdBy ?? this.createdBy,
      tier: tier ?? this.tier,
      perks: perks ?? this.perks,
      rangeInKm: rangeInKm ?? this.rangeInKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }
}