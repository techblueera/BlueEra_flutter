class GeocodingResponse {
  final List<Result> results;
  final String status;

  GeocodingResponse({
    required this.results,
    required this.status,
  });

  factory GeocodingResponse.fromJson(Map<String, dynamic> json) {
    return GeocodingResponse(
      results: (json['results'] as List<dynamic>)
          .map((e) => Result.fromJson(e))
          .toList(),
      status: json['status'] ?? '',
    );
  }
}

class Result {
  final List<AddressComponent> addressComponents;
  final String formattedAddress;
  final Geometry geometry;
  final String placeId;

  Result({
    required this.addressComponents,
    required this.formattedAddress,
    required this.geometry,
    required this.placeId,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      addressComponents: (json['address_components'] as List<dynamic>)
          .map((e) => AddressComponent.fromJson(e))
          .toList(),
      formattedAddress: json['formatted_address'] ?? '',
      geometry: Geometry.fromJson(json['geometry']),
      placeId: json['place_id'] ?? '',
    );
  }
}

class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'] ?? '',
      shortName: json['short_name'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

class Geometry {
  final Location location;

  Geometry({required this.location});

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
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }
}
