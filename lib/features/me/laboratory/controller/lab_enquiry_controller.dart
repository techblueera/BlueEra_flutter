import 'dart:developer';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_enquiry_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:get/get.dart';

/// GetX provider for the customer → laboratory enquiry flow (see
/// `lib/docs/LABORATORY_ENQUIRY_INTEGRATION_GUIDE.md`).
///
/// Contract:
/// - `laboratory_id` is the `LaboratoryProfile._id`.
/// - `tests` / `purpose` / `timeline` are free-form string arrays — the
///   sheet's chip selections flow through unmodified.
/// - At least one of the three arrays or a non-empty `note` is required
///   (server rejects an empty enquiry with 400).
class LabEnquiryController extends GetxController {
  final RxBool isSubmitting = false.obs;

  /// Raise a laboratory enquiry. Returns the new enquiryId on success,
  /// null on failure. The in-chat `healthcare_enquiry` card is delivered
  /// asynchronously by `be_chat_service` after it consumes the Kafka
  /// event — do not block navigation on it.
  Future<String?> submitLaboratoryEnquiry({
    required String laboratoryId,
    required List<String> tests,
    required List<String> purpose,
    required List<String> timeline,
    required String note,
    List<String> photoPaths = const [],
  }) async {
    if (laboratoryId.trim().isEmpty) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    }
    try {
      isSubmitting.value = true;
      AppLoader.show();

      final cleanedTests = tests.where((s) => s.trim().isNotEmpty).toList();
      final cleanedPurpose =
          purpose.where((s) => s.trim().isNotEmpty).toList();
      final cleanedTimeline =
          timeline.where((s) => s.trim().isNotEmpty).toList();
      final trimmedNote = note.trim();

      final body = <String, dynamic>{
        'laboratory_id': laboratoryId,
        if (cleanedTests.isNotEmpty) 'tests': cleanedTests,
        if (cleanedPurpose.isNotEmpty) 'purpose': cleanedPurpose,
        if (cleanedTimeline.isNotEmpty) 'timeline': cleanedTimeline,
        if (trimmedNote.isNotEmpty) 'note': trimmedNote,
      };
      log('[ENQUIRY] laboratory submit → POST '
          'lab-service/laboratory-enquiries '
          'laboratory_id=$laboratoryId photos=${photoPaths.length} body=$body');

      final res = await LabEnquiryRepo().sendLaboratoryEnquiry(
        params: body,
        photoPaths: photoPaths,
      );
      log('[ENQUIRY] laboratory response: '
          'success=${res.isSuccess} statusCode=${res.statusCode} '
          'message=${res.message} data=${res.response?.data}');

      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return null;
      }
      return _extractEnquiryId(res.response?.data);
    } catch (e, st) {
      log('[ENQUIRY] laboratory submit threw: $e\n$st');
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      AppLoader.hide();
      isSubmitting.value = false;
    }
  }

  /// Reads `data.enquiryId` (or `_id` / `id`) from the standard
  /// `{ success, data: {…} }` envelope. Returns empty string when
  /// success came back without an id so the caller still navigates.
  String _extractEnquiryId(dynamic data) {
    final inner = (data is Map ? data['data'] : null);
    if (inner is Map) {
      final id =
          (inner['enquiryId'] ?? inner['_id'] ?? inner['id'])?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return '';
  }
}
