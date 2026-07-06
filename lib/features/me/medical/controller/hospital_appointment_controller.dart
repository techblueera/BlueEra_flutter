import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical/repo/hospital_appointment_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the hospital-appointment flow. Mirrors
/// [HotelBookingController] but for
/// `lib/docs/healthcare-appointment-ui-integration.md`:
///   • [submitAppointment] → `POST /hospital-appointments`
///   • [respondToAppointment] (owner) → `PUT /:id/status` with
///     `accepted`/`declined`
///   • [cancelAppointment] (customer) → same `/:id/status` endpoint with
///     `cancelled` (customer-cancel path)
class HospitalAppointmentController extends GetxController {
  final RxBool isSubmitting = false.obs;

  /// Book an appointment with a specific doctor (OPD record).
  ///
  /// Required per doc §1: `hospital_id`, `opd_id`, `appointmentDate`.
  /// [enquiryId] links this appointment back to a prior enquiry raised
  /// by the same customer on the same hospital (enquiry-first flow).
  /// [preferredTime] is free text — OPD `timing` is free text.
  ///
  /// Returns the newly-created appointment id on success, null on
  /// failure. The client does NOT fabricate the chat card — the backend
  /// auto-creates it after POST succeeds and emits
  /// `newHealthcareBookingReceived`.
  Future<String?> submitAppointment({
    required String hospitalId,
    required String opdId,
    required String appointmentDate,
    String? preferredTime,
    String? patientName,
    String? enquiryId,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    try {
      isSubmitting.value = true;
      AppLoader.show();

      // Guard the doc's three required fields client-side. Fails fast
      // avoids a round-trip on a busted call.
      if (hospitalId.trim().isEmpty) {
        commonSnackBar(message: 'A valid hospital_id is required');
        return null;
      }
      if (opdId.trim().isEmpty) {
        commonSnackBar(message: 'Please pick a doctor');
        return null;
      }
      if (appointmentDate.trim().isEmpty) {
        commonSnackBar(message: 'Please pick an appointment date');
        return null;
      }

      final body = <String, dynamic>{
        'hospital_id': hospitalId.trim(),
        'opd_id': opdId.trim(),
        'appointmentDate': appointmentDate,
        if (preferredTime != null && preferredTime.trim().isNotEmpty)
          'preferredTime': preferredTime.trim(),
        if (patientName != null && patientName.trim().isNotEmpty)
          'patientName': patientName.trim(),
        if (enquiryId != null && enquiryId.trim().isNotEmpty)
          'enquiry_id': enquiryId.trim(),
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      log('[APPOINTMENT] hospital submit → POST hospital-appointments '
          'hospital_id=$hospitalId opd_id=$opdId enquiry_id=$enquiryId '
          'photos=${photoPaths.length}');
      final res = await HospitalAppointmentRepo()
          .sendHospitalAppointment(params: body, photoPaths: photoPaths);
      log('[APPOINTMENT] response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message} '
          'data=${res.response?.data}');
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return null;
      }
      final data = res.response?.data;
      final inner = (data is Map ? data['data'] : null);
      if (inner is Map) {
        final id = (inner['appointmentId'] ?? inner['_id'] ?? inner['id'])
            ?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
      // Success without an id is unexpected but not fatal — the
      // socket-delivered card carries the real id.
      return '';
    } catch (e, st) {
      log('[APPOINTMENT] submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Owner Accept/Decline. 409 (already settled — socket already flipped
  /// the card) is treated as success for idempotency.
  Future<bool> respondToAppointment({
    required String appointmentId,
    required bool accept,
  }) =>
      _updateStatus(
          appointmentId: appointmentId,
          status: accept ? 'accepted' : 'declined');

  /// Customer cancel while `pending` **or** `accepted` (doc §2). Same
  /// endpoint as accept/decline.
  Future<bool> cancelAppointment(String appointmentId) =>
      _updateStatus(appointmentId: appointmentId, status: 'cancelled');

  Future<bool> _updateStatus({
    required String appointmentId,
    required String status,
  }) async {
    log('[APPOINTMENT] updateStatus → PUT '
        'appointmentId=$appointmentId status=$status');
    try {
      final res = await HospitalAppointmentRepo()
          .updateHospitalAppointmentStatus(
        appointmentId: appointmentId,
        params: {ApiKeys.status: status},
      );
      log('[APPOINTMENT] updateStatus response: '
          'success=${res.isSuccess} statusCode=${res.statusCode} '
          'message=${res.message}');
      // 409 = terminal / re-sent same status → idempotent success;
      // socket has already flipped the card.
      if (res.statusCode == 409) return true;
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      log('[APPOINTMENT] updateStatus threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Source-of-truth status fetch for a card that lost its local latch
  /// (fresh login on a new device). Returns lowercased status or null
  /// on failure.
  Future<String?> fetchAppointmentStatus(String appointmentId) async {
    if (appointmentId.trim().isEmpty) return null;
    try {
      final ResponseModel res =
          await HospitalAppointmentRepo()
              .getHospitalAppointmentById(appointmentId);
      if (!res.isSuccess) return null;
      final data = res.response?.data;
      final inner = (data is Map ? (data['data'] ?? data) : null);
      if (inner is Map) {
        final status = inner['status']?.toString();
        if (status != null && status.isNotEmpty) return status.toLowerCase();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
