import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_booking_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the laboratory-**booking** flow
/// (`lib/docs/laboratory-booking-ui-integration.md`).
///
///   • [submitLabBooking]      → POST `/laboratory-bookings`
///   • [respondToLabBooking]   → owner PUT `/:id/status` (accept/decline)
///   • [cancelLabBooking]      → customer PUT `/:id/cancel` while
///                               `pending` OR `accepted` (doc §2b)
///   • [fetchOwnerLabBookings] → RxList inbox for a future owner tab
///
/// Server-side validation to be aware of:
///   • `preferredTime` must match `^([01]\d|2[0-3]):[0-5]\d$` — the sheet
///     picker only ever emits that shape, so the controller passes the
///     string through unmodified.
///   • `collectionMode = HOME` requires a non-empty `address`. The sheet
///     enforces this in its `_canSubmit` gate, so we only strip empties
///     here rather than double-validating.
class LabBookingController extends GetxController {
  final RxBool isSubmitting = false.obs;

  /// Owner-inbox list — parallels [HospitalAppointmentController.ownerAppointments].
  /// Not yet driven by a UI tab (the doc calls out that the in-chat card
  /// consumer is still pending), but wired here so a future tab can bind
  /// without another round of controller work.
  final RxList<Map<String, dynamic>> ownerBookings =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingOwnerBookings = false.obs;

  Future<String?> submitLabBooking({
    required String laboratoryId,
    required String testId,
    required String appointmentDate,
    required String preferredTime, // required per product ask; 24-hour HH:mm
    String? collectionMode, // 'HOME' | 'AT_LAB' (defaults server-side to AT_LAB)
    String? address,
    String? patientName,
    String? enquiryId,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    try {
      isSubmitting.value = true;
      AppLoader.show();

      // Fail fast on the doc's required trio; saves a round-trip.
      if (laboratoryId.trim().isEmpty) {
        commonSnackBar(message: 'A valid laboratory_id is required');
        return null;
      }
      if (testId.trim().isEmpty) {
        commonSnackBar(message: 'Please pick a test');
        return null;
      }
      if (appointmentDate.trim().isEmpty) {
        commonSnackBar(message: 'Please pick an appointment date');
        return null;
      }
      if (preferredTime.trim().isEmpty) {
        commonSnackBar(message: 'Please pick a preferred time');
        return null;
      }
      final mode = (collectionMode ?? '').trim().toUpperCase();
      if (mode == 'HOME' && (address ?? '').trim().isEmpty) {
        commonSnackBar(message: 'Address is required for HOME collection');
        return null;
      }

      final body = <String, dynamic>{
        'laboratory_id': laboratoryId.trim(),
        'test_id': testId.trim(),
        'appointmentDate': appointmentDate,
        'preferredTime': preferredTime.trim(),
        if (mode.isNotEmpty) 'collectionMode': mode,
        if (mode == 'HOME' && (address ?? '').trim().isNotEmpty)
          ApiKeys.address: address!.trim(),
        if (patientName != null && patientName.trim().isNotEmpty)
          'patientName': patientName.trim(),
        if (enquiryId != null && enquiryId.trim().isNotEmpty)
          'enquiry_id': enquiryId.trim(),
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      log('[LAB_BOOKING] submit → POST /laboratory-bookings '
          'laboratory_id=$laboratoryId test_id=$testId mode=$mode '
          'enquiry_id=$enquiryId photos=${photoPaths.length}');

      final res = await LabBookingRepo()
          .sendLabBooking(params: body, photoPaths: photoPaths);
      log('[LAB_BOOKING] response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message} '
          'data=${res.response?.data}');
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return null;
      }
      final data = res.response?.data;
      final inner = (data is Map ? data['data'] : null);
      if (inner is Map) {
        final id = (inner['bookingId'] ?? inner['_id'] ?? inner['id'])
            ?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
      // Success without an id is unexpected but not fatal — the
      // socket-delivered card carries the real id.
      return '';
    } catch (e, st) {
      log('[LAB_BOOKING] submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Owner accept/decline. 409 (already settled — socket already flipped
  /// the card) is treated as success for idempotency.
  Future<bool> respondToLabBooking({
    required String bookingId,
    required bool accept,
  }) async {
    final status = accept ? 'accepted' : 'declined';
    log('[LAB_BOOKING] updateStatus → PUT '
        'bookingId=$bookingId status=$status');
    try {
      final res = await LabBookingRepo().updateLabBookingStatus(
        bookingId: bookingId,
        params: {ApiKeys.status: status},
      );
      log('[LAB_BOOKING] updateStatus response: '
          'success=${res.isSuccess} statusCode=${res.statusCode} '
          'message=${res.message}');
      if (res.statusCode == 409) return true;
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      log('[LAB_BOOKING] updateStatus threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Customer cancels their own booking while it is `pending` OR
  /// `accepted` (doc §2b). Idempotent: 409 (settled through another
  /// path — e.g. owner declined and the socket already flipped the
  /// card) is treated as success so the UI can re-sync without a
  /// snackbar. Mirrors [HospitalAppointmentController.cancelAppointment].
  Future<bool> cancelLabBooking({required String bookingId}) async {
    final id = bookingId.trim();
    if (id.isEmpty) return false;
    log('[LAB_BOOKING] cancel → PUT bookingId=$id');
    try {
      final res = await LabBookingRepo().cancelLabBooking(bookingId: id);
      log('[LAB_BOOKING] cancel response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message}');
      if (res.statusCode == 409) return true;
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      log('[LAB_BOOKING] cancel threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Owner-inbox fetch — `GET /laboratory-bookings/owner/me`.
  Future<void> fetchOwnerLabBookings({String? status}) async {
    try {
      isLoadingOwnerBookings.value = true;
      final res =
          await LabBookingRepo().getOwnerLabBookings(status: status);
      if (!res.isSuccess) {
        log('[LAB_BOOKING] fetchOwnerLabBookings failed: ${res.message}');
        return;
      }
      final data = res.response?.data;
      final list = (data is Map ? data['data'] : null);
      if (list is List) {
        ownerBookings.assignAll(
          list
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList(),
        );
      } else {
        ownerBookings.clear();
      }
    } catch (e, st) {
      log('[LAB_BOOKING] fetchOwnerLabBookings threw: $e\n$st');
    } finally {
      isLoadingOwnerBookings.value = false;
    }
  }

  /// Source-of-truth status fetch for a chat card that lost its local
  /// latch (fresh login on a new device). Returns lowercased status or
  /// null on failure.
  Future<String?> fetchLabBookingStatus(String bookingId) async {
    if (bookingId.trim().isEmpty) return null;
    try {
      final res = await LabBookingRepo().getLabBookingById(bookingId);
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
