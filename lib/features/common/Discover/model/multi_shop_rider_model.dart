import 'get_booking_rider_model.dart';

/// Response of `POST /fare/multi-shop/riders`.
///
/// The service sorts the supplied shops furthest → nearest from the user
/// (route begins at the furthest shop), returns the ordered [sortedShops],
/// the [furthestShop] (route start), the total [routeDistanceKm], and the
/// nearby [riders] grouped by vehicle type — identical shape to
/// `GET /fare/riders` (see [VehicleAllResponse]).
class MultiShopRidersResponse {
  final List<SortedShop> sortedShops;
  final SortedShop? furthestShop;
  final double? routeDistanceKm;

  /// Riders near the furthest shop, grouped by vehicle type. Empty
  /// ([VehicleAllResponse] with all-null fields) when none are nearby.
  final VehicleAllResponse riders;

  MultiShopRidersResponse({
    this.sortedShops = const [],
    this.furthestShop,
    this.routeDistanceKm,
    VehicleAllResponse? riders,
  }) : riders = riders ?? VehicleAllResponse();

  factory MultiShopRidersResponse.fromJson(Map<String, dynamic> json) {
    final shops = (json['sortedShops'] as List?)
            ?.map((e) => SortedShop.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        <SortedShop>[];
    return MultiShopRidersResponse(
      sortedShops: shops,
      furthestShop: json['furthestShop'] != null
          ? SortedShop.fromJson(Map<String, dynamic>.from(json['furthestShop']))
          : null,
      routeDistanceKm:
          double.tryParse(json['routeDistanceKm']?.toString() ?? ''),
      // `riders` is `{}` when none are nearby — fromJson safely yields an
      // all-null VehicleAllResponse in that case.
      riders: VehicleAllResponse.fromJson(
        json['riders'] is Map
            ? Map<String, dynamic>.from(json['riders'])
            : <String, dynamic>{},
      ),
    );
  }
}

/// One shop in the sorted multi-stop route. `sequence` 0 = furthest
/// (visited first), `n-1` = nearest to the user.
class SortedShop {
  final String businessId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int sequence;
  final double? distanceFromUserKm;

  SortedShop({
    required this.businessId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.sequence = 0,
    this.distanceFromUserKm,
  });

  factory SortedShop.fromJson(Map<String, dynamic> json) {
    return SortedShop(
      businessId: json['businessId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      sequence: int.tryParse(json['sequence']?.toString() ?? '') ?? 0,
      distanceFromUserKm:
          double.tryParse(json['distanceFromUserKm']?.toString() ?? ''),
    );
  }

  /// Body shape expected by `POST /fare/multi-shop/riders` and
  /// `POST /fare/multi-shop/orders` for each shop. [items] is optional but
  /// recommended for the order call (stored on the GroceryOrder).
  Map<String, dynamic> toRequestJson({List<Map<String, dynamic>>? items}) => {
        'businessId': businessId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (items != null) 'items': items,
      };
}
