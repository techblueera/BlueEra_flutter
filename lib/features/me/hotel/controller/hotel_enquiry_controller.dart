import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_enquiry_repo.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the hotel-enquiry flow. Wraps [HotelEnquiryRepo] with
/// the same shape used by [PropertyEnquiryController] /
/// [HealthcareEnquiryController] so the bottom-sheet / chat-card code can
/// call it identically. See `lib/docs/enquiry-flows-ui-integration.md` §2a.
class HotelEnquiryController extends GetxController {
  static const bool _useStub = false;

  final RxBool isSubmitting = false.obs;

  /// Raise a hotel enquiry. [selections] is the grouped chip-checkbox
  /// map keyed by section title (Room Type / Purpose / Amenities /
  /// Timeline). The hotel endpoint stores those titles' canonical
  /// lowercase names server-side (`roomType` / `purpose` / `amenities` /
  /// `timeline`), so the controller maps known display titles down to
  /// those keys; unknown groups ship verbatim.
  ///
  /// Returns the newly-created enquiry id on success (or a synthetic
  /// timestamp id in stub mode), and null on failure. The sheet needs
  /// the id to fabricate the in-chat card metadata — see
  /// `Docs/backend/hotel-enquiry-card.md`.
  Future<String?> submitHotelEnquiry({
    required String hotelId,
    required Map<String, List<String>> selections,
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

      final cleaned = <String, List<String>>{};
      selections.forEach((title, items) {
        final list = items.where((s) => s.trim().isNotEmpty).toList();
        if (list.isNotEmpty) cleaned[title] = list;
      });
      final body = <String, dynamic>{
        ApiKeys.hotel_id: hotelId,
        ..._toNamedFields(cleaned),
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      log('[ENQUIRY] hotel submit → POST hotel-service/api/hotel-enquiries '
          'hotel_id=$hotelId photos=${photoPaths.length} body=$body');
      final res = await HotelEnquiryRepo().sendHotelEnquiry(params: body, photoPaths: photoPaths);
      log('[ENQUIRY] hotel response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message} '
          'data=${res.response?.data}');
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return null;
      }
      // Response shape (per lib/docs/enquiry-flows-ui-integration.md §2a):
      // `{ success, data: { enquiryId, status } }`. Accept `_id`/`id` too
      // in case the backend echoes the raw document.
      final data = res.response?.data;
      final inner = (data is Map ? data['data'] : null);
      if (inner is Map) {
        final id = (inner['enquiryId'] ?? inner['_id'] ?? inner['id'])?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
      // Success without an id is unexpected but not fatal — the sheet
      // will skip the card fabrication in that case.
      return '';
    } catch (e, st) {
      log('[ENQUIRY] hotel submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Owner accepts / declines from the in-chat card. 409 (already
  /// settled — socket has already flipped the card) is treated as
  /// success for idempotency, matching the property / healthcare flows.
  Future<bool> updateHotelEnquiryStatus({
    required String enquiryId,
    required String status,
  }) async {
    if (_useStub) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    log('[ENQUIRY] hotel updateStatus → PUT '
        'enquiryId=$enquiryId status=$status');
    try {
      final res = await HotelEnquiryRepo().updateHotelEnquiryStatus(
        enquiryId: enquiryId,
        params: {ApiKeys.status: status},
      );
      log('[ENQUIRY] hotel updateStatus response: '
          'success=${res.isSuccess} statusCode=${res.statusCode} '
          'message=${res.message}');
      if (res.statusCode == 409) return true;
      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      log('[ENQUIRY] hotel updateStatus threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Fetch the current server-side status of a hotel enquiry.
  /// Returns 'pending' / 'accepted' / 'declined' on success, `null` on
  /// failure. Used by the owner chat card as the source-of-truth when
  /// the local Hive latch is empty (e.g., first render on a device the
  /// owner just installed / a fresh login).
  Future<String?> fetchHotelEnquiryStatus(String enquiryId) async {
    if (enquiryId.trim().isEmpty) return null;
    try {
      final res = await HotelEnquiryRepo().getHotelEnquiryById(enquiryId);
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

  Map<String, List<String>> _toNamedFields(Map<String, List<String>> selections) {
    const titleToKey = <String, String>{
      'Room Type': 'roomType',
      'Room Types': 'roomType',
      'Purpose': 'purpose',
      'Amenities': 'amenities',
      'Hotel Amenities': 'hotelAmenities',
      'Room Amenities': 'roomAmenities',
      'Timeline': 'timeline',
    };
    final out = <String, List<String>>{};
    selections.forEach((title, items) {
      final key = titleToKey[title] ?? title;
      out[key] = items;
    });
    return out;
  }

  /// Fetch the hotel-wide amenity keys (Wi-Fi, pool, gym, …). Only the
  /// key names are returned — the enquiry sheet lets the customer pick
  /// any of them regardless of whether the specific hotel has them on,
  /// so the boolean values are dropped.
  Future<List<String>> fetchHotelAmenityKeys() async {
    try {
      final res = await HotelServiceRepo().getHotelAmenitiesRepo();
      if (!res.isSuccess) return const [];
      return _extractBoolKeys(res.response?.data);
    } catch (e) {
      log('[ENQUIRY] hotel amenities fetch threw: $e');
      return const [];
    }
  }

  /// Fetch the per-room amenity template. Calling with an empty roomId
  /// asks the backend for the catalog of available room-amenity keys
  /// with their default flags (see [HotelServiceRepo.getHotelRoomAmenitiesRepo]).
  Future<List<String>> fetchRoomAmenityKeys() async {
    try {
      final res = await HotelServiceRepo().getHotelRoomAmenitiesRepo(roomId: '');
      if (!res.isSuccess) return const [];
      return _extractBoolKeys(res.response?.data);
    } catch (e) {
      log('[ENQUIRY] room amenities fetch threw: $e');
      return const [];
    }
  }

  List<String> _extractBoolKeys(dynamic body) {
    final inner = (body is Map ? body['data'] : null);
    if (inner is! Map) return const [];
    return [
      for (final entry in inner.entries)
        if (entry.value is bool) entry.key.toString(),
    ];
  }
}
