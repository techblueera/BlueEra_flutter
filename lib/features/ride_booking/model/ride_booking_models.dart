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

/// A rider who is live near the customer right now
/// (`GET riders/live-in-radius` → `riders[]`).
///
/// Discovery only — these are the vehicles drawn on the home map, NOT a list
/// the customer books from. The broadcast dispatch decides who actually takes
/// the job, so nothing here is an offer and none of it is carried into an
/// order.
class RideLiveRider {
  const RideLiveRider({
    required this.userId,
    required this.name,
    required this.vehicleType,
    required this.riderStatus,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.lastSeen,
  });

  /// Identity of the rider — the marker id on the map, so a rider that moves
  /// between polls updates in place instead of duplicating.
  final String userId;
  final String name;

  /// The rider's own `vehicleType` enum (`twoWheelerRider`, …) — the artwork
  /// key, and NOT necessarily the coarse category that was queried.
  final String vehicleType;

  /// `available` | `busy` | … — what the server says about their state.
  final String riderStatus;

  final double latitude;
  final double longitude;

  /// Straight-line distance from the query point, as the server measured it.
  final double? distanceKm;

  /// When this position was last reported. A stale fix is still drawn — the
  /// server decides what counts as live — but it is what a "last seen" line
  /// would read from.
  final DateTime? lastSeen;

  /// `0,0` means the rider has no usable fix; drawing it would put a vehicle in
  /// the Atlantic.
  bool get hasCoordinates => latitude != 0 && longitude != 0;

  factory RideLiveRider.fromJson(Map<dynamic, dynamic> json) {
    // Coordinates arrive nested under `location`, with a flat pair and a
    // GeoJSON array tolerated for the same reason as [RidePlace].
    double lat = _toDouble(json['latitude']) ?? 0;
    double lng = _toDouble(json['longitude']) ?? 0;
    final location = json['location'];
    if (location is Map) {
      lat = _toDouble(location['latitude']) ?? lat;
      lng = _toDouble(location['longitude']) ?? lng;
      final coords = location['coordinates'];
      if (lat == 0 && lng == 0 && coords is List && coords.length >= 2) {
        lng = _toDouble(coords[0]) ?? 0;
        lat = _toDouble(coords[1]) ?? 0;
      }
    }
    return RideLiveRider(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      vehicleType: (json['vehicleType'] ?? '').toString(),
      riderStatus: (json['riderStatus'] ?? json['status'] ?? '').toString(),
      latitude: lat,
      longitude: lng,
      distanceKm: _toDouble(json['distanceKm']),
      lastSeen: DateTime.tryParse(json['lastSeen']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// One entry of the backend vehicle catalogue
/// (`GET riders/onboarding/vehicle-enums` → `vehicleType[]`).
///
/// [code] is the `vehicleType` enum verbatim — the same value the fare quote
/// groups by and the broadcast create call sends, so a tile built from this
/// can never book a type the server doesn't know.
class RideVehicleType {
  const RideVehicleType({required this.code, required this.label});

  /// `slug_id`, e.g. `twoWheelerRider`, `goods3Wheeler`.
  final String code;

  /// `slug_value` — the server's own display name, falling back to the app's
  /// name table when the payload omits it.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideVehicleType &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
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

  /// Maps the backend's `status` string onto the UI lifecycle.
  ///
  /// Covers the broadcast vocabulary (`pending` / `payment-pending` /
  /// `confirmed` / `in-progress` / `rejected`) documented in
  /// RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md §3, alongside the older
  /// spellings so nothing regresses if either is sent.
  ///
  /// Hyphens are normalised to underscores first, so `payment-pending` and
  /// `PAYMENT_PENDING` both land on the same branch.
  static RideStatus fromString(String? raw) {
    final key = (raw ?? '').toUpperCase().replaceAll('-', '_').trim();
    switch (key) {
      case 'PENDING':
        // Broadcast waves are still ringing riders — nobody has won yet.
        return RideStatus.searching;
      case 'PAYMENT_PENDING':
      case 'CONFIRMED':
      case 'ASSIGNED':
      case 'ACCEPTED':
        return RideStatus.assigned;
      case 'ARRIVED':
        return RideStatus.arrived;
      case 'IN_PROGRESS':
      case 'ON_TRIP':
      case 'STARTED':
      // `picked-up` is listed as an active-ride status by
      // RIDER_LOCATION_POLLING_GUIDE.md but is absent from the broadcast
      // guide's §3 table. Unmapped it fell to the `searching` default, which
      // reads as "no captain yet" while the passenger is already in the
      // vehicle — the ETA banner would say "Pickup in —" mid-ride and the
      // hand-off to live tracking would never fire.
      case 'PICKED_UP':
        return RideStatus.onTrip;
      case 'COMPLETED':
        return RideStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
        return RideStatus.cancelled;
      case 'REJECTED':
      case 'NO_RIDERS_FOUND':
      case 'EXPIRED':
        return RideStatus.noRidersFound;
      default:
        // Unknown → keep searching rather than falsely ending the ride. An
        // unrecognised terminal state would strand the user on this screen,
        // which the status poll's own terminal branches will still catch.
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
///
/// Hydrated from three different producers — the status poll's
/// `metadata.assignedRider`, the socket's `ride:queue:accepted.riderInfo`, and
/// the rider-location poll — which do not agree on spelling. [fromJson] accepts
/// all of them so no call site has to hand-pick keys, and [merge] lets a later,
/// thinner payload fill gaps without erasing what an earlier one already knew.
class RideCaptain {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final String? vehicleNumber;
  final String? vehicleModel;

  /// Backend `vehicleType` enum (`twoWheelerRider`, `carMini`, …). Sent on
  /// `assignedRider`; lets the card name the category the customer booked.
  final String? vehicleType;
  final double? rating;

  /// Lifetime completed rides, shown as social proof next to the rating.
  final int? totalOrders;
  final double? latitude;
  final double? longitude;

  const RideCaptain({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
    this.vehicleNumber,
    this.vehicleModel,
    this.vehicleType,
    this.rating,
    this.totalOrders,
    this.latitude,
    this.longitude,
  });

  /// The user service degrades to `"N/A"` when it is briefly unavailable
  /// (contract: fail-soft). That is a placeholder, not a name — treat it as
  /// absent so the UI shows its own fallback instead of a rider called "N/A".
  bool get hasName => name.isNotEmpty && name != 'N/A';

  /// First name for "Message Ramesh"-style copy; empty when unknown.
  String get firstName => hasName ? name.split(' ').first : '';

  factory RideCaptain.fromJson(Map<dynamic, dynamic> json) {
    // Vehicle details arrive nested under `vehicleInformation` in the rider
    // shape the fare/rider APIs return, and flat in the older payloads.
    final vehicle =
        json['vehicleInformation'] is Map ? json['vehicleInformation'] as Map : const {};

    // Coordinates are flat, nested under `location`, or GeoJSON [lng, lat].
    double? lat = _toDouble(json['latitude']);
    double? lng = _toDouble(json['longitude']);
    final location = json['location'];
    if (location is Map) {
      lat ??= _toDouble(location['latitude']);
      lng ??= _toDouble(location['longitude']);
      final coords = location['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng ??= _toDouble(coords[0]);
        lat ??= _toDouble(coords[1]);
      }
    }

    return RideCaptain(
      // `userId` is what the rider-location poll calls it; the status poll and
      // the socket use `riderId`/`id`.
      id: (json['id'] ?? json['riderId'] ?? json['userId'] ?? json['_id'] ?? '')
          .toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? json['contact'] ?? json['contact_no'])?.toString(),
      // `profile_image` is the snake_case spelling the rider APIs actually use.
      photoUrl: (json['photoUrl'] ??
              json['profileImage'] ??
              json['profile_image'])
          ?.toString(),
      vehicleNumber: (json['vehicleNumber'] ??
              vehicle['registrationNo'] ??
              vehicle['registration_no'])
          ?.toString(),
      vehicleModel:
          (json['vehicleModel'] ?? vehicle['vehicleName'] ?? vehicle['model'])
              ?.toString(),
      vehicleType:
          (json['vehicleType'] ?? vehicle['vehicleType'])?.toString(),
      rating: _toDouble(json['rating']),
      totalOrders: _toDouble(json['totalOrders'])?.toInt(),
      latitude: lat,
      longitude: lng,
    );
  }

  /// Overlay [other] onto this captain, keeping existing values where the newer
  /// payload is silent.
  ///
  /// The location poll carries position but rarely the plate; the socket winner
  /// carries the name but no position. Plain replacement makes the card flicker
  /// between them — details appearing, then vanishing on the next tick.
  RideCaptain merge(RideCaptain other) {
    return RideCaptain(
      id: other.id.isNotEmpty ? other.id : id,
      name: other.hasName ? other.name : name,
      phone: other.phone ?? phone,
      photoUrl: other.photoUrl ?? photoUrl,
      vehicleNumber: other.vehicleNumber ?? vehicleNumber,
      vehicleModel: other.vehicleModel ?? vehicleModel,
      vehicleType: other.vehicleType ?? vehicleType,
      rating: other.rating ?? rating,
      totalOrders: other.totalOrders ?? totalOrders,
      latitude: other.latitude ?? latitude,
      longitude: other.longitude ?? longitude,
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

  /// Who ended the ride — `customer`, `rider`, `system`… Present only once
  /// [status] is cancelled. Without it the customer is told "this ride was
  /// cancelled" even when the captain dropped it, which reads like their own
  /// action failed.
  final String? cancelledBy;

  /// Server reason code behind the cancellation, e.g. `TAKING_LONGER`.
  final String? cancellationReason;

  final DateTime? cancelledAt;

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
    this.cancelledBy,
    this.cancellationReason,
    this.cancelledAt,
  });

  /// True when the CAPTAIN ended the ride — the case that needs explaining,
  /// because the customer didn't do it and is left waiting otherwise.
  bool get isCancelledByCaptain {
    final by = cancelledBy?.toLowerCase().trim();
    return by == 'rider' || by == 'captain' || by == 'driver';
  }

  bool get isCancelledByCustomer =>
      cancelledBy?.toLowerCase().trim() == 'customer';

  /// `TAKING_LONGER` → `Taking longer`. Null when the server sent no reason,
  /// so callers can omit the clause rather than print an empty one.
  String? get cancellationReasonLabel {
    final raw = cancellationReason?.trim();
    if (raw == null || raw.isEmpty) return null;
    final words = raw.toLowerCase().replaceAll('_', ' ').trim();
    if (words.isEmpty) return null;
    return words[0].toUpperCase() + words.substring(1);
  }

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
      cancelledBy: json['cancelledBy']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      cancelledAt: DateTime.tryParse(json['cancelledAt']?.toString() ?? ''),
    );
  }

  RideBooking copyWith({
    RideStatus? status,
    RideCaptain? captain,
    int? pickupEtaMinutes,
    int? captainDistanceMeters,
    double? searchProgress,
    double? fare,
    String? startOtp,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? cancelledAt,
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
      startOtp: startOtp ?? this.startOtp,
      captain: captain ?? this.captain,
      pickupEtaMinutes: pickupEtaMinutes ?? this.pickupEtaMinutes,
      captainDistanceMeters:
          captainDistanceMeters ?? this.captainDistanceMeters,
      searchProgress: searchProgress ?? this.searchProgress,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
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
