import 'dart:convert';
SubscriptionOfferModel subscriptionOfferModelFromJson(String str) => SubscriptionOfferModel.fromJson(json.decode(str));
String subscriptionOfferModelToJson(SubscriptionOfferModel data) => json.encode(data.toJson());
class SubscriptionOfferModel {
  SubscriptionOfferModel({
      this.success, 
      this.message, 
      this.data,});

  SubscriptionOfferModel.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(OfferData.fromJson(v));
      });
    }
  }
  bool? success;
  String? message;
  List<OfferData>? data;

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

OfferData dataFromJson(String str) => OfferData.fromJson(json.decode(str));
String dataToJson(OfferData data) => json.encode(data.toJson());
class OfferData {
  OfferData({
      this.id, 
      this.offerId, 
      this.active, 
      this.name, 
      this.offerAmount, 
      this.minSubsAmount, 
      this.endDate, 
      this.currency, 
      this.method, 
      this.createdBy,});

  OfferData.fromJson(dynamic json) {
    id = json['_id'];
    offerId = json['offer_id'];
    active = json['active'];
    name = json['name'];
    offerAmount = json['offer_amount'];
    minSubsAmount = json['min_subs_amount'];
    endDate = json['end_date'];
    currency = json['currency'];
    method = json['method'];
    createdBy = json['created_by'];
  }
  String? id;
  String? offerId;
  bool? active;
  String? name;
  int? offerAmount;
  int? minSubsAmount;
  String? endDate;
  String? currency;
  String? method;
  String? createdBy;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = id;
    map['offer_id'] = offerId;
    map['active'] = active;
    map['name'] = name;
    map['offer_amount'] = offerAmount;
    map['min_subs_amount'] = minSubsAmount;
    map['end_date'] = endDate;
    map['currency'] = currency;
    map['method'] = method;
    map['created_by'] = createdBy;
    return map;
  }

}