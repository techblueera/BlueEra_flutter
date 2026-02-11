class PaymentResponseModel {
  String? requestId;
  String? id;
  String? orderId;
  int? estimatedPickupTime;
  EstimatedFareDetails? estimatedFareDetails;
  String? trackingUrl;

  LocationModel? pickupLocation;
  LocationModel? dropLocation;
  String? fare;

  PaymentResponseModel({
    this.requestId,
    this.orderId,
    this.id,
    this.estimatedPickupTime,
    this.estimatedFareDetails,
    this.trackingUrl,
    this.pickupLocation,
    this.fare,
    this.dropLocation,
  });

  PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    requestId = json['request_id'];
    orderId = json['order_id'];
    id = json['_id'];
    fare = json['fare'].toString();
    estimatedPickupTime = json['estimated_pickup_time'];
    estimatedFareDetails = json['estimated_fare_details'] != null
        ? EstimatedFareDetails.fromJson(json['estimated_fare_details'])
        : null;
    trackingUrl = json['tracking_url'];

    pickupLocation = json['pickupLocation'] != null
        ? LocationModel.fromJson(json['pickupLocation'])
        : null;

    dropLocation = json['dropLocation'] != null
        ? LocationModel.fromJson(json['dropLocation'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['request_id'] = requestId;
    data['order_id'] = orderId;
    data['_id'] = id;
    data['fare'] = fare;
    data['estimated_pickup_time'] = estimatedPickupTime;

    if (estimatedFareDetails != null) {
      data['estimated_fare_details'] = estimatedFareDetails!.toJson();
    }

    data['tracking_url'] = trackingUrl;

    if (pickupLocation != null) {
      data['pickupLocation'] = pickupLocation!.toJson();
    }

    if (dropLocation != null) {
      data['dropLocation'] = dropLocation!.toJson();
    }

    return data;
  }
}

// ==========================
//  LOCATION MODELS
// ==========================

class LocationModel {
  LocationDataRider? location;

  LocationModel({this.location});

  LocationModel.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? LocationDataRider.fromJson(json['location'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (location != null) data['location'] = location!.toJson();
    return data;
  }
}

class LocationDataRider {
  String? type;
  List<double>? coordinates;

  LocationDataRider({this.type, this.coordinates});

  LocationDataRider.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    coordinates = json['coordinates'] != null
        ? List<double>.from(json['coordinates'].map((x) => double.parse(x.toString())))
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
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
