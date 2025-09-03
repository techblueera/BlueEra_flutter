import 'dart:convert';

SubscriptionCreateModel subscriptionCreateModelFromJson(String str) =>
    SubscriptionCreateModel.fromJson(json.decode(str));

String subscriptionCreateModelToJson(SubscriptionCreateModel data) =>
    json.encode(data.toJson());

class SubscriptionCreateModel {
  SubscriptionCreateModel({
    this.success,
    this.message,
    this.data,
  });

  SubscriptionCreateModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? SubscriptionData.fromJson(json['data']) : null;
  }

  bool? success;
  String? message;
  SubscriptionData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

SubscriptionData dataFromJson(String str) => SubscriptionData.fromJson(json.decode(str));

String dataToJson(SubscriptionData data) => json.encode(data.toJson());

class SubscriptionData {
  SubscriptionData({
    this.userId,
    this.planId,
    this.autoPay,
    this.status,
    this.totalCount,
    this.paidCount,
    this.remainingCount,
    this.subscriptionId,
    this.cancelAtCycleEnd,
    this.offerId,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  SubscriptionData.fromJson(dynamic json) {
    userId = json['user_id'];
    planId = json['plan_id'];
    autoPay = json['auto_pay'];
    status = json['status'];
    totalCount = json['total_count'];
    paidCount = json['paid_count'];
    remainingCount = json['remaining_count'];
    subscriptionId = json['subscription_id'];
    cancelAtCycleEnd = json['cancel_at_cycle_end'];
    offerId = json['offer_id'];
    id = json['_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    v = json['__v'];
  }

  String? userId;
  String? planId;
  bool? autoPay;
  String? status;
  int? totalCount;
  int? paidCount;
  int? remainingCount;
  String? subscriptionId;
  bool? cancelAtCycleEnd;
  String? offerId;
  String? id;
  String? createdAt;
  String? updatedAt;
  int? v;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = userId;
    map['plan_id'] = planId;
    map['auto_pay'] = autoPay;
    map['status'] = status;
    map['total_count'] = totalCount;
    map['paid_count'] = paidCount;
    map['remaining_count'] = remainingCount;
    map['subscription_id'] = subscriptionId;
    map['cancel_at_cycle_end'] = cancelAtCycleEnd;
    map['offer_id'] = offerId;
    map['_id'] = id;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['__v'] = v;
    return map;
  }
}
