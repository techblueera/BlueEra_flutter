import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';

/// Outcome of an AI document-verification call.
///
/// [failureMessage] is the most actionable reason the document was rejected,
/// ready to show to the user. It is null only when [isValid].
class AiDocumentVerificationResult {
  const AiDocumentVerificationResult._(this.isValid, this.failureMessage);

  const AiDocumentVerificationResult.valid() : this._(true, null);

  const AiDocumentVerificationResult.invalid(String message)
      : this._(false, message);

  final bool isValid;
  final String? failureMessage;
}

/// Verifies document images against the number the user typed, via the AI
/// document service (`ai-service/api/ai-document/verify`).
///
/// Shared by every KYC surface that uploads a document image — the personal
/// documents flow (Aadhaar / PAN / Driving Licence / RC) and the Aadhaar
/// manual-verification fallback.
class AiDocumentVerificationService extends BaseService {
  /// `document_name` values the endpoint understands.
  static const String aadhaar = 'Aadhar';
  static const String pan = 'PAN';
  static const String drivingLicense = 'Driving License';
  static const String vehicleRc = 'RC';

  /// Verifies [images] against [documentNumber] for a [documentName] drawn from
  /// the constants above.
  ///
  /// Every failure — a rejected document, a non-2xx response, an unreadable
  /// body, a thrown exception — resolves to an invalid result. A document is
  /// never treated as verified on the strength of a check that did not actually
  /// complete, so callers can gate an upload on [AiDocumentVerificationResult.isValid]
  /// alone.
  Future<AiDocumentVerificationResult> verify({
    required String documentName,
    required String documentNumber,
    required List<File> images,
  }) async {
    try {
      final imageParts = await multiPartMultipleImages(arrImages: images);

      final response = await ApiBaseHelper().postHTTP(
        aiDocumentVerify,
        params: <String, dynamic>{
          ApiKeys.documentName: documentName,
          ApiKeys.documentNumber: documentNumber,
          ApiKeys.images: imageParts,
        },
        isMultipart: true,
        showProgress: false,
        onError: (error) {},
        onSuccess: (data) {},
      );

      if (!response.isSuccess) {
        return AiDocumentVerificationResult.invalid(
          _messageOf(response.message) ?? AppStrings.documentVerificationFailed,
        );
      }

      // The verifier returns per-check booleans:
      //   document_type_matches   — the image is the document we asked for
      //   number_readable         — the number on the image is legible
      //   document_number_matches — it matches the number the user typed
      //   is_verified             — overall pass/fail
      // They sit under `data` (or at the body root).
      final body = response.response?.data;
      final Map verifyData = (body is Map)
          ? (body['data'] is Map ? body['data'] as Map : body)
          : <String, dynamic>{};

      // A missing flag defaults to true so a document without that check (e.g.
      // no number entered) isn't blocked by an absent field.
      bool flag(String key) {
        final v = verifyData[key];
        return v is bool ? v : true;
      }

      if (!flag('document_type_matches')) {
        return const AiDocumentVerificationResult.invalid(
            AppStrings.docTypeMismatch);
      }
      if (!flag('number_readable')) {
        return const AiDocumentVerificationResult.invalid(
            AppStrings.docNumberNotReadable);
      }
      if (!flag('document_number_matches')) {
        return const AiDocumentVerificationResult.invalid(
            AppStrings.docNumberMismatch);
      }
      if (!flag('is_verified')) {
        return AiDocumentVerificationResult.invalid(
          _messageOf(response.message) ?? AppStrings.documentVerificationFailed,
        );
      }
      return const AiDocumentVerificationResult.valid();
    } catch (e) {
      log('document verification error -- $e');
      return const AiDocumentVerificationResult.invalid(
          AppStrings.documentVerificationFailed);
    }
  }

  /// `ResponseModel.message` is an untyped getter over the raw body — normalise
  /// it to a non-empty string, or null when there's nothing worth showing.
  String? _messageOf(dynamic message) {
    final text = message?.toString();
    return (text != null && text.isNotEmpty) ? text : null;
  }
}
