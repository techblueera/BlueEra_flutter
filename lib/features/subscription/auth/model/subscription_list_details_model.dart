class SubscriptionPlanDetailsNewModel {
  bool? success;
  String? message;
  List<SubscriptionPlanData>? data;
  String? bannerVideoUrl;

  SubscriptionPlanDetailsNewModel({
    this.success,
    this.message,
    this.data,
    this.bannerVideoUrl,
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
      bannerVideoUrl: json['bannerVideoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
      'bannerVideoUrl': bannerVideoUrl,
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
  int? amountBeforeDiscount;
  String? currency;
  String? createdBy;
  String? tier;
  List<String>? perks;
  int? rangeInKm;
  String? mode;
  String? createdAt;
  String? updatedAt;
  int? v;
  String? perkType;
  int? perkValue;
  int? perkBonus;
  num? taxPercent;
  int? taxAmount;
  int? totalAmount;
  String? sacCode;
  String? entityType;

  SubscriptionPlanData({
    this.id,
    this.planId,
    this.interval,
    this.period,
    this.active,
    this.name,
    this.description,
    this.amount,
    this.amountBeforeDiscount,
    this.currency,
    this.createdBy,
    this.tier,
    this.perks,
    this.rangeInKm,
    this.mode,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.perkType,
    this.perkValue,
    this.perkBonus,
    this.taxPercent,
    this.taxAmount,
    this.totalAmount,
    this.sacCode,
    this.entityType,
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
      amountBeforeDiscount: json['amountBeforeDiscount'] is int
          ? json['amountBeforeDiscount']
          : int.tryParse('${json['amountBeforeDiscount']}'),
      currency: json['currency']?.toString(),
      createdBy: json['created_by']?.toString(),
      tier: json['tier']?.toString(),
      perks: json['perks'] != null
          ? List<String>.from(json['perks'])
          : [],
      rangeInKm: json['rangeInKm'] is int
          ? json['rangeInKm']
          : int.tryParse('${json['rangeInKm']}'),
      mode: json['mode']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      v: json['__v'] is int
          ? json['__v']
          : int.tryParse('${json['__v']}'),
      perkType: json['perk_type']?.toString(),
      perkValue: json['perk_value'] is int
          ? json['perk_value']
          : int.tryParse('${json['perk_value']}'),
      perkBonus: json['perk_bonus'] is int
          ? json['perk_bonus']
          : int.tryParse('${json['perk_bonus']}'),
      taxPercent: json['tax_percent'] is num
          ? json['tax_percent']
          : num.tryParse('${json['tax_percent']}'),
      taxAmount: json['tax_amount'] is int
          ? json['tax_amount']
          : int.tryParse('${json['tax_amount']}'),
      totalAmount: json['total_amount'] is int
          ? json['total_amount']
          : int.tryParse('${json['total_amount']}'),
      sacCode: json['sac_code']?.toString(),
      entityType: json['entity_type']?.toString(),
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
      'amountBeforeDiscount': amountBeforeDiscount,
      'currency': currency,
      'created_by': createdBy,
      'tier': tier,
      'perks': perks,
      'rangeInKm': rangeInKm,
      'mode': mode,
      'created_at': createdAt,
      'updated_at': updatedAt,
      '__v': v,
      'perk_type': perkType,
      'perk_value': perkValue,
      'perk_bonus': perkBonus,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'sac_code': sacCode,
      'entity_type': entityType,
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
    int? amountBeforeDiscount,
    String? currency,
    String? createdBy,
    String? tier,
    List<String>? perks,
    int? rangeInKm,
    String? mode,
    String? createdAt,
    String? updatedAt,
    int? v,
    String? perkType,
    int? perkValue,
    int? perkBonus,
    num? taxPercent,
    int? taxAmount,
    int? totalAmount,
    String? sacCode,
    String? entityType,
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
      amountBeforeDiscount: amountBeforeDiscount ?? this.amountBeforeDiscount,
      currency: currency ?? this.currency,
      createdBy: createdBy ?? this.createdBy,
      tier: tier ?? this.tier,
      perks: perks ?? this.perks,
      rangeInKm: rangeInKm ?? this.rangeInKm,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
      perkType: perkType ?? this.perkType,
      perkValue: perkValue ?? this.perkValue,
      perkBonus: perkBonus ?? this.perkBonus,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      sacCode: sacCode ?? this.sacCode,
      entityType: entityType ?? this.entityType,
    );
  }
}