import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

/// REST surface for the customer → laboratory **test booking** flow
/// described in `lib/docs/laboratory-booking-ui-integration.md`.
///
/// Distinct from [LabEnquiryRepo]:
///   • Enquiry (`/laboratory-enquiries`) is the *interest* stage that
///     produces a `healthcare_enquiry` chat card.
///   • Booking (`/laboratory-bookings`) is the *appointment* stage that
///     carries `test_id` + `appointmentDate` + 24-hour `preferredTime`,
///     produces `CREATE_HEALTHCARE_BOOKING` for the chat consumer, and
///     is the enquiry-first hook opened after an enquiry is accepted.
///
/// Photos are sent as `multipart/form-data` (`payload` JSON string +
/// up to 5 `photos` files) when local paths are provided, or as plain
/// JSON otherwise. Mirrors [HospitalAppointmentRepo].
class LabBookingRepo extends BaseService {
  Future<ResponseModel> sendLabBooking({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        laboratoryBookings,
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
      laboratoryBookings,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// PUT: lab owner accepts / declines while the booking is `pending`.
  /// The doc notes `cancelled` exists in the model but no endpoint sets
  /// it yet — customer cancel is deliberately not exposed here.
  Future<ResponseModel> updateLabBookingStatus({
    required String bookingId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      laboratoryBookingStatus(bookingId),
      params: params,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET one — used by the owner chat card to hydrate the booking's
  /// current server-side status.
  Future<ResponseModel> getLabBookingById(String bookingId) async {
    return ApiBaseHelper().getHTTP(
      laboratoryBookingById(bookingId),
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// Customer outbox — bookings I sent. Supports `status`/`page`/`limit`.
  Future<ResponseModel> getMyLabBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      laboratoryBookingsMe,
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

  /// Owner inbox — bookings on my labs.
  Future<ResponseModel> getOwnerLabBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      laboratoryBookingsOwnerMe,
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
