import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/delivery_partner/repo/delivery_partner_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/repo/my_document_repo.dart';
import 'package:flutter/foundation.dart';

/// What [AadhaarRecordService.recordEverywhere] managed to write.
///
/// Both halves are reported rather than collapsed into one boolean: the three
/// callers care about different halves, and a caller that blocks its user on
/// the wrong one either strands them on a form for bookkeeping they cannot see
/// or waves them through a record that was never saved.
@immutable
class AadhaarRecordResult {
  const AadhaarRecordResult({
    required this.documentRecorded,
    required this.riderOnboardingRecorded,
    this.documentFailureMessage,
  });

  /// The Aadhaar now exists in `document-service`, so the My Documents screen
  /// shows it and will not ask again.
  final bool documentRecorded;

  /// The rider onboarding `aadhar` step is ticked, so the rider flow will not
  /// ask again.
  final bool riderOnboardingRecorded;

  /// The server's reason for refusing the document write, when it gave one.
  final String? documentFailureMessage;
}

/// Writes ONE verified Aadhaar into BOTH places that can ask for it.
///
/// ## Why this exists
///
/// The app has two independent Aadhaar records and three entry points, and
/// each entry point used to write exactly one of them:
///
/// * `document-service/documents` — what the **My Documents** screen reads.
/// * The rider onboarding `PUT` — whose `aadhar` flag the **rider flow**
///   reads. The two are separate stores; neither endpoint writes the other.
///
/// So a gig worker who verified during signup was asked again the first time
/// they opened My Documents, and a rider who uploaded through My Documents was
/// asked again the first time they opened the rider flow. Each entry point had
/// fixed its own direction and left the other one broken.
///
/// Every caller now routes through here, so a verified Aadhaar satisfies both
/// readers no matter where it was entered.
///
/// ## What it does not do
///
/// It does not upload. Callers pass URLs they have already uploaded, because
/// every one of them had a copy on S3 before this existed — uploading here
/// would mean sending each image twice.
///
/// It does not throw, and it raises no snackbar. Which half is fatal depends
/// entirely on which screen the user is standing on, so the decision is the
/// caller's; this reports and lets them choose.
class AadhaarRecordService {
  const AadhaarRecordService._();

  static Future<AadhaarRecordResult> recordEverywhere({
    required String aadhaarNumber,
    required String frontUrl,
    required String backUrl,
  }) async {
    // Concurrent: the two stores are unrelated, and running them in sequence
    // would put a second round trip in front of a user waiting on a spinner.
    final results = await Future.wait([
      _recordDocument(
        aadhaarNumber: aadhaarNumber,
        frontUrl: frontUrl,
        backUrl: backUrl,
      ),
      recordRiderOnboarding(
        aadhaarNumber: aadhaarNumber,
        frontUrl: frontUrl,
        backUrl: backUrl,
      ),
    ]);

    final document = results[0] as _WriteOutcome;
    final rider = results[1] as bool;

    return AadhaarRecordResult(
      documentRecorded: document.ok,
      riderOnboardingRecorded: rider,
      documentFailureMessage: document.message,
    );
  }

  /// The `document-service` record — the one My Documents reads.
  static Future<_WriteOutcome> _recordDocument({
    required String aadhaarNumber,
    required String frontUrl,
    required String backUrl,
  }) async {
    try {
      // The WIRE spelling. Posting the local "AADHAR" is refused outright with
      // `400 Invalid document payload`; see [DocumentKeys.apiType]. `value` is
      // keyed by the same string so the two can never disagree.
      final apiType = DocumentKeys.apiType(DocumentKeys.aadhar);
      final response = await MyDocumentRepo().addDocument(params: {
        ApiKeys.documentType: apiType,
        ApiKeys.files: {
          ApiKeys.front: frontUrl,
          ApiKeys.back: backUrl,
        },
        ApiKeys.value: jsonEncode({apiType: aadhaarNumber}),
      });
      if (response.isSuccess) return const _WriteOutcome(ok: true);
      return _WriteOutcome(ok: false, message: response.message);
    } catch (e, s) {
      debugPrint('❌ Aadhaar document record failed: $e\n$s');
      return const _WriteOutcome(ok: false);
    }
  }

  /// The rider onboarding record — the one whose `aadhar` flag the rider flow
  /// reads.
  ///
  /// Public because the gig-work bridge still needs a number-only version when
  /// its images could not be uploaded: the flag is worth setting on its own,
  /// and the number alone is a better record than nothing. Pass null URLs for
  /// that case.
  static Future<bool> recordRiderOnboarding({
    required String aadhaarNumber,
    String? frontUrl,
    String? backUrl,
  }) async {
    try {
      final response =
          await DeliveryPartnerRepo().ridersOnboardingPersonalIdentificationRepo(
        params: <String, dynamic>{
          ApiKeys.aadharNo: aadhaarNumber,
          // Only when BOTH are present: a half-uploaded card reaches the
          // reviewer as an incomplete record, and the number alone is the
          // better fallback.
          if ((frontUrl ?? '').isNotEmpty && (backUrl ?? '').isNotEmpty)
            ApiKeys.aadharImages: {
              ApiKeys.front: frontUrl,
              ApiKeys.back: backUrl,
            },
        },
      );
      return response.isSuccess;
    } catch (e, s) {
      debugPrint('❌ Aadhaar rider-onboarding record failed: $e\n$s');
      return false;
    }
  }
}

@immutable
class _WriteOutcome {
  const _WriteOutcome({required this.ok, this.message});
  final bool ok;
  final String? message;
}
