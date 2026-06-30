import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical/repo/healthcare_enquiry_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the unified healthcare-enquiry flow. Routes the request
/// to the right REST producer based on [category]:
///   • `HOSPITAL` → `hospital-service/hospital-enquiries` (multipart-friendly).
///   • anything else (Doctors / Labs / Pharmacy / Surgical / future) →
///     `user-service/business-enquiries`, which is JSON-only and requires
///     pre-uploaded photo URLs — the controller handles the presign upload
///     transparently so callers can pass local photo paths.
///
/// Both endpoints produce the same in-chat `healthcare_enquiry` card and
/// emit the same socket events, so the in-chat card / status-update code
/// stays single-shape (see lib/docs/healthcare-enquiry-ui-integration.md).
class HealthcareEnquiryController extends GetxController {
  /// Backend is live. Flip to `true` to exercise the sheet offline.
  static const bool _useStub = false;

  /// Server-recognised category for the hospital producer. Anything else
  /// routes through the generic business endpoint.
  static const String categoryHospital = 'HOSPITAL';

  final RxBool isSubmitting = false.obs;

  /// Raise a healthcare enquiry. [selections] is the grouped chip-checkbox
  /// map (each key = section title, e.g. "Departments" / "Test Types"). Only
  /// non-empty arrays are sent — mirrors the server-side "at least one
  /// selection or a note" gating. Returns true on HTTP 2xx (treat 201 as
  /// success — the backend does not return a conversationId).
  Future<bool> submitHealthcareEnquiry({
    required String category,
    required String listingId,
    required Map<String, List<String>> selections,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    final isHospital =
        category.toUpperCase() == categoryHospital;
    try {
      isSubmitting.value = true;
      AppLoader.show();

      if (_useStub) {
        await Future.delayed(const Duration(milliseconds: 600));
        return true;
      }

      // Drop empty selection groups so the body matches the server contract.
      final cleanedSelections = <String, List<String>>{};
      selections.forEach((key, value) {
        final items = value.where((s) => s.trim().isNotEmpty).toList();
        if (items.isNotEmpty) cleanedSelections[key] = items;
      });

      final trimmedNote = note.trim();
      final repo = HealthcareEnquiryRepo();

      if (isHospital) {
        // Hospital endpoint takes the named arrays directly (Departments /
        // Purpose / Timeline) — see §1 of the integration guide. We forward
        // the selections map as-is, mapped to its server-expected lowercase
        // keys when present so the snake-case hospital contract is honoured.
        final body = <String, dynamic>{
          ApiKeys.hospital_id: listingId,
          ..._toHospitalNamedFields(cleanedSelections),
          if (trimmedNote.isNotEmpty) ApiKeys.note: trimmedNote,
        };
        log('[ENQUIRY] healthcare/HOSPITAL submit → POST '
            'hospital-service/hospital-enquiries '
            'hospital_id=$listingId photos=${photoPaths.length} body=$body');
        final res = await repo.sendHospitalEnquiry(
          params: body,
          photoPaths: photoPaths,
        );
        log('[ENQUIRY] healthcare/HOSPITAL response: '
            'success=${res.isSuccess} statusCode=${res.statusCode} '
            'message=${res.message} data=${res.response?.data}');
        if (!res.isSuccess) {
          commonSnackBar(
              message: res.message ?? AppStrings.somethingWentWrong);
          return false;
        }
        return true;
      }

      // Non-hospital: JSON only — photos must be pre-uploaded.
      final photoUrls = photoPaths.isEmpty
          ? const <String>[]
          : await repo.uploadPhotosViaPresign(photoPaths);
      final body = <String, dynamic>{
        ApiKeys.business_id: listingId,
        if (cleanedSelections.isNotEmpty) 'selections': cleanedSelections,
        if (trimmedNote.isNotEmpty) ApiKeys.note: trimmedNote,
        if (photoUrls.isNotEmpty) ApiKeys.photos: photoUrls,
      };
      log('[ENQUIRY] healthcare/$category submit → POST '
          'user-service/business-enquiries '
          'business_id=$listingId photos=${photoUrls.length} body=$body');
      final res = await repo.sendBusinessEnquiry(params: body);
      log('[ENQUIRY] healthcare/$category response: '
          'success=${res.isSuccess} statusCode=${res.statusCode} '
          'message=${res.message} data=${res.response?.data}');
      if (!res.isSuccess) {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e, st) {
      log('[ENQUIRY] healthcare submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Owner accepts / declines from the in-chat card. [category] picks the
  /// right endpoint; [status] is 'accepted' or 'declined'. Returns true on
  /// success; 409 (decision already made — socket already flipped the card)
  /// is treated as success for idempotency.
  Future<bool> updateHealthcareEnquiryStatus({
    required String enquiryId,
    required String category,
    required String status,
  }) async {
    if (_useStub) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    final repo = HealthcareEnquiryRepo();
    final isHospital = category.toUpperCase() == categoryHospital;
    log('[ENQUIRY] healthcare/${isHospital ? 'HOSPITAL' : category} '
        'updateStatus → PUT enquiryId=$enquiryId status=$status');
    try {
      final res = isHospital
          ? await repo.updateHospitalEnquiryStatus(
              enquiryId: enquiryId,
              params: {ApiKeys.status: status},
            )
          : await repo.updateBusinessEnquiryStatus(
              enquiryId: enquiryId,
              params: {ApiKeys.status: status},
            );
      log('[ENQUIRY] healthcare/${isHospital ? 'HOSPITAL' : category} '
          'updateStatus response: success=${res.isSuccess} '
          'statusCode=${res.statusCode} message=${res.message}');
      if (res.statusCode == 409) return true;
      if (!res.isSuccess) {
        commonSnackBar(
            message: res.message ?? AppStrings.somethingWentWrong);
        return false;
      }
      return true;
    } catch (e) {
      log('[ENQUIRY] healthcare/${isHospital ? 'HOSPITAL' : category} '
          'updateStatus threw: $e');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return false;
    }
  }

  /// Hospital endpoint takes the legacy named arrays (`departments`,
  /// `purpose`, `timeline`). The sheet stores them under their display
  /// titles ("Departments" / "Purpose" / "Timeline"), so this maps those
  /// titles to the API keys; any unknown title is forwarded verbatim so
  /// future groups still ship without a code change.
  Map<String, List<String>> _toHospitalNamedFields(
      Map<String, List<String>> selections) {
    const titleToKey = <String, String>{
      'Departments': 'departments',
      'Department': 'departments',
      'Purpose': 'purpose',
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
