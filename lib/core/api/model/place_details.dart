class PlaceDetailsResponse {
  final PlaceResult result;
  final String status;

  PlaceDetailsResponse({
    required this.result,
    required this.status,
  });

  factory PlaceDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDetailsResponse(
      result: PlaceResult.fromJson(json['result']),
      status: json['status'] ?? '',
    );
  }
}

class PlaceResult {
  final Geometry geometry;

  PlaceResult({
    required this.geometry,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      geometry: Geometry.fromJson(json['geometry']),
    );
  }
}

class Geometry {
  final Location location;

  Geometry({
    required this.location,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location: Location.fromJson(json['location']),
    );
  }
}

class Location {
  final double lat;
  final double lng;

  Location({
    required this.lat,
    required this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}
