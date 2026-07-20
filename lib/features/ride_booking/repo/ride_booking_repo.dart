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
  Future<ResponseModel> getDynamicFare({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    String? orderFor,
  }) {
    return ApiBaseHelper().getHTTP(
      getBookingRidersDynamic,
      params: {
        'pickupLatitude': pickupLat,
        'pickupLongitude': pickupLng,
        'dropLatitude': dropLat,
        'dropLongitude': dropLng,
        if (orderFor != null) 'orderFor': orderFor,
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
