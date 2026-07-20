/// Models for the Rapido-style customer ride-booking flow.
///
/// Every `fromJson` is defensive: the backend is still being built against
/// docs/backend/RIDE_BOOKING_FRONTEND_INTEGRATION.md, so a missing or
/// differently-typed field degrades to a sensible default rather than
/// throwing mid-flow.
library;

/// Safe numeric coercion — the backend may send fares as `40`, `40.0` or
/// `"40"` depending on the serializer.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

/// A pickup or drop point. Used for recents, search results, saved places and
/// the two ends of a booking.
class RidePlace {
  final String? id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final bool isSaved;

  const RidePlace({
    this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.isSaved = false,
  });

  /// True once we have a usable coordinate. `0,0` is treated as "unset"
  /// rather than the Atlantic — it is what the geocoder returns on failure.
  bool get hasCoordinates => latitude != 0 && longitude != 0;

  /// Single-line form for compact rows and API payloads.
  String get fullAddress =>
      subtitle.isEmpty ? title : '$title, $subtitle';

  RidePlace copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? latitude,
    double? longitude,
    bool? isSaved,
  }) {
    return RidePlace(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  factory RidePlace.fromJson(Map<dynamic, dynamic> json) {
    // Accept both a flat {latitude, longitude} and a GeoJSON
    // {location: {coordinates: [lng, lat]}} shape.
    double lat = _toDouble(json['latitude']) ?? 0;
    double lng = _toDouble(json['longitude']) ?? 0;
    final location = json['location'];
    if (lat == 0 && lng == 0 && location is Map) {
      final coords = location['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = _toDouble(coords[0]) ?? 0;
        lat = _toDouble(coords[1]) ?? 0;
      }
    }
    return RidePlace(
      id: json['id']?.toString() ?? json['placeId']?.toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? json['address'] ?? '').toString(),
      latitude: lat,
      longitude: lng,
      isSaved: json['isSaved'] == true || json['saved'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'subtitle': subtitle,
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// One bookable vehicle category with its quoted fare — a row on the
/// vehicle-selection sheet.
class RideVehicleOption {
  /// Stable machine code: `BIKE`, `AUTO`, `CAB_ECONOMY`, `CAB_PREMIUM`, `PARCEL`.
  final String code;
  final String name;

  /// Optional one-liner under the name ("Quick Bike rides").
  final String? description;

  /// Server-issued badge such as `FASTEST` / `CHEAPEST`. Null for most rows.
  final String? badge;
  final double fare;
  final int? seats;

  /// Minutes until drop-off, used to render the "Drop 3:16 pm" line.
  final int? dropEtaMinutes;

  /// Minutes until the captain reaches pickup.
  final int? pickupEtaMinutes;

  /// Short-lived token that must be echoed back when booking, so the fare the
  /// user saw is the fare that gets charged.
  final String quoteId;

  const RideVehicleOption({
    required this.code,
    required this.name,
    required this.fare,
    required this.quoteId,
    this.description,
    this.badge,
    this.seats,
    this.dropEtaMinutes,
    this.pickupEtaMinutes,
  });

  factory RideVehicleOption.fromJson(Map<dynamic, dynamic> json) {
    return RideVehicleOption(
      code: (json['code'] ?? json['vehicleType'] ?? '').toString(),
      name: (json['name'] ?? json['label'] ?? '').toString(),
      description: json['description']?.toString(),
      badge: json['badge']?.toString(),
      fare: _toDouble(json['fare']) ?? 0,
      seats: _toInt(json['seats']),
      dropEtaMinutes: _toInt(json['dropEtaMinutes']),
      pickupEtaMinutes: _toInt(json['pickupEtaMinutes']),
      quoteId: (json['quoteId'] ?? '').toString(),
    );
  }
}

/// Lifecycle of a booking. Drives which screen the user sees, so the mapping
/// from the server string is centralised here.
enum RideStatus {
  searching,
  assigned,
  arrived,
  onTrip,
  completed,
  cancelled,
  noRidersFound;

  static RideStatus fromString(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'ASSIGNED':
      case 'ACCEPTED':
        return RideStatus.assigned;
      case 'ARRIVED':
        return RideStatus.arrived;
      case 'ON_TRIP':
      case 'STARTED':
        return RideStatus.onTrip;
      case 'COMPLETED':
        return RideStatus.completed;
      case 'CANCELLED':
        return RideStatus.cancelled;
      case 'NO_RIDERS_FOUND':
      case 'EXPIRED':
        return RideStatus.noRidersFound;
      default:
        return RideStatus.searching;
    }
  }

  /// True while the booking still warrants an open tracking screen.
  bool get isActive =>
      this == RideStatus.searching ||
      this == RideStatus.assigned ||
      this == RideStatus.arrived ||
      this == RideStatus.onTrip;

  /// True once a captain is attached, i.e. show tracking instead of searching.
  bool get hasCaptain =>
      this == RideStatus.assigned ||
      this == RideStatus.arrived ||
      this == RideStatus.onTrip;
}

/// The assigned captain, shown on the tracking card.
class RideCaptain {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final String? vehicleNumber;
  final String? vehicleModel;
  final double? rating;
  final double? latitude;
  final double? longitude;

  const RideCaptain({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
    this.vehicleNumber,
    this.vehicleModel,
    this.rating,
    this.latitude,
    this.longitude,
  });

  factory RideCaptain.fromJson(Map<dynamic, dynamic> json) {
    return RideCaptain(
      id: (json['id'] ?? json['riderId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['profileImage']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
      vehicleModel: json['vehicleModel']?.toString(),
      rating: _toDouble(json['rating']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }
}

/// Full booking state as returned by the status poll.
class RideBooking {
  final String rideId;
  final RideStatus status;
  final RidePlace pickup;
  final RidePlace drop;
  final String vehicleCode;
  final String vehicleName;
  final double fare;
  final String paymentMode;

  /// 4-digit OTP the customer reads out to start the ride.
  final String? startOtp;
  final RideCaptain? captain;

  /// Minutes until the captain reaches pickup, server-computed.
  final int? pickupEtaMinutes;

  /// Straight-line/road distance from captain to pickup, in metres.
  final int? captainDistanceMeters;

  /// 0–1 progress of the search fan-out, for the searching screen's bar.
  final double searchProgress;

  const RideBooking({
    required this.rideId,
    required this.status,
    required this.pickup,
    required this.drop,
    required this.vehicleCode,
    required this.vehicleName,
    required this.fare,
    this.paymentMode = 'CASH',
    this.startOtp,
    this.captain,
    this.pickupEtaMinutes,
    this.captainDistanceMeters,
    this.searchProgress = 0,
  });

  factory RideBooking.fromJson(Map<dynamic, dynamic> json) {
    final captain = json['captain'] ?? json['rider'];
    return RideBooking(
      rideId: (json['rideId'] ?? json['id'] ?? '').toString(),
      status: RideStatus.fromString(json['status']?.toString()),
      pickup: json['pickup'] is Map
          ? RidePlace.fromJson(json['pickup'])
          : const RidePlace(title: '', subtitle: '', latitude: 0, longitude: 0),
      drop: json['drop'] is Map
          ? RidePlace.fromJson(json['drop'])
          : const RidePlace(title: '', subtitle: '', latitude: 0, longitude: 0),
      vehicleCode: (json['vehicleCode'] ?? json['vehicleType'] ?? '').toString(),
      vehicleName: (json['vehicleName'] ?? '').toString(),
      fare: _toDouble(json['fare']) ?? 0,
      paymentMode: (json['paymentMode'] ?? 'CASH').toString(),
      startOtp: json['startOtp']?.toString() ?? json['otp']?.toString(),
      captain: captain is Map ? RideCaptain.fromJson(captain) : null,
      pickupEtaMinutes: _toInt(json['pickupEtaMinutes']),
      captainDistanceMeters: _toInt(json['captainDistanceMeters']),
      searchProgress: _toDouble(json['searchProgress']) ?? 0,
    );
  }

  RideBooking copyWith({
    RideStatus? status,
    RideCaptain? captain,
    int? pickupEtaMinutes,
    int? captainDistanceMeters,
    double? searchProgress,
    double? fare,
  }) {
    return RideBooking(
      rideId: rideId,
      status: status ?? this.status,
      pickup: pickup,
      drop: drop,
      vehicleCode: vehicleCode,
      vehicleName: vehicleName,
      fare: fare ?? this.fare,
      paymentMode: paymentMode,
      startOtp: startOtp,
      captain: captain ?? this.captain,
      pickupEtaMinutes: pickupEtaMinutes ?? this.pickupEtaMinutes,
      captainDistanceMeters:
          captainDistanceMeters ?? this.captainDistanceMeters,
      searchProgress: searchProgress ?? this.searchProgress,
    );
  }
}

/// A row on the "Why do you want to cancel?" sheet. Server-driven so ops can
/// reword reasons without shipping an app update.
class RideCancelReason {
  final String code;
  final String label;

  /// Optional warning copy, e.g. a cancellation fee notice.
  final String? note;

  const RideCancelReason({
    required this.code,
    required this.label,
    this.note,
  });

  factory RideCancelReason.fromJson(Map<dynamic, dynamic> json) {
    return RideCancelReason(
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      note: json['note']?.toString(),
    );
  }
}
