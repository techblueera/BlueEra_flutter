import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// `hospital-service/doctor-appointments*`.
///
/// Note there is NO `opd_id` here — that belongs to the hospital booking API.
/// The doctor's name, specialization and fee are snapshotted server-side, so
/// they are never sent from the client.
class DoctorAppointmentRepo extends BaseService {
  /// `GET /doctor-appointments/owner/me` — the doctor's Booking tab inbox.
  Future<ResponseModel> getOwnerAppointments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      doctorAppointmentsOwnerMe,
      params: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `GET /doctor-appointments/me` — requests the logged-in customer sent.
  Future<ResponseModel> getMyAppointments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return ApiBaseHelper().getHTTP(
      doctorAppointmentsMe,
      params: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  Future<ResponseModel> getAppointmentById({
    required String appointmentId,
  }) async {
    return ApiBaseHelper().getHTTP(
      doctorAppointmentById(appointmentId),
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// Picker paths → [File], dropping anything that no longer exists on disk.
  ///
  /// A stale path is normal: the OS can evict a camera temp file between the
  /// pick and the submit. Sending it would make `MultipartFile.fromFile` throw
  /// mid-upload and fail the whole booking, so a vanished photo is silently
  /// skipped instead — the appointment still goes through.
  static List<File> filesFromPaths(List<String> paths) {
    final out = <File>[];
    for (final path in paths) {
      if (path.trim().isEmpty) continue;
      final file = File(path);
      if (file.existsSync()) out.add(file);
    }
    return out;
  }

  /// `POST /doctor-appointments` — the customer requests an appointment.
  ///
  /// With [photos] this becomes multipart, and the multipart shape is
  /// unusual: ONE text part named `payload` holding the JSON STRING of every
  /// field, plus up to five file parts all named `photos`. Sending the fields
  /// as individual form parts does not work.
  ///
  /// Never auto-retry — you would create a duplicate booking.
  Future<ResponseModel> createAppointment({
    required Map<String, dynamic> body,
    List<File> photos = const [],
    void Function(int, int)? onSendProgress,
  }) async {
    if (photos.isEmpty) {
      return ApiBaseHelper().postHTTP(
        doctorAppointments,
        params: body,
        showProgress: false,
        onError: (_) {},
        onSuccess: (_) {},
      );
    }
    final formData = FormData();
    formData.fields.add(MapEntry('payload', jsonEncode(body)));
    for (final file in photos) {
      formData.files.add(MapEntry(
        'photos',
        await MultipartFile.fromFile(
          file.path,
          filename: p.basename(file.path),
        ),
      ));
    }
    return ApiBaseHelper().postMultiImage(
      doctorAppointments,
      params: formData,
      showProgress: false,
      onSendProgress: onSendProgress,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }

  /// `PUT /doctor-appointments/:id/status`.
  ///
  /// Idempotent for the SAME status (200); a DIFFERENT status on an already
  /// resolved appointment returns 409 — refresh the list, the other party
  /// acted first.
  Future<ResponseModel> updateStatus({
    required String appointmentId,
    required String status,
  }) async {
    return ApiBaseHelper().putHTTP(
      doctorAppointmentStatus(appointmentId),
      params: {'status': status},
      showProgress: false,
      onError: (_) {},
      onSuccess: (_) {},
    );
  }
}
