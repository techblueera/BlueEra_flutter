class PlaceList {
  final String id;
  final String name;
  final String shortDescription;
  final String phone;
  final String email;
  final bool isCommercial;
  final List<String> photos;
  final List<String> category;
  final List<VisitingHours> visitingHours;
  final Coordinates coordinates;
  final LocationModel location;

  PlaceList({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.phone,
    required this.email,
    required this.isCommercial,
    required this.photos,
    required this.category,
    required this.visitingHours,
    required this.coordinates,
    required this.location,
  });

  factory PlaceList.fromJson(Map<String, dynamic> json) {
    return PlaceList(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isCommercial: json['isCommercial'] ?? false,
      photos: List<String>.from(json['photos'] ?? []),
      category: List<String>.from(json['category'] ?? []),
      visitingHours: (json['visitingHours'] as List?)
          ?.where((e) => e is Map<String, dynamic>)
          .map((e) => VisitingHours.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
      location: LocationModel.fromJson(json['location'] ?? {}),
    );
  }
}

class VisitingHours {
  final String day;
  final bool open;
  final String startTime;
  final String endTime;

  VisitingHours({
    required this.day,
    required this.open,
    required this.startTime,
    required this.endTime,
  });

  factory VisitingHours.fromJson(Map<String, dynamic> json) {
    return VisitingHours(
      day: json['day'] ?? '',
      open: json['open'] ?? false,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }
}
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}

class LocationModel {
  final Coordinates coordinates;
  final String address;

  LocationModel({required this.coordinates, required this.address});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
      address: json['address'] ?? '',
    );
  }
}
