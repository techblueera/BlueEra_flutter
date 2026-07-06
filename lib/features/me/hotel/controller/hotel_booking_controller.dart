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
  /// - [roomId] makes the booking **room-level** (doc §2.1): `checkIn` /
  ///   `checkOut` become required and the server derives roomName /
  ///   roomType / pricePerNight from the Room doc, enforcing availability
  ///   against `Room.totalRooms`.
  /// - [enquiryId] links this booking back to a prior hotel enquiry
  ///   raised by the same customer against the same hotel
  ///   (enquiry-first flow).
  ///
  /// Returns the newly-created booking id on success (or a synthetic
  /// timestamp id in stub mode), and null on failure. The client does
  /// NOT fabricate the chat card — the backend auto-creates it after
  /// the POST succeeds and pushes it via `newHotelBookingReceived`.
  Future<String?> submitHotelBooking({
    required String hotelId,
    String? roomId,
    String? enquiryId,
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

      // Client-side guard for the doc's room-level rule (server also
      // enforces with 400 `checkIn and checkOut are required when booking
      // a room`, but failing fast avoids a round-trip).
      final isRoomLevel = roomId != null && roomId.trim().isNotEmpty;
      if (isRoomLevel) {
        final hasIn = checkIn != null && checkIn.trim().isNotEmpty;
        final hasOut = checkOut != null && checkOut.trim().isNotEmpty;
        if (!hasIn || !hasOut) {
          commonSnackBar(
              message: 'Check-in and check-out are required for room booking');
          return null;
        }
      }

      final body = <String, dynamic>{
        ApiKeys.hotel_id: hotelId,
        if (isRoomLevel) 'room_id': roomId.trim(),
        if (enquiryId != null && enquiryId.trim().isNotEmpty)
          'enquiry_id': enquiryId.trim(),
        // Doc §2.1: `roomType` is ignored when `room_id` is sent (server
        // uses the Room's type), so we drop it to keep the wire clean.
        if (!isRoomLevel && roomType != null && roomType.trim().isNotEmpty)
          'roomType': roomType.trim(),
        if (checkIn != null && checkIn.trim().isNotEmpty) 'checkIn': checkIn,
        if (checkOut != null && checkOut.trim().isNotEmpty)
          'checkOut': checkOut,
        if (guests != null && guests > 0) 'guests': guests,
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      log('[BOOKING] hotel submit → POST hotel-service/api/hotel-bookings '
          'hotel_id=$hotelId roomId=$roomId enquiryId=$enquiryId '
          'photos=${photoPaths.length} body=$body');
      final res = await HotelBookingRepo()
          .sendHotelBooking(params: body, photoPaths: photoPaths);
      log('[BOOKING] hotel response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message} '
          'data=${res.response?.data}');
      if (!res.isSuccess) {
        // Doc §2.1: 409 `code: "ROOM_NOT_AVAILABLE"` means the room is
        // fully accepted for the requested dates. Surface it distinctly
        // — a plain "something went wrong" would mislead the buyer.
        if (_isRoomNotAvailable(res)) {
          commonSnackBar(
              message: 'Room is not available for the selected dates');
        } else {
          commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        }
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
      // Doc §2.2: accepting a room-level booking re-checks availability.
      // A 409 `ROOM_NOT_AVAILABLE` on accept means the room is already
      // fully booked for these dates — show it distinctly and DO NOT
      // treat as success.
      if (res.statusCode == 409 && _isRoomNotAvailable(res)) {
        commonSnackBar(
            message:
                'All rooms of this type are already booked for these dates');
        return false;
      }
      // Any other 409 = idempotent (already-resolved / re-sent the same
      // status) — the socket has already flipped the card, so success.
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

  /// Detect the doc §2.1 / §2.2 `code: "ROOM_NOT_AVAILABLE"` shape. The
  /// server tags room-availability 409s with this code so we can render
  /// a specific message rather than the generic "already resolved".
  bool _isRoomNotAvailable(res) {
    if (res.statusCode != 409) return false;
    final data = res.response?.data;
    if (data is Map) {
      if (data['code']?.toString().toUpperCase() == 'ROOM_NOT_AVAILABLE') {
        return true;
      }
      final inner = data['error'];
      if (inner is Map &&
          inner['code']?.toString().toUpperCase() == 'ROOM_NOT_AVAILABLE') {
        return true;
      }
    }
    final msg = res.message?.toString().toLowerCase() ?? '';
    return msg.contains('not available') || msg.contains('overbook');
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
