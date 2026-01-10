class PlaceDetailsResponse {
  final Result? result;

  PlaceDetailsResponse({this.result});

  factory PlaceDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDetailsResponse(
      result: json['result'] != null ? Result.fromJson(json['result']) : null,
    );
  }
}

class Result {
  final List<AddressComponent>? addressComponents;
  final Geometry? geometry;
  final String? formattedAddress;
  final String? website;

  Result({this.addressComponents, this.website,  this.geometry, this.formattedAddress});

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      addressComponents: (json['address_components'] as List?)
          ?.map((e) => AddressComponent.fromJson(e))
          .toList(),
      geometry: json['geometry'] != null
          ? Geometry.fromJson(json['geometry'])
          : null,
      formattedAddress: json['formatted_address'],
      website: json['website'],
    );
  }
}

class AddressComponent {
  final String? longName;
  final String? shortName;
  final List<String>? types;

  AddressComponent({this.longName, this.shortName, this.types});

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'],
      shortName: json['short_name'],
      types: (json['types'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

class Geometry {
  final Location? location;

  Geometry({this.location});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location:
      json['location'] != null ? Location.fromJson(json['location']) : null,
    );
  }
}

class Location {
  final double? lat;
  final double? lng;

  Location({this.lat, this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
