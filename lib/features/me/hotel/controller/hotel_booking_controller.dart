import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_booking_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the hotel-booking flow. Mirrors
/// [HotelEnquiryController] but for §2b of
/// `lib/docs/enquiry-flows-ui-integration.md`:
///   • [submitHotelBooking] → `POST /hotel-bookings`
///   • [respondToBooking] (owner) → `PUT /:id/status` with
///     `accepted`/`declined`
///   • [cancelBooking] (buyer) → same `/:id/status` endpoint with
///     `cancelled` (booking-only extra transition)
class HotelBookingController extends GetxController {
  static const bool _useStub = false;

  final RxBool isSubmitting = false.obs;

  /// Raise a hotel booking.
  ///
  /// Returns the newly-created booking id on success (or a synthetic
  /// timestamp id in stub mode), and null on failure. The client does
  /// NOT fabricate the chat card — the backend auto-creates it after
  /// the POST succeeds and pushes it via `newHotelBookingReceived`
  /// (see §2b + §"Sockets"). Compare to the vehicle-booking removal in
  /// `vehicle_enquiry_sheet.dart` where fabrication produced duplicates.
  Future<String?> submitHotelBooking({
    required String hotelId,
    String? roomType,
    String? checkIn,
    String? checkOut,
    int? guests,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    try {
      isSubmitting.value = true;
      AppLoader.show();

      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 600));
        return 'stub_${DateTime.now().millisecondsSinceEpoch}';
      }

      final body = <String, dynamic>{
        ApiKeys.hotel_id: hotelId,
        if (roomType != null && roomType.trim().isNotEmpty)
          'roomType': roomType.trim(),
        if (checkIn != null && checkIn.trim().isNotEmpty) 'checkIn': checkIn,
        if (checkOut != null && checkOut.trim().isNotEmpty)
          'checkOut': checkOut,
        if (guests != null && guests > 0) 'guests': guests,
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      log('[BOOKING] hotel submit → POST hotel-service/api/hotel-bookings '
          'hotel_id=$hotelId photos=${photoPaths.length} body=$body');
      final res = await HotelBookingRepo()
          .sendHotelBooking(params: body, photoPaths: photoPaths);
      log('[BOOKING] hotel response: success=${res.isSuccess} '
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
      // Success without an id is unexpected but not fatal — the sheet
      // still lands; the socket-delivered card carries the real id.
      return '';
    } catch (e, st) {
      log('[BOOKING] hotel submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Owner Accept/Decline. 409 (already settled — socket already flipped
  /// the card) is treated as success for idempotency.
  Future<bool> respondToBooking({
    required String bookingId,
    required bool accept,
  }) =>
      _updateStatus(bookingId: bookingId, status: accept ? 'accepted' : 'declined');

  /// Buyer cancel while `pending`. Same endpoint as accept/decline —
  /// the doc §2b explicitly notes this shape for hotel booking.
  Future<bool> cancelBooking(String bookingId) =>
      _updateStatus(bookingId: bookingId, status: 'cancelled');

  Future<bool> _updateStatus({
    required String bookingId,
    required String status,
  }) async {
    if (_useStub) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    log('[BOOKING] hotel updateStatus → PUT '
        'bookingId=$bookingId status=$status');
    try {
      final res = await HotelBookingRepo().updateHotelBookingStatus(
        bookingId: bookingId,
        params: {ApiKeys.status: status},
      );
      log('[BOOKING] hotel updateStatus response: '
          'success=${res.isSuccess} statusCode=${res.statusCode} '
          'message=${res.message}');
      if (res.statusCode == 409) return true;
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      log('[BOOKING] hotel updateStatus threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Fetch the current server-side status of a hotel booking — used by
  /// the chat card as the source-of-truth when the local metadata latch
  /// is empty (fresh login on a new device).
  Future<String?> fetchHotelBookingStatus(String bookingId) async {
    if (bookingId.trim().isEmpty) return null;
    try {
      final res = await HotelBookingRepo().getHotelBookingById(bookingId);
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
