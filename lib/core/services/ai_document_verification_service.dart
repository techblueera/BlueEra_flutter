import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';

/// What the verifier could READ off the document, on a successful check.
///
/// The endpoint OCRs the card and returns the holder's details alongside the
/// pass/fail flags. Surfacing them lets a caller skip asking for what the
/// document already says — see the gig-work onboarding step, which pre-fills
/// name and date of birth from here.
///
/// Every field is nullable: the verifier reports what it could read, and a
/// blurry or masked card can pass the number check while yielding no name.
class AiExtractedIdentity {
  const AiExtractedIdentity({
    this.name,
    this.gender,
    this.dateOfBirth,
    this.yearOfBirth,
    this.address,
    this.addressPincode,
    this.documentNumber,
  });

  /// As printed on the card, e.g. "Purjanya Pratap".
  final String? name;

  /// As the verifier reports it — upper case, e.g. "MALE". Raw rather than a
  /// parsed enum: this service has no business knowing which gender values a
  /// given form offers, and the card can say things no dropdown lists.
  final String? gender;

  /// As printed, `dd/MM/yyyy` on Aadhaar. Parse with [parsedDateOfBirth].
  final String? dateOfBirth;

  /// Present on cards that carry only a year of birth, not a full date.
  final String? yearOfBirth;
  final String? address;
  final String? addressPincode;
  final String? documentNumber;

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory AiExtractedIdentity.fromVerifyData(Map data) {
    // The verifier reports each detail twice: rolled up at the top level, and
    // on the per-side block it was read from. The top level is authoritative,
    // but it is only populated when the corresponding `*_extracted` flag is
    // true — so the front block is read as a fallback rather than trusting one
    // shape. Everything identifying is printed on the FRONT; the back carries
    // only the address, and its fields come back null.
    final front = data['aadhaar_front'];
    final Map frontData = front is Map ? front : const {};

    return AiExtractedIdentity(
      name: _str(data['name']) ?? _str(frontData['extracted_name']),
      gender: _str(data['gender']) ?? _str(frontData['extracted_gender']),
      dateOfBirth: _str(data['date_of_birth']) ??
          _str(frontData['extracted_date_of_birth']),
      yearOfBirth: _str(data['year_of_birth']) ??
          _str(frontData['extracted_year_of_birth']),
      address: _str(data['address']),
      addressPincode: _str(data['address_pincode']),
      documentNumber: _str(data['extracted_document_number']) ??
          _str(frontData['extracted_document_number']),
    );
  }

  /// [dateOfBirth] as a date, or null when it is absent or in a shape we don't
  /// recognise.
  ///
  /// Tolerant of separator and order because this string is OCR'd off a card
  /// rather than issued by an API: Aadhaar prints `dd/MM/yyyy`, but the
  /// verifier has also been seen returning `dd-MM-yyyy` and ISO `yyyy-MM-dd`.
  /// A four-digit first part is read as the year, otherwise as the day.
  DateTime? get parsedDateOfBirth {
    final raw = dateOfBirth;
    if (raw == null) return null;
    final parts = raw.split(RegExp(r'[/\-.]'));
    if (parts.length != 3) return null;
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);
    if (a == null || b == null || c == null) return null;
    final int year, month, day;
    if (parts[0].length == 4) {
      year = a;
      month = b;
      day = c;
    } else {
      day = a;
      month = b;
      year = c;
    }
    if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final parsed = DateTime(year, month, day);
    // Round-trip guard: DateTime rolls 31 Feb over into March rather than
    // failing, and a rolled-over date is a misread, not a birthday.
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }
}

/// Outcome of an AI document-verification call.
///
/// [failureMessage] is the most actionable reason the document was rejected,
/// ready to show to the user. It is null only when [isValid].
///
/// [extracted] carries what the verifier read off the document, and is only
/// ever populated on a valid result.
class AiDocumentVerificationResult {
  const AiDocumentVerificationResult._(
    this.isValid,
    this.failureMessage, [
    this.extracted,
  ]);

  const AiDocumentVerificationResult.valid({AiExtractedIdentity? extracted})
      : this._(true, null, extracted);

  const AiDocumentVerificationResult.invalid(String message)
      : this._(false, message);

  final bool isValid;
  final String? failureMessage;
  final AiExtractedIdentity? extracted;
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
      return AiDocumentVerificationResult.valid(
        extracted: AiExtractedIdentity.fromVerifyData(verifyData),
      );
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
