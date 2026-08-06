import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// API layer for the Rapido-style BROADCAST ride flow.
///
/// Contract: docs/backend/RIDER_BROADCAST_DISPATCH_FRONTEND_GUIDE.md
///
/// These are the REAL `rider-service/fare/*` endpoints. The imagined
/// `ride-booking-service/*` API this flow was first written against does not
/// exist — see the guide's reconciliation note. What makes a ride a broadcast
/// is one field on create: `orderType: "broadcast"` with no `selectedRiders`.
/// The server then rings nearby riders in expanding waves and the first to
/// accept wins.
///
/// The older hand-picked flow (`Discover/`, `orderType: "standard"` /
/// `"fare-call"`) is untouched and keeps its own repo.
///
/// `showProgress: false` throughout — this flow drives its own inline loading
/// states, and a blocking global spinner over a live map reads as a hang.
class RideBookingRepo extends BaseService {
  /// `GET fare/riders/dynamic` — riders grouped by vehicle type with a
  /// dynamic fare per type. Prices the vehicle list; the customer does NOT
  /// pick a rider from it.
  ///
  /// Takes the same trip-context params as the old hand-picked
  /// `GET fare/riders` (`DiscoverController.getBookingRidersApi`) — they sit on
  /// the same service and the fare/serviceability inputs are the same. Sending
  /// only the four coordinates leaves the server to guess the trip type and
  /// re-derive the distance, which is how a quote ends up disagreeing with the
  /// order created from it.
  ///
  /// [distanceInKm] is ROAD distance, not straight-line — the old flow measures
  /// it off the driving polyline and the fare slabs are built for that number.
  /// [allVehicleTypes] switches the endpoint into CATALOG mode: it returns the
  /// full 12-type fare list — passenger and parcel/goods alike — each with
  /// `ridersAvailable` / `riderCount` / `nearestRiderKm`, and it never answers
  /// with a bare `{}`.
  ///
  /// That is what lets the picker be quoted ONCE per trip. Without it the
  /// response only covers the types with riders nearby, so the screen had to
  /// re-quote every time the user tapped a different vehicle — and an empty
  /// city returned `{}`, leaving nothing to render at all.
  Future<ResponseModel> getDynamicFare({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    String? orderFor,
    int? rangeInKm,
    String? pincode,
    double? distanceInKm,
    bool allVehicleTypes = false,
  }) {
    return ApiBaseHelper().getHTTP(
      getBookingRidersDynamic,
      params: {
        'pickupLatitude': pickupLat,
        'pickupLongitude': pickupLng,
        'dropLatitude': dropLat,
        'dropLongitude': dropLng,
        if (orderFor != null) 'orderFor': orderFor,
        if (rangeInKm != null) 'range_in_km': rangeInKm,
        if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
        if (distanceInKm != null && distanceInKm > 0)
          'distance_in_km': distanceInKm,
        if (allVehicleTypes) 'allVehicleTypes': true,
      },
      showProgress: false,
    );
  }

  /// `GET riders/onboarding/vehicle-enums` — the backend's vehicle catalogue,
  /// `{ vehicleType: [{slug_id, slug_value}], … }`.
  ///
  /// No `type=` filter: that param narrows the list to one rider PROFESSION,
  /// which is the onboarding case. A customer choosing a service needs the
  /// full catalogue. `slug_id` is the same `vehicleType` enum the fare quote
  /// and the broadcast create call speak, so what the customer taps is what
  /// the order carries — no local table to drift out of sync.
  Future<ResponseModel> getVehicleEnums() {
    return ApiBaseHelper().getHTTP(vehicleEnums, showProgress: false);
  }

  /// `GET riders/live-in-radius` — who is live around a point right now.
  ///
  /// Feeds the vehicles drawn on the home map. Discovery only: it does not
  /// reserve, quote or address any of the riders it returns, so it is safe to
  /// call on a tap and cheap to let go stale.
  ///
  /// [vehicleType] is the server's COARSE category (`rider`, `car`, …), not the
  /// `vehicleType` enum a booking carries — see
  /// [RideBookingController.liveRiderCategoryFor].
  Future<ResponseModel> getLiveRidersInRadius({
    required double lat,
    required double lng,
    required String vehicleType,
    int radiusKm = 5,
    int limit = 20,
  }) {
    return ApiBaseHelper().getHTTP(
      ridersLiveInRadius,
      params: {
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
        'vehicleType': vehicleType,
        'limit': limit,
      },
      showProgress: false,
    );
  }

  /// `POST fare/orders` with `orderType: "broadcast"`.
  ///
  /// [selectedRiders] is deliberately absent — sending it would turn this back
  /// into the hand-picked flow. Response carries `orderId`, which the whole
  /// tracking phase is keyed on.
  Future<ResponseModel> createBroadcastOrder({
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropLocation,
    required num fare,
    required String modeOfPayment,
    String orderFor = 'InCity',
    String orderForWhom = 'myself',
    String? vehicleType,
  }) {
    return ApiBaseHelper().postHTTP(
      makeTransportBookOrder,
      params: {
        'orderType': 'broadcast',
        'orderFor': orderFor,
        'pickupLocation': pickupLocation,
        'dropLocation': dropLocation,
        'fare': fare,
        'modeOfPayment': modeOfPayment,
        'orderForWhom': orderForWhom,
        if (vehicleType != null && vehicleType.isNotEmpty)
          'vehicleType': vehicleType,
      },
      showProgress: false,
    );
  }

  /// `GET fare/orders/{orderId}/status` → `{ status, pickupOTP?, metadata }`.
  /// Drives searching → assigned → tracking.
  Future<ResponseModel> getBookingStatus(String orderId) {
    return ApiBaseHelper().getHTTP(
      checkTrackOrderStatus(orderId),
      showProgress: false,
    );
  }

  /// `GET fare/orders/{orderId}/rider-location` → `{ rideActive, rider }`.
  /// Polled ~5s once a rider is attached.
  Future<ResponseModel> getCaptainLocation(String orderId) {
    return ApiBaseHelper().getHTTP(
      riderLiveLocationForOrder(orderId),
      showProgress: false,
    );
  }

  /// `POST fare/orders/{orderId}/cancel` — customer cancels.
  Future<ResponseModel> cancelBooking({
    required String orderId,
    required String reasonCode,
    String? comment,
  }) {
    return ApiBaseHelper().postHTTP(
      cancelFareOrder(orderId),
      params: {
        'reason': reasonCode,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      showProgress: false,
    );
  }
}
