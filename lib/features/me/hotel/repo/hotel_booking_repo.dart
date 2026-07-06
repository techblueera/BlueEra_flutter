import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

/// REST surface for the hotel-**booking** flow described in
/// `lib/docs/enquiry-flows-ui-integration.md` §2b. Distinct from the
/// enquiry flow (§2a, [HotelEnquiryRepo]):
///   • `POST hotel-bookings` — carries dates/guests; the backend creates
///     the in-chat `hotel_booking` card and emits `newHotelBookingReceived`.
///   • `PUT  hotel-bookings/:id/status` — **owner** accepts / declines
///     **or the buyer sends `cancelled`** (booking-only extra transition);
///     emits `hotelBookingStatusUpdated` on the same event.
///
/// Photos can be sent as `multipart/form-data` (`payload` JSON part + up
/// to 5 `photos` files) or as already-uploaded URLs in the JSON body.
/// This repo uses multipart when local paths are present, mirroring the
/// hotel-enquiry flow.
class HotelBookingRepo extends BaseService {
  Future<ResponseModel> sendHotelBooking({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        hotelBookings,
        params: params,
        showProgress: false,
        onSuccess: (_) {},
        onError: (_) {},
      );
    }
    final files = <MultipartFile>[];
    for (final path in photoPaths) {
      files.add(await MultipartFile.fromFile(path));
    }
    final multipartParams = <String, dynamic>{
      'payload': jsonEncode(params),
      'photos': files,
    };
    return ApiBaseHelper().postHTTP(
      hotelBookings,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// Same endpoint for both `accepted`/`declined` (owner) and `cancelled`
  /// (buyer). The doc calls this out as a booking-only quirk vs the four
  /// enquiry verticals — see §2b + §"Notes for the chat card widget".
  Future<ResponseModel> updateHotelBookingStatus({
    required String bookingId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      hotelBookingStatus(bookingId),
      params: params,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET one — used by the chat card to hydrate the booking's current
  /// server-side status.
  Future<ResponseModel> getHotelBookingById(String bookingId) async {
    return ApiBaseHelper().getHTTP(
      hotelBookingById(bookingId),
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// Customer outbox — bookings I sent (doc §2.3
  /// `GET /hotel-bookings/me`). `status` filter allows
  /// `pending`/`accepted`/`declined`/`cancelled`; `limit` server-clamped
  /// to 1..100.
  Future<ResponseModel> getMyHotelBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      hotelBookingsMe,
      params: <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// Owner inbox — bookings on my hotels (doc §2.3
  /// `GET /hotel-bookings/owner/me`). Same query params as the outbox.
  Future<ResponseModel> getOwnerHotelBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      hotelBookingsOwnerMe,
      params: <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }
}
