import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_enquiry_repo.dart';
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
  Future<bool> submitHotelEnquiry({
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
        return true;
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
      final res = await HotelEnquiryRepo()
          .sendHotelEnquiry(params: body, photoPaths: photoPaths);
      log('[ENQUIRY] hotel response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message} '
          'data=${res.response?.data}');
      if (!res.isSuccess) {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e, st) {
      log('[ENQUIRY] hotel submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
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
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      log('[ENQUIRY] hotel updateStatus threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  Map<String, List<String>> _toNamedFields(
      Map<String, List<String>> selections) {
    const titleToKey = <String, String>{
      'Room Type': 'roomType',
      'Room Types': 'roomType',
      'Purpose': 'purpose',
      'Amenities': 'amenities',
      'Timeline': 'timeline',
    };
    final out = <String, List<String>>{};
    selections.forEach((title, items) {
      final key = titleToKey[title] ?? title;
      out[key] = items;
    });
    return out;
  }
}
