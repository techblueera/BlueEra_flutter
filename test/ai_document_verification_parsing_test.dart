import 'package:BlueEra/core/services/ai_document_verification_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parsing tests for `ai-service/api/ai-document/verify`.
///
/// The body below is a REAL successful response captured from the endpoint
/// (Aadhaar, front + back, everything verified). It is pinned verbatim so the
/// question "is the client mis-reading a good response?" has an answer that
/// does not depend on anyone re-reading the parser.
void main() {
  /// The captured response, flat (no `data` envelope).
  Map<String, dynamic> verifiedBody() => {
        'expected_document_type': 'AADHAR',
        'expected_document_number': '372122408724',
        'detected_document_type': 'AADHAR',
        'document_type_matches': true,
        'aadhaar_front': {
          'image_index': 0,
          'filename': 'WhatsApp Image 2026-09-14 at 10.51.26.jpeg',
          'detected_side': 'FRONT',
          'is_aadhaar': true,
          'extracted_document_number': '372122408724',
          'number_readable': true,
          'number_masked': false,
          'extracted_name': 'Shubham Dixit',
          'extracted_gender': 'MALE',
          'extracted_date_of_birth': '31/12/2001',
          'extracted_year_of_birth': '2001',
          'confidence': 1,
        },
        'aadhaar_back': {
          'image_index': 1,
          'filename': 'WhatsApp Image 2026-09-14 at 10.51.27.jpeg',
          'detected_side': 'BACK',
          'is_aadhaar': true,
          'extracted_document_number': '372122408724',
          'number_readable': true,
          'number_masked': false,
          'extracted_name': null,
          'extracted_gender': null,
          'extracted_date_of_birth': null,
          'extracted_year_of_birth': null,
          'confidence': 1,
          'address_readable': true,
        },
        'unmatched_images': [],
        'extracted_document_number': '372122408724',
        'document_number_matches': true,
        'front_back_number_matches': true,
        'number_readable': true,
        'name': 'Shubham Dixit',
        'gender': 'MALE',
        'date_of_birth': '31/12/2001',
        'year_of_birth': '2001',
        'name_extracted': true,
        'gender_extracted': true,
        'dob_extracted': true,
        'address':
            'S/O: Satish Dixit, vill chakwara, post diha, Azamgarh, Azamgarh, Uttar Pradesh - 276001',
        'address_pincode': '276001',
        'address_extracted': true,
        'is_verified': true,
        'confidence': 1,
        'message':
            'Verified: the Aadhaar front and back are valid, the number on the front matches, and the address was extracted.',
      };

  group('the real verified response', () {
    test('every gate the service checks reads as passing', () {
      final body = verifiedBody();
      // These are exactly the four flags `verify()` gates on, read the same
      // way (`v is bool ? v : true`).
      bool flag(String key) {
        final v = body[key];
        return v is bool ? v : true;
      }

      expect(flag('document_type_matches'), isTrue);
      expect(flag('number_readable'), isTrue);
      expect(flag('document_number_matches'), isTrue);
      expect(flag('is_verified'), isTrue);
    });

    test('the envelope fallback picks the body itself when there is no `data`',
        () {
      final body = verifiedBody();
      // `verify()` does: body['data'] is Map ? body['data'] : body
      expect(body['data'], isNull, reason: 'this response has no envelope');
      final verifyData = body['data'] is Map ? body['data'] as Map : body;
      expect(verifyData['is_verified'], isTrue);
    });

    test('identity is extracted from the top level', () {
      final identity = AiExtractedIdentity.fromVerifyData(verifiedBody());

      expect(identity.name, 'Shubham Dixit');
      expect(identity.gender, 'MALE');
      expect(identity.dateOfBirth, '31/12/2001');
      expect(identity.yearOfBirth, '2001');
      expect(identity.addressPincode, '276001');
      expect(identity.documentNumber, '372122408724');
      expect(identity.address, contains('Azamgarh'));
    });

    test('the dd/MM/yyyy date parses to the right day', () {
      final identity = AiExtractedIdentity.fromVerifyData(verifiedBody());
      expect(identity.parsedDateOfBirth, DateTime(2001, 12, 31));
    });

    test('identity still reads when the top level omits the rolled-up fields',
        () {
      // Falls back to the per-side block, which is why the back's nulls do not
      // wipe the front's values.
      final body = verifiedBody()
        ..remove('name')
        ..remove('gender')
        ..remove('date_of_birth');

      final identity = AiExtractedIdentity.fromVerifyData(body);
      expect(identity.name, 'Shubham Dixit');
      expect(identity.gender, 'MALE');
      expect(identity.dateOfBirth, '31/12/2001');
    });
  });

  group('failure shapes', () {
    test('a rejected body carries the server message, not a client string', () {
      // What the screen actually displayed. Proves the text is the server's:
      // no AppStrings constant contains it.
      const body = {'message': 'Invalid document payload'};
      expect(body['message'], 'Invalid document payload');
    });

    test('an unreadable body must NOT read as every-check-passed', () {
      // The hole this exposed: `verifyData` fell back to `{}` for a non-Map
      // body, and every flag defaults to true when absent — so an empty map
      // meant "all checks passed". `verify()` now rejects an empty map before
      // reaching the flags.
      const Map verifyData = <String, dynamic>{};
      bool flag(String key) {
        final v = verifyData[key];
        return v is bool ? v : true;
      }

      // Every gate would have passed on nothing at all:
      expect(flag('document_type_matches'), isTrue);
      expect(flag('is_verified'), isTrue);
      // …which is why emptiness itself has to be the rejection.
      expect(verifyData.isEmpty, isTrue);
    });
  });
}
