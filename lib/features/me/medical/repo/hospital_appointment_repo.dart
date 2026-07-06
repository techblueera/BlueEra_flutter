import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';

/// REST surface for the hospital-**appointment** flow described in
/// `lib/docs/healthcare-appointment-ui-integration.md`. Distinct from the
/// (unified) healthcare-enquiry flow:
///   • `POST hospital-appointments` — carries `opd_id` + date/time; the
///     backend creates the in-chat `healthcare_booking` card and emits
///     `newHealthcareBookingReceived`.
///   • `PUT  hospital-appointments/:id/status` — **owner** accepts /
///     declines OR the buyer sends `cancelled` (customer-cancel path,
///     mirroring hotel-booking). Emits `healthcareBookingStatusUpdated`.
///
/// Photos (reports/prescriptions) can be sent as `multipart/form-data`
/// (`payload` JSON part + up to 5 `photos` files) or as already-uploaded
/// URLs in the JSON body. This repo uses multipart when local paths are
/// present, mirroring the hotel-enquiry / hotel-booking pipes.
class HospitalAppointmentRepo extends BaseService {
  Future<ResponseModel> sendHospitalAppointment({
    required Map<String, dynamic> params,
    List<String> photoPaths = const [],
  }) async {
    if (photoPaths.isEmpty) {
      return ApiBaseHelper().postHTTP(
        hospitalAppointments,
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
      hospitalAppointments,
      params: multipartParams,
      isMultipart: true,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// Same endpoint for owner `accepted`/`declined` and customer
  /// `cancelled` — the doc explicitly notes this shape (§2).
  Future<ResponseModel> updateHospitalAppointmentStatus({
    required String appointmentId,
    required Map<String, dynamic> params,
  }) async {
    return ApiBaseHelper().putHTTP(
      hospitalAppointmentStatus(appointmentId),
      params: params,
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// GET one — used by the chat card to hydrate the appointment's true
  /// current status when the local metadata latch is empty.
  Future<ResponseModel> getHospitalAppointmentById(String appointmentId) async {
    return ApiBaseHelper().getHTTP(
      hospitalAppointmentById(appointmentId),
      showProgress: false,
      onSuccess: (_) {},
      onError: (_) {},
    );
  }

  /// Customer outbox — appointments I sent. Supports `status`/`page`/`limit`.
  Future<ResponseModel> getMyHospitalAppointments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      hospitalAppointmentsMe,
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

  /// Owner inbox — appointments on my hospital. Same query params.
  Future<ResponseModel> getOwnerHospitalAppointments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      hospitalAppointmentsOwnerMe,
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
