import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/school/repo/education_enquiry_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the education-enquiry flow. Mirrors
/// [HotelEnquiryController]: the sheet calls [submitEducationEnquiry], the
/// in-chat card calls [updateEducationEnquiryStatus]. See
/// `lib/docs/enquiry-flows-ui-integration.md` §3.
class EducationEnquiryController extends GetxController {
  static const bool _useStub = false;

  final RxBool isSubmitting = false.obs;

  /// Raise an education enquiry. [selections] is the grouped chip-
  /// checkbox map keyed by section title (Courses / Admission For /
  /// Requirements / Timeline). Known display titles are mapped to the
  /// snake-case keys the server expects; unknown groups ship verbatim.
  ///
  /// Returns the newly-created enquiry id on success (or a synthetic
  /// timestamp id in stub mode), and null on failure. The sheet needs
  /// the id to fabricate the in-chat card metadata — see
  /// `Docs/backend/education-enquiry-card.md`.
  Future<String?> submitEducationEnquiry({
    required String listingId,
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
        ApiKeys.listing_id: listingId,
        ..._toNamedFields(cleaned),
        if (note.trim().isNotEmpty) ApiKeys.note: note.trim(),
      };
      log('[ENQUIRY] education submit → POST '
          'education-service/education-enquiries '
          'listing_id=$listingId photos=${photoPaths.length} body=$body');
      final res = await EducationEnquiryRepo()
          .sendEducationEnquiry(params: body, photoPaths: photoPaths);
      log('[ENQUIRY] education response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message} '
          'data=${res.response?.data}');
      if (!res.isSuccess) {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong);
        return null;
      }
      // Response shape (per lib/docs/enquiry-flows-ui-integration.md §3):
      // `{ success, data: { enquiryId, status } }`. Accept `_id`/`id` too
      // in case the backend echoes the raw document.
      final data = res.response?.data;
      final inner = (data is Map ? data['data'] : null);
      if (inner is Map) {
        final id = (inner['enquiryId'] ?? inner['_id'] ?? inner['id'])
            ?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
      // Success without an id is unexpected but not fatal — the sheet
      // will still fabricate the card without one; Accept/Decline just
      // won't work until the backend response is fixed.
      return '';
    } catch (e, st) {
      log('[ENQUIRY] education submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Owner accepts / declines from the in-chat card. 409 (already
  /// settled — socket has already flipped the card) is treated as
  /// success for idempotency, matching the hotel / healthcare flows.
  Future<bool> updateEducationEnquiryStatus({
    required String enquiryId,
    required String status,
  }) async {
    if (_useStub) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    log('[ENQUIRY] education updateStatus → PUT '
        'enquiryId=$enquiryId status=$status');
    try {
      final res = await EducationEnquiryRepo().updateEducationEnquiryStatus(
        enquiryId: enquiryId,
        params: {ApiKeys.status: status},
      );
      log('[ENQUIRY] education updateStatus response: '
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
      log('[ENQUIRY] education updateStatus threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Fetch the current server-side status of an education enquiry —
  /// see [HotelEnquiryController.fetchHotelEnquiryStatus] for the
  /// rationale.
  Future<String?> fetchEducationEnquiryStatus(String enquiryId) async {
    if (enquiryId.trim().isEmpty) return null;
    try {
      final res =
          await EducationEnquiryRepo().getEducationEnquiryById(enquiryId);
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

  Map<String, List<String>> _toNamedFields(
      Map<String, List<String>> selections) {
    const titleToKey = <String, String>{
      'Courses': 'courses',
      'Course': 'courses',
      'Admission For': 'admissionFor',
      'Admission': 'admissionFor',
      'Requirements': 'requirements',
      'Requirement': 'requirements',
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
