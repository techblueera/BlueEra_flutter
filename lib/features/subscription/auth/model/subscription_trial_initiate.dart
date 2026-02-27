class SubscriptionTrialInitiate {
  bool? success;
  String? message;
  SubscriptionTrialInitiateData? data;

  SubscriptionTrialInitiate({this.success, this.message, this.data});

  SubscriptionTrialInitiate.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new SubscriptionTrialInitiateData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class SubscriptionTrialInitiateData {
  String? subscriptionId;
  int? amount;
  String? currency;
  String? keyId;
  String? subscriptionPlanId;

  SubscriptionTrialInitiateData(
      {this.subscriptionId,
        this.amount,
        this.currency,
        this.keyId,
        this.subscriptionPlanId});

  SubscriptionTrialInitiateData.fromJson(Map<String, dynamic> json) {
    subscriptionId = json['subscription_id'];
    amount = json['amount'];
    currency = json['currency'];
    keyId = json['key_id'];
    subscriptionPlanId = json['subscriptionPlanId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['subscription_id'] = this.subscriptionId;
    data['amount'] = this.amount;
    data['currency'] = this.currency;
    data['key_id'] = this.keyId;
    data['subscriptionPlanId'] = this.subscriptionPlanId;
    return data;
  }
}