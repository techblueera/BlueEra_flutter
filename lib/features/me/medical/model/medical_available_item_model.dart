class MedicalAvailableItemModel {
  // List<AvailableItem>? availableItems;
  num? totalPrice;
  int? totalNoofAvailableItems;
  int? totalNoOfMissingItems;
  String? rideOrderId;
  String? groceryOrderId;

  MedicalAvailableItemModel({
    // this.availableItems,
    this.totalPrice,
    this.totalNoofAvailableItems,
    this.totalNoOfMissingItems,
    this.rideOrderId,
    this.groceryOrderId,
  });

  factory MedicalAvailableItemModel.fromJson(Map<String, dynamic> json) =>
      MedicalAvailableItemModel(
        // availableItems: json["availableItems"] == null
        //     ? []
        //     : List<AvailableItem>.from(
        //     json["availableItems"]!.map((x) => AvailableItem.fromJson(x))),
        totalPrice: json["totalPrice"],
        // Mapping new keys
        totalNoofAvailableItems: json["totalNoofAvailableItems"],
        totalNoOfMissingItems: json["TotalNoOfMissingItems"], // Note the capital 'T' in JSON
        rideOrderId: json["RideOrderId"], // Note the capital 'R' in JSON
        groceryOrderId: json["groceryOrderId"],
      );

  Map<String, dynamic> toJson() => {
    // "availableItems": availableItems == null
    //     ? []
    //     : List<dynamic>.from(availableItems!.map((x) => x.toJson())),
    "totalPrice": totalPrice,
    "totalNoofAvailableItems": totalNoofAvailableItems,
    "TotalNoOfMissingItems": totalNoOfMissingItems,
    "RideOrderId": rideOrderId,
    "groceryOrderId": groceryOrderId,
  };
}