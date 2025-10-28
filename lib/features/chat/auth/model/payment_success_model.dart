class PaymentResponseModel {
  String? requestId;
  String? orderId;
  int? estimatedPickupTime;
  EstimatedFareDetails? estimatedFareDetails;
  String? trackingUrl;

  PaymentResponseModel(
      {this.requestId,
        this.orderId,
        this.estimatedPickupTime,
        this.estimatedFareDetails,
        this.trackingUrl});

  PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    requestId = json['request_id'];
    orderId = json['order_id'];
    estimatedPickupTime = json['estimated_pickup_time'];
    estimatedFareDetails = json['estimated_fare_details'] != null
        ? new EstimatedFareDetails.fromJson(json['estimated_fare_details'])
        : null;
    trackingUrl = json['tracking_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['request_id'] = this.requestId;
    data['order_id'] = this.orderId;
    data['estimated_pickup_time'] = this.estimatedPickupTime;
    if (this.estimatedFareDetails != null) {
      data['estimated_fare_details'] = this.estimatedFareDetails!.toJson();
    }
    data['tracking_url'] = this.trackingUrl;
    return data;
  }
}

class EstimatedFareDetails {
  String? currency;
  int? minorAmount;

  EstimatedFareDetails({this.currency, this.minorAmount});

  EstimatedFareDetails.fromJson(Map<String, dynamic> json) {
    currency = json['currency'];
    minorAmount = json['minor_amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currency'] = this.currency;
    data['minor_amount'] = this.minorAmount;
    return data;
  }
}
