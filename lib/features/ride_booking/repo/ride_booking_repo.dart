import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// API layer for the Rapido-style ride-booking flow.
///
/// Endpoint contract: docs/backend/RIDE_BOOKING_FRONTEND_INTEGRATION.md
///
/// `showProgress: false` throughout — this flow drives its own inline loading
/// states (shimmer rows, the searching progress bar), and a blocking global
/// spinner on top of a live map reads as a hang.
class RideBookingRepo extends BaseService {
  /// GET recent destinations for the home list.
  Future<ResponseModel> getRecentPlaces({int limit = 10}) {
    return ApiBaseHelper().getHTTP(
      rideRecentPlaces,
      params: {'limit': limit},
      showProgress: false,
    );
  }

  /// GET place autocomplete. [lat]/[lng] bias results toward the user so
  /// "New Market" resolves in their city, not the first match nationally.
  Future<ResponseModel> searchPlaces({
    required String query,
    double? lat,
    double? lng,
  }) {
    return ApiBaseHelper().getHTTP(
      ridePlaceSearch,
      params: {
        'q': query,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
      showProgress: false,
    );
  }

  /// POST a chosen place so it appears in the recents list next time.
  Future<ResponseModel> recordRecentPlace(Map<String, dynamic> place) {
    return ApiBaseHelper().postHTTP(
      ridePlaceSearch,
      params: place,
      showProgress: false,
    );
  }

  /// GET snapped pickup points near a coordinate, for the confirm-pickup map.
  Future<ResponseModel> getPickupPoints({
    required double lat,
    required double lng,
  }) {
    return ApiBaseHelper().getHTTP(
      ridePickupPoints,
      params: {'lat': lat, 'lng': lng},
      showProgress: false,
    );
  }

  /// GET the user's hearted places.
  Future<ResponseModel> getSavedPlaces() {
    return ApiBaseHelper().getHTTP(rideSavedPlaces, showProgress: false);
  }

  /// POST a place into the saved list (heart tap).
  Future<ResponseModel> savePlace(Map<String, dynamic> place) {
    return ApiBaseHelper().postHTTP(
      rideSavedPlaces,
      params: place,
      showProgress: false,
    );
  }

  /// DELETE a saved place (un-heart tap).
  Future<ResponseModel> deleteSavedPlace(String id) {
    return ApiBaseHelper().deleteHTTP(
      rideSavedPlaceById(id),
      showProgress: false,
    );
  }

  /// POST a fare quote for the pickup/drop pair. Returns one option per
  /// available vehicle category.
  Future<ResponseModel> getFareQuote({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> drop,
    List<Map<String, dynamic>> stops = const [],
  }) {
    return ApiBaseHelper().postHTTP(
      rideFareQuote,
      params: {
        'pickup': pickup,
        'drop': drop,
        if (stops.isNotEmpty) 'stops': stops,
      },
      showProgress: false,
    );
  }

  /// POST the booking. [quoteId] locks in the fare the user saw.
  Future<ResponseModel> createBooking({
    required String quoteId,
    required String vehicleCode,
    required String paymentMode,
  }) {
    return ApiBaseHelper().postHTTP(
      rideBookings,
      params: {
        'quoteId': quoteId,
        'vehicleCode': vehicleCode,
        'paymentMode': paymentMode,
      },
      showProgress: false,
    );
  }

  /// GET the booking's current state — the searching/tracking poll.
  Future<ResponseModel> getBookingStatus(String rideId) {
    return ApiBaseHelper().getHTTP(
      rideBookingStatus(rideId),
      showProgress: false,
    );
  }

  /// GET the assigned captain's live position.
  Future<ResponseModel> getCaptainLocation(String rideId) {
    return ApiBaseHelper().getHTTP(
      rideCaptainLocation(rideId),
      showProgress: false,
    );
  }

  /// POST a fare bump while still searching ("+₹20").
  Future<ResponseModel> raiseFare({
    required String rideId,
    required double amount,
  }) {
    return ApiBaseHelper().postHTTP(
      rideRaiseFare(rideId),
      params: {'amount': amount},
      showProgress: false,
    );
  }

  /// GET the cancellation reason list.
  Future<ResponseModel> getCancelReasons() {
    return ApiBaseHelper().getHTTP(rideCancelReasons, showProgress: false);
  }

  /// POST the cancellation.
  Future<ResponseModel> cancelBooking({
    required String rideId,
    required String reasonCode,
    String? comment,
  }) {
    return ApiBaseHelper().postHTTP(
      rideCancelBooking(rideId),
      params: {
        'reasonCode': reasonCode,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      showProgress: false,
    );
  }
}
