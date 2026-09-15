import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two bodies a verified Aadhaar produces, and the rule that both are
/// always written.
///
/// A verified Aadhaar has to satisfy TWO independent readers:
///
///   * `document-service/documents` — what the My Documents screen reads.
///   * the rider onboarding `PUT` — whose `aadhar` flag the rider flow reads.
///
/// Neither endpoint writes the other, and each of the three entry points used
/// to write only one of them, so whichever screen the user had not used yet
/// asked for the same card a second time. These pin the shapes so a change to
/// one body cannot quietly drop the other.
///
/// The bodies are rebuilt here rather than captured from the service: the
/// service's writes go through repos that need a Dio stack, and what is worth
/// protecting is the SHAPE — particularly the `documentType` spelling, which
/// is what the server rejected.
void main() {
  const aadhaar = '571397092762';
  const frontUrl = 'https://example.test/front.jpg';
  const backUrl = 'https://example.test/back.jpg';

  Map<String, dynamic> documentBody() {
    final apiType = DocumentKeys.apiType(DocumentKeys.aadhar);
    return {
      ApiKeys.documentType: apiType,
      ApiKeys.files: {ApiKeys.front: frontUrl, ApiKeys.back: backUrl},
      ApiKeys.value: jsonEncode({apiType: aadhaar}),
    };
  }

  Map<String, dynamic> riderBody({String? front, String? back}) {
    return <String, dynamic>{
      ApiKeys.aadharNo: aadhaar,
      if ((front ?? '').isNotEmpty && (back ?? '').isNotEmpty)
        ApiKeys.aadharImages: {ApiKeys.front: front, ApiKeys.back: back},
    };
  }

  group('document-service body', () {
    /// The exact failure from the bug report:
    /// "AADHAR is not a valid enum value for path documentType".
    test('sends the wire documentType, never the local key', () {
      expect(documentBody()[ApiKeys.documentType], 'aadhar');
    });

    test('keys value by the same string as documentType', () {
      final body = documentBody();
      final decoded =
          jsonDecode(body[ApiKeys.value] as String) as Map<String, dynamic>;

      expect(
        decoded.keys.single,
        body[ApiKeys.documentType],
        reason: 'value and documentType must not disagree about the type',
      );
      expect(decoded.values.single, aadhaar);
    });

    test('carries both sides of the card', () {
      expect(documentBody()[ApiKeys.files],
          {ApiKeys.front: frontUrl, ApiKeys.back: backUrl});
    });
  });

  group('rider onboarding body', () {
    test('carries the number and both images', () {
      expect(riderBody(front: frontUrl, back: backUrl), {
        ApiKeys.aadharNo: aadhaar,
        ApiKeys.aadharImages: {ApiKeys.front: frontUrl, ApiKeys.back: backUrl},
      });
    });

    /// A half-uploaded card reaches the reviewer as an incomplete record, so
    /// the number alone is the better fallback — but the step still gets
    /// ticked, which is the whole point of the bridge.
    test('omits images entirely when only one side uploaded', () {
      expect(riderBody(front: frontUrl, back: null),
          {ApiKeys.aadharNo: aadhaar});
      expect(riderBody(front: null, back: backUrl),
          {ApiKeys.aadharNo: aadhaar});
      expect(riderBody(), {ApiKeys.aadharNo: aadhaar});
    });
  });

  group('the two bodies together', () {
    /// They are different endpoints with different contracts — the point is
    /// not that the bodies match, but that the same verified card reaches
    /// both, under the same number.
    test('agree on the Aadhaar number and the image URLs', () {
      final document = documentBody();
      final rider = riderBody(front: frontUrl, back: backUrl);

      final documentValue =
          jsonDecode(document[ApiKeys.value] as String) as Map<String, dynamic>;

      expect(documentValue.values.single, rider[ApiKeys.aadharNo]);
      expect(document[ApiKeys.files], rider[ApiKeys.aadharImages]);
    });

    test('use different field names, so neither body can be reused as the '
        'other', () {
      final document = documentBody();
      final rider = riderBody(front: frontUrl, back: backUrl);

      expect(document.containsKey(ApiKeys.aadharNo), isFalse);
      expect(rider.containsKey(ApiKeys.documentType), isFalse);
    });
  });
}
