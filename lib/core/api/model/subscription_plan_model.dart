import 'dart:convert';
SubscriptionPlanModel subscriptionPlanModelFromJson(String str) => SubscriptionPlanModel.fromJson(json.decode(str));
String subscriptionPlanModelToJson(SubscriptionPlanModel data) => json.encode(data.toJson());
class SubscriptionPlanModel {
  SubscriptionPlanModel({
      this.success, 
      this.message, 
      this.data,});

  SubscriptionPlanModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(GetSubscriptionData.fromJson(v));
      });
    }
  }
  bool? success;
  String? message;
  List<GetSubscriptionData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

GetSubscriptionData dataFromJson(String str) => GetSubscriptionData.fromJson(json.decode(str));
String dataToJson(GetSubscriptionData data) => json.encode(data.toJson());
class GetSubscriptionData {
  GetSubscriptionData({
      this.id, 
      this.planId, 
      this.interval, 
      this.period, 
      this.active, 
      this.name, 
      this.description, 
      this.amount, 
      this.currency, 
      this.createdBy,});

  GetSubscriptionData.fromJson(dynamic json) {
    id = json['_id'];
    planId = json['plan_id'];
    interval = json['interval'];
    period = json['period'];
    active = json['active'];
    name = json['name'];
    description = json['description'];
    amount = json['amount'];
    currency = json['currency'];
    createdBy = json['created_by'];
  }
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

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['plan_id'] = planId;
    map['interval'] = interval;
    map['period'] = period;
    map['active'] = active;
    map['name'] = name;
    map['description'] = description;
    map['amount'] = amount;
    map['currency'] = currency;
    map['created_by'] = createdBy;
    return map;
  }

}