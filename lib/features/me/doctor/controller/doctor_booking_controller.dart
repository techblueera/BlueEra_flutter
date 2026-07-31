import 'dart:developer';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/doctor/model/doctor_appointment_model.dart';
import 'package:BlueEra/features/me/doctor/repo/doctor_appointment_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// CUSTOMER side of `hospital-service/doctor-appointments`.
///
/// Deliberately separate from [DoctorAppointmentController], which is the
/// doctor's own inbox (`/owner/me`). The two lists are different collections
/// of the same model with opposite permissions — the owner accepts/declines,
/// the customer creates and cancels — so sharing one controller would mean one
/// `appointments` list serving two screens with two different sources.
class DoctorBookingController extends GetxController {
  final DoctorAppointmentRepo _repo = DoctorAppointmentRepo();

  static const int _pageSize = 20;

  final RxBool isSubmitting = false.obs;

  /// `GET /doctor-appointments/me` — what this customer has booked.
  final RxList<DoctorAppointment> myAppointments = <DoctorAppointment>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString loadError = ''.obs;

  /// Ids currently mid-cancel, so only that card's button spins.
  final RxSet<String> updatingIds = <String>{}.obs;

  int _page = 1;
  DoctorPagination _pagination = const DoctorPagination();

  bool get hasMore => _pagination.hasMore;

  /// Creates the appointment request. Returns the new appointment id on
  /// success (or `''` when the server answered 2xx without one), null on
  /// failure so the caller can skip its follow-up work.
  ///
  /// Guide §3.3: `business_id` + `appointmentDate` are the only required
  /// fields, and `opd_id` / `doctorName` / `specialization` / `fees` must
  /// never be sent — the server snapshots those from the listing.
  ///
  /// NEVER auto-retry this on timeout; a second POST creates a duplicate
  /// booking. The guide's rule is to verify with `GET /doctor-appointments/me`
  /// instead.
  Future<String?> submitAppointment({
    required String businessId,
    required String appointmentDate,
    String? preferredTime,
    String? patientName,
    String? enquiryId,
    String note = '',
    List<String> photoPaths = const [],
  }) async {
    if (isSubmitting.value) return null;
    try {
      isSubmitting.value = true;
      AppLoader.show();

      if (businessId.trim().isEmpty) {
        commonSnackBar(message: AppStrings.somethingWentWrong.tr);
        return null;
      }
      if (appointmentDate.trim().isEmpty) {
        commonSnackBar(message: AppStrings.doctorPickDateError.tr);
        return null;
      }

      final body = <String, dynamic>{
        'business_id': businessId.trim(),
        'appointmentDate': appointmentDate,
        if (preferredTime != null && preferredTime.trim().isNotEmpty)
          'preferredTime': preferredTime.trim(),
        if (patientName != null && patientName.trim().isNotEmpty)
          'patientName': patientName.trim(),
        if (enquiryId != null && enquiryId.trim().isNotEmpty)
          'enquiry_id': enquiryId.trim(),
        if (note.trim().isNotEmpty) 'note': note.trim(),
      };

      log('[DOCTOR-APPT] submit → POST doctor-appointments '
          'business_id=$businessId enquiry_id=$enquiryId '
          'photos=${photoPaths.length}');
      final res = await _repo.createAppointment(
        body: body,
        photos: DoctorAppointmentRepo.filesFromPaths(photoPaths),
      );
      log('[DOCTOR-APPT] response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message}');

      if (!res.isSuccess) {
        commonSnackBar(
          message: res.message?.toString() ?? AppStrings.somethingWentWrong.tr,
        );
        return null;
      }

      final inner = res.data;
      if (inner is Map) {
        final id =
            (inner['appointmentId'] ?? inner['_id'] ?? inner['id'])?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
      // 2xx without an id is unexpected but not fatal — the socket-delivered
      // booking card carries the real id.
      return '';
    } catch (e, st) {
      log('[DOCTOR-APPT] submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return null;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Loads page 1 of the customer's own requests, replacing the list.
  Future<void> fetchMyAppointments() async {
    isLoading.value = true;
    loadError.value = '';
    _page = 1;
    try {
      final response = await _repo.getMyAppointments(page: _page, limit: _pageSize);
      if (!response.isSuccess) {
        loadError.value =
            response.message?.toString() ?? AppStrings.somethingWentWrong.tr;
        return;
      }
      myAppointments.assignAll(DoctorAppointment.listFrom(response.data));
      _pagination = _paginationOf(response.getExtraData('pagination'));
    } on Exception catch (e) {
      loadError.value = '${AppStrings.errorFetchingData.tr}: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Appends the next page. Guarded so hitting the scroll boundary twice
  /// cannot double-fire.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final next = _page + 1;
      final response =
          await _repo.getMyAppointments(page: next, limit: _pageSize);
      if (!response.isSuccess) return;
      myAppointments.addAll(DoctorAppointment.listFrom(response.data));
      _page = next;
      _pagination = _paginationOf(response.getExtraData('pagination'));
    } on Exception {
      // Silent — the loaded pages stay on screen and the user can retry.
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Customer cancel. Server-enforced rule (guide §3.4): allowed from
  /// `pending` AND `accepted`; `declined` / `cancelled` are terminal and
  /// answer 409, which means the other party already resolved it — refresh
  /// rather than retry.
  Future<void> cancel(String appointmentId) async {
    if (appointmentId.isEmpty || updatingIds.contains(appointmentId)) return;
    updatingIds.add(appointmentId);
    try {
      final response = await _repo.updateStatus(
        appointmentId: appointmentId,
        status: DoctorAppointmentStatus.cancelled,
      );
      if (!response.isSuccess) {
        commonSnackBar(
          message: response.message?.toString() ??
              AppStrings.somethingWentWrong.tr,
        );
        if (response.response?.statusCode == 409) {
          await fetchMyAppointments();
        }
        return;
      }
      final index = myAppointments.indexWhere((a) => a.id == appointmentId);
      if (index >= 0) {
        myAppointments[index] = myAppointments[index]
            .copyWithStatus(DoctorAppointmentStatus.cancelled);
      }
      commonSnackBar(
        message: response.message?.toString() ?? AppStrings.successful.tr,
      );
    } on Exception {
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    } finally {
      updatingIds.remove(appointmentId);
    }
  }

  // ── Chat-card mutations ───────────────────────────────────────────
  //
  // The in-chat `healthcare_booking` card drives BOTH sides of a doctor
  // appointment — the doctor accepts/declines, the customer cancels — and both
  // hit the same `PUT /doctor-appointments/:id/status`. These return bool
  // (rather than mutating [myAppointments] like [cancel] above) because the
  // card owns its own optimistic state and only needs to know if the call
  // stuck.

  /// Doctor's Accept / Decline from the chat card.
  Future<bool> respondToAppointment({
    required String appointmentId,
    required bool accept,
  }) =>
      _updateStatusBool(
        appointmentId: appointmentId,
        status: accept
            ? DoctorAppointmentStatus.accepted
            : DoctorAppointmentStatus.declined,
      );

  /// Customer's Cancel from the chat card. Allowed from `pending` AND
  /// `accepted`.
  Future<bool> cancelAppointment(String appointmentId) => _updateStatusBool(
        appointmentId: appointmentId,
        status: DoctorAppointmentStatus.cancelled,
      );

  Future<bool> _updateStatusBool({
    required String appointmentId,
    required String status,
  }) async {
    if (appointmentId.trim().isEmpty) return false;
    try {
      final res = await _repo.updateStatus(
        appointmentId: appointmentId.trim(),
        status: status,
      );
      // 409 = already terminal, or the same status re-sent. The socket has
      // already flipped the card, so treat it as an idempotent success rather
      // than showing the user an error for a state they can see is correct.
      if (res.response?.statusCode == 409) return true;
      if (!res.isSuccess) {
        commonSnackBar(
          message: res.message?.toString() ?? AppStrings.somethingWentWrong.tr,
        );
        return false;
      }
      return true;
    } on Exception catch (e) {
      log('[DOCTOR-APPT] status update threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
      return false;
    }
  }

  DoctorPagination _paginationOf(dynamic raw) => DoctorPagination.fromJson(
        raw is Map ? Map<String, dynamic>.from(raw) : null,
      );
}
