class PlacePrediction {
  final String? description;
  String? city;
  final String? placeId;
  String? distanceInKm; // Set after distance calculation
  double? lat; // Set after distance calculation
  double? lng; // Set after distance calculation

  PlacePrediction({
    this.description,
    this.placeId,
    this.distanceInKm,
    this.lat,
    this.lng,
    this.city,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
    );
  }

  static List<PlacePrediction> fromList(List<dynamic> jsonList) {
    return jsonList.map((e) => PlacePrediction.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'description': description,
      'place_id': placeId,
      'distance_in_km': distanceInKm,
      'lat': lat,
      'lng': lng,
    };
  }

  PlacePrediction copyWith({
    String? city,
    String? description,
    String? placeId,
    String? distanceInKm,
    double? lat,
    double? lng,
  }) {
    return PlacePrediction(
      city: city ?? this.city,
      description: description ?? this.description,
      placeId: placeId ?? this.placeId,
      distanceInKm: distanceInKm ?? this.distanceInKm,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}
